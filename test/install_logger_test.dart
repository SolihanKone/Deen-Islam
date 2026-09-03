import 'package:deen_connect/core/telemetry/install_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('newInstallId is a UUID v4', () {
    final id = InstallLogger.newInstallId();
    expect(
      id,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });
}
