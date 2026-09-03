import '../entities/quran_ayah.dart';
import '../entities/surah_summary.dart';

abstract class QuranRepository {
  Future<List<SurahSummary>> getSurahList();

  Future<List<QuranAyah>> getSurahAyahs(
    int surahNumber, {
    required String translationEditionId,
  });

  Future<List<QuranSearchMatch>> searchAyahs(
    String query, {
    required String searchEditionId,
  });
}

class QuranSearchMatch {
  QuranSearchMatch({
    required this.surahNumber,
    required this.surahName,
    required this.ayahNumberInSurah,
    required this.snippet,
  });

  final int surahNumber;
  final String surahName;
  final int ayahNumberInSurah;
  final String snippet;
}
