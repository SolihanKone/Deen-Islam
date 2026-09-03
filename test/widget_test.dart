import 'package:flutter_test/flutter_test.dart';

import 'package:deen_connect/core/utils/qibla_utils.dart';

void main() {
  test('qibla bearing from New York is roughly northeast', () {
    const lat = 40.7128;
    const lon = -74.0060;
    final b = qiblaBearing(lat, lon);
    expect(b, greaterThan(50));
    expect(b, lessThan(70));
  });
}
