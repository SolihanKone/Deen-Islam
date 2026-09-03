import 'package:equatable/equatable.dart';

class SurahSummary extends Equatable {
  const SurahSummary({
    required this.number,
    required this.nameArabic,
    required this.nameEnglish,
    required this.englishNameTranslation,
    required this.numberOfAyahs,
    required this.revelationType,
  });

  final int number;
  final String nameArabic;
  final String nameEnglish;
  final String englishNameTranslation;
  final int numberOfAyahs;
  final String revelationType;

  @override
  List<Object?> get props =>
      [number, nameArabic, nameEnglish, englishNameTranslation, numberOfAyahs, revelationType];
}
