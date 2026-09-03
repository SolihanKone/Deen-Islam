import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:qcf_quran/qcf_quran.dart';
import 'package:quran/quran.dart' as q;

import '../../../../core/theme/app_theme.dart';
import '../../domain/mushaf_navigation.dart';
import '../../domain/models/mushaf_page_model.dart';
import 'madinah_surah_header.dart';

/// Minimum line divisor for sparse pages (e.g. pages 1–2 with ~8 lines).
/// Prevents FittedBox from over-scaling QCF text and stretching word spacing.
const kMushafStandardLineDivisor = 9.5;

/// Line slot height for one mushaf row.
double mushafLineSlotHeight(
  double viewportHeight,
  int lineCount, {
  required bool listenMode,
}) {
  if (listenMode) {
    return viewportHeight / kMushafStandardLineDivisor;
  }
  final divisor = lineCount > kMushafStandardLineDivisor
      ? lineCount.toDouble()
      : kMushafStandardLineDivisor;
  return viewportHeight / divisor;
}


/// Renders one Madinah Mushaf page line-by-line from pre-defined layout data.
class MadinahMushafPageRenderer extends StatelessWidget {
  const MadinahMushafPageRenderer({
    super.key,
    required this.page,
    required this.height,
    this.fontScale = 1.0,
    this.theme,
    this.accentColor,
    this.playingItem,
    this.listenMode = false,
    this.onPlaybackItemTap,
    this.showTranslation = false,
    this.translation = q.Translation.enSaheeh,
  });

  final MushafPageModel page;
  final double height;
  final double fontScale;
  final QcfThemeData? theme;
  final Color? accentColor;
  final MushafPlaybackItem? playingItem;

  /// When true, lines use a fixed slot height so the page can scroll within
  /// the viewport while listening.
  final bool listenMode;

  /// Called when the user taps an ayah (or bismillah) while listening.
  final void Function(MushafPlaybackItem item)? onPlaybackItemTap;

  /// When true, show each ayah's translation directly under its Arabic.
  final bool showTranslation;
  final q.Translation translation;

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = theme ?? const QcfThemeData();
    final accent = accentColor ?? Theme.of(context).colorScheme.primary;
    final pageBg = effectiveTheme.pageBackgroundColor;
    final lineCount = page.lines.length.clamp(1, 20);
    final lineSlotHeight = mushafLineSlotHeight(
      height,
      lineCount,
      listenMode: listenMode || showTranslation,
    );
    final baseFontSize = getFontSize(page.pageNumber, context) * fontScale;

    final headerTheme = effectiveTheme.copyWith(
      headerTextColor: accent,
      basmalaColor: accent,
    );

    if (showTranslation) {
      return ColoredBox(
        color: pageBg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < page.lines.length; i++)
              ..._translationModeChildren(
                context: context,
                lineIndex: i,
                line: page.lines[i],
                page: page,
                baseFontSize: baseFontSize,
                lineSlotHeight: lineSlotHeight,
                theme: headerTheme,
                accentColor: accent,
                playingItem: playingItem,
                horizontalPadding: effectiveTheme.horizontalPadding,
                onPlaybackItemTap: onPlaybackItemTap,
                verseBackgroundColor: effectiveTheme.verseBackgroundColor,
                translation: translation,
                fontScale: fontScale,
              ),
          ],
        ),
      );
    }

    final naturalContentHeight = lineSlotHeight * lineCount;
    final contentHeight = listenMode ? naturalContentHeight : height;
    final centerSparsePage =
        !listenMode && naturalContentHeight < height - 1;

    return ColoredBox(
      color: pageBg,
      child: SizedBox(
        height: contentHeight,
        width: double.infinity,
        child: Column(
          mainAxisAlignment:
              centerSparsePage ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            for (final line in page.lines)
              SizedBox(
                height: lineSlotHeight,
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.center,
                    child: _MushafLineView(
                      line: line,
                      page: page,
                      baseFontSize: baseFontSize,
                      lineSlotHeight: lineSlotHeight,
                      theme: headerTheme,
                      accentColor: accent,
                      playingItem: playingItem,
                      horizontalPadding: effectiveTheme.horizontalPadding,
                      onPlaybackItemTap: onPlaybackItemTap,
                      verseBackgroundColor: effectiveTheme.verseBackgroundColor,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _translationModeChildren({
    required BuildContext context,
    required int lineIndex,
    required MushafLineModel line,
    required MushafPageModel page,
    required double baseFontSize,
    required double lineSlotHeight,
    required QcfThemeData theme,
    required Color accentColor,
    required MushafPlaybackItem? playingItem,
    required double horizontalPadding,
    required void Function(MushafPlaybackItem item)? onPlaybackItemTap,
    required Color? Function(int surah, int verse)? verseBackgroundColor,
    required q.Translation translation,
    required double fontScale,
  }) {
    final lineWidget = SizedBox(
      height: lineSlotHeight,
      child: ClipRect(
        child: Align(
          alignment: Alignment.center,
          child: _MushafLineView(
            line: line,
            page: page,
            baseFontSize: baseFontSize,
            lineSlotHeight: lineSlotHeight,
            theme: theme,
            accentColor: accentColor,
            playingItem: playingItem,
            horizontalPadding: horizontalPadding,
            onPlaybackItemTap: onPlaybackItemTap,
            verseBackgroundColor: verseBackgroundColor,
          ),
        ),
      ),
    );

    switch (line.type) {
      case MushafLineType.surahHeader:
      case MushafLineType.basmala:
        return [lineWidget];

      case MushafLineType.text:
        final isFatihaBismillah =
            line.verseRange == '1:1-1:1' && page.primarySurah == 1;
        if (isFatihaBismillah) {
          return [
            lineWidget,
            _AyahTranslationText(
              surah: 1,
              ayah: 1,
              translation: translation,
              fontScale: fontScale,
              playing: playingItem != null &&
                  !playingItem.isBismillah &&
                  playingItem.surah == 1 &&
                  playingItem.ayah == 1,
            ),
          ];
        }

        if (line.words.isEmpty) {
          return [lineWidget];
        }

        final segments = groupWordsByAyah(line.words);
        final out = <Widget>[];
        for (final segment in segments) {
          out.add(
            SizedBox(
              height: lineSlotHeight,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: _AyahSegmentLine(
                      segments: [segment],
                      fontFamily: page.qcfFontFamily,
                      fontSize: baseFontSize,
                      textColor: theme.verseTextColor,
                      playingItem: playingItem,
                      onPlaybackItemTap: onPlaybackItemTap,
                      verseBackgroundColor: verseBackgroundColor,
                    ),
                  ),
                ),
              ),
            ),
          );
          if (!ayahContinuesAfterLine(
            page,
            lineIndex,
            segment.surah,
            segment.ayah,
          )) {
            out.add(
              _AyahTranslationText(
                surah: segment.surah,
                ayah: segment.ayah,
                translation: translation,
                fontScale: fontScale,
                playing: playingItem != null &&
                    !playingItem.isBismillah &&
                    playingItem.surah == segment.surah &&
                    playingItem.ayah == segment.ayah,
              ),
            );
          }
        }
        return out;
    }
  }
}

class _AyahTranslationText extends StatelessWidget {
  const _AyahTranslationText({
    required this.surah,
    required this.ayah,
    required this.translation,
    required this.fontScale,
    this.playing = false,
  });

  final int surah;
  final int ayah;
  final q.Translation translation;
  final double fontScale;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = q
        .getVerseTranslation(surah, ayah, translation: translation)
        .trim();
    if (text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 12),
      child: Text(
        text,
        textAlign: TextAlign.start,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.4,
              fontSize: 14 * fontScale,
              fontWeight: playing ? FontWeight.w700 : FontWeight.w500,
              color: playing ? scheme.onSurface : scheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

/// Whether [surah]:[ayah] still has words on a later text line of [page].
bool ayahContinuesAfterLine(
  MushafPageModel page,
  int lineIndex,
  int surah,
  int ayah,
) {
  for (var i = lineIndex + 1; i < page.lines.length; i++) {
    final line = page.lines[i];
    if (line.type == MushafLineType.surahHeader ||
        line.type == MushafLineType.basmala) {
      return false;
    }
    if (line.type == MushafLineType.text && line.words.isNotEmpty) {
      return line.words.any((w) => w.surah == surah && w.ayah == ayah);
    }
  }
  return false;
}

/// Vertical space taken by the page-break divider above a Mushaf page.
const kMushafPageDividerExtent = 48.0;

/// Estimated height of one interleaved translation block (for scroll math).
const kMushafTranslationBlockEstimate = 64.0;

/// Y offset to the start of [lineIndex], including interleaved translations.
double mushafOffsetToLine(
  MushafPageModel page,
  int lineIndex,
  double lineSlotHeight, {
  required bool withTranslations,
}) {
  if (!withTranslations) return lineIndex * lineSlotHeight;

  var y = 0.0;
  for (var i = 0; i < lineIndex && i < page.lines.length; i++) {
    final line = page.lines[i];
    if (line.type == MushafLineType.text && line.words.isNotEmpty) {
      final segments = groupWordsByAyah(line.words);
      for (final segment in segments) {
        y += lineSlotHeight;
        if (!ayahContinuesAfterLine(page, i, segment.surah, segment.ayah)) {
          y += kMushafTranslationBlockEstimate;
        }
      }
    } else {
      y += lineSlotHeight;
      final isFatiha = line.verseRange == '1:1-1:1' && page.primarySurah == 1;
      if (isFatiha) y += kMushafTranslationBlockEstimate;
    }
  }
  return y;
}

/// Last layout line that belongs to [item], or null.
int? lastLineIndexForPlayingItem(
  MushafPageModel page,
  MushafPlaybackItem? item,
) {
  if (item == null) return null;
  int? last;
  for (var i = 0; i < page.lines.length; i++) {
    final line = page.lines[i];
    if (item.isBismillah && line.type == MushafLineType.basmala) {
      if (item.surah == (line.surahNumber ?? page.primarySurah)) last = i;
    } else if (!item.isBismillah &&
        item.ayah != null &&
        line.type == MushafLineType.text) {
      if (mushafLineContainsAyah(line.verseRange, item.surah, item.ayah!)) {
        last = i;
      }
    }
  }
  return last;
}

/// Pixel height from the first line of [item] through its last line (and
/// translation, when shown).
double mushafPlayingBlockHeight(
  MushafPageModel page,
  MushafPlaybackItem item,
  double lineSlotHeight, {
  required bool withTranslations,
}) {
  final first = lineIndexForPlayingItem(page, item);
  final last = lastLineIndexForPlayingItem(page, item);
  if (first == null || last == null) return lineSlotHeight;
  final top = mushafOffsetToLine(
    page,
    first,
    lineSlotHeight,
    withTranslations: withTranslations,
  );
  var bottom = mushafOffsetToLine(
        page,
        last,
        lineSlotHeight,
        withTranslations: withTranslations,
      ) +
      lineSlotHeight;
  if (withTranslations &&
      !item.isBismillah &&
      item.ayah != null &&
      !ayahContinuesAfterLine(page, last, item.surah, item.ayah!)) {
    bottom += kMushafTranslationBlockEstimate;
  }
  return (bottom - top).clamp(lineSlotHeight, double.infinity);
}

class _MushafLineView extends StatelessWidget {
  const _MushafLineView({
    required this.line,
    required this.page,
    required this.baseFontSize,
    required this.lineSlotHeight,
    required this.theme,
    required this.accentColor,
    required this.horizontalPadding,
    this.playingItem,
    this.onPlaybackItemTap,
    this.verseBackgroundColor,
  });

  final MushafLineModel line;
  final MushafPageModel page;
  final double baseFontSize;
  final double lineSlotHeight;
  final QcfThemeData theme;
  final Color accentColor;
  final double horizontalPadding;
  final MushafPlaybackItem? playingItem;
  final void Function(MushafPlaybackItem item)? onPlaybackItemTap;
  final Color? Function(int surah, int verse)? verseBackgroundColor;

  bool _ayahIsPlaying(int surah, int ayah) {
    final item = playingItem;
    if (item == null || item.isBismillah || item.ayah == null) return false;
    return item.surah == surah && item.ayah == ayah;
  }

  bool get _bismillahIsPlaying {
    final item = playingItem;
    if (item == null || !item.isBismillah) return false;
    return item.surah == (line.surahNumber ?? page.primarySurah);
  }

  @override
  Widget build(BuildContext context) {
    switch (line.type) {
      case MushafLineType.surahHeader:
        final surah = line.surahNumber ?? page.primarySurah;
        return SizedBox(
          height: lineSlotHeight,
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: MadinahSurahHeader(
              surahNumber: surah,
              accentColor: accentColor,
              width: MediaQuery.sizeOf(context).width,
              compact: true,
            ),
          ),
        );

      case MushafLineType.basmala:
        if (!theme.showBasmala) return const SizedBox.shrink();
        final basmalaText = q.basmala;
        final surah = line.surahNumber ?? page.primarySurah;
        final bg = _bismillahIsPlaying
            ? verseBackgroundColor?.call(surah, 1)
            : null;
        final basmalaWidget = FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            basmalaText,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            maxLines: 1,
            style: AppTheme.arabicText(context, fontSize: baseFontSize * 0.92)
                .copyWith(
              color: accentColor,
              fontWeight: FontWeight.bold,
              height: 1.0,
              backgroundColor: bg,
            ),
          ),
        );
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: SizedBox(
            height: lineSlotHeight,
            width: double.infinity,
            child: onPlaybackItemTap != null
                ? GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onPlaybackItemTap!(
                      (isBismillah: true, surah: surah, ayah: null),
                    ),
                    child: basmalaWidget,
                  )
                : basmalaWidget,
          ),
        );

      case MushafLineType.text:
        final isFatihaBismillah =
            line.verseRange == '1:1-1:1' && page.primarySurah == 1;
        if (isFatihaBismillah) {
          final bg = _ayahIsPlaying(1, 1)
              ? verseBackgroundColor?.call(1, 1)
              : null;
          final text = q.getVerse(1, 1, verseEndSymbol: true);
          final fatihaWidget = FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              maxLines: 1,
              style: AppTheme.arabicText(context, fontSize: baseFontSize * 0.92)
                  .copyWith(
                color: accentColor,
                fontWeight: FontWeight.bold,
                height: 1.0,
                backgroundColor: bg,
              ),
            ),
          );
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: SizedBox(
              height: lineSlotHeight,
              width: double.infinity,
              child: onPlaybackItemTap != null
                  ? GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onPlaybackItemTap!(
                        (isBismillah: false, surah: 1, ayah: 1),
                      ),
                      child: fatihaWidget,
                    )
                  : fatihaWidget,
            ),
          );
        }

        if (line.words.isNotEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: SizedBox(
              height: lineSlotHeight,
              width: double.infinity,
              child: _AyahSegmentLine(
                segments: groupWordsByAyah(line.words),
                fontFamily: page.qcfFontFamily,
                fontSize: baseFontSize,
                textColor: theme.verseTextColor,
                playingItem: playingItem,
                onPlaybackItemTap: onPlaybackItemTap,
                verseBackgroundColor: verseBackgroundColor,
              ),
            ),
          );
        }

        final style = TextStyle(
          fontFamily: page.qcfFontFamily,
          package: 'qcf_quran',
          fontSize: baseFontSize,
          height: 1.0,
          color: theme.verseTextColor,
          letterSpacing: 0,
          wordSpacing: 0,
        );
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: SizedBox(
            height: lineSlotHeight,
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                line.renderText,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                style: style,
              ),
            ),
          ),
        );
    }
  }
}

class _AyahSegmentLine extends StatefulWidget {
  const _AyahSegmentLine({
    required this.segments,
    required this.fontFamily,
    required this.fontSize,
    required this.textColor,
    this.playingItem,
    this.onPlaybackItemTap,
    this.verseBackgroundColor,
  });

  final List<MushafAyahSegment> segments;
  final String fontFamily;
  final double fontSize;
  final Color textColor;
  final MushafPlaybackItem? playingItem;
  final void Function(MushafPlaybackItem item)? onPlaybackItemTap;
  final Color? Function(int surah, int verse)? verseBackgroundColor;

  @override
  State<_AyahSegmentLine> createState() => _AyahSegmentLineState();
}

class _AyahSegmentLineState extends State<_AyahSegmentLine> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void initState() {
    super.initState();
    _syncRecognizers();
  }

  @override
  void didUpdateWidget(covariant _AyahSegmentLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.segments.length != widget.segments.length ||
        oldWidget.onPlaybackItemTap != widget.onPlaybackItemTap) {
      _disposeRecognizers();
      _syncRecognizers();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  void _syncRecognizers() {
    if (widget.onPlaybackItemTap == null) return;
    for (final segment in widget.segments) {
      _recognizers.add(
        TapGestureRecognizer()
          ..onTap = () => widget.onPlaybackItemTap!(
                (isBismillah: false, surah: segment.surah, ayah: segment.ayah),
              ),
      );
    }
  }

  bool _isPlaying(MushafAyahSegment segment) {
    final item = widget.playingItem;
    if (item == null || item.isBismillah || item.ayah == null) return false;
    return item.surah == segment.surah && item.ayah == segment.ayah;
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontFamily: widget.fontFamily,
      package: 'qcf_quran',
      fontSize: widget.fontSize,
      height: 1.0,
      color: widget.textColor,
      letterSpacing: 0,
      wordSpacing: 0,
    );

    final spans = <InlineSpan>[];
    for (var i = 0; i < widget.segments.length; i++) {
      final segment = widget.segments[i];
      spans.add(
        TextSpan(
          text: segment.qpcText,
          recognizer:
              widget.onPlaybackItemTap != null ? _recognizers[i] : null,
          style: baseStyle.copyWith(
            backgroundColor: _isPlaying(segment)
                ? widget.verseBackgroundColor?.call(segment.surah, segment.ayah)
                : null,
          ),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text.rich(
        TextSpan(children: spans),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        maxLines: 1,
      ),
    );
  }
}

/// Returns the rendered content height for a mushaf page.
double mushafPageContentHeight(
  MushafPageModel page,
  double viewportHeight, {
  required bool listenMode,
}) {
  if (!listenMode) return viewportHeight;
  final lineCount = page.lines.length.clamp(1, 20);
  return mushafLineSlotHeight(viewportHeight, lineCount, listenMode: true) *
      lineCount;
}

/// Line slot height used when [listenMode] is enabled.
double mushafListenLineSlotHeight(double viewportHeight) =>
    viewportHeight / kMushafStandardLineDivisor;

/// Whether a page begins with a surah opening header.
bool pageStartsWithSurahHeader(MushafPageModel page) =>
    page.lines.isNotEmpty &&
    page.lines.first.type == MushafLineType.surahHeader;

/// Returns whether a verse falls within a layout line's verse range.
bool mushafLineContainsAyah(String? range, int surah, int ayah) {
  if (range == null || range.isEmpty) return false;
  final bounds = range.split('-');
  final startParts = bounds.first.split(':');
  if (startParts.length != 2) return false;
  final startSurah = int.tryParse(startParts[0]);
  final startAyah = int.tryParse(startParts[1]);
  if (startSurah == null || startAyah == null) return false;

  var endSurah = startSurah;
  var endAyah = startAyah;
  if (bounds.length > 1) {
    final endParts = bounds.last.split(':');
    if (endParts.length == 2) {
      endSurah = int.tryParse(endParts[0]) ?? startSurah;
      endAyah = int.tryParse(endParts[1]) ?? startAyah;
    }
  }

  if (surah < startSurah || surah > endSurah) return false;
  if (surah == startSurah && ayah < startAyah) return false;
  if (surah == endSurah && ayah > endAyah) return false;
  return true;
}

/// Returns the 0-based line index of the currently playing ayah on a page, or null.
int? lineIndexForPlayingItem(MushafPageModel page, MushafPlaybackItem? item) {
  if (item == null) return null;
  for (var i = 0; i < page.lines.length; i++) {
    final line = page.lines[i];
    if (item.isBismillah && line.type == MushafLineType.basmala) {
      if (item.surah == (line.surahNumber ?? page.primarySurah)) return i;
    } else if (!item.isBismillah &&
        item.ayah != null &&
        line.type == MushafLineType.text) {
      if (mushafLineContainsAyah(line.verseRange, item.surah, item.ayah!)) {
        return i;
      }
    }
  }
  return null;
}
