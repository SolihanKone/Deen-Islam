import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/async_body.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/entities/surah_summary.dart';
import '../providers/quran_providers.dart';

String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

class QuranSearchScreen extends ConsumerStatefulWidget {
  const QuranSearchScreen({super.key});

  @override
  ConsumerState<QuranSearchScreen> createState() => _QuranSearchScreenState();
}

class _QuranSearchScreenState extends ConsumerState<QuranSearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final edition = ref.watch(settingsProvider).defaultTranslationId;
    final async = ref.watch(
      quranSearchProvider((query: _query, edition: edition)),
    );
    final surahsAsync = ref.watch(surahListProvider);
    final q = _norm(_query);
    final surahHits = surahsAsync.maybeWhen(
      data: (list) {
        if (q.length < 2) return <SurahSummary>[];
        return list
            .where(
              (s) =>
                  _norm(s.nameEnglish).contains(q) ||
                  _norm(s.englishNameTranslation).contains(q) ||
                  s.number.toString() == q,
            )
            .toList();
      },
      orElse: () => <SurahSummary>[],
    );

    final t = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.searchQuran),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              controller: _controller,
              hintText: t.searchHint,
              leading: const Icon(Icons.search_rounded),
              trailing: [
                if (_query.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                  ),
              ],
              onChanged: (v) => setState(() => _query = v),
              onSubmitted: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: _query.trim().length < 2
                ? Center(
                    child: Text(
                      t.typeAtLeast2,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : AsyncBody(
                    async: async,
                    onRetry: () => ref.invalidate(
                      quranSearchProvider((query: _query, edition: edition)),
                    ),
                    data: (context, matches) {
                      if (matches.isEmpty && surahHits.isEmpty) {
                        return Center(child: Text(t.noResults));
                      }
                      return ListView(
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          if (surahHits.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: Text(
                                t.surahs,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            ...surahHits.map(
                              (s) => ListTile(
                                leading: CircleAvatar(child: Text('${s.number}')),
                                title: Text(t.surahName(s.number)),
                                subtitle: Text(s.englishNameTranslation),
                                onTap: () =>
                                    context.push('/learn-quran/surah/${s.number}'),
                              ),
                            ),
                            if (matches.isNotEmpty) const Divider(height: 32),
                          ],
                          if (matches.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: Text(
                                t.ayahs,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            ...matches.map(
                              (m) => ListTile(
                                title: Text(
                                  '${m.surahName} · ${m.ayahNumberInSurah}',
                                  style:
                                      const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: _HighlightText(
                                  text: m.snippet,
                                  query: _query,
                                ),
                                onTap: () => context
                                    .push('/learn-quran/surah/${m.surahNumber}'),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _HighlightText extends StatelessWidget {
  const _HighlightText({required this.text, required this.query});

  final String text;
  final String query;

  @override
  Widget build(BuildContext context) {
    final q = query.trim();
    if (q.isEmpty) return Text(text, maxLines: 4, overflow: TextOverflow.ellipsis);

    final lower = text.toLowerCase();
    final needle = q.toLowerCase();
    final spans = <InlineSpan>[];
    var start = 0;
    var idx = lower.indexOf(needle, start);
    final style = Theme.of(context).textTheme.bodyMedium;
    final hl = style?.copyWith(
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      fontWeight: FontWeight.w600,
    );

    while (idx >= 0) {
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx), style: style));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + needle.length),
        style: hl,
      ));
      start = idx + needle.length;
      idx = lower.indexOf(needle, start);
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: style));
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: 5,
      overflow: TextOverflow.ellipsis,
    );
  }
}
