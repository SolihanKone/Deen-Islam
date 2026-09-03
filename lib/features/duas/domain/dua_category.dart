import 'package:flutter/material.dart';

/// Metadata for dua categories (Hisn-style groupings).
class DuaCategory {
  const DuaCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  static const List<DuaCategory> all = [
    DuaCategory(
      id: 'morning',
      title: 'Morning',
      subtitle: 'Adhkar after Fajr',
      icon: Icons.wb_sunny_rounded,
      color: Color(0xFFE09F3E),
    ),
    DuaCategory(
      id: 'evening',
      title: 'Evening',
      subtitle: 'Adhkar after Asr',
      icon: Icons.nights_stay_rounded,
      color: Color(0xFF5C4D7D),
    ),
    DuaCategory(
      id: 'after_salah',
      title: 'After Salah',
      subtitle: 'Remembrance after prayer',
      icon: Icons.mosque_rounded,
      color: Color(0xFF1B4332),
    ),
    DuaCategory(
      id: 'sleep',
      title: 'Sleep',
      subtitle: 'Before bed & waking',
      icon: Icons.bedtime_rounded,
      color: Color(0xFF3D5A80),
    ),
    DuaCategory(
      id: 'home',
      title: 'Home & Mosque',
      subtitle: 'Entering and leaving',
      icon: Icons.home_rounded,
      color: Color(0xFF2D6A4F),
    ),
    DuaCategory(
      id: 'food',
      title: 'Food & Drink',
      subtitle: 'Before and after meals',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFBC4749),
    ),
    DuaCategory(
      id: 'travel',
      title: 'Travel',
      subtitle: 'On the journey',
      icon: Icons.flight_rounded,
      color: Color(0xFF0077B6),
    ),
    DuaCategory(
      id: 'protection',
      title: 'Protection',
      subtitle: 'Fear, anxiety, ruqyah',
      icon: Icons.shield_rounded,
      color: Color(0xFF9B2335),
    ),
    DuaCategory(
      id: 'forgiveness',
      title: 'Forgiveness',
      subtitle: 'Istighfar & repentance',
      icon: Icons.volunteer_activism_rounded,
      color: Color(0xFF6A994E),
    ),
    DuaCategory(
      id: 'family',
      title: 'Family',
      subtitle: 'Parents & children',
      icon: Icons.family_restroom_rounded,
      color: Color(0xFFB56576),
    ),
    DuaCategory(
      id: 'quranic',
      title: 'Quranic Duas',
      subtitle: 'From the Qur’an',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF386641),
    ),
    DuaCategory(
      id: 'illness',
      title: 'Illness',
      subtitle: 'Healing & visiting sick',
      icon: Icons.health_and_safety_rounded,
      color: Color(0xFF4A6FA5),
    ),
    DuaCategory(
      id: 'daily',
      title: 'Daily Life',
      subtitle: 'Clothes, toilet, sneezing',
      icon: Icons.today_rounded,
      color: Color(0xFF6D6875),
    ),
    DuaCategory(
      id: 'hajj',
      title: 'Hajj & Umrah',
      subtitle: 'Pilgrimage remembrances',
      icon: Icons.landscape_rounded,
      color: Color(0xFF8B5E3C),
    ),
  ];

  static DuaCategory? byId(String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }
}
