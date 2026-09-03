import 'package:equatable/equatable.dart';

class QuranAyah extends Equatable {
  const QuranAyah({
    required this.globalAyahNumber,
    required this.numberInSurah,
    required this.arabicText,
    required this.translationText,
  });

  final int globalAyahNumber;
  final int numberInSurah;
  final String arabicText;
  final String translationText;

  @override
  List<Object?> get props =>
      [globalAyahNumber, numberInSurah, arabicText, translationText];
}
