abstract final class ApiConstants {
  static const String alQuranBase = 'https://api.alquran.cloud/v1';
  static const String aladhanBase = 'https://api.aladhan.com/v1';
  static const String everyAyahBase = 'https://everyayah.com/data';
}

/// AlQuran Cloud edition identifiers for translations (extend as needed).
abstract final class QuranEditions {
  static const String arabicUthmani = 'quran-uthmani';
  static const String englishSahih = 'en.sahih';
  static const String urdu = 'ur.jalandhry';
  static const String french = 'fr.hamidullah';

  static const Map<String, String> labels = {
    arabicUthmani: 'Arabic (Uthmani)',
    englishSahih: 'English — Saheeh International',
    urdu: 'Urdu',
    french: 'French — Hamidullah',
  };

  static List<String> translationIds() => [
        englishSahih,
        urdu,
        french,
      ];
}
