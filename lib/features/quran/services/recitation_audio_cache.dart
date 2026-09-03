import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

final recitationCacheBytesProvider = FutureProvider<int>((ref) {
  return RecitationAudioCache.instance.sizeBytes();
});

/// Caches streamed recitation MP3s so previously heard (or prefetched) ayahs
/// play offline.
class RecitationAudioCache {
  RecitationAudioCache._();

  static final RecitationAudioCache instance = RecitationAudioCache._();

  static const _minCompleteBytes = 2000;

  /// Slightly above typical 128 kbps so we prefetch a bit more than 3 minutes
  /// when a reciter is encoded at a lower rate.
  static const _bitsPerSecond = 160000;

  /// Drop oldest files once the cache grows past this size.
  static const maxCacheBytes = 400 * 1024 * 1024;

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 45),
      followRedirects: true,
    ),
  );

  final Map<String, Future<void>> _inflight = {};
  Directory? _dir;

  Future<AudioSource> sourceForUrl(String url) async {
    final inflight = _inflight[url];
    if (inflight != null) {
      try {
        await inflight;
      } catch (_) {}
    }
    final file = await _fileForUrl(url);
    await _writeMime(file);
    if (_fileLooksComplete(file)) {
      return AudioSource.file(file.path);
    }
    return LockCachingAudioSource(Uri.parse(url), cacheFile: file);
  }

  /// Downloads [url] into the recitation cache if it is not already complete.
  Future<void> prefetch(String url) {
    final existing = _inflight[url];
    if (existing != null) return existing;
    final future = _download(url);
    _inflight[url] = future;
    return future.whenComplete(() {
      if (identical(_inflight[url], future)) {
        _inflight.remove(url);
      }
    });
  }

  Future<Duration> estimatedDurationForUrl(String url) async {
    return estimatedDurationOf(await _fileForUrl(url));
  }

  Duration estimatedDurationOf(File file) {
    if (!_fileLooksComplete(file)) return Duration.zero;
    final ms = (file.lengthSync() * 8 * 1000) ~/ _bitsPerSecond;
    return Duration(milliseconds: ms.clamp(4000, 240000));
  }

  Future<int> sizeBytes() async {
    final dir = await _ensureDir();
    if (!dir.existsSync()) return 0;
    var total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        try {
          total += await entity.length();
        } catch (_) {}
      }
    }
    return total;
  }

  Future<void> clearAll() async {
    _inflight.clear();
    final dir = await _ensureDir();
    _dir = null;
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Future<void> enforceCap() async {
    final dir = await _ensureDir();
    if (!dir.existsSync()) return;
    final files = <File>[];
    await for (final entity in dir.list(recursive: false, followLinks: false)) {
      if (entity is File) files.add(entity);
    }
    var total = 0;
    final stats = <File, FileStat>{};
    for (final file in files) {
      try {
        final stat = file.statSync();
        stats[file] = stat;
        total += stat.size;
      } catch (_) {}
    }
    if (total <= maxCacheBytes) return;

    files.sort((a, b) {
      final am = stats[a]?.modified ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bm = stats[b]?.modified ?? DateTime.fromMillisecondsSinceEpoch(0);
      return am.compareTo(bm);
    });

    final recent = DateTime.now().subtract(const Duration(seconds: 45));
    for (final pass in [0, 1]) {
      if (total <= maxCacheBytes) return;
      for (final file in files) {
        if (total <= maxCacheBytes) return;
        if (!file.existsSync()) continue;
        if (file.path.endsWith('.part')) continue;
        final stat = stats[file];
        if (pass == 0 && stat != null && stat.modified.isAfter(recent)) {
          continue;
        }
        final len = stat?.size ?? file.lengthSync();
        try {
          await file.delete();
          total -= len;
        } catch (_) {}
      }
    }
  }

  Future<File> _fileForUrl(String url) async {
    final dir = await _ensureDir();
    return File('${dir.path}/${_stableKey(url)}.mp3');
  }

  bool _fileLooksComplete(File file) {
    return file.existsSync() && file.lengthSync() >= _minCompleteBytes;
  }

  Future<void> _writeMime(File file) async {
    final mime = File('${file.path}.mime');
    if (!mime.existsSync()) {
      await mime.writeAsString('audio/mpeg');
    }
  }

  Future<void> _download(String url) async {
    final file = await _fileForUrl(url);
    if (_fileLooksComplete(file)) return;
    final part = File('${file.path}.part');
    try {
      if (await part.exists()) await part.delete();
      await part.parent.create(recursive: true);
      await _dio.download(url, part.path);
      if (!await part.exists() || await part.length() < _minCompleteBytes) {
        if (await part.exists()) await part.delete();
        return;
      }
      await _writeMime(file);
      if (await file.exists()) await file.delete();
      await part.rename(file.path);
      await enforceCap();
    } catch (e) {
      if (await part.exists()) {
        try {
          await part.delete();
        } catch (_) {}
      }
      if (kDebugMode) debugPrint('Recitation prefetch: $e');
      rethrow;
    }
  }

  Future<Directory> _ensureDir() async {
    final existing = _dir;
    if (existing != null) return existing;
    final root = await getApplicationSupportDirectory();
    final dir = Directory('${root.path}/recitation_cache');
    await dir.create(recursive: true);
    _dir = dir;
    return dir;
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
}
