import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../domain/entities/piper_voice.dart';
import 'piper_tts_client.dart';

/// Speaks Quran translation with on-device Kokoro (English) or Piper TTS.
class TranslationTtsService {
  TranslationTtsService({PiperTtsClient? piper})
      : _piper = piper ?? PiperTtsClient();

  final PiperTtsClient _piper;
  final AudioPlayer _player = AudioPlayer(handleInterruptions: false);

  bool _cancelled = false;
  int _speakToken = 0;
  Completer<void>? _playbackDone;

  bool get isConfigured => true;

  static String languageLabelForEdition(String translationId) {
    if (translationId.startsWith('ur')) return 'Urdu';
    if (translationId.startsWith('fr')) return 'French';
    return 'English';
  }

  /// Warm the WAV cache (and download the model if needed) while Arabic plays.
  Future<void> prefetch(
    String text, {
    required String translationId,
    required String voice,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final resolved = PiperVoice.resolve(
      preferredId: voice,
      translationId: translationId,
    );
    try {
      if (kDebugMode) {
        debugPrint(
          'TTS prefetch start (${resolved.engine.name}, ${resolved.id}, '
          '${resolved.language})',
        );
      }
      await _piper.synthesizeToFile(text: trimmed, voiceId: resolved.id);
      if (kDebugMode) debugPrint('TTS prefetch ready');
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('TTS prefetch failed: $e');
        debugPrint('$st');
      }
    }
  }

  /// Speaks [text] with on-device TTS and waits until finished.
  ///
  /// Returns `true` if playback finished (or text was empty), `false` if it was
  /// interrupted so the caller can restart.
  Future<bool> speak(
    String text, {
    required String translationId,
    required String voice,
    VoidCallback? onAudioReady,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return true;

    final token = ++_speakToken;
    _cancelled = false;
    final resolved = PiperVoice.resolve(
      preferredId: voice,
      translationId: translationId,
    );
    if (_cancelled || token != _speakToken) return false;

    final File file = await _piper.synthesizeToFile(
      text: trimmed,
      voiceId: resolved.id,
    );
    if (_cancelled || token != _speakToken) return false;
    onAudioReady?.call();

    final done = Completer<void>();
    _playbackDone = done;
    var armed = false;
    late StreamSubscription<PlayerState> sub;
    sub = _player.playerStateStream.listen((ps) {
      if (_cancelled || token != _speakToken) {
        if (!done.isCompleted) done.complete();
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
        if (!done.isCompleted) done.complete();
      }
    });

    try {
      await _player.setAudioSource(AudioSource.file(file.path));
      if (_cancelled || token != _speakToken) return false;
      try {
        final session = await AudioSession.instance;
        await session.setActive(true);
      } catch (_) {}
      await _player.play();
      await done.future;
      return !_cancelled && token == _speakToken;
    } finally {
      await sub.cancel();
      if (_playbackDone == done) _playbackDone = null;
    }
  }

  Future<void> interrupt() async {
    _speakToken++;
    final done = _playbackDone;
    _playbackDone = null;
    if (done != null && !done.isCompleted) {
      done.complete();
    }
    await _player.stop();
  }

  Future<void> stop() async {
    _cancelled = true;
    await interrupt();
  }

  Future<void> dispose() async {
    await stop();
    await _player.dispose();
    await _piper.dispose();
  }
}
