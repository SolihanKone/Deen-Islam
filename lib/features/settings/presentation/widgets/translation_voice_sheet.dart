import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../quran/domain/entities/piper_voice.dart';
import '../../../quran/services/translation_voice_preview.dart';
import '../providers/settings_provider.dart';

/// Voice picker that speaks a Kokoro/Piper sample (downloads the model once).
Future<void> showTranslationVoiceSheet({
  required BuildContext context,
  required WidgetRef ref,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => const _TranslationVoiceSheet(),
  );
}

class _TranslationVoiceSheet extends ConsumerStatefulWidget {
  const _TranslationVoiceSheet();

  @override
  ConsumerState<_TranslationVoiceSheet> createState() =>
      _TranslationVoiceSheetState();
}

class _TranslationVoiceSheetState
    extends ConsumerState<_TranslationVoiceSheet> {
  final _preview = TranslationVoicePreview();
  String? _playingId;
  var _loading = false;
  final _ready = <String>{};

  @override
  void initState() {
    super.initState();
    _loadReady();
  }

  Future<void> _loadReady() async {
    for (final v in PiperVoice.presets) {
      if (await _preview.isModelReady(v.id) && mounted) {
        setState(() => _markReady(v.id));
      }
    }
  }

  void _markReady(String id) {
    final voice = PiperVoice.byId(id);
    if (voice.engine == TtsEngine.kokoro) {
      for (final v in PiperVoice.presets) {
        if (v.engine == TtsEngine.kokoro) _ready.add(v.id);
      }
    } else {
      _ready.add(id);
    }
  }

  @override
  void dispose() {
    _preview.dispose();
    super.dispose();
  }

  Future<void> _select(String id) async {
    await ref.read(settingsProvider.notifier).setTranslationVoice(id);
    if (!mounted) return;
    setState(() {
      _playingId = id;
      _loading = true;
    });
    try {
      await _preview.play(
        voice: id,
        onAudioReady: () {
          if (mounted && _playingId == id) {
            setState(() {
              _loading = false;
              _markReady(id);
            });
          }
        },
      );
    } catch (e) {
      if (!mounted || _playingId != id) return;
      setState(() => _loading = false);
      final t = AppStrings.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.friendlyError(e))));
    } finally {
      if (mounted && _playingId == id) {
        setState(() => _loading = false);
      }
    }
  }

  List<_VoiceRow> _voiceRows(AppStrings t) {
    final rows = <_VoiceRow>[];
    void addGroup(String title, String language) {
      rows.add(_VoiceRow.header(title));
      for (final v in PiperVoice.presets) {
        if (v.language == language) rows.add(_VoiceRow.voice(v));
      }
    }

    addGroup(t.voiceGroupEnglishKokoro, 'en');
    addGroup(t.voiceGroupFrenchPiper, 'fr');
    addGroup(t.voiceGroupUrduPiper, 'ur');
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(settingsProvider).translationVoiceId;
    final scheme = Theme.of(context).colorScheme;
    final t = AppStrings.of(context);
    final rows = _voiceRows(t);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.translationVoice,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.translationVoiceSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final row = rows[index];
                  if (row.header != null) {
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        6,
                        index == 0 ? 4 : 16,
                        6,
                        8,
                      ),
                      child: Text(
                        row.header!,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }
                  final voice = row.voice!;
                  final isSelected = voice.id == selected;
                  final isLoading = voice.id == _playingId && _loading;
                  final isHearing = voice.id == _playingId && !_loading;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Material(
                      color: isSelected
                          ? scheme.primaryContainer.withValues(alpha: 0.55)
                          : scheme.surfaceContainerHighest.withValues(
                              alpha: 0.35,
                            ),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: isLoading ? null : () => _select(voice.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      voice.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${t.voiceLanguage(voice.language)} · ${t.voiceStyle(voice.style)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isLoading)
                                const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                  ),
                                )
                              else if (isHearing)
                                Icon(
                                  Icons.volume_up_rounded,
                                  color: scheme.primary,
                                )
                              else if (_ready.contains(voice.id))
                                Icon(
                                  Icons.offline_pin_rounded,
                                  color: scheme.primary,
                                )
                              else
                                Icon(
                                  Icons.download_rounded,
                                  color: scheme.onSurfaceVariant,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VoiceRow {
  const _VoiceRow._({this.header, this.voice});

  factory _VoiceRow.header(String title) => _VoiceRow._(header: title);
  factory _VoiceRow.voice(PiperVoice voice) => _VoiceRow._(voice: voice);

  final String? header;
  final PiperVoice? voice;
}
