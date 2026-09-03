import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/quran_ayah.dart';
import '../../domain/entities/surah_summary.dart';
import '../../domain/repositories/quran_repository.dart' show QuranSearchMatch;
import '../../data/repositories/quran_repository_impl.dart';

final surahListProvider = FutureProvider<List<SurahSummary>>((ref) async {
  final repo = ref.watch(quranRepositoryProvider);
  return repo.getSurahList();
});

typedef SurahAyahsArgs = ({int surahNumber, String translationId});

final surahAyahsProvider =
    FutureProvider.family<List<QuranAyah>, SurahAyahsArgs>((ref, args) async {
  final repo = ref.watch(quranRepositoryProvider);
  return repo.getSurahAyahs(
    args.surahNumber,
    translationEditionId: args.translationId,
  );
});

final quranSearchProvider = FutureProvider.family<
    List<QuranSearchMatch>,
    ({String query, String edition})>((ref, args) async {
  if (args.query.trim().isEmpty) return [];
  final repo = ref.watch(quranRepositoryProvider);
  return repo.searchAyahs(args.query, searchEditionId: args.edition);
});
