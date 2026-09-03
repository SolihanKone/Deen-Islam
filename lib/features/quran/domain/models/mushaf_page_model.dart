import 'package:qcf_quran/qcf_quran.dart';

/// Type of a pre-defined line on a Madinah Mushaf page.
enum MushafLineType {
  surahHeader,
  basmala,
  text,
}

/// One word token from the mushaf layout (QPC glyphs + verse location).
class MushafWordModel {
  const MushafWordModel({
    required this.location,
    required this.qpcV2,
    required this.surah,
    required this.ayah,
  });

  final String location;
  final String qpcV2;
  final int surah;
  final int ayah;

  String get renderGlyph => qpcV2.replaceAll(RegExp(r'[\s\n]'), '');

  factory MushafWordModel.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as String;
    final parts = location.split(':');
    return MushafWordModel(
      location: location,
      qpcV2: json['qpcV2'] as String,
      surah: int.parse(parts[0]),
      ayah: int.parse(parts[1]),
    );
  }
}

/// Contiguous QPC glyphs for one ayah within a layout line.
class MushafAyahSegment {
  const MushafAyahSegment({
    required this.surah,
    required this.ayah,
    required this.qpcText,
  });

  final int surah;
  final int ayah;
  final String qpcText;
}

/// Groups layout words into per-ayah glyph runs for highlighting and taps.
List<MushafAyahSegment> groupWordsByAyah(List<MushafWordModel> words) {
  if (words.isEmpty) return [];

  final segments = <MushafAyahSegment>[];
  final buffer = StringBuffer();
  int? currentSurah;
  int? currentAyah;

  void flush() {
    if (currentSurah == null || currentAyah == null || buffer.isEmpty) return;
    segments.add(
      MushafAyahSegment(
        surah: currentSurah,
        ayah: currentAyah,
        qpcText: buffer.toString(),
      ),
    );
    buffer.clear();
  }

  for (final word in words) {
    if (word.surah != currentSurah || word.ayah != currentAyah) {
      flush();
      currentSurah = word.surah;
      currentAyah = word.ayah;
    }
    buffer.write(word.renderGlyph);
  }
  flush();
  return segments;
}

/// One fixed line from the printed Mushaf layout (no dynamic wrapping).
class MushafLineModel {
  const MushafLineModel({
    required this.lineNumber,
    required this.type,
    required this.renderText,
    this.verseRange,
    this.surahNumber,
    this.words = const [],
  });

  final int lineNumber;
  final MushafLineType type;

  /// QPC v2 glyph string for QCF font, or Uthmani text for headers.
  final String renderText;
  final String? verseRange;
  final int? surahNumber;
  final List<MushafWordModel> words;

  factory MushafLineModel.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    final type = switch (typeStr) {
      'surah-header' => MushafLineType.surahHeader,
      'basmala' => MushafLineType.basmala,
      _ => MushafLineType.text,
    };

    var renderText = '';
    var words = const <MushafWordModel>[];
    if (type == MushafLineType.basmala) {
      renderText = json['qpcV2'] as String? ?? '';
    } else if (type == MushafLineType.text) {
      final rawWords = json['words'] as List<dynamic>?;
      if (rawWords != null && rawWords.isNotEmpty) {
        words = rawWords
            .map((w) => MushafWordModel.fromJson(w as Map<String, dynamic>))
            .toList();
        renderText = words.map((w) => w.renderGlyph).join();
      } else {
        renderText = json['text'] as String? ?? '';
      }
    } else {
      renderText = json['text'] as String? ?? '';
    }

    int? surahNumber;
    if (json['surah'] != null) {
      surahNumber = int.tryParse(json['surah'].toString());
    }

    return MushafLineModel(
      lineNumber: json['line'] as int,
      type: type,
      renderText: renderText,
      verseRange: json['verseRange'] as String?,
      surahNumber: surahNumber,
      words: words,
    );
  }
}

/// One of exactly 604 Madinah Mushaf pages with ordered pre-defined lines.
class MushafPageModel {
  const MushafPageModel({
    required this.pageNumber,
    required this.lines,
    required this.primarySurah,
    required this.juz,
  });

  final int pageNumber;
  final List<MushafLineModel> lines;
  final int primarySurah;
  final int juz;

  static const int totalPages = 604;

  String get qcfFontFamily => 'QCF_P${pageNumber.toString().padLeft(3, '0')}';

  factory MushafPageModel.fromJson(Map<String, dynamic> json) {
    final pageNumber = json['page'] as int;
    final lines = (json['lines'] as List<dynamic>)
        .map((e) => MushafLineModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final segments = getPageData(pageNumber);
    final first = segments.first as Map;
    final primarySurah = int.parse(first['surah'].toString());
    final firstAyah = int.parse(first['start'].toString());
    final juz = getJuzNumber(primarySurah, firstAyah);

    return MushafPageModel(
      pageNumber: pageNumber,
      lines: lines,
      primarySurah: primarySurah,
      juz: juz,
    );
  }
}
