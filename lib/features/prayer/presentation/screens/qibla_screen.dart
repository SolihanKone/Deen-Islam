import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/qibla_utils.dart';
import '../../../../core/widgets/app_ui.dart';
import '../providers/prayer_providers.dart';

class QiblaScreen extends ConsumerWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final t = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.qibla)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.sm,
          AppSpacing.screenH,
          AppSpacing.screenBottom,
        ),
        children: [
          AppSectionHeader(title: t.faceTheKaaba, subtitle: t.holdPhoneFlat),
          const QiblaCompassCard(),
          const SizedBox(height: AppSpacing.md),
          AppSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.howToUse,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                _TipRow(
                  icon: Icons.stay_current_portrait_rounded,
                  text: t.qiblaTipLevel,
                  color: scheme.primary,
                ),
                _TipRow(
                  icon: Icons.rotate_90_degrees_ccw_rounded,
                  text: t.qiblaTipRotate,
                  color: scheme.primary,
                ),
                _TipRow(
                  icon: Icons.location_on_outlined,
                  text: t.qiblaTipLocation,
                  color: scheme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSurfaceCard(
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: scheme.secondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t.compassAccuracy,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class QiblaCompassCard extends ConsumerWidget {
  const QiblaCompassCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posAsync = ref.watch(userPositionProvider);
    final scheme = Theme.of(context).colorScheme;

    return posAsync.when(
      data: (pos) {
        final qibla = qiblaBearing(pos.latitude, pos.longitude);
        return AppSurfaceCard(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          child: StreamBuilder<CompassEvent?>(
            stream: FlutterCompass.events,
            builder: (context, snapshot) {
              final heading = snapshot.data?.heading;
              if (heading == null) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(AppStrings.of(context).compassUnavailable),
                  ),
                );
              }
              final diff = headingDelta(heading, qibla);
              final aligned = diff.abs() < 8;
              final turn = diff * math.pi / 180;

              return Column(
                children: [
                  Text(
                    aligned
                        ? AppStrings.of(context).facingQibla
                        : AppStrings.of(context).turnTowardArrow,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: aligned ? scheme.primary : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 220,
                    width: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(220, 220),
                          painter: _CompassPainter(
                            ringColor: scheme.primary.withValues(alpha: 0.25),
                            tickColor: scheme.outlineVariant,
                            aligned: aligned,
                            accent: scheme.primary,
                          ),
                        ),
                        Transform.rotate(
                          angle: turn,
                          child: Icon(
                            Icons.navigation_rounded,
                            size: 78,
                            color: aligned
                                ? AppTheme.accentGold
                                : scheme.primary,
                          ),
                        ),
                        Positioned(
                          top: 18,
                          child: Text(
                            AppStrings.of(context).compassNorth,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    AppStrings.of(
                      context,
                    ).degreesFromNorth(qibla.toStringAsFixed(1)),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    aligned
                        ? AppStrings.of(context).stayStillPray
                        : AppStrings.of(
                            context,
                          ).degreesToGo(diff.abs().toStringAsFixed(0)),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
      loading: () => const AppSurfaceCard(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => AppSurfaceCard(
        child: Text(
          '${AppStrings.of(context).qiblaNeedsLocation}\n${AppStrings.of(context).friendlyError(e)}',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  _CompassPainter({
    required this.ringColor,
    required this.tickColor,
    required this.aligned,
    required this.accent,
  });

  final Color ringColor;
  final Color tickColor;
  final bool aligned;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 10;
    final ring = Paint()
      ..color = aligned ? accent.withValues(alpha: 0.45) : ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = aligned ? 5 : 3;
    canvas.drawCircle(c, r, ring);

    final tick = Paint()
      ..color = tickColor
      ..strokeWidth = 2;
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final outer = Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r);
      final inner = Offset(
        c.dx + math.cos(a) * (r - 12),
        c.dy + math.sin(a) * (r - 12),
      );
      canvas.drawLine(inner, outer, tick);
    }
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) =>
      oldDelegate.aligned != aligned;
}
