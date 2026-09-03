import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/app_ui.dart';
import '../providers/quran_prefs_provider.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final bookmarks = ref.watch(quranPrefsProvider).bookmarks.toList()..sort();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(strings.bookmarks)),
      body: bookmarks.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  strings.noBookmarksYet,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.sm,
                AppSpacing.screenH,
                AppSpacing.screenBottom,
              ),
              itemCount: bookmarks.length,
              itemBuilder: (context, index) {
                final key = bookmarks[index];
                final parts = key.split(':');
                final surah = int.tryParse(parts.first) ?? 0;
                final ayah = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
                final name = surah >= 1 && surah <= 114
                    ? strings.surahName(surah)
                    : strings.surahWordNumber(surah);

                return AppActionTile(
                  icon: Icons.bookmark_rounded,
                  title: '$name $surah:$ayah',
                  subtitle: strings.openInSurahReader,
                  onTap: () {
                    if (surah > 0) {
                      context.push('/learn-quran/surah/$surah');
                    }
                  },
                );
              },
            ),
    );
  }
}
