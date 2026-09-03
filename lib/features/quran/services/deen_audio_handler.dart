import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Lock-screen / Control Center / notification controls for Quran playback.
///
/// The [just_audio] player stays in [QuranPlayerController]; this handler
/// only forwards media-button events and publishes now-playing metadata.
class DeenAudioHandler extends BaseAudioHandler with SeekHandler {
  DeenAudioHandler();

  static DeenAudioHandler? instance;

  Future<void> Function()? _onPlay;
  Future<void> Function()? _onPause;
  Future<void> Function()? _onStop;
  Future<void> Function()? _onSkipNext;
  Future<void> Function()? _onSkipPrevious;
  Future<void> Function(Duration position)? _onSeek;

  void bind({
    required Future<void> Function() onPlay,
    required Future<void> Function() onPause,
    required Future<void> Function() onStop,
    required Future<void> Function() onSkipNext,
    required Future<void> Function() onSkipPrevious,
    required Future<void> Function(Duration position) onSeek,
  }) {
    _onPlay = onPlay;
    _onPause = onPause;
    _onStop = onStop;
    _onSkipNext = onSkipNext;
    _onSkipPrevious = onSkipPrevious;
    _onSeek = onSeek;
  }

  void unbind() {
    _onPlay = null;
    _onPause = null;
    _onStop = null;
    _onSkipNext = null;
    _onSkipPrevious = null;
    _onSeek = null;
  }

  void publish({
    required String title,
    required String artist,
    required bool playing,
    required bool loading,
    required bool seekable,
    Duration position = Duration.zero,
    Duration duration = Duration.zero,
  }) {
    final item = MediaItem(
      id: 'deen-islam-quran',
      title: title,
      artist: artist,
      album: 'Deen Islam',
      duration: duration > Duration.zero ? duration : null,
    );
    if (mediaItem.value?.title != item.title ||
        mediaItem.value?.artist != item.artist ||
        mediaItem.value?.duration != item.duration) {
      mediaItem.add(item);
    }

    final controls = [
      MediaControl.skipToPrevious,
      playing ? MediaControl.pause : MediaControl.play,
      MediaControl.skipToNext,
      MediaControl.stop,
    ];
    final systemActions = <MediaAction>{
      MediaAction.skipToNext,
      MediaAction.skipToPrevious,
      MediaAction.stop,
      if (seekable) MediaAction.seek,
    };

    playbackState.add(
      playbackState.value.copyWith(
        controls: controls,
        systemActions: systemActions,
        androidCompactActionIndices: const [0, 1, 2],
        processingState: loading
            ? AudioProcessingState.loading
            : playing
                ? AudioProcessingState.ready
                : AudioProcessingState.ready,
        playing: playing,
        updatePosition: position,
        bufferedPosition: duration,
        speed: 1,
        queueIndex: 0,
      ),
    );
  }

  Future<void> hide() async {
    mediaItem.add(null);
    playbackState.add(
      PlaybackState(
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
    try {
      await super.stop();
    } catch (e) {
      if (kDebugMode) debugPrint('Audio handler hide: $e');
    }
  }

  @override
  Future<void> play() async => _onPlay?.call();

  @override
  Future<void> pause() async => _onPause?.call();

  @override
  Future<void> stop() async {
    await _onStop?.call();
    await hide();
  }

  @override
  Future<void> skipToNext() async => _onSkipNext?.call();

  @override
  Future<void> skipToPrevious() async => _onSkipPrevious?.call();

  @override
  Future<void> seek(Duration position) async => _onSeek?.call(position);
}

Future<void> initDeenAudioService() async {
  if (DeenAudioHandler.instance != null) return;
  try {
    final handler = await AudioService.init(
      builder: () {
        final h = DeenAudioHandler();
        DeenAudioHandler.instance = h;
        return h;
      },
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.deenconnect.deen_connect.audio',
        androidNotificationChannelName: 'Quran playback',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
        notificationColor: Color(0xFF1B4332),
      ),
    );
    DeenAudioHandler.instance = handler;
  } catch (e) {
    if (kDebugMode) debugPrint('AudioService.init: $e');
  }
}
