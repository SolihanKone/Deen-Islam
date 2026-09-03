import 'package:equatable/equatable.dart';

import '../../../core/l10n/localized_content.dart';

class AllahName extends Equatable {
  const AllahName({
    required this.id,
    required this.number,
    required this.arabic,
    required this.transliteration,
    required this.meaning,
  });

  final String id;
  final int number;
  final String arabic;
  final String transliteration;
  final String meaning;

  factory AllahName.fromJson(Map<String, dynamic> json) => AllahName(
        id: json['id'] as String,
        number: (json['number'] as num).toInt(),
        arabic: json['arabic'] as String,
        transliteration: json['transliteration'] as String,
        meaning: json['meaning'] as String,
      );

  String meaningFor(String locale) =>
      LocalizedContent.nameMeaning(id, locale, meaning);

  @override
  List<Object?> get props =>
      [id, number, arabic, transliteration, meaning];
}
