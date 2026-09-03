import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/audio/arabic_tts.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/async_body.dart';
import '../../domain/dua_category.dart';
import '../../domain/dua_item.dart';
import '../providers/duas_providers.dart';

class DuasScreen extends ConsumerWidget {
  const DuasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(duasListProvider);
    final favCount = ref.watch(favoriteDuasProvider).length;
    final scheme = Theme.of(context).colorScheme;
    final t = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.duas)),
      body: AsyncBody(
        async: async,
        onRetry: () => ref.invalidate(duasListProvider),
        data: (context, list) {
          final counts = <String, int>{};
          for (final d in list) {
            counts[d.category] = (counts[d.category] ?? 0) + 1;
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.sm,
              AppSpacing.screenH,
              AppSpacing.screenBottom,
            ),
            children: [
              Text(
                t.chooseCategory,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                t.tapPlayArabic,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (favCount > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CategoryTile(
                    title: t.favorites,
                    subtitle: t.savedCount(favCount),
                    icon: Icons.favorite_rounded,
                    color: scheme.primary,
                    count: favCount,
                    expand: false,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _DuaListScreen(
                          title: t.favorites,
                          favoritesOnly: true,
                        ),
                      ),
                    ),
                  ),
                ),
              Builder(
                builder: (context) {
                  final cats = DuaCategory.all
                      .where((c) => (counts[c.id] ?? 0) > 0)
                      .toList();
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cats.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      mainAxisExtent: 132,
                    ),
                    itemBuilder: (context, index) {
                      final cat = cats[index];
                      final count = counts[cat.id] ?? 0;
                      return _CategoryTile(
                        title: t.duaCategoryTitle(cat.id),
                        subtitle: t.duaCategorySubtitle(cat.id),
                        icon: cat.icon,
                        color: cat.color,
                        count: count,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => _DuaListScreen(
                              title: t.duaCategoryTitle(cat.id),
                              categoryId: cat.id,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.count,
    required this.onTap,
    this.expand = true,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback onTap;

  /// When false (e.g. Favorites in a ListView), avoid Expanded/Spacer so
  /// the tile works with unbounded height.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const Spacer(),
                    Text(
                      '$count',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                if (expand) ...[
                  const SizedBox(height: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                ),
                          ),
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                    height: 1.15,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DuaListScreen extends ConsumerWidget {
  const _DuaListScreen({
    required this.title,
    this.categoryId,
    this.favoritesOnly = false,
  });

  final String title;
  final String? categoryId;
  final bool favoritesOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = favoritesOnly
        ? ref.watch(favoriteDuasListProvider)
        : ref.watch(duasInCategoryProvider(categoryId!));
    final tts = ref.watch(arabicTtsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (tts.speakingId != null)
            IconButton(
              tooltip: AppStrings.of(context).stop,
              onPressed: () => ref.read(arabicTtsProvider.notifier).stop(),
              icon: const Icon(Icons.stop_rounded),
            ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(child: Text(AppStrings.of(context).noDuasInCategory));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.sm,
              AppSpacing.screenH,
              AppSpacing.screenBottom,
            ),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final d = list[i];
              return _DuaCard(
                dua: d,
                speaking: tts.isSpeaking(d.id),
                onPlay: () =>
                    ref.read(arabicTtsProvider.notifier).toggle(d.id, d.arabic),
                onOpen: () => _openDetail(context, ref, d),
              );
            },
          );
        },
      ),
    );
  }

  void _openDetail(BuildContext context, WidgetRef ref, DuaItem dua) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (context, scroll) => Consumer(
          builder: (context, ref, _) {
            final fav = ref.watch(favoriteDuasProvider).contains(dua.id);
            final speaking =
                ref.watch(arabicTtsProvider.select((s) => s.isSpeaking(dua.id)));
            final locale = AppStrings.of(context).languageCode;
            final meaning = dua.translationFor(locale);
            return ListView(
              controller: scroll,
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        dua.titleFor(locale),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => ref
                          .read(favoriteDuasProvider.notifier)
                          .toggle(dua.id),
                      icon: Icon(
                        fav ? Icons.favorite : Icons.favorite_border,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.tonalIcon(
                  onPressed: () => ref
                      .read(arabicTtsProvider.notifier)
                      .toggle(dua.id, dua.arabic),
                  icon: Icon(
                    speaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                  ),
                  label: Text(
                    speaking
                        ? AppStrings.of(context).stopArabic
                        : AppStrings.of(context).playArabic,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  dua.arabic,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: AppTheme.arabicText(context).copyWith(fontSize: 24),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  dua.transliteration,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                ),
                if (meaning.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    meaning,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(height: 1.5),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DuaCard extends ConsumerWidget {
  const _DuaCard({
    required this.dua,
    required this.speaking,
    required this.onPlay,
    required this.onOpen,
  });

  final DuaItem dua;
  final bool speaking;
  final VoidCallback onPlay;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final fav = ref.watch(favoriteDuasProvider).contains(dua.id);
    final locale = AppStrings.of(context).languageCode;

    return AppSurfaceCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dua.titleFor(locale),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              IconButton(
                tooltip: speaking
                    ? AppStrings.of(context).stop
                    : AppStrings.of(context).playArabic,
                visualDensity: VisualDensity.compact,
                onPressed: onPlay,
                icon: Icon(
                  speaking ? Icons.stop_circle_rounded : Icons.play_circle_filled_rounded,
                  color: scheme.primary,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () =>
                    ref.read(favoriteDuasProvider.notifier).toggle(dua.id),
                icon: Icon(
                  fav ? Icons.favorite : Icons.favorite_border,
                  color: fav ? scheme.primary : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            dua.arabic,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.arabicText(context).copyWith(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
