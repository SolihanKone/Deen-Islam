import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/quran_player_provider.dart';

/// Previous / next ayah and repeat-one, shared by Learn and Read Quran bars.
class PlaybackTransportButtons extends ConsumerWidget {
  const PlaybackTransportButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(quranPlayerProvider.notifier);
    final repeat = ref.watch(settingsProvider.select((s) => s.repeatAyah));
    final t = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _iconBtn(
          tooltip: t.previousAyah,
          onPressed: ctrl.skipToPreviousAyah,
          icon: Icons.skip_previous_rounded,
        ),
        _iconBtn(
          tooltip: t.nextAyah,
          onPressed: ctrl.skipToNextAyah,
          icon: Icons.skip_next_rounded,
        ),
        Tooltip(
          message: t.repeatAyah,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Material(
              color: repeat ? scheme.primary : Colors.transparent,
              elevation: repeat ? 3 : 0,
              shadowColor: scheme.primary.withValues(alpha: 0.55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: repeat
                      ? scheme.primary
                      : scheme.outlineVariant.withValues(alpha: 0.7),
                  width: repeat ? 0 : 1,
                ),
              ),
              child: InkWell(
                onTap: () =>
                    ref.read(settingsProvider.notifier).setRepeatAyah(!repeat),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                  child: Icon(
                    Icons.repeat_one_rounded,
                    size: 22,
                    color: repeat ? scheme.onPrimary : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _iconBtn({
    required String tooltip,
    required VoidCallback? onPressed,
    required IconData icon,
  }) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 28),
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
    );
  }
}
