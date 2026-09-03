import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';

/// Shared bottom action bar: Play · Search · Translation (compact).
class QuranNavBar extends StatelessWidget {
  const QuranNavBar({
    super.key,
    required this.onPlay,
    required this.onSearch,
    required this.onToggleTranslation,
    required this.translationOn,
    this.playing = false,
    this.extra,
  });

  final VoidCallback onPlay;
  final VoidCallback onSearch;
  final VoidCallback onToggleTranslation;
  final bool translationOn;
  final bool playing;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = AppStrings.of(context);

    return Material(
      elevation: 8,
      color: scheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 4, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (extra != null) ...[
                extra!,
                Divider(
                  height: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ],
              Row(
                children: [
                  Expanded(
                    child: _NavAction(
                      icon: playing
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_filled_rounded,
                      label: playing ? s.pause : s.play,
                      selected: playing,
                      onTap: onPlay,
                    ),
                  ),
                  Expanded(
                    child: _NavAction(
                      icon: Icons.search_rounded,
                      label: s.searchSurah,
                      onTap: onSearch,
                    ),
                  ),
                  Expanded(
                    child: _NavAction(
                      icon: translationOn
                          ? Icons.translate_rounded
                          : Icons.translate_outlined,
                      label: s.translation,
                      selected: translationOn,
                      onTap: onToggleTranslation,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavAction extends StatelessWidget {
  const _NavAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 1),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    height: 1.1,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
