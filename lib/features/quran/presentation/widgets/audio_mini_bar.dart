import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/widgets/settings_option_sheet.dart';
import '../../../settings/presentation/widgets/translation_voice_sheet.dart';
import '../../domain/entities/piper_voice.dart';
import '../../domain/entities/reciter.dart';
import '../providers/quran_player_provider.dart';
import 'arabic_speed_button.dart';
import 'playback_transport_buttons.dart';

class AudioMiniBar extends ConsumerWidget {
  const AudioMiniBar({
    super.key,
    required this.surahName,
    required this.ayahCount,
    this.onPlaySurah,
  });

  final String surahName;
  final int ayahCount;
  final VoidCallback? onPlaySurah;

  Future<void> _pickReciter(
    BuildContext context,
    WidgetRef ref,
    String selected,
  ) async {
    final t = AppStrings.of(context);
    final next = await showSettingsOptionSheet<String>(
      context: context,
      title: t.arabicReciter,
      subtitle: t.arabicReciterHint,
      selected: selected,
      options: [
        for (final r in Reciter.presets)
          SettingsOption(value: r.id, title: r.name),
      ],
    );
    if (next == null || next == selected) return;
    await ref.read(settingsProvider.notifier).setReciter(next);
  }

  Future<void> _pickTranslationVoice(
    BuildContext context,
    WidgetRef ref,
  ) {
    return showTranslationVoiceSheet(context: context, ref: ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quranPlayerProvider);
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(quranPlayerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    final t = AppStrings.of(context);
    final idle = state.surahNumber == null && !state.loading;
    final reciter = Reciter.byId(settings.reciterId);
    final showTranslationVoice =
        state.includeTranslationAudio || settings.showTranslation;

    final label = idle
        ? surahName
        : state.isPlayingTranslation
            ? '$surahName · ${t.translation} ${state.currentAyahInSurah}/$ayahCount'
            : '$surahName ${state.currentAyahInSurah}/$ayahCount';

    return Material(
      elevation: 8,
      color: scheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _CompactVoiceChip(
                      label: t.arabicChip,
                      value: reciter.name,
                      onTap: () =>
                          _pickReciter(context, ref, settings.reciterId),
                    ),
                  ),
                  if (showTranslationVoice) ...[
                    const SizedBox(width: 6),
                    Expanded(
                      child: _CompactVoiceChip(
                        label: t.voiceChip,
                        value: PiperVoice.byId(settings.translationVoiceId).name,
                        onTap: () => _pickTranslationVoice(context, ref),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (idle) ...[
                    const ArabicSpeedButton(),
                    TextButton(
                      onPressed: onPlaySurah,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(t.play),
                    ),
                  ] else ...[
                    const ArabicSpeedButton(),
                    const PlaybackTransportButtons(),
                    IconButton(
                      tooltip: t.stop,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 28),
                      onPressed: ctrl.stop,
                      icon: const Icon(Icons.stop_rounded, size: 18),
                    ),
                    IconButton(
                      tooltip: state.playing || state.isPlayingTranslation
                          ? t.pause
                          : t.play,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 28),
                      onPressed: state.loading ? null : ctrl.togglePlayPause,
                      icon: Icon(
                        state.playing || state.isPlayingTranslation
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 20,
                      ),
                    ),
                  ],
                  if (state.loading)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
              if (!idle && !state.isPlayingTranslation)
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 1.5,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 4),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 8),
                  ),
                  child: SizedBox(
                    height: 18,
                    child: Slider(
                      value: () {
                        final d = state.duration.inMilliseconds;
                        if (d <= 0) return 0.0;
                        return (state.position.inMilliseconds / d)
                            .clamp(0.0, 1.0);
                      }(),
                      onChanged: state.loading
                          ? null
                          : (v) {
                              final d = state.duration.inMilliseconds;
                              ctrl.seekCurrentSource(
                                Duration(milliseconds: (v * d).round()),
                              );
                            },
                    ),
                  ),
                ),
              if (state.error != null)
                Text(
                  t.friendlyError(state.error!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: scheme.error, fontSize: 10),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactVoiceChip extends StatelessWidget {
  const _CompactVoiceChip({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.65),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$label · $value',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                ),
              ),
              Icon(
                Icons.expand_more_rounded,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
