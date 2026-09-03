import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/dua_item.dart';

final duasRepositoryProvider = Provider<DuasRepository>((ref) {
  return DuasRepository();
});

class DuasRepository {
  List<DuaItem>? _cache;

  Future<List<DuaItem>> loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/duas.json');
    final list = jsonDecode(raw) as List<dynamic>;
    _cache = list
        .map(
          (e) => DuaItem(
            id: e['id'] as String,
            category: e['category'] as String,
            title: e['title'] as String,
            arabic: e['arabic'] as String,
            transliteration: e['transliteration'] as String,
            translation: e['translation'] as String,
          ),
        )
        .toList();
    return _cache!;
  }

  Future<List<DuaItem>> byCategory(String category) async {
    final all = await loadAll();
    return all.where((d) => d.category == category).toList();
  }
}
