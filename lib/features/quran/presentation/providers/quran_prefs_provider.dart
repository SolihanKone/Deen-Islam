import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/storage/hive_boxes.dart';

class QuranPrefs extends Equatable {
  const QuranPrefs({
    required this.bookmarks,
    this.lastSurah,
    this.lastAyahInSurah,
    this.lastMushafPage,
  });

  final Set<String> bookmarks;
  final int? lastSurah;
  final int? lastAyahInSurah;
  final int? lastMushafPage;

  static String bookmarkKey(int surah, int ayah) => '$surah:$ayah';

  QuranPrefs copyWith({
    Set<String>? bookmarks,
    int? lastSurah,
    int? lastAyahInSurah,
    int? lastMushafPage,
  }) {
    return QuranPrefs(
      bookmarks: bookmarks ?? this.bookmarks,
      lastSurah: lastSurah ?? this.lastSurah,
      lastAyahInSurah: lastAyahInSurah ?? this.lastAyahInSurah,
      lastMushafPage: lastMushafPage ?? this.lastMushafPage,
    );
  }

  @override
  List<Object?> get props =>
      [bookmarks, lastSurah, lastAyahInSurah, lastMushafPage];
}

final quranPrefsProvider =
    NotifierProvider<QuranPrefsNotifier, QuranPrefs>(QuranPrefsNotifier.new);

class QuranPrefsNotifier extends Notifier<QuranPrefs> {
  Box<String> get _bm => Hive.box<String>(HiveBoxes.bookmarks);
  Box<dynamic> get _st => Hive.box<dynamic>(HiveBoxes.settings);

  @override
  QuranPrefs build() {
    final keys = _bm.keys.cast<String>().toSet();
    return QuranPrefs(
      bookmarks: keys.toSet(),
      lastSurah: _st.get('last_surah') as int?,
      lastAyahInSurah: _st.get('last_ayah') as int?,
      lastMushafPage: _st.get('last_mushaf_page') as int?,
    );
  }

  Future<void> toggleBookmark(int surah, int ayah) async {
    final k = QuranPrefs.bookmarkKey(surah, ayah);
    if (state.bookmarks.contains(k)) {
      await _bm.delete(k);
    } else {
      await _bm.put(k, '1');
    }
    state = state.copyWith(bookmarks: _bm.keys.cast<String>().toSet());
  }

  bool isBookmarked(int surah, int ayah) =>
      state.bookmarks.contains(QuranPrefs.bookmarkKey(surah, ayah));

  Future<void> saveLastRead(int surah, int ayahInSurah) async {
    await _st.put('last_surah', surah);
    await _st.put('last_ayah', ayahInSurah);
    state = state.copyWith(lastSurah: surah, lastAyahInSurah: ayahInSurah);
  }

  Future<void> saveLastMushafPage(int page) async {
    await _st.put('last_mushaf_page', page);
    state = state.copyWith(lastMushafPage: page);
  }
}
