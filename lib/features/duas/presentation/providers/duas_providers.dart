import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/storage/hive_boxes.dart';
import '../../data/duas_repository.dart';
import '../../domain/dua_item.dart';

final duasListProvider = FutureProvider<List<DuaItem>>((ref) async {
  return ref.watch(duasRepositoryProvider).loadAll();
});

final favoriteDuasProvider =
    NotifierProvider<FavoriteDuasNotifier, Set<String>>(FavoriteDuasNotifier.new);

final duasInCategoryProvider =
    Provider.family<AsyncValue<List<DuaItem>>, String>((ref, categoryId) {
  final async = ref.watch(duasListProvider);
  return async.whenData(
    (list) => list.where((d) => d.category == categoryId).toList(),
  );
});

final favoriteDuasListProvider = Provider<AsyncValue<List<DuaItem>>>((ref) {
  final async = ref.watch(duasListProvider);
  final favs = ref.watch(favoriteDuasProvider);
  return async.whenData(
    (list) => list.where((d) => favs.contains(d.id)).toList(),
  );
});

class FavoriteDuasNotifier extends Notifier<Set<String>> {
  Box<String> get _box => Hive.box<String>(HiveBoxes.favoritesDuas);

  @override
  Set<String> build() => _box.keys.cast<String>().toSet();

  Future<void> toggle(String id) async {
    if (state.contains(id)) {
      await _box.delete(id);
    } else {
      await _box.put(id, '1');
    }
    state = _box.keys.cast<String>().toSet();
  }

  bool isFavorite(String id) => state.contains(id);
}
