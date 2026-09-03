import 'package:hive_flutter/hive_flutter.dart';

abstract final class HiveBoxes {
  static const String settings = 'settings';
  static const String quranCache = 'quran_cache';
  static const String bookmarks = 'bookmarks';
  static const String favoritesDuas = 'favorites_duas';
  static const String recentRecitation = 'recent_recitation';
  static const String lastLatitude = 'last_latitude';
  static const String lastLongitude = 'last_longitude';
  static const String installIdKey = 'install_id';
}

Future<void> initHive() async {
  await Hive.initFlutter();
  await Future.wait([
    Hive.openBox<String>(HiveBoxes.quranCache),
    Hive.openBox<dynamic>(HiveBoxes.settings),
    Hive.openBox<String>(HiveBoxes.bookmarks),
    Hive.openBox<String>(HiveBoxes.favoritesDuas),
    Hive.openBox<String>(HiveBoxes.recentRecitation),
  ]);
}
