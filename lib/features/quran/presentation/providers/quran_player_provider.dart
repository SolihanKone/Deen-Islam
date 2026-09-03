import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/quran.dart' as q;

import '../../../../core/storage/hive_boxes.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/arabic_playback_speed.dart';
import '../../domain/entities/reciter.dart';
import '../../domain/mushaf_navigation.dart';
import '../../domain/mushaf_translation.dart';
import '../../services/deen_audio_handler.dart';
import '../../services/recitation_audio_cache.dart';
import '../../services/translation_tts_service.dart';
import 'quran_player_state.dart';

export 'quran_player_state.dart';

final quranPlayerProvider =
    NotifierProvider<QuranPlayerController, QuranPlayerState>(
  QuranPlayerController.new,
);

class QuranPlayerController extends Notifier<QuranPlayerState> {
  final AudioPlayer _player = AudioPlayer(handleInterruptions: false);
  final TranslationTtsService _tts = TranslationTtsService();
  bool _advancingMushafPage = false;
  int _playbackEpoch = 0;
  int _activeConcatEpoch = -1;

  bool _sequenceActive = false;
  bool _sequenceCancelled = false;
  bool _sequencePaused = false;
  Completer<void>? _pauseGate;
  Completer<bool>? _arabicWait;
  int _sequenceToken = 0;
  var _sessionReady = false;

  List<String> _arabicQueueUrls = [];
  var _arabicQueueContinuesMushaf = false;
  int? _arabicQueueMushafPage;
  int _prefetchGen = 0;
  int _positionBucket = -1;
  var _lockScreenActive = false;

  /// Prefetch this much upcoming Arabic audio during Arabic-only playback.
  static const _arabicPrefetchAhead = Duration(minutes: 3);
  static const _arabicPrefetchMaxFiles = 20;

  /// Start translation this far before the Arabic ayah ends so the voices overlap.
  static const _translationLead = Duration(milliseconds: 300);

  @override
  QuranPlayerState build() {
    ref.onDispose(() {
      _sequenceCancelled = true;
      _releasePauseGate();
      DeenAudioHandler.instance?.unbind();
      _tts.dispose();
      _player.dispose();
    });
    DeenAudioHandler.instance?.bind(
      onPlay: resume,
      onPause: pause,
      onStop: stop,
      onSkipNext: skipToNextAyah,
      onSkipPrevious: skipToPreviousAyah,
      onSeek: seekCurrentSource,
    );
    // Mid-listen voice / translation-language change: cut current TTS and
    // resume with the new translation voice / edition text.
    ref.listen(settingsProvider, (prev, next) {
      if (prev?.arabicPlaybackSpeed != next.arabicPlaybackSpeed) {
        unawaited(_applyArabicSpeed());
      }
      if (!_sequenceActive || !state.includeTranslationAudio) return;
      final voiceChanged =
          prev?.translationVoiceId != next.translationVoiceId;
      final translationChanged =
          prev?.defaultTranslationId != next.defaultTranslationId;
      if (!voiceChanged && !translationChanged) return;
      if (!state.isPlayingTranslation) return;
      unawaited(_tts.interrupt());
    });
    _initSession();
    _player.positionStream.listen((p) {
      if (state.isPlayingTranslation) return;
      final bucket = p.inMilliseconds ~/ 200;
      if (bucket == _positionBucket && p < state.duration) return;
      _positionBucket = bucket;
      state = state.copyWith(position: p);
      _syncLockScreen();
    });
    _player.durationStream.listen((d) {
      if (d != null && !state.isPlayingTranslation && d != state.duration) {
        state = state.copyWith(duration: d);
        _syncLockScreen();
      }
    });
    _player.playingStream.listen((v) {
      if (state.isPlayingTranslation) return;
      if (state.playing == v) return;
      state = state.copyWith(playing: v);
      _syncLockScreen();
    });
    _player.currentIndexStream.listen((i) {
      if (i == null || state.includeTranslationAudio) return;
      if (ref.read(settingsProvider).repeatAyah &&
          i != state.currentPlaylistIndex) {
        unawaited(
          _player.seek(Duration.zero, index: state.currentPlaylistIndex),
        );
        return;
      }
      state = state.copyWith(currentPlaylistIndex: i, error: null);
      _kickArabicPrefetch();
      _syncLockScreen();
    });
    _player.playerStateStream.listen((ps) async {
      final buffering = ps.processingState == ProcessingState.loading ||
          ps.processingState == ProcessingState.buffering;
      if (buffering != state.loading) {
        state = state.copyWith(loading: buffering);
      }
      if (ps.processingState != ProcessingState.completed) return;
      if (_activeConcatEpoch != _playbackEpoch) return;
      if (!state.includeTranslationAudio &&
          ref.read(settingsProvider).repeatAyah) {
        final index = state.currentPlaylistIndex;
        try {
          await _player.seek(Duration.zero, index: index);
          await _player.play();
        } catch (_) {}
        return;
      }
      if (!state.isMushafPlayback ||
          !state.mushafContinuePages ||
          state.includeTranslationAudio ||
          state.mushafPage == null ||
          _advancingMushafPage) {
        return;
      }
      final lastIndex = state.mushafItems.length - 1;
      if (lastIndex < 0 || state.currentPlaylistIndex < lastIndex) return;
      final nextPage = state.mushafPage! + 1;
      if (nextPage > q.totalPagesCount) return;
      _advancingMushafPage = true;
      try {
        await playMushafPage(nextPage, continuePages: true);
      } finally {
        _advancingMushafPage = false;
      }
    });
    return const QuranPlayerState();
  }

  Future<void> _initSession() async {
    if (_sessionReady) return;
    _sessionReady = true;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
      await session.setActive(true);
      session.becomingNoisyEventStream.listen((_) {
        unawaited(pause());
      });
      // Phone calls send `pause`. Screen lock often sends `unknown` — ignore
      // that so recitation keeps going with the screen off.
      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          if (event.type == AudioInterruptionType.pause) {
            unawaited(pause());
          }
        } else if (event.type == AudioInterruptionType.pause) {
          unawaited(resume());
        }
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Audio session: $e');
      }
    }
  }

  Future<void> _ensureSessionActive() async {
    try {
      final session = await AudioSession.instance;
      await session.setActive(true);
    } catch (_) {}
  }

  Reciter get _reciter {
    final id = ref.read(settingsProvider).reciterId;
    return Reciter.byId(id);
  }

  Future<void> _applyArabicSpeed() async {
    final speed = ArabicPlaybackSpeed.sanitize(
      ref.read(settingsProvider).arabicPlaybackSpeed,
    );
    try {
      await _player.setSpeed(speed);
    } catch (e) {
      if (kDebugMode) debugPrint('Arabic speed: $e');
    }
  }

  void _clearArabicQueue() {
    _arabicQueueUrls = [];
    _arabicQueueContinuesMushaf = false;
    _arabicQueueMushafPage = null;
    _prefetchGen++;
  }

  void _setArabicQueue(
    List<String> urls, {
    required bool continueMushaf,
    int? mushafPage,
  }) {
    _arabicQueueUrls = urls;
    _arabicQueueContinuesMushaf = continueMushaf;
    _arabicQueueMushafPage = mushafPage;
  }

  void _kickArabicPrefetch() {
    if (state.includeTranslationAudio) return;
    if (_arabicQueueUrls.isEmpty) return;
    final gen = ++_prefetchGen;
    unawaited(_prefetchArabicAhead(gen));
  }

  List<String> _upcomingArabicUrls({required int fromIndex}) {
    final urls = <String>[];
    if (fromIndex >= 0 && fromIndex < _arabicQueueUrls.length) {
      urls.addAll(_arabicQueueUrls.sublist(fromIndex));
    }
    if (!_arabicQueueContinuesMushaf) return urls;
    final startPage = _arabicQueueMushafPage;
    if (startPage == null) return urls;
    final reciter = _reciter;
    var page = startPage + 1;
    while (urls.length < _arabicPrefetchMaxFiles &&
        page <= q.totalPagesCount) {
      for (final item in MushafNavigation.playbackItemsOnPage(page)) {
        urls.add(
          item.isBismillah
              ? reciter.bismillahUrl()
              : reciter.ayahUrl(item.surah, item.ayah!),
        );
        if (urls.length >= _arabicPrefetchMaxFiles) break;
      }
      page++;
    }
    return urls;
  }

  Future<void> _prefetchArabicAhead(int gen) async {
    final from = (_player.currentIndex ?? 0) + 1;
    final urls = _upcomingArabicUrls(fromIndex: from);
    var ahead = Duration.zero;
    var count = 0;
    for (final url in urls) {
      if (gen != _prefetchGen) return;
      if (ahead >= _arabicPrefetchAhead || count >= _arabicPrefetchMaxFiles) {
        return;
      }
      try {
        await RecitationAudioCache.instance.prefetch(url);
      } catch (e) {
        if (kDebugMode) debugPrint('Arabic prefetch: $e');
        continue;
      }
      if (gen != _prefetchGen) return;
      ahead += await RecitationAudioCache.instance.estimatedDurationForUrl(url);
      count++;
    }
  }

  String _urlForMushafItem(MushafPlaybackItem item) {
    final r = _reciter;
    return item.isBismillah
        ? r.bismillahUrl()
        : r.ayahUrl(item.surah, item.ayah!);
  }

  bool _arabicPastTranslationLead() {
    if (_player.processingState == ProcessingState.completed) return true;
    final duration = _player.duration;
    if (duration == null || duration <= Duration.zero) return false;
    return duration - _player.position <= _translationLead;
  }

  Future<bool> _waitForTranslationLead({required int token}) async {
    if (_sequenceCancelled || token != _sequenceToken) return false;
    if (_arabicPastTranslationLead()) {
      return !_sequenceCancelled && token == _sequenceToken;
    }

    final done = Completer<bool>();
    _arabicWait = done;

    void finish(bool value) {
      if (!done.isCompleted) done.complete(value);
    }

    void considerLead() {
      if (_sequenceCancelled || token != _sequenceToken) {
        finish(false);
        return;
      }
      if (_arabicPastTranslationLead()) finish(true);
    }

    var armed = _player.playing ||
        _player.processingState == ProcessingState.ready ||
        _player.processingState == ProcessingState.buffering ||
        _player.processingState == ProcessingState.completed;

    late StreamSubscription<PlayerState> subState;
    subState = _player.playerStateStream.listen((ps) {
      if (_sequenceCancelled || token != _sequenceToken) {
        finish(false);
        return;
      }
      if (!armed) {
        if (ps.processingState == ProcessingState.loading ||
            ps.processingState == ProcessingState.buffering ||
            ps.processingState == ProcessingState.ready ||
            ps.playing) {
          armed = true;
          considerLead();
        }
        return;
      }
      if (ps.processingState == ProcessingState.completed) {
        finish(true);
      }
    });
    final subPos = _player.positionStream.listen((_) => considerLead());
    final subDur = _player.durationStream.listen((_) => considerLead());

    try {
      considerLead();
      return await done.future;
    } finally {
      await subState.cancel();
      await subPos.cancel();
      await subDur.cancel();
      if (_arabicWait == done) _arabicWait = null;
    }
  }

  Future<bool> _startArabicAndWaitForLead(
    String url, {
    required int token,
  }) async {
    await _player.setAudioSource(
      await RecitationAudioCache.instance.sourceForUrl(url),
    );
    await _applyArabicSpeed();
    if (_sequenceCancelled || token != _sequenceToken) return false;
    await _ensureSessionActive();
    if (!_sequencePaused) await _player.play();
    if (!_sequenceCancelled && token == _sequenceToken) {
      state = state.copyWith(playing: true, loading: false);
    }
    return _waitForTranslationLead(token: token);
  }

  void _releasePauseGate() {
    final gate = _pauseGate;
    _pauseGate = null;
    if (gate != null && !gate.isCompleted) {
      gate.complete();
    }
  }

  Future<void> _awaitUnpaused() async {
    while (_sequencePaused && !_sequenceCancelled) {
      _pauseGate = Completer<void>();
      await _pauseGate!.future;
    }
  }

  Future<void> _cancelSequence() async {
    _sequenceCancelled = true;
    _sequencePaused = false;
    _sequenceToken++;
    _activeConcatEpoch = -1;
    _clearArabicQueue();
    _releasePauseGate();
    final wait = _arabicWait;
    _arabicWait = null;
    if (wait != null && !wait.isCompleted) {
      wait.complete(false);
    }
    await _tts.stop();
  }

  Future<void> _playMushafItems(
    List<MushafPlaybackItem> items, {
    required String recentKey,
  }) async {
    final urls = [
      for (final item in items) _urlForMushafItem(item),
    ];
    _setArabicQueue(
      urls,
      continueMushaf: state.mushafContinuePages,
      mushafPage: state.mushafPage,
    );
    final sources = <AudioSource>[];
    for (final url in urls) {
      sources.add(await RecitationAudioCache.instance.sourceForUrl(url));
    }
    await _player.setAudioSource(
      ConcatenatingAudioSource(children: sources),
    );
    await _applyArabicSpeed();
    await _player.play();
    _activeConcatEpoch = _playbackEpoch;
    state = state.copyWith(playing: true, loading: false);
    _kickArabicPrefetch();
    _syncLockScreen();
    await _pushRecent(recentKey);
  }

  Future<void> playMushafPage(
    int pageNumber, {
    bool continuePages = false,
  }) async {
    _playbackEpoch++;
    await _cancelSequence();
    await _player.stop();
    final items = MushafNavigation.playbackItemsOnPage(pageNumber);
    if (items.isEmpty) return;

    final withTranslation = ref.read(settingsProvider).showTranslation;
    state = QuranPlayerState(
      loading: true,
      isMushafPlayback: true,
      mushafPage: pageNumber,
      mushafItems: items,
      mushafContinuePages: continuePages,
      currentPlaylistIndex: 0,
      includeTranslationAudio: withTranslation,
    );
    try {
      if (withTranslation) {
        await _runMushafSequenceWithTranslations(
          startPage: pageNumber,
          startItems: items,
          continuePages: continuePages,
          recentKey: 'mushaf|page|$pageNumber',
        );
      } else {
        await _playMushafItems(
          items,
          recentKey: 'mushaf|page|$pageNumber',
        );
      }
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  /// Jump to a specific ayah (or bismillah) on its page and keep reciting.
  Future<void> playMushafFromItem(
    MushafPlaybackItem from, {
    bool continuePages = true,
  }) async {
    _playbackEpoch++;
    await _cancelSequence();
    await _player.stop();
    final pageNumber = from.isBismillah
        ? MushafNavigation.pageForSurah(from.surah)
        : q.getPageNumber(from.surah, from.ayah!);
    final pageItems = MushafNavigation.playbackItemsOnPage(pageNumber);
    final startIndex = pageItems.indexWhere(
      (item) =>
          item.isBismillah == from.isBismillah &&
          item.surah == from.surah &&
          item.ayah == from.ayah,
    );
    if (startIndex < 0) {
      await playMushafPage(pageNumber, continuePages: continuePages);
      return;
    }

    final items = pageItems.sublist(startIndex);
    final recentKey = from.isBismillah
        ? 'mushaf|bismillah|${from.surah}'
        : 'mushaf|${from.surah}|${from.ayah}';

    final withTranslation = ref.read(settingsProvider).showTranslation;
    state = QuranPlayerState(
      loading: true,
      isMushafPlayback: true,
      mushafPage: pageNumber,
      mushafItems: items,
      mushafContinuePages: continuePages,
      currentPlaylistIndex: 0,
      includeTranslationAudio: withTranslation,
    );
    try {
      if (withTranslation) {
        await _runMushafSequenceWithTranslations(
          startPage: pageNumber,
          startItems: items,
          continuePages: continuePages,
          recentKey: recentKey,
        );
      } else {
        await _playMushafItems(items, recentKey: recentKey);
      }
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> _runMushafSequenceWithTranslations({
    required int startPage,
    required List<MushafPlaybackItem> startItems,
    required bool continuePages,
    required String recentKey,
  }) async {
    final token = ++_sequenceToken;
    _sequenceCancelled = false;
    _sequencePaused = false;
    _sequenceActive = true;
    await _pushRecent(recentKey);

    var page = startPage;
    var items = startItems;

    try {
      while (true) {
        if (_sequenceCancelled || token != _sequenceToken) return;

        state = state.copyWith(
          mushafPage: page,
          mushafItems: items,
          mushafContinuePages: continuePages,
          isMushafPlayback: true,
          includeTranslationAudio: true,
        );

        for (var i = 0; i < items.length; i++) {
          if (_sequenceCancelled || token != _sequenceToken) return;
          await _awaitUnpaused();
          if (_sequenceCancelled || token != _sequenceToken) return;

          final item = items[i];
          state = state.copyWith(
            currentPlaylistIndex: i,
            isPlayingTranslation: false,
            error: null,
          );
          _syncLockScreen();

          if (item.isBismillah || item.ayah == null) {
            final finishedArabic =
                await _playMushafItemAndWait(item, token: token);
            if (!finishedArabic ||
                _sequenceCancelled ||
                token != _sequenceToken) {
              return;
            }
            if (ref.read(settingsProvider).repeatAyah) {
              i--;
            }
            continue;
          }

          final r = _reciter;
          final currentWarm = _prefetchMushafTranslation(item);
          final finishedLead = await _startArabicAndWaitForLead(
            r.ayahUrl(item.surah, item.ayah!),
            token: token,
          );
          if (!finishedLead ||
              _sequenceCancelled ||
              token != _sequenceToken) {
            return;
          }

          await currentWarm;
          if (_sequenceCancelled || token != _sequenceToken) return;
          await _awaitUnpaused();
          if (_sequenceCancelled || token != _sequenceToken) return;

          MushafPlaybackItem? nextPlayable;
          for (var j = i + 1; j < items.length; j++) {
            if (!items[j].isBismillah && items[j].ayah != null) {
              nextPlayable = items[j];
              break;
            }
          }
          if (nextPlayable == null &&
              continuePages &&
              page < q.totalPagesCount) {
            final nextItems = MushafNavigation.playbackItemsOnPage(page + 1);
            for (final next in nextItems) {
              if (!next.isBismillah && next.ayah != null) {
                nextPlayable = next;
                break;
              }
            }
          }
          if (nextPlayable != null) {
            unawaited(_prefetchMushafTranslation(nextPlayable));
          }

          while (!_sequenceCancelled && token == _sequenceToken) {
            final latest = ref.read(settingsProvider);
            final voice = latest.translationVoiceId;
            final editionId = latest.defaultTranslationId;
            final edition = MushafTranslation.fromEditionId(editionId);
            final text = q
                .getVerseTranslation(
                  item.surah,
                  item.ayah!,
                  translation: edition,
                )
                .trim();
            if (text.isEmpty) break;

            state = state.copyWith(
              isPlayingTranslation: true,
              playing: true,
              loading: true,
              position: Duration.zero,
              duration: Duration.zero,
            );
            late final bool finished;
            try {
              finished = await _tts.speak(
                text,
                translationId: editionId,
                voice: voice,
                onAudioReady: () {
                  if (!_sequenceCancelled && token == _sequenceToken) {
                    state = state.copyWith(loading: false);
                  }
                },
              );
            } catch (e) {
              if (_sequenceCancelled || token != _sequenceToken) return;
              state = state.copyWith(
                isPlayingTranslation: false,
                loading: false,
                error: e.toString(),
              );
              break;
            }
            if (_sequenceCancelled || token != _sequenceToken) return;
            if (_sequencePaused) {
              state = state.copyWith(
                isPlayingTranslation: false,
                playing: false,
              );
              await _awaitUnpaused();
              continue;
            }
            final stillSame = ref.read(settingsProvider).translationVoiceId ==
                    voice &&
                ref.read(settingsProvider).defaultTranslationId == editionId;
            if (!finished || !stillSame) {
              continue;
            }
            state = state.copyWith(isPlayingTranslation: false);
            break;
          }
          if (ref.read(settingsProvider).repeatAyah) {
            i--;
          }
        }

        if (!continuePages) break;
        page += 1;
        if (page > q.totalPagesCount) break;
        items = MushafNavigation.playbackItemsOnPage(page);
        if (items.isEmpty) break;
      }

      if (token == _sequenceToken && !_sequenceCancelled) {
        state = state.copyWith(
          playing: false,
          isPlayingTranslation: false,
          loading: false,
        );
      }
    } catch (e) {
      if (token == _sequenceToken) {
        state = state.copyWith(
          loading: false,
          playing: false,
          isPlayingTranslation: false,
          error: e.toString(),
        );
      }
    } finally {
      if (token == _sequenceToken) {
        _sequenceActive = false;
      }
    }
  }

  Future<void> _prefetchMushafTranslation(MushafPlaybackItem item) async {
    if (item.isBismillah || item.ayah == null) return;
    final settings = ref.read(settingsProvider);
    final edition = MushafTranslation.fromEditionId(
      settings.defaultTranslationId,
    );
    final text = q
        .getVerseTranslation(
          item.surah,
          item.ayah!,
          translation: edition,
        )
        .trim();
    if (text.isEmpty) return;
    await _tts.prefetch(
      text,
      translationId: settings.defaultTranslationId,
      voice: settings.translationVoiceId,
    );
  }

  Future<bool> _playMushafItemAndWait(
    MushafPlaybackItem item, {
    required int token,
  }) async {
    final r = _reciter;
    final url = item.isBismillah
        ? r.bismillahUrl()
        : r.ayahUrl(item.surah, item.ayah!);

    final done = Completer<bool>();
    _arabicWait = done;
    var armed = false;
    late StreamSubscription<PlayerState> sub;
    sub = _player.playerStateStream.listen((ps) {
      if (_sequenceCancelled || token != _sequenceToken) {
        if (!done.isCompleted) done.complete(false);
        return;
      }
      if (!armed) {
        if (ps.processingState == ProcessingState.loading ||
            ps.processingState == ProcessingState.buffering ||
            ps.processingState == ProcessingState.ready ||
            ps.playing) {
          armed = true;
        }
        return;
      }
      if (ps.processingState == ProcessingState.completed) {
        if (!done.isCompleted) done.complete(true);
      }
    });

    try {
      await _player.setAudioSource(
        await RecitationAudioCache.instance.sourceForUrl(url),
      );
      await _applyArabicSpeed();
      if (_sequenceCancelled || token != _sequenceToken) return false;
      if (!_sequencePaused) await _player.play();
      return await done.future;
    } finally {
      await sub.cancel();
      if (_arabicWait == done) _arabicWait = null;
    }
  }

  Future<void> _playAyahList(
    List<MushafAyahRef> ayahs, {
    required String recentKey,
  }) async {
    final items = [
      for (final a in ayahs)
        (isBismillah: false, surah: a.surah, ayah: a.ayah),
    ];
    await _playMushafItems(items, recentKey: recentKey);
  }

  bool _shouldPlayTranslations(Map<int, String>? translations) {
    return ref.read(settingsProvider).showTranslation;
  }

  Future<void> playFullSurah(
    int surahNumber,
    int ayahCount, {
    Map<int, String>? translations,
  }) async {
    _playbackEpoch++;
    await _cancelSequence();
    await _player.stop();

    final withTranslation = _shouldPlayTranslations(translations);
    state = QuranPlayerState(
      loading: true,
      surahNumber: surahNumber,
      ayahCount: ayahCount,
      playlistStartAyah: 1,
      currentPlaylistIndex: 0,
      includeTranslationAudio: withTranslation,
    );
    try {
      if (withTranslation) {
        await _runSurahSequence(
          surahNumber: surahNumber,
          startAyah: 1,
          ayahCount: ayahCount,
          translations: translations ?? const {},
          recentKey: '$surahNumber|full|$ayahCount',
        );
      } else {
        final ayahs = [
          for (var i = 1; i <= ayahCount; i++) (surah: surahNumber, ayah: i),
        ];
        await _playAyahList(ayahs, recentKey: '$surahNumber|full|$ayahCount');
      }
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> playFromAyah(
    int surahNumber,
    int startAyahInSurah,
    int ayahCount, {
    Map<int, String>? translations,
  }) async {
    _playbackEpoch++;
    await _cancelSequence();
    await _player.stop();

    final withTranslation = _shouldPlayTranslations(translations);
    state = QuranPlayerState(
      loading: true,
      surahNumber: surahNumber,
      ayahCount: ayahCount,
      playlistStartAyah: startAyahInSurah,
      currentPlaylistIndex: 0,
      includeTranslationAudio: withTranslation,
    );
    try {
      if (withTranslation) {
        await _runSurahSequence(
          surahNumber: surahNumber,
          startAyah: startAyahInSurah,
          ayahCount: ayahCount,
          translations: translations ?? const {},
          recentKey: '$surahNumber|ayah|$startAyahInSurah',
        );
      } else {
        final ayahs = [
          for (var i = startAyahInSurah; i <= ayahCount; i++)
            (surah: surahNumber, ayah: i),
        ];
        await _playAyahList(
          ayahs,
          recentKey: '$surahNumber|ayah|$startAyahInSurah',
        );
      }
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  /// Resume mushaf playback from the current ayah using latest translation mode.
  Future<void> continueMushafWithCurrentSettings() async {
    if (!state.isMushafPlayback) return;
    final item = state.currentMushafItem;
    final page = state.mushafPage;
    final continuePages = state.mushafContinuePages;
    if (item != null) {
      await playMushafFromItem(item, continuePages: continuePages);
      return;
    }
    if (page == null) return;
    await playMushafPage(page, continuePages: continuePages);
  }

  /// Resume surah playback from the current ayah using latest translation mode.
  Future<void> continueSurahWithCurrentSettings({
    Map<int, String>? translations,
  }) async {
    final surah = state.surahNumber;
    if (surah == null || state.ayahCount <= 0) return;
    await playFromAyah(
      surah,
      state.currentAyahInSurah,
      state.ayahCount,
      translations: translations,
    );
  }

  String _liveTranslationText(int surahNumber, int ayah) {
    final edition = MushafTranslation.fromEditionId(
      ref.read(settingsProvider).defaultTranslationId,
    );
    return q
        .getVerseTranslation(surahNumber, ayah, translation: edition)
        .trim();
  }

  Future<void> _runSurahSequence({
    required int surahNumber,
    required int startAyah,
    required int ayahCount,
    required Map<int, String> translations,
    required String recentKey,
  }) async {
    final token = ++_sequenceToken;
    _sequenceCancelled = false;
    _sequencePaused = false;
    _sequenceActive = true;

    try {
      await _pushRecent(recentKey);
      for (var ayah = startAyah; ayah <= ayahCount; ayah++) {
        if (_sequenceCancelled || token != _sequenceToken) return;
        await _awaitUnpaused();
        if (_sequenceCancelled || token != _sequenceToken) return;

        final playlistIndex = ayah - startAyah;
        state = state.copyWith(
          currentPlaylistIndex: playlistIndex,
          isPlayingTranslation: false,
          error: null,
          includeTranslationAudio: true,
        );
        _syncLockScreen();

        final settings = ref.read(settingsProvider);
        final translationId = settings.defaultTranslationId;
        final ttsVoice = settings.translationVoiceId;
        // Prefer live edition text so language changes apply mid-play.
        var text = _liveTranslationText(surahNumber, ayah);
        if (text.isEmpty) {
          text = translations[ayah]?.trim() ?? '';
        }
        var nextText = ayah < ayahCount
            ? _liveTranslationText(surahNumber, ayah + 1)
            : '';
        if (nextText.isEmpty && ayah < ayahCount) {
          nextText = translations[ayah + 1]?.trim() ?? '';
        }

        final currentWarm = text.isEmpty
            ? Future<void>.value()
            : _tts.prefetch(
                text,
                translationId: translationId,
                voice: ttsVoice,
              );

        final finishedLead = await _startArabicAndWaitForLead(
          _reciter.ayahUrl(surahNumber, ayah),
          token: token,
        );
        if (!finishedLead ||
            _sequenceCancelled ||
            token != _sequenceToken) {
          return;
        }

        await _awaitUnpaused();
        if (_sequenceCancelled || token != _sequenceToken) return;

        if (text.isEmpty) continue;

        await currentWarm;
        if (_sequenceCancelled || token != _sequenceToken) return;

        if (nextText.isNotEmpty) {
          unawaited(
            _tts.prefetch(
              nextText,
              translationId: translationId,
              voice: ttsVoice,
            ),
          );
        }

        while (!_sequenceCancelled && token == _sequenceToken) {
          final latest = ref.read(settingsProvider);
          final activeTranslationId = latest.defaultTranslationId;
          final activeVoice = latest.translationVoiceId;
          final liveText = _liveTranslationText(surahNumber, ayah);
          final speakText =
              liveText.isNotEmpty ? liveText : (translations[ayah]?.trim() ?? '');
          if (speakText.isEmpty) break;

          if (activeVoice != ttsVoice ||
              activeTranslationId != translationId ||
              speakText != text) {
            unawaited(
              _tts.prefetch(
                speakText,
                translationId: activeTranslationId,
                voice: activeVoice,
              ),
            );
          }

          state = state.copyWith(
            isPlayingTranslation: true,
            playing: true,
            loading: true,
            position: Duration.zero,
            duration: Duration.zero,
          );
          late final bool finished;
          try {
            finished = await _tts.speak(
              speakText,
              translationId: activeTranslationId,
              voice: activeVoice,
              onAudioReady: () {
                if (!_sequenceCancelled && token == _sequenceToken) {
                  state = state.copyWith(loading: false);
                }
              },
            );
          } catch (e) {
            if (_sequenceCancelled || token != _sequenceToken) return;
            state = state.copyWith(
              isPlayingTranslation: false,
              loading: false,
              error: e.toString(),
            );
            break;
          }
          if (_sequenceCancelled || token != _sequenceToken) return;
          if (_sequencePaused) {
            state = state.copyWith(
              isPlayingTranslation: false,
              playing: false,
            );
            await _awaitUnpaused();
            continue;
          }
          final stillSameVoice =
              ref.read(settingsProvider).translationVoiceId == activeVoice;
          final stillSameEdition =
              ref.read(settingsProvider).defaultTranslationId ==
                  activeTranslationId;
          if (!finished || !stillSameVoice || !stillSameEdition) {
            continue;
          }
          state = state.copyWith(isPlayingTranslation: false);
          break;
        }
        if (ref.read(settingsProvider).repeatAyah) {
          ayah--;
        }
      }

      if (token == _sequenceToken && !_sequenceCancelled) {
        state = state.copyWith(
          playing: false,
          isPlayingTranslation: false,
          loading: false,
        );
      }
    } catch (e) {
      if (token == _sequenceToken) {
        state = state.copyWith(
          loading: false,
          playing: false,
          isPlayingTranslation: false,
          error: e.toString(),
        );
      }
    } finally {
      if (token == _sequenceToken) {
        _sequenceActive = false;
      }
    }
  }

  Future<void> _pushRecent(String entry) async {
    final box = Hive.box<String>(HiveBoxes.recentRecitation);
    final list = box.values.toList();
    list.remove(entry);
    list.insert(0, entry);
    await box.clear();
    for (var i = 0; i < list.length && i < 20; i++) {
      await box.add(list[i]);
    }
  }

  MushafPlaybackItem? _adjacentMushafItem(int delta) {
    final current = state.currentMushafItem;
    if (current == null) return null;
    final page = current.isBismillah
        ? MushafNavigation.pageForSurah(current.surah)
        : q.getPageNumber(current.surah, current.ayah!);
    final pageItems = MushafNavigation.playbackItemsOnPage(page);
    final index = pageItems.indexWhere(
      (item) =>
          item.isBismillah == current.isBismillah &&
          item.surah == current.surah &&
          item.ayah == current.ayah,
    );
    if (index < 0) return null;
    final next = index + delta;
    if (next >= 0 && next < pageItems.length) return pageItems[next];
    if (delta > 0 && page < q.totalPagesCount) {
      final items = MushafNavigation.playbackItemsOnPage(page + 1);
      return items.isEmpty ? null : items.first;
    }
    if (delta < 0 && page > 1) {
      final items = MushafNavigation.playbackItemsOnPage(page - 1);
      return items.isEmpty ? null : items.last;
    }
    return null;
  }

  Future<void> skipToNextAyah() => _skipAyah(1);

  Future<void> skipToPreviousAyah() => _skipAyah(-1);

  Future<void> _skipAyah(int delta) async {
    if (!state.hasActiveTrack) return;
    if (state.isMushafPlayback) {
      final next = _adjacentMushafItem(delta);
      if (next == null) return;
      await playMushafFromItem(
        next,
        continuePages: state.mushafContinuePages,
      );
      return;
    }
    final surah = state.surahNumber;
    if (surah == null || state.ayahCount <= 0) return;
    final nextAyah = state.currentAyahInSurah + delta;
    if (nextAyah < 1 || nextAyah > state.ayahCount) return;
    await playFromAyah(surah, nextAyah, state.ayahCount);
  }

  String _nowPlayingTitle() {
    if (state.isMushafPlayback) {
      final item = state.currentMushafItem;
      if (item == null) {
        return state.mushafPage != null ? 'Page ${state.mushafPage}' : 'Quran';
      }
      final name = q.getSurahNameEnglish(item.surah);
      if (item.isBismillah) return 'Bismillah · $name';
      return '$name ${item.surah}:${item.ayah}';
    }
    final surah = state.surahNumber;
    if (surah == null) return 'Quran';
    final name = q.getSurahNameEnglish(surah);
    return '$name $surah:${state.currentAyahInSurah}';
  }

  void _syncLockScreen() {
    final handler = DeenAudioHandler.instance;
    if (handler == null) return;
    if (!state.hasActiveTrack) {
      if (_lockScreenActive) {
        _lockScreenActive = false;
        unawaited(handler.hide());
      }
      return;
    }
    _lockScreenActive = true;
    handler.publish(
      title: _nowPlayingTitle(),
      artist: _reciter.name,
      playing: state.playing || state.isPlayingTranslation,
      loading: state.loading,
      seekable:
          !state.isPlayingTranslation && !state.includeTranslationAudio,
      position: state.position,
      duration: state.duration,
    );
  }

  Future<void> pause() async {
    if (state.includeTranslationAudio && _sequenceActive) {
      _sequencePaused = true;
      await _player.pause();
      if (state.isPlayingTranslation) {
        await _tts.stop();
        state = state.copyWith(playing: false, isPlayingTranslation: false);
      } else {
        state = state.copyWith(playing: false);
      }
      _syncLockScreen();
      return;
    }
    await _player.pause();
    _syncLockScreen();
  }

  Future<void> resume() async {
    if (state.includeTranslationAudio && _sequenceActive) {
      _sequencePaused = false;
      _releasePauseGate();
      if (!state.isPlayingTranslation) {
        await _player.play();
      }
      state = state.copyWith(playing: true);
      _syncLockScreen();
      return;
    }
    await _player.play();
    _syncLockScreen();
  }

  Future<void> togglePlayPause() async {
    if (state.includeTranslationAudio && _sequenceActive) {
      if (_sequencePaused || !state.playing) {
        await resume();
      } else {
        await pause();
      }
      return;
    }
    if (_player.playing) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> seekToAyahInPlaylist(int playlistIndexZeroBased) async {
    if (state.includeTranslationAudio) return;
    await _player.seek(Duration.zero, index: playlistIndexZeroBased);
  }

  Future<void> seekCurrentSource(Duration position) => _player.seek(position);

  Future<void> stop() async {
    await _cancelSequence();
    await _player.stop();
    state = const QuranPlayerState();
    _syncLockScreen();
  }
}
