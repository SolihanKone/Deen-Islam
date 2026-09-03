import 'package:flutter/material.dart';
import 'package:qcf_quran/qcf_quran.dart';

/// Full-width Madinah Mushaf surah opening cartouche.
class MadinahSurahHeader extends StatelessWidget {
  const MadinahSurahHeader({
    super.key,
    required this.surahNumber,
    this.accentColor,
    this.width,
    this.compact = false,
  });

  final int surahNumber;
  final Color? accentColor;
  final double? width;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = accentColor ?? scheme.primary;
    final headerWidth = width ?? MediaQuery.sizeOf(context).width;
    final horizontalInset = compact ? 10.0 : 14.0;
    final frameWidth = headerWidth - (horizontalInset * 2);
    final frameHeight = compact ? frameWidth * 0.16 : frameWidth * 0.18;
    final nameSize = compact ? frameWidth * 0.075 : frameWidth * 0.08;

    return SizedBox(
      width: headerWidth,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalInset),
        child: _SurahCartouche(
          surahNumber: surahNumber,
          accentColor: accent,
          frameWidth: frameWidth,
          frameHeight: frameHeight,
          nameFontSize: nameSize,
        ),
      ),
    );
  }
}

class _SurahCartouche extends StatelessWidget {
  const _SurahCartouche({
    required this.surahNumber,
    required this.accentColor,
    required this.frameWidth,
    required this.frameHeight,
    required this.nameFontSize,
  });

  final int surahNumber;
  final Color accentColor;
  final double frameWidth;
  final double frameHeight;
  final double nameFontSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: frameWidth,
      height: frameHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/mainframe.png',
            package: 'qcf_quran',
            width: frameWidth,
            height: frameHeight,
            fit: BoxFit.fill,
            color: accentColor.withValues(alpha: 0.18),
            colorBlendMode: BlendMode.srcATop,
          ),
          Padding(
            padding: EdgeInsets.only(top: frameHeight * 0.06),
            child: Text(
              'surah${surahNumber.toString().padLeft(3, '0')}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: SurahFontHelper.fontFamily,
                package: 'qcf_quran',
                fontSize: nameFontSize,
                color: accentColor,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
