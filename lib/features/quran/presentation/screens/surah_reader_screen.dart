import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quran/quran.dart' as q;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/async_body.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/entities/quran_ayah.dart';
import '../providers/quran_player_provider.dart';
import '../providers/quran_prefs_provider.dart';
import '../providers/quran_providers.dart';
import '../widgets/audio_mini_bar.dart';
import '../widgets/quran_nav_bar.dart';

/// Basmala is shown for every surah except At-Tawbah (9).
/// For Al-Fatiha (1) it is ayah 1; elsewhere it is a standalone header.
bool _showsStandaloneBasmala(int surahNumber) =>
    surahNumber != 1 && surahNumber != 9;

bool _showsBasmala(int surahNumber) => surahNumber != 9;

class SurahReaderScreen extends ConsumerStatefulWidget {
  const SurahReaderScreen({super.key, required this.surahNumber});

  final int surahNumber;

  @override
  ConsumerState<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends ConsumerState<SurahReaderScreen>
    with WidgetsBindingObserver {
  final ItemScrollController _scroll = ItemScrollController();
  final ItemPositionsListener _positions = ItemPositionsListener.create();
  Timer? _readDebounce;
  Timer? _syncingTimer;
  Timer? _followBackTimer;
  var _syncingScroll = false;
  var _userDetached = false;
  var _didInitialFollow = false;

  static const _followBackDelay = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _positions.itemPositions.addListener(_onVisibleAyahsChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _readDebounce?.cancel();
    _syncingTimer?.cancel();
    _followBackTimer?.cancel();
    _positions.itemPositions.removeListener(_onVisibleAyahsChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _clearFollowBack();
      _scrollToPlayingAyah(force: true);
    }
  }

  void _scheduleFollowBack() {
    _userDetached = true;
    _followBackTimer?.cancel();
    _followBackTimer = Timer(_followBackDelay, () {
      if (!mounted) return;
      _clearFollowBack();
      _scrollToPlayingAyah(force: true);
    });
  }

  void _clearFollowBack() {
    _followBackTimer?.cancel();
    _userDetached = false;
  }

  void _scrollToPlayingAyah({bool animate = true, bool force = false}) {
    if (_userDetached && !force) return;
    final next = ref.read(quranPlayerProvider);
    if (next.surahNumber != widget.surahNumber) return;
    final i = _listIndexForAyah(next.currentAyahInSurah);
    if (i < 0) return;
    if (animate && !_ayahNeedsFollow(i)) return;
    try {
      if (!_scroll.isAttached) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scrollToPlayingAyah(animate: animate);
        });
        return;
      }
      if (animate) {
        _syncingScroll = true;
        _syncingTimer?.cancel();
        _syncingTimer = Timer(const Duration(milliseconds: 500), () {
          _syncingScroll = false;
        });
        _scroll.scrollTo(
          index: i,
          alignment: 0.12,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scroll.jumpTo(index: i, alignment: 0.12);
      }
    } catch (_) {}
  }

  void _onVisibleAyahsChanged() {
    final positions = _positions.itemPositions.value;
    if (positions.isEmpty) return;
    var minIndex = positions.first.index;
    for (final p in positions) {
      if (p.index < minIndex) minIndex = p.index;
    }
    _readDebounce?.cancel();
    _readDebounce = Timer(const Duration(milliseconds: 500), () {
      final ayahs = ref
          .read(
            surahAyahsProvider((
              surahNumber: widget.surahNumber,
              translationId: ref.read(settingsProvider).defaultTranslationId,
            )),
          )
          .valueOrNull;
      if (ayahs == null || ayahs.isEmpty) return;
      final offset = _showsStandaloneBasmala(widget.surahNumber) ? 1 : 0;
      final ayahIndex = (minIndex - offset).clamp(0, ayahs.length - 1);
      ref
          .read(quranPrefsProvider.notifier)
          .saveLastRead(widget.surahNumber, ayahs[ayahIndex].numberInSurah);
    });
  }

  int _listIndexForAyah(int ayahInSurah) {
    final offset = _showsStandaloneBasmala(widget.surahNumber) ? 1 : 0;
    return ayahInSurah - 1 + offset;
  }

  /// Scroll when the recited ayah is missing or too high/low in the viewport.
  bool _ayahNeedsFollow(int index) {
    for (final p in _positions.itemPositions.value) {
      if (p.index != index) continue;
      return p.itemLeadingEdge < 0.06 || p.itemLeadingEdge > 0.30;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final args = (
      surahNumber: widget.surahNumber,
      translationId: settings.defaultTranslationId,
    );
    final ayahsAsync = ref.watch(surahAyahsProvider(args));
    final surahsAsync = ref.watch(surahListProvider);
    ref.watch(quranPlayerProvider.select((s) => s.followKey));
    final player = ref.read(quranPlayerProvider);
    final playerCtrl = ref.read(quranPlayerProvider.notifier);
    final t = AppStrings.of(context);
    final title = t.surahName(widget.surahNumber);

    final ayahCount = surahsAsync.maybeWhen(
      data: (l) {
        try {
          return l
              .firstWhere((e) => e.number == widget.surahNumber)
              .numberOfAyahs;
        } catch (_) {
          return 0;
        }
      },
      orElse: () => 0,
    );

    if (!_didInitialFollow && ayahsAsync.hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _didInitialFollow) return;
        _didInitialFollow = true;
        _scrollToPlayingAyah(animate: false);
      });
    }

    ref.listen(quranPlayerProvider, (prev, next) {
      if (prev?.followKey == next.followKey) return;
      if (next.surahNumber != widget.surahNumber) return;
      if (_userDetached) return;
      final modeSwitch =
          prev?.includeTranslationAudio != next.includeTranslationAudio;
      if (modeSwitch) {
        _scrollToPlayingAyah();
        return;
      }
      if (prev?.currentPlaylistIndex != next.currentPlaylistIndex ||
          prev?.playlistStartAyah != next.playlistStartAyah ||
          prev?.isPlayingTranslation != next.isPlayingTranslation) {
        _scrollToPlayingAyah();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_increase_rounded),
            onPressed: () {
              ref
                  .read(settingsProvider.notifier)
                  .setFontScale(settings.quranFontScale + 0.05);
            },
          ),
          IconButton(
            icon: const Icon(Icons.text_decrease_rounded),
            onPressed: () {
              ref
                  .read(settingsProvider.notifier)
                  .setFontScale(settings.quranFontScale - 0.05);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: AsyncBody(
              async: ayahsAsync,
              onRetry: () => ref.invalidate(surahAyahsProvider(args)),
              data: (context, ayahs) {
                final standalone = _showsStandaloneBasmala(widget.surahNumber);
                final showBasmala = _showsBasmala(widget.surahNumber);
                return NotificationListener<UserScrollNotification>(
                  onNotification: (notification) {
                    if (_syncingScroll) return false;
                    final playing = ref.read(quranPlayerProvider);
                    if (playing.hasActiveTrack &&
                        playing.surahNumber == widget.surahNumber) {
                      _scheduleFollowBack();
                    }
                    return false;
                  },
                  child: ScrollablePositionedList.builder(
                    itemCount: ayahs.length + (standalone ? 1 : 0),
                    itemScrollController: _scroll,
                    itemPositionsListener: _positions,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    itemBuilder: (context, index) {
                      if (standalone && index == 0) {
                        return _BismillahHeader(
                          arabic: q.basmala,
                          fontScale: settings.quranFontScale,
                        );
                      }
                      final ayahIndex = standalone ? index - 1 : index;
                      final ayah = ayahs[ayahIndex];
                      final highlighted =
                          player.surahNumber == widget.surahNumber &&
                          ayah.numberInSurah == player.currentAyahInSurah;

                      // Al-Fatiha 1:1 is Bismillah — show it as the top header.
                      if (showBasmala &&
                          widget.surahNumber == 1 &&
                          ayah.numberInSurah == 1) {
                        return _BismillahHeader(
                          arabic: ayah.arabicText,
                          fontScale: settings.quranFontScale,
                          translation: settings.showTranslation
                              ? ayah.translationText
                              : null,
                          highlighted: highlighted,
                          onPlay: () {
                            _clearFollowBack();
                            playerCtrl.playFromAyah(
                              widget.surahNumber,
                              ayah.numberInSurah,
                              ayahCount,
                              translations: {
                                for (final a in ayahs)
                                  a.numberInSurah: a.translationText,
                              },
                            );
                          },
                        );
                      }

                      return _AyahCard(
                        ayah: ayah,
                        surahNumber: widget.surahNumber,
                        highlighted: highlighted,
                        showTranslation: settings.showTranslation,
                        fontScale: settings.quranFontScale,
                        bookmarked: ref
                            .watch(quranPrefsProvider)
                            .bookmarks
                            .contains(
                              QuranPrefs.bookmarkKey(
                                widget.surahNumber,
                                ayah.numberInSurah,
                              ),
                            ),
                        onBookmark: () => ref
                            .read(quranPrefsProvider.notifier)
                            .toggleBookmark(
                              widget.surahNumber,
                              ayah.numberInSurah,
                            ),
                        onPlayAyah: () {
                          _clearFollowBack();
                          playerCtrl.playFromAyah(
                            widget.surahNumber,
                            ayah.numberInSurah,
                            ayahCount,
                            translations: {
                              for (final a in ayahs)
                                a.numberInSurah: a.translationText,
                            },
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
          if (player.surahNumber == widget.surahNumber)
            AudioMiniBar(
              surahName: title,
              ayahCount: ayahCount,
              onPlaySurah: ayahCount > 0
                  ? () {
                      _clearFollowBack();
                      final loaded = ref
                          .read(surahAyahsProvider(args))
                          .valueOrNull;
                      playerCtrl.playFullSurah(
                        widget.surahNumber,
                        ayahCount,
                        translations: loaded == null
                            ? null
                            : {
                                for (final a in loaded)
                                  a.numberInSurah: a.translationText,
                              },
                      );
                    }
                  : null,
            ),
          QuranNavBar(
            playing:
                player.surahNumber == widget.surahNumber &&
                (player.playing || player.isPlayingTranslation),
            translationOn: settings.showTranslation,
            onPlay: () {
              if (player.surahNumber == widget.surahNumber &&
                  (player.playing ||
                      player.isPlayingTranslation ||
                      player.loading)) {
                playerCtrl.togglePlayPause();
                return;
              }
              final loaded = ref.read(surahAyahsProvider(args)).valueOrNull;
              if (ayahCount <= 0) return;
              _clearFollowBack();
              playerCtrl.playFullSurah(
                widget.surahNumber,
                ayahCount,
                translations: loaded == null
                    ? null
                    : {
                        for (final a in loaded)
                          a.numberInSurah: a.translationText,
                      },
              );
            },
            onSearch: () => context.push('/learn-quran/search'),
            onToggleTranslation: () async {
              final next = !settings.showTranslation;
              await ref
                  .read(settingsProvider.notifier)
                  .setShowTranslation(next);
              if (player.surahNumber != widget.surahNumber) return;
              final loaded = ref
                  .read(
                    surahAyahsProvider((
                      surahNumber: widget.surahNumber,
                      translationId: ref
                          .read(settingsProvider)
                          .defaultTranslationId,
                    )),
                  )
                  .valueOrNull;
              final translations = (!next || loaded == null)
                  ? null
                  : {
                      for (final a in loaded)
                        a.numberInSurah: a.translationText,
                    };
              await playerCtrl.continueSurahWithCurrentSettings(
                translations: translations,
              );
              if (mounted) _scrollToPlayingAyah();
            },
          ),
        ],
      ),
    );
  }
}

class _BismillahHeader extends StatelessWidget {
  const _BismillahHeader({
    required this.arabic,
    required this.fontScale,
    this.translation,
    this.highlighted = false,
    this.onPlay,
  });

  final String arabic;
  final double fontScale;
  final String? translation;
  final bool highlighted;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlighted
              ? scheme.primary
              : scheme.outlineVariant.withValues(alpha: 0.35),
          width: highlighted ? 2 : 1,
        ),
        color: highlighted
            ? scheme.primaryContainer.withValues(alpha: 0.25)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onPlay != null)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: onPlay,
                icon: const Icon(Icons.play_circle_outline_rounded),
                visualDensity: VisualDensity.compact,
              ),
            ),
          Text(
            arabic,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: AppTheme.arabicText(context).copyWith(
              fontSize: 24 * fontScale,
              fontWeight: FontWeight.w700,
              color: scheme.primary,
              height: 1.8,
            ),
          ),
          if (translation != null && translation!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              translation!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.45,
                fontSize: 15 * fontScale,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AyahCard extends StatelessWidget {
  const _AyahCard({
    required this.ayah,
    required this.surahNumber,
    required this.highlighted,
    required this.showTranslation,
    required this.fontScale,
    required this.bookmarked,
    required this.onBookmark,
    required this.onPlayAyah,
  });

  final QuranAyah ayah;
  final int surahNumber;
  final bool highlighted;
  final bool showTranslation;
  final double fontScale;
  final bool bookmarked;
  final VoidCallback onBookmark;
  final VoidCallback onPlayAyah;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlighted
              ? scheme.primary
              : scheme.outlineVariant.withValues(alpha: 0.4),
          width: highlighted ? 2 : 1,
        ),
        color: highlighted
            ? scheme.primaryContainer.withValues(alpha: 0.25)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Chip(
                label: Text('${ayah.numberInSurah}'),
                visualDensity: VisualDensity.compact,
              ),
              const Spacer(),
              IconButton(
                onPressed: onBookmark,
                icon: Icon(
                  bookmarked ? Icons.bookmark : Icons.bookmark_outline,
                ),
              ),
              IconButton(
                onPressed: onPlayAyah,
                icon: const Icon(Icons.play_circle_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ayah.arabicText,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: AppTheme.arabicText(
              context,
            ).copyWith(fontSize: 22 * fontScale),
          ),
          if (showTranslation && ayah.translationText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              ayah.translationText,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.45,
                fontSize: 16 * fontScale,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
