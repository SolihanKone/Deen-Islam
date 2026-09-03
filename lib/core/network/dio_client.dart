import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/app_exception.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 25),
      receiveTimeout: const Duration(seconds: 25),
      validateStatus: (s) => s != null && s < 500,
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (e, handler) {
        if (kDebugMode) {
          debugPrint('Dio error: ${e.message}');
        }
        handler.next(e);
      },
    ),
  );
  return dio;
});

extension DioResponseX on Response<dynamic> {
  void ensureSuccess() {
    final code = data is Map ? data['code'] as int? : null;
    if (statusCode != 200 || (code != null && code != 200)) {
      final status = data is Map ? data['status']?.toString() : null;
      throw NetworkException(status ?? 'Request failed', code: '$statusCode');
    }
  }
}
