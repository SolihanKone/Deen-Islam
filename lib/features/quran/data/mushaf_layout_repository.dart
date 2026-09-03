import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/mushaf_page_model.dart';

/// Loads pre-defined Madinah Mushaf line layout from bundled JSON assets.
class MushafLayoutRepository {
  MushafLayoutRepository();

  final Map<int, MushafPageModel> _cache = {};

  Future<MushafPageModel> loadPage(int pageNumber) async {
    final page = pageNumber.clamp(1, MushafPageModel.totalPages);
    final cached = _cache[page];
    if (cached != null) return cached;

    final assetPath =
        'assets/mushaf/pages/page-${page.toString().padLeft(3, '0')}.json';
    final raw = await rootBundle.loadString(assetPath);
    final model = MushafPageModel.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    _cache[page] = model;
    return model;
  }

  MushafPageModel? cachedPage(int pageNumber) => _cache[pageNumber];

  void preloadPages(Iterable<int> pageNumbers) {
    for (final page in pageNumbers) {
      if (page >= 1 &&
          page <= MushafPageModel.totalPages &&
          !_cache.containsKey(page)) {
        loadPage(page);
      }
    }
  }

  void clearCache() => _cache.clear();
}

final mushafLayoutRepositoryProvider = Provider<MushafLayoutRepository>(
  (ref) => MushafLayoutRepository(),
);

final mushafPageModelProvider =
    FutureProvider.family<MushafPageModel, int>((ref, pageNumber) {
  return ref.read(mushafLayoutRepositoryProvider).loadPage(pageNumber);
});
