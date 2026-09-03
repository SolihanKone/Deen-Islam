import 'dart:convert';
import 'dart:io';

/// Anonymous install counter. No accounts — one UUID per app install.
///
/// Run from the repo root:
///   INSTALL_LOG_KEY=dc_install_local dart backend/install_log/server.dart
///
/// Count installs:
///   curl -H "X-Api-Key: dc_install_local" http://127.0.0.1:8787/v1/stats
void main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '8787');
  final apiKey = Platform.environment['INSTALL_LOG_KEY'] ?? 'dc_install_local';
  final store = _InstallStore(_dataFile());
  await store.load();

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  _printListenAddresses(port, apiKey);

  await for (final request in server) {
    await _handle(request, store, apiKey);
  }
}

Future<void> _handle(
  HttpRequest request,
  _InstallStore store,
  String apiKey,
) async {
  final response = request.response;
  try {
    _cors(response);
    final path = request.uri.path;
    if (request.method == 'OPTIONS') {
      response.statusCode = HttpStatus.noContent;
      return;
    }

    if (request.method == 'GET' && path == '/health') {
      _json(response, {'ok': true});
      return;
    }

    if (!_authorized(request, apiKey)) {
      response.statusCode = HttpStatus.unauthorized;
      _json(response, {'error': 'unauthorized'});
      return;
    }

    if (request.method == 'POST' && path == '/v1/installs') {
      final body = await utf8.decoder.bind(request).join();
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        response.statusCode = HttpStatus.badRequest;
        _json(response, {'error': 'invalid_json'});
        return;
      }
      final id = '${decoded['installId']}'.trim();
      if (!_isUuid(id)) {
        response.statusCode = HttpStatus.badRequest;
        _json(response, {'error': 'invalid_install_id'});
        return;
      }
      final platform = '${decoded['platform'] ?? 'unknown'}'.trim();
      final created = await store.upsert(id, platform);
      _json(response, {'ok': true, 'created': created});
      return;
    }

    if (request.method == 'GET' && path == '/v1/stats') {
      _json(response, store.stats());
      return;
    }

    response.statusCode = HttpStatus.notFound;
    _json(response, {'error': 'not_found'});
  } catch (e) {
    response.statusCode = HttpStatus.internalServerError;
    _json(response, {'error': 'server_error'});
  } finally {
    await response.close();
  }
}

bool _authorized(HttpRequest request, String apiKey) {
  if (apiKey.isEmpty) return true;
  return request.headers.value('x-api-key') == apiKey;
}

bool _isUuid(String id) {
  return RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  ).hasMatch(id);
}

void _cors(HttpResponse response) {
  response.headers
    ..set('Access-Control-Allow-Origin', '*')
    ..set('Access-Control-Allow-Headers', 'Content-Type, X-Api-Key')
    ..set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
}

void _json(HttpResponse response, Map<String, Object?> body) {
  response.headers.contentType = ContentType.json;
  response.write(jsonEncode(body));
}

File _dataFile() {
  final script = Platform.script.toFilePath();
  final dir = File(script).parent;
  return File('${dir.path}/data/installs.json');
}

void _printListenAddresses(int port, String apiKey) {
  stdout.writeln('Install log listening:');
  stdout.writeln('  http://127.0.0.1:$port');
  NetworkInterface.list().then((interfaces) {
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          stdout.writeln(
            '  http://${addr.address}:$port   <- use this INSTALL_LOG_URL on a phone',
          );
        }
      }
    }
    stdout.writeln(
      'Stats: curl -H "X-Api-Key: $apiKey" http://127.0.0.1:$port/v1/stats',
    );
  });
}

class _InstallStore {
  _InstallStore(this.file);

  final File file;
  final Map<String, Map<String, String>> _rows = {};

  Future<void> load() async {
    if (!file.existsSync()) return;
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) return;
    decoded.forEach((key, value) {
      if (key is String && value is Map) {
        _rows[key] = {
          'firstSeen': '${value['firstSeen'] ?? ''}',
          'lastSeen': '${value['lastSeen'] ?? ''}',
          'platform': '${value['platform'] ?? 'unknown'}',
        };
      }
    });
  }

  Future<bool> upsert(String id, String platform) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final existing = _rows[id];
    final created = existing == null;
    _rows[id] = {
      'firstSeen': existing?['firstSeen']?.isNotEmpty == true
          ? existing!['firstSeen']!
          : now,
      'lastSeen': now,
      'platform': platform,
    };
    await file.parent.create(recursive: true);
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(_rows));
    return created;
  }

  Map<String, Object> stats() {
    final now = DateTime.now().toUtc();
    var last24h = 0;
    for (final row in _rows.values) {
      final last = DateTime.tryParse(row['lastSeen'] ?? '');
      if (last != null && now.difference(last) <= const Duration(hours: 24)) {
        last24h++;
      }
    }
    return {
      'uniqueInstalls': _rows.length,
      'last24h': last24h,
    };
  }
}
