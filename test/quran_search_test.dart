import 'package:deen_connect/core/constants/api_constants.dart';
import 'package:deen_connect/features/quran/data/repositories/quran_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ayah search runs locally and finds Al-Fatiha', () async {
    final repo = QuranRepositoryImpl();
    final matches = await repo.searchAyahs(
      'Guide us',
      searchEditionId: QuranEditions.englishSahih,
    );
    expect(matches, isNotEmpty);
    expect(matches.first.surahNumber, 1);
  });
}
