import 'package:quran/quran.dart' as q;

import '../../../core/constants/api_constants.dart';

/// Maps AlQuran Cloud edition ids / locale codes to offline `quran` translations.
abstract final class MushafTranslation {
  static q.Translation fromEditionId(String editionId) {
    final id = editionId.trim().toLowerCase();
    if (id.startsWith('ur') || id.contains('urdu')) {
      return q.Translation.urdu;
    }
    if (id.startsWith('fr') || id.contains('hamidullah') || id == 'fr') {
      return q.Translation.frHamidullah;
    }
    switch (editionId) {
      case QuranEditions.urdu:
        return q.Translation.urdu;
      case QuranEditions.french:
        return q.Translation.frHamidullah;
      case QuranEditions.englishSahih:
      default:
        return q.Translation.enSaheeh;
    }
  }
}
