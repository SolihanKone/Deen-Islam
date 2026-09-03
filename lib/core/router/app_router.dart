import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/duas/presentation/screens/duas_screen.dart';
import '../../features/home/presentation/dashboard_screen.dart';
import '../../features/names_of_allah/presentation/screens/names_of_allah_screen.dart';
import '../../features/prayer/presentation/screens/prayer_screen.dart';
import '../../features/prayer/presentation/screens/qibla_screen.dart';
import '../../features/quran/presentation/screens/bookmarks_screen.dart';
import '../../features/quran/presentation/screens/learn_quran_screen.dart';
import '../../features/quran/presentation/screens/mushaf_reader_screen.dart';
import '../../features/quran/presentation/screens/quran_search_screen.dart';
import '../../features/quran/presentation/screens/surah_list_screen.dart';
import '../../features/quran/presentation/screens/surah_reader_screen.dart';
import '../../features/quran/presentation/providers/quran_prefs_provider.dart';
import '../../features/settings/presentation/screens/privacy_policy_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/tasbeeh/presentation/screens/tasbeeh_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/mushaf',
        builder: (context, state) {
          final fromQuery =
              int.tryParse(state.uri.queryParameters['page'] ?? '');
          final prefs = ref.read(quranPrefsProvider);
          final page = fromQuery ?? prefs.lastMushafPage ?? 1;
          return MushafReaderScreen(
            initialPage: page,
            autoPlayAudio: state.uri.queryParameters['audio'] == '1',
            continueAudioPages: state.uri.queryParameters['audio'] == '1',
          );
        },
      ),
      GoRoute(
        path: '/learn-quran',
        builder: (context, state) => const LearnQuranScreen(),
        routes: [
          GoRoute(
            path: 'surahs',
            builder: (context, state) => const SurahListScreen(),
          ),
          GoRoute(
            path: 'surah/:num',
            builder: (context, state) => SurahReaderScreen(
              surahNumber: int.parse(state.pathParameters['num']!),
            ),
          ),
          GoRoute(
            path: 'search',
            builder: (context, state) => const QuranSearchScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/bookmarks',
        builder: (context, state) => const BookmarksScreen(),
      ),
      GoRoute(
        path: '/duas',
        builder: (context, state) => const DuasScreen(),
      ),
      GoRoute(
        path: '/tasbeeh',
        builder: (context, state) => const TasbeehScreen(),
      ),
      GoRoute(
        path: '/names-of-allah',
        builder: (context, state) => const NamesOfAllahScreen(),
      ),
      GoRoute(
        path: '/prayer',
        builder: (context, state) => const PrayerScreen(),
      ),
      GoRoute(
        path: '/qibla',
        builder: (context, state) => const QiblaScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
    ],
  );
});
