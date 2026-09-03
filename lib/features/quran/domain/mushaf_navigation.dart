import 'package:quran/quran.dart' as q;

/// Ayah on a mushaf page, or bismillah before a surah start (surah 1 & 9 excluded).
typedef MushafAyahRef = ({int surah, int ayah});

typedef MushafPlaybackItem = ({
  bool isBismillah,
  int surah,
  int? ayah,
});

abstract final class MushafNavigation {
  static int get startPage => 1;

  static int get endPage => q.totalPagesCount;

  static int pageForSurah(int surahNumber) =>
      q.getPageNumber(surahNumber, 1);

  static int pageForJuz(int juzNumber) {
    final verses = q.getSurahAndVersesFromJuz(juzNumber);
    final firstSurah = verses.keys.first;
    final firstVerse = verses[firstSurah]!.first;
    return q.getPageNumber(firstSurah, firstVerse);
  }

  static int juzForPage(int pageNumber) {
    final segments = q.getPageData(pageNumber);
    final first = segments.first as Map;
    return q.getJuzNumber(first['surah'] as int, first['start'] as int);
  }

  static int primarySurahForPage(int pageNumber) {
    final segments = q.getPageData(pageNumber);
    return (segments.first as Map)['surah'] as int;
  }

  static String surahNameArabicForPage(int pageNumber) =>
      q.getSurahNameArabic(primarySurahForPage(pageNumber));

  static String surahNameEnglishForPage(int pageNumber) =>
      q.getSurahNameEnglish(primarySurahForPage(pageNumber));

  static String pageLabel(int pageNumber) => '$pageNumber / ${q.totalPagesCount}';

  /// Audio queue for a page — inserts bismillah before ayah 1 when a surah begins.
  static List<MushafPlaybackItem> playbackItemsOnPage(int pageNumber) {
    final segments = q.getPageData(pageNumber).cast<Map>();
    final items = <MushafPlaybackItem>[];
    for (final segment in segments) {
      final surah = segment['surah'] as int;
      final start = segment['start'] as int;
      final end = segment['end'] as int;
      if (start == 1 && surah != 1 && surah != 9) {
        items.add((isBismillah: true, surah: surah, ayah: null));
      }
      for (var ayah = start; ayah <= end; ayah++) {
        items.add((isBismillah: false, surah: surah, ayah: ayah));
      }
    }
    return items;
  }
}
