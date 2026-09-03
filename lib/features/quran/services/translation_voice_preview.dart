import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'piper_tts_client.dart';

/// Plays a translation-voice sample. First success is saved on disk.
class TranslationVoicePreview {
  TranslationVoicePreview({PiperTtsClient? piper})
      : _piper = piper ?? PiperTtsClient();

  final PiperTtsClient _piper;
  final AudioPlayer _player = AudioPlayer();
  var _token = 0;

  Future<bool> isCached(String voice) => _piper.hasPreview(voice);

  Future<bool> isModelReady(String voice) => _piper.isModelReady(voice);

  /// Downloads the model if needed, synthesizes, then plays.
  Future<void> play({
    required String voice,
    VoidCallback? onAudioReady,
  }) async {
    final token = ++_token;
    await _player.stop();

    final file = await _piper.synthesizePreview(voice);
    if (token != _token) return;
    onAudioReady?.call();
    await _player.setAudioSource(AudioSource.file(file.path));
    if (token != _token) return;
    await _player.play();
    await _player.playerStateStream.firstWhere(
      (s) =>
          s.processingState == ProcessingState.completed ||
          s.processingState == ProcessingState.idle,
    );
  }

  Future<void> stop() async {
    _token++;
    await _player.stop();
  }

  Future<void> dispose() async {
    await stop();
    await _player.dispose();
    await _piper.dispose();
  }
}
