import 'package:equatable/equatable.dart';

import '../../domain/mushaf_navigation.dart';

class QuranPlayerState extends Equatable {
  const QuranPlayerState({
    this.surahNumber,
    this.ayahCount = 0,
    this.playlistStartAyah = 1,
    this.currentPlaylistIndex = 0,
    this.playing = false,
    this.loading = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.error,
    this.isMushafPlayback = false,
    this.mushafPage,
    this.mushafItems = const [],
    this.mushafContinuePages = false,
    this.isPlayingTranslation = false,
    this.includeTranslationAudio = false,
  });

  final int? surahNumber;
  final int ayahCount;
  final int playlistStartAyah;
  final int currentPlaylistIndex;
  final bool playing;
  final bool loading;
  final Duration position;
  final Duration duration;
  final String? error;
  final bool isMushafPlayback;
  final int? mushafPage;
  final List<MushafPlaybackItem> mushafItems;
  final bool mushafContinuePages;
  final bool isPlayingTranslation;
  final bool includeTranslationAudio;

  int get currentAyahInSurah => playlistStartAyah + currentPlaylistIndex;

  bool get hasActiveTrack =>
      isMushafPlayback || (surahNumber != null && ayahCount > 0);

  MushafPlaybackItem? get currentMushafItem {
    if (!isMushafPlayback ||
        currentPlaylistIndex < 0 ||
        currentPlaylistIndex >= mushafItems.length) {
      return null;
    }
    return mushafItems[currentPlaylistIndex];
  }

  QuranPlayerState copyWith({
    int? surahNumber,
    int? ayahCount,
    int? playlistStartAyah,
    int? currentPlaylistIndex,
    bool? playing,
    bool? loading,
    Duration? position,
    Duration? duration,
    String? error,
    bool? isMushafPlayback,
    int? mushafPage,
    List<MushafPlaybackItem>? mushafItems,
    bool? mushafContinuePages,
    bool? isPlayingTranslation,
    bool? includeTranslationAudio,
  }) {
    return QuranPlayerState(
      surahNumber: surahNumber ?? this.surahNumber,
      ayahCount: ayahCount ?? this.ayahCount,
      playlistStartAyah: playlistStartAyah ?? this.playlistStartAyah,
      currentPlaylistIndex:
          currentPlaylistIndex ?? this.currentPlaylistIndex,
      playing: playing ?? this.playing,
      loading: loading ?? this.loading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      error: error,
      isMushafPlayback: isMushafPlayback ?? this.isMushafPlayback,
      mushafPage: mushafPage ?? this.mushafPage,
      mushafItems: mushafItems ?? this.mushafItems,
      mushafContinuePages:
          mushafContinuePages ?? this.mushafContinuePages,
      isPlayingTranslation:
          isPlayingTranslation ?? this.isPlayingTranslation,
      includeTranslationAudio:
          includeTranslationAudio ?? this.includeTranslationAudio,
    );
  }

  /// Fields the page readers follow. Progress ticks are omitted so the
  /// 604-page mushaf does not rebuild several times a second.
  Object get followKey => (
        surahNumber,
        ayahCount,
        playlistStartAyah,
        currentPlaylistIndex,
        playing,
        isMushafPlayback,
        mushafPage,
        mushafContinuePages,
        isPlayingTranslation,
        includeTranslationAudio,
        error,
      );

  @override
  List<Object?> get props => [
        surahNumber,
        ayahCount,
        playlistStartAyah,
        currentPlaylistIndex,
        playing,
        loading,
        position,
        duration,
        error,
        isMushafPlayback,
        mushafPage,
        mushafItems,
        mushafContinuePages,
        isPlayingTranslation,
        includeTranslationAudio,
      ];
}
