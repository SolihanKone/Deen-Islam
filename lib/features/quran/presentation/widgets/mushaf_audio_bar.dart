import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran/quran.dart' as q;

import '../../../../core/l10n/app_strings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/widgets/settings_option_sheet.dart';
import '../../../settings/presentation/widgets/translation_voice_sheet.dart';
import '../../domain/entities/piper_voice.dart';
import '../../domain/entities/reciter.dart';
import '../../domain/mushaf_navigation.dart';
import '../providers/quran_player_provider.dart';
import 'arabic_speed_button.dart';
import 'playback_transport_buttons.dart';

class MushafAudioBar extends ConsumerWidget {
  const MushafAudioBar({super.key, this.embedded = false});

  /// When true, omit outer elevation/SafeArea (parent provides them).
  final bool embedded;

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

    final playerState = ref.read(quranPlayerProvider);
    final currentItem = playerState.currentMushafItem;
    if (playerState.isMushafPlayback && currentItem != null) {
      await ref.read(quranPlayerProvider.notifier).playMushafFromItem(
            currentItem,
            continuePages: playerState.mushafContinuePages,
          );
    }
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
    final ctrl = ref.read(quranPlayerProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final scheme = Theme.of(context).colorScheme;
    final reciter = Reciter.byId(settings.reciterId);
    final t = AppStrings.of(context);
    final showTranslationVoice =
        state.includeTranslationAudio || settings.showTranslation;

    if (!state.isMushafPlayback) return const SizedBox.shrink();

    final item = state.currentMushafItem;
    String ayahLabel;
    if (item != null) {
      final surahName = t.surahName(item.surah);
      if (item.isBismillah) {
        ayahLabel = '$surahName · ${t.bismillah}';
      } else {
        ayahLabel = '$surahName ${item.surah}:${item.ayah}';
      }
      if (state.isPlayingTranslation) {
        ayahLabel = '$ayahLabel · ${t.translation}';
      }
    } else {
      ayahLabel = state.mushafPage != null
          ? t.pageLabel(state.mushafPage!)
          : t.listening;
    }

    final durationMs = state.duration.inMilliseconds;
    final positionMs = state.position.inMilliseconds.clamp(0, durationMs);
    final progress = durationMs > 0 ? positionMs / durationMs : 0.0;

    return Material(
      elevation: embedded ? 0 : 8,
      color: scheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        bottom: !embedded,
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
                      ayahLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
              if (!state.isPlayingTranslation)
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
                      value: progress.clamp(0.0, 1.0),
                      onChanged: state.loading
                          ? null
                          : (v) {
                              final target = Duration(
                                milliseconds: (v * durationMs).round(),
                              );
                              ctrl.seekCurrentSource(target);
                            },
                    ),
                  ),
                ),
              if (state.error != null)
                Text(
                  AppStrings.of(context).friendlyError(state.error!),
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

int pageForMushafPlaybackItem(MushafPlaybackItem item) {
  if (item.isBismillah) return q.getPageNumber(item.surah, 1);
  return q.getPageNumber(item.surah, item.ayah!);
}
