import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

import '../domain/entities/piper_voice.dart';

class PiperTtsException implements Exception {
  PiperTtsException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// On-device TTS via sherpa-onnx (Kokoro for English, Piper for French/Urdu).
/// Models download once, then stay local.
class PiperTtsClient {
  PiperTtsClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(minutes: 8),
              ),
            );

  final Dio _dio;
  final Map<String, sherpa_onnx.OfflineTts> _engines = {};
  final Map<String, Future<void>> _downloads = {};
  final Map<String, Future<File>> _inflight = {};
  Future<void>? _queueTail;
  var _bindingsReady = false;

  static const previewPhraseEn = 'Peace be upon you.';
  static const previewPhraseFr = 'Que la paix soit sur vous.';
  static const previewPhraseUr = 'السلام علیکم';

  static String previewPhraseFor(String language) => switch (language) {
        'fr' => previewPhraseFr,
        'ur' => previewPhraseUr,
        _ => previewPhraseEn,
      };

  Future<void> _ensureBindings() async {
    if (_bindingsReady) return;
    sherpa_onnx.initBindings();
    _bindingsReady = true;
  }

  Future<Directory> _modelsRoot() async {
    final dir = await getApplicationSupportDirectory();
    return Directory(p.join(dir.path, 'piper_tts'));
  }

  Future<Directory> _modelDir(PiperVoice voice) async {
    final root = await _modelsRoot();
    return Directory(p.join(root.path, 'models', voice.modelKey));
  }

  Future<File> previewCacheFile(String voiceId) async {
    final root = await _modelsRoot();
    final id = PiperVoice.byId(voiceId).id;
    return File(p.join(root.path, 'preview', '$id.wav'));
  }

  Future<bool> hasPreview(String voiceId) async {
    final file = await previewCacheFile(voiceId);
    return file.existsSync() && file.lengthSync() > 44;
  }

  Future<bool> isModelReady(String voiceId) async {
    final voice = PiperVoice.byId(voiceId);
    final dir = await _modelDir(voice);
    final marker = File(p.join(dir.path, '.ready'));
    if (!await marker.exists()) return false;
    return _modelFilesComplete(voice, dir);
  }

  bool _modelFilesComplete(PiperVoice voice, Directory dir) {
    if (_findOnnx(dir) == null ||
        _findTokens(dir) == null ||
        _findEspeakData(dir) == null) {
      return false;
    }
    if (voice.engine == TtsEngine.kokoro && _findVoices(dir) == null) {
      return false;
    }
    return true;
  }

  Future<File> synthesizePreview(String voiceId) async {
    final voice = PiperVoice.byId(voiceId);
    final dest = await previewCacheFile(voice.id);
    if (await dest.exists() && await dest.length() > 44) return dest;
    final file = await synthesizeToFile(
      text: previewPhraseFor(voice.language),
      voiceId: voice.id,
    );
    await dest.parent.create(recursive: true);
    if (file.path != dest.path) {
      await file.copy(dest.path);
    }
    return dest;
  }

  Future<File> synthesizeToFile({
    required String text,
    required String voiceId,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw PiperTtsException('Empty translation text');
    }
    final voice = PiperVoice.byId(voiceId);
    final inflightKey = '${voice.id}|$trimmed';
    final existing = _inflight[inflightKey];
    if (existing != null) return existing;

    final future = _synthesizeFresh(trimmed: trimmed, voice: voice);
    _inflight[inflightKey] = future;
    try {
      return await future;
    } finally {
      _inflight.remove(inflightKey);
    }
  }

  Future<File> _synthesizeFresh({
    required String trimmed,
    required PiperVoice voice,
  }) async {
    final cache = await _wavCacheFile(voice.id, trimmed);
    if (await cache.exists() && await cache.length() > 44) return cache;

    await ensureModel(voice.id);
    await _ensureBindings();

    final previous = _queueTail;
    final gate = Completer<void>();
    _queueTail = gate.future;
    if (previous != null) {
      try {
        await previous;
      } catch (_) {}
    }
    try {
      final tts = await _engineFor(voice);
      final speed = voice.engine == TtsEngine.kokoro ? 1.0 : 0.95;
      final audio = tts.generate(
        text: trimmed,
        sid: voice.speakerId,
        speed: speed,
      );
      if (audio.samples.isEmpty) {
        throw PiperTtsException('TTS returned no audio');
      }
      await cache.parent.create(recursive: true);
      final ok = sherpa_onnx.writeWave(
        filename: cache.path,
        samples: audio.samples,
        sampleRate: audio.sampleRate,
      );
      if (!ok) {
        throw PiperTtsException('Could not write TTS audio');
      }
      if (kDebugMode) {
        debugPrint(
          'TTS ready engine=${voice.engine.name} voice=${voice.id} '
          'sid=${voice.speakerId} samples=${audio.samples.length}',
        );
      }
      return cache;
    } finally {
      if (!gate.isCompleted) gate.complete();
    }
  }

  Future<sherpa_onnx.OfflineTts> _engineFor(PiperVoice voice) async {
    final cached = _engines[voice.modelKey];
    if (cached != null) return cached;
    final dir = await _modelDir(voice);
    final onnx = _findOnnx(dir);
    final tokens = _findTokens(dir);
    final dataDir = _findEspeakData(dir);
    if (onnx == null || tokens == null || dataDir == null) {
      throw PiperTtsException('Model files missing for ${voice.name}');
    }

    late final sherpa_onnx.OfflineTtsConfig config;
    if (voice.engine == TtsEngine.kokoro) {
      final voices = _findVoices(dir);
      if (voices == null) {
        throw PiperTtsException('Kokoro voices.bin missing for ${voice.name}');
      }
      config = sherpa_onnx.OfflineTtsConfig(
        model: sherpa_onnx.OfflineTtsModelConfig(
          kokoro: sherpa_onnx.OfflineTtsKokoroModelConfig(
            model: onnx.path,
            voices: voices.path,
            tokens: tokens.path,
            dataDir: dataDir.path,
          ),
          numThreads: 2,
          debug: false,
          provider: 'cpu',
        ),
        maxNumSenetences: 1,
      );
    } else {
      config = sherpa_onnx.OfflineTtsConfig(
        model: sherpa_onnx.OfflineTtsModelConfig(
          vits: sherpa_onnx.OfflineTtsVitsModelConfig(
            model: onnx.path,
            tokens: tokens.path,
            dataDir: dataDir.path,
          ),
          numThreads: 2,
          debug: false,
          provider: 'cpu',
        ),
        maxNumSenetences: 1,
      );
    }
    final tts = sherpa_onnx.OfflineTts(config);
    _engines[voice.modelKey] = tts;
    return tts;
  }

  Future<void> ensureModel(String voiceId) async {
    final voice = PiperVoice.byId(voiceId);
    if (await isModelReady(voice.id)) return;
    final inflight = _downloads[voice.modelKey];
    if (inflight != null) {
      await inflight;
      return;
    }
    final future = _downloadAndExtract(voice);
    _downloads[voice.modelKey] = future;
    try {
      await future;
    } finally {
      _downloads.remove(voice.modelKey);
    }
  }

  Future<void> _downloadAndExtract(PiperVoice voice) async {
    final dir = await _modelDir(voice);
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);

    final tmp = File(p.join(dir.path, 'model.tar.bz2'));
    if (kDebugMode) {
      debugPrint('TTS download ${voice.archiveUrl}');
    }
    try {
      await _dio.download(voice.archiveUrl, tmp.path);
    } on DioException catch (e) {
      throw PiperTtsException(
        'Could not download the ${voice.name} voice. '
        'Connect to the internet once and try again. (${e.message ?? e})',
      );
    }
    if (!await tmp.exists() || await tmp.length() < 1000) {
      throw PiperTtsException('Downloaded TTS model is empty');
    }

    try {
      await _extractTarBz2(tmp, dir);
    } catch (e) {
      throw PiperTtsException('Could not unpack the ${voice.name} voice: $e');
    } finally {
      if (await tmp.exists()) {
        await tmp.delete();
      }
    }

    if (!_modelFilesComplete(voice, dir)) {
      throw PiperTtsException(
        'TTS model for ${voice.name} is incomplete after download',
      );
    }
    await File(p.join(dir.path, '.ready')).writeAsString('ok');
  }

  Future<void> _extractTarBz2(File archiveFile, Directory dest) async {
    final compressed = await archiveFile.readAsBytes();
    final tarBytes = BZip2Decoder().decodeBytes(compressed);
    final tar = TarDecoder().decodeBytes(tarBytes);
    for (final entry in tar) {
      var name = entry.name.replaceAll('\\', '/');
      while (name.startsWith('./')) {
        name = name.substring(2);
      }
      final parts = name.split('/').where((s) => s.isNotEmpty).toList();
      if (parts.isEmpty) continue;
      final skipRoot = parts.length > 1 &&
          (parts.first.startsWith('vits-piper') ||
              parts.first.startsWith('kokoro'));
      final relative =
          skipRoot ? p.joinAll(parts.sublist(1)) : p.joinAll(parts);
      if (relative.contains('..')) continue;
      final outPath = p.join(dest.path, relative);
      if (entry.isDirectory || name.endsWith('/')) {
        await Directory(outPath).create(recursive: true);
        continue;
      }
      final out = File(outPath);
      await out.parent.create(recursive: true);
      await out.writeAsBytes(entry.content);
    }
  }

  File? _findOnnx(Directory dir) {
    if (!dir.existsSync()) return null;
    final matches = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.onnx'))
        .toList();
    if (matches.isEmpty) return null;
    return matches.first;
  }

  File? _findTokens(Directory dir) {
    if (!dir.existsSync()) return null;
    for (final f in dir.listSync(recursive: true).whereType<File>()) {
      if (p.basename(f.path).toLowerCase() == 'tokens.txt') return f;
    }
    return null;
  }

  File? _findVoices(Directory dir) {
    if (!dir.existsSync()) return null;
    for (final f in dir.listSync(recursive: true).whereType<File>()) {
      if (p.basename(f.path).toLowerCase() == 'voices.bin') return f;
    }
    return null;
  }

  Directory? _findEspeakData(Directory dir) {
    if (!dir.existsSync()) return null;
    for (final d in dir.listSync(recursive: true).whereType<Directory>()) {
      if (p.basename(d.path) == 'espeak-ng-data') return d;
    }
    return null;
  }

  Future<File> _wavCacheFile(String voiceId, String text) async {
    final root = await _modelsRoot();
    final key = _stableKey('$voiceId|$text');
    return File(p.join(root.path, 'wav', voiceId, '$key.wav'));
  }

  static String _stableKey(String input) {
    const fnvOffset = 0xcbf29ce484222325;
    const fnvPrime = 0x100000001b3;
    var hash = fnvOffset;
    for (final b in utf8.encode(input)) {
      hash ^= b;
      hash = (hash * fnvPrime) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }

  Future<void> dispose() async {
    for (final tts in _engines.values) {
      try {
        tts.free();
      } catch (_) {}
    }
    _engines.clear();
  }
}
