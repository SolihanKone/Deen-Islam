import 'package:flutter/material.dart';
import 'package:qcf_quran/qcf_quran.dart' as qcf;

import '../../../../core/l10n/app_strings.dart';
import '../../domain/mushaf_navigation.dart';
import '../../domain/models/mushaf_page_model.dart';

Future<int?> showMushafGoToSheet(
  BuildContext context, {
  required int currentPage,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _MushafGoToSheet(currentPage: currentPage),
  );
}

class _MushafGoToSheet extends StatefulWidget {
  const _MushafGoToSheet({required this.currentPage});

  final int currentPage;

  @override
  State<_MushafGoToSheet> createState() => _MushafGoToSheetState();
}

class _MushafGoToSheetState extends State<_MushafGoToSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final TextEditingController _pageField;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _pageField = TextEditingController(text: '${widget.currentPage}');
  }

  @override
  void dispose() {
    _tabs.dispose();
    _pageField.dispose();
    super.dispose();
  }

  void _go(int page) {
    Navigator.of(context).pop(
      page.clamp(MushafNavigation.startPage, MushafPageModel.totalPages),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.72;

    return SizedBox(
      height: height,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Text(AppStrings.of(context).goTo, style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabs,
            tabs: [
              Tab(text: AppStrings.of(context).pageWord),
              Tab(text: AppStrings.of(context).surahWord),
              Tab(text: AppStrings.of(context).juzWord),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _PageTab(
                  controller: _pageField,
                  onGo: () {
                    final n = int.tryParse(_pageField.text.trim());
                    if (n != null) _go(n);
                  },
                ),
                _SurahTab(onSelect: (s) => _go(MushafNavigation.pageForSurah(s))),
                _JuzTab(onSelect: (j) => _go(MushafNavigation.pageForJuz(j))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageTab extends StatelessWidget {
  const _PageTab({required this.controller, required this.onGo});

  final TextEditingController controller;
  final VoidCallback onGo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.of(context).enterPage(MushafPageModel.totalPages)),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: AppStrings.of(context).pageNumber,
              prefixIcon: const Icon(Icons.menu_book_outlined),
            ),
            onSubmitted: (_) => onGo(),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onGo, child: Text(AppStrings.of(context).go)),
        ],
      ),
    );
  }
}

class _SurahTab extends StatelessWidget {
  const _SurahTab({required this.onSelect});

  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: qcf.totalSurahCount,
      itemBuilder: (context, i) {
        final n = i + 1;
        final page = MushafNavigation.pageForSurah(n);
        return ListTile(
          leading: CircleAvatar(
            radius: 18,
            child: Text('$n', style: const TextStyle(fontSize: 12)),
          ),
          title: Text(AppStrings.of(context).surahName(n)),
          subtitle: Text(
            AppStrings.of(context).surahPageSubtitle(
              qcf.getSurahNameArabic(n),
              page,
            ),
          ),
          onTap: () => onSelect(n),
        );
      },
    );
  }
}

class _JuzTab extends StatelessWidget {
  const _JuzTab({required this.onSelect});

  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: qcf.totalJuzCount,
      itemBuilder: (context, i) {
        final n = i + 1;
        final page = MushafNavigation.pageForJuz(n);
        return ListTile(
          leading: CircleAvatar(
            radius: 18,
            child: Text('$n', style: const TextStyle(fontSize: 12)),
          ),
          title: Text(AppStrings.of(context).juzLabel(n)),
          subtitle: Text(AppStrings.of(context).startsOnPage(page)),
          onTap: () => onSelect(n),
        );
      },
    );
  }
}
