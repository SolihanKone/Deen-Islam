import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/audio/arabic_tts.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/storage/hive_boxes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/async_body.dart';
import '../../domain/tasbeeh_item.dart';
import '../providers/tasbeeh_providers.dart';

class TasbeehScreen extends ConsumerWidget {
  const TasbeehScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tasbeehListProvider);
    final tts = ref.watch(arabicTtsProvider);
    final t = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.tasbeeh),
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
        onRetry: () => ref.invalidate(tasbeehListProvider),
        data: (context, list) {
          final core = list.where((e) => e.category == 'core').toList();
          final virtue = list.where((e) => e.category == 'virtue').toList();
          final sets = list.where((e) => e.category == 'sets').toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.sm,
              AppSpacing.screenH,
              AppSpacing.screenBottom,
            ),
            children: [
              Text(
                t.tapDhikrHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              AppSectionHeader(title: t.coreDhikr),
              ...core.map((item) => _TasbeehTile(item: item)),
              AppSectionHeader(title: t.virtuousRemembrances),
              ...virtue.map((item) => _TasbeehTile(item: item)),
              AppSectionHeader(title: t.dailySets),
              ...sets.map((item) => _TasbeehTile(item: item)),
            ],
          );
        },
      ),
    );
  }
}

class _TasbeehTile extends ConsumerWidget {
  const _TasbeehTile({required this.item});

  final TasbeehItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final speaking = ref.watch(arabicTtsProvider).isSpeaking(item.id);

    return AppSurfaceCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TasbeehCounterScreen(item: item),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.titleFor(AppStrings.of(context).languageCode),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.arabic,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.arabicText(context, fontSize: 18),
                ),
                Text(
                  AppStrings.of(context).targetLabel(item.target),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
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
                .toggle(item.id, item.arabic),
            icon: Icon(
              speaking ? Icons.stop_circle_rounded : Icons.play_circle_filled_rounded,
              color: scheme.primary,
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

class TasbeehCounterScreen extends ConsumerStatefulWidget {
  const TasbeehCounterScreen({super.key, required this.item});

  final TasbeehItem item;

  @override
  ConsumerState<TasbeehCounterScreen> createState() =>
      _TasbeehCounterScreenState();
}

class _TasbeehCounterScreenState extends ConsumerState<TasbeehCounterScreen> {
  late int _count;

  String get _key => 'tasbeeh_${widget.item.id}';

  @override
  void initState() {
    super.initState();
    final box = Hive.box<dynamic>(HiveBoxes.settings);
    _count = (box.get(_key) as int?) ?? 0;
  }

  Future<void> _persist() async {
    await Hive.box<dynamic>(HiveBoxes.settings).put(_key, _count);
  }

  Future<void> _tap() async {
    HapticFeedback.lightImpact();
    setState(() => _count += 1);
    await _persist();
  }

  Future<void> _reset() async {
    setState(() => _count = 0);
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final scheme = Theme.of(context).colorScheme;
    final target = item.target;
    final progress = target <= 0 ? 0.0 : (_count % target) / target;
    final loops = target <= 0 ? 0 : _count ~/ target;
    final speaking = ref.watch(arabicTtsProvider).isSpeaking(item.id);
    final t = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          item.titleFor(t.languageCode),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: t.reset,
            onPressed: _reset,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tapSize =
                  (constraints.maxHeight * 0.28).clamp(112.0, 180.0);
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Text(
                            item.arabic,
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: AppTheme.arabicText(context, fontSize: 28)
                                .copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.transliteration,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.translationFor(t.languageCode),
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.tonalIcon(
                            onPressed: () => ref
                                .read(arabicTtsProvider.notifier)
                                .toggle(item.id, item.arabic),
                            icon: Icon(
                              speaking
                                  ? Icons.stop_rounded
                                  : Icons.volume_up_rounded,
                            ),
                            label: Text(speaking ? t.stop : t.playArabic),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight * 0.55,
                    ),
                    child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_count',
                            style: Theme.of(context)
                                .textTheme
                                .displayLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: scheme.primary,
                                ),
                          ),
                          Text(
                            t.ofTargetCompleted(target, loops),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress == 0 && _count > 0 ? 1 : progress,
                              minHeight: 10,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: tapSize,
                            height: tapSize,
                            child: Material(
                              color: scheme.primary,
                              shape: const CircleBorder(),
                              elevation: 4,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: _tap,
                                child: Center(
                                  child: Text(
                                    t.tap,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: scheme.onPrimary,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.2,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
