import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/storage/hive_boxes.dart';
import 'core/telemetry/install_logger.dart';
import 'features/prayer/services/prayer_notification_service.dart';
import 'features/quran/services/deen_audio_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    debugPrint(
      'Translation TTS — Kokoro English, Piper French/Urdu; download once',
    );
  }
  try {
    await initializeDateFormatting('ar');
    await initializeDateFormatting('ur');
    await initializeDateFormatting('fr');
  } catch (_) {}
  await initHive();
  await PrayerNotificationService.init();
  await initDeenAudioService();
  unawaited(InstallLogger.heartbeat());

  runApp(
    const ProviderScope(
      child: DeenConnectApp(),
    ),
  );
}
