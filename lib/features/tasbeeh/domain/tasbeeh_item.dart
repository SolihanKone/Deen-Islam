import 'package:equatable/equatable.dart';

import '../../../core/l10n/localized_content.dart';

class TasbeehItem extends Equatable {
  const TasbeehItem({
    required this.id,
    required this.title,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.target,
    required this.category,
  });

  final String id;
  final String title;
  final String arabic;
  final String transliteration;
  final String translation;
  final int target;
  final String category;

  factory TasbeehItem.fromJson(Map<String, dynamic> json) => TasbeehItem(
        id: json['id'] as String,
        title: json['title'] as String,
        arabic: json['arabic'] as String,
        transliteration: json['transliteration'] as String? ?? '',
        translation: json['translation'] as String? ?? '',
        target: (json['target'] as num?)?.toInt() ?? 33,
        category: json['category'] as String? ?? 'core',
      );

  String titleFor(String locale) =>
      LocalizedContent.tasbeehTitle(id, locale, title);

  String translationFor(String locale) =>
      LocalizedContent.tasbeehTranslation(id, locale, translation);

  @override
  List<Object?> get props =>
      [id, title, arabic, transliteration, translation, target, category];
}
