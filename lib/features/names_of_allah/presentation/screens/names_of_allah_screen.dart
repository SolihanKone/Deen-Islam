import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/audio/arabic_tts.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/async_body.dart';
import '../../domain/allah_name.dart';
import '../providers/names_providers.dart';

class NamesOfAllahScreen extends ConsumerWidget {
  const NamesOfAllahScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(namesOfAllahProvider);
    final tts = ref.watch(arabicTtsProvider);
    final t = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.namesOfAllah),
        actions: [
          if (tts.speakingId != null)
            IconButton(
              tooltip: t.stop,
              onPressed: () => ref.read(arabicTtsProvider.notifier).stop(),
              icon: const Icon(Icons.stop_rounded),
            ),
        ],
      ),
      body: AsyncBody(
        async: async,
        onRetry: () => ref.invalidate(namesOfAllahProvider),
        data: (context, list) {
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.sm,
              AppSpacing.screenH,
              AppSpacing.screenBottom,
            ),
            itemCount: list.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    t.namesIntro,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                );
              }
              final name = list[index - 1];
              return _NameCard(name: name);
            },
          );
        },
      ),
    );
  }
}

class _NameCard extends ConsumerWidget {
  const _NameCard({required this.name});

  final AllahName name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final speaking = ref.watch(arabicTtsProvider).isSpeaking(name.id);

    return AppSurfaceCard(
      onTap: () => _openDetail(context, ref, name),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${name.number}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  name.arabic,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: AppTheme.arabicText(context, fontSize: 22).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  name.transliteration,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  name.meaningFor(AppStrings.of(context).languageCode),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: speaking
                ? AppStrings.of(context).stop
                : AppStrings.of(context).playArabic,
            onPressed: () => ref
                .read(arabicTtsProvider.notifier)
                .toggle(name.id, name.arabic),
            icon: Icon(
              speaking
                  ? Icons.stop_circle_rounded
                  : Icons.play_circle_filled_rounded,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, WidgetRef ref, AllahName name) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Consumer(
          builder: (context, ref, _) {
            final speaking =
                ref.watch(arabicTtsProvider.select((s) => s.isSpeaking(name.id)));
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${name.number}. ${name.transliteration}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                const SizedBox(height: 12),
                Text(
                  name.arabic,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: AppTheme.arabicText(context, fontSize: 36).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name.meaningFor(AppStrings.of(context).languageCode),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: () => ref
                      .read(arabicTtsProvider.notifier)
                      .toggle(name.id, name.arabic),
                  icon: Icon(
                    speaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                  ),
                  label: Text(
                    speaking
                        ? AppStrings.of(context).stop
                        : AppStrings.of(context).playArabic,
                  ),
                ),
              ],
              ),
            );
          },
        ),
      ),
    );
  }
}
