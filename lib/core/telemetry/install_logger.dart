import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../storage/hive_boxes.dart';

/// Optional anonymous install heartbeat. Disabled unless
/// `--dart-define=INSTALL_LOG_URL=...` is passed at build time.
///
/// Store builds must omit this define so the IPA does not phone home.
abstract final class InstallLogger {
  static const _uuidPattern =
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$';

  static const _urlDefine = String.fromEnvironment('INSTALL_LOG_URL');
  static const _keyDefine = String.fromEnvironment('INSTALL_LOG_KEY');

  static Future<void> heartbeat() async {
    final baseUrl = _urlDefine.trim();
    if (baseUrl.isEmpty) {
      if (kDebugMode) {
        debugPrint('Install log skipped — INSTALL_LOG_URL not defined');
      }
      return;
    }

    final id = await _ensureInstallId();
    final key = _keyDefine.trim();
    final origin = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      await dio.post<void>(
        '$origin/v1/installs',
        data: {
          'installId': id,
          'platform': defaultTargetPlatform.name,
        },
        options: Options(
          headers: {
            if (key.isNotEmpty) 'X-Api-Key': key,
            'Content-Type': 'application/json',
          },
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Install log skipped: $e');
    }
  }

  static Future<String> _ensureInstallId() async {
    final box = Hive.box<dynamic>(HiveBoxes.settings);
    final existing = box.get(HiveBoxes.installIdKey) as String?;
    if (existing != null && RegExp(_uuidPattern).hasMatch(existing)) {
      return existing;
    }
    final id = newInstallId();
    await box.put(HiveBoxes.installIdKey, id);
    return id;
  }

  static String newInstallId() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String h(int i) => bytes[i].toRadixString(16).padLeft(2, '0');
    return '${h(0)}${h(1)}${h(2)}${h(3)}-'
        '${h(4)}${h(5)}-'
        '${h(6)}${h(7)}-'
        '${h(8)}${h(9)}-'
        '${h(10)}${h(11)}${h(12)}${h(13)}${h(14)}${h(15)}';
  }
}
