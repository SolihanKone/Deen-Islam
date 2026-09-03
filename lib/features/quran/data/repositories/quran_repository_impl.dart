import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran/quran.dart' as q;

import '../../domain/entities/quran_ayah.dart';
import '../../domain/entities/surah_summary.dart';
import '../../domain/mushaf_translation.dart';
import '../../domain/repositories/quran_repository.dart';

final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  return QuranRepositoryImpl();
});

class QuranRepositoryImpl implements QuranRepository {
  QuranRepositoryImpl();

  @override
  Future<List<SurahSummary>> getSurahList() async {
    return [
      for (var n = 1; n <= 114; n++)
        SurahSummary(
          number: n,
          nameArabic: q.getSurahNameArabic(n),
          nameEnglish: q.getSurahNameEnglish(n),
          englishNameTranslation: q.getSurahNameEnglish(n),
          numberOfAyahs: q.getVerseCount(n),
          revelationType: q.getPlaceOfRevelation(n),
        ),
    ];
  }

  @override
  Future<List<QuranAyah>> getSurahAyahs(
    int surahNumber, {
    required String translationEditionId,
  }) async {
    final edition = MushafTranslation.fromEditionId(translationEditionId);
    final count = q.getVerseCount(surahNumber);
    return [
      for (var i = 1; i <= count; i++)
        QuranAyah(
          globalAyahNumber: 0,
          numberInSurah: i,
          arabicText: q.getVerse(surahNumber, i, verseEndSymbol: true),
          translationText: q.getVerseTranslation(
            surahNumber,
            i,
            translation: edition,
          ),
        ),
    ];
  }

  @override
  Future<List<QuranSearchMatch>> searchAyahs(
    String query, {
    required String searchEditionId,
  }) async {
    final needle = query.trim();
    if (needle.isEmpty) return [];
    final lower = needle.toLowerCase();
    final edition = MushafTranslation.fromEditionId(searchEditionId);
    final matches = <QuranSearchMatch>[];

    for (var surah = 1; surah <= 114; surah++) {
      final count = q.getVerseCount(surah);
      final name = q.getSurahNameEnglish(surah);
      for (var ayah = 1; ayah <= count; ayah++) {
        final translation = q.getVerseTranslation(
          surah,
          ayah,
          translation: edition,
        );
        final arabic = q.getVerse(surah, ayah);
        final translationHit = translation.toLowerCase().contains(lower);
        final arabicHit = arabic.contains(needle);
        if (!translationHit && !arabicHit) continue;
        matches.add(
          QuranSearchMatch(
            surahNumber: surah,
            surahName: name,
            ayahNumberInSurah: ayah,
            snippet: translationHit ? translation : arabic,
          ),
        );
        if (matches.length >= 80) return matches;
      }
    }
    return matches;
  }
}
