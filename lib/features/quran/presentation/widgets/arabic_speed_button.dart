import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/widgets/settings_option_sheet.dart';
import '../../domain/arabic_playback_speed.dart';

/// Compact control to change Arabic recitation speed (not translation TTS).
class ArabicSpeedButton extends ConsumerWidget {
  const ArabicSpeedButton({super.key});

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final t = AppStrings.of(context);
    final selected = ArabicPlaybackSpeed.sanitize(
      ref.read(settingsProvider).arabicPlaybackSpeed,
    );
    final next = await showSettingsOptionSheet<double>(
      context: context,
      title: t.arabicSpeed,
      subtitle: t.arabicSpeedHint,
      selected: selected,
      options: [
        for (final speed in ArabicPlaybackSpeed.presets)
          SettingsOption(
            value: speed,
            title: ArabicPlaybackSpeed.label(speed),
            subtitle: t.arabicSpeedName(speed),
          ),
      ],
    );
    if (next == null || next == selected) return;
    await ref.read(settingsProvider.notifier).setArabicPlaybackSpeed(next);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speed = ArabicPlaybackSpeed.sanitize(
      ref.watch(settingsProvider).arabicPlaybackSpeed,
    );
    final t = AppStrings.of(context);
    return Tooltip(
      message: t.arabicSpeed,
      child: TextButton(
        onPressed: () => _pick(context, ref),
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          minimumSize: const Size(36, 28),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          ArabicPlaybackSpeed.label(speed),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.1,
              ),
        ),
      ),
    );
  }
}
