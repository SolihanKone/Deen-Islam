import 'package:equatable/equatable.dart';

import '../../../core/l10n/localized_content.dart';

class DuaItem extends Equatable {
  const DuaItem({
    required this.id,
    required this.category,
    required this.title,
    required this.arabic,
    required this.transliteration,
    required this.translation,
  });

  final String id;
  final String category;
  final String title;
  final String arabic;
  final String transliteration;
  final String translation;

  String titleFor(String locale) =>
      LocalizedContent.duaTitle(id, locale, title);

  String translationFor(String locale) =>
      LocalizedContent.duaTranslation(id, locale, translation);

  @override
  List<Object?> get props =>
      [id, category, title, arabic, transliteration, translation];
}
