/// Arabic recitation rates for [AudioPlayer.setSpeed]. Translation TTS is 1×.
abstract final class ArabicPlaybackSpeed {
  static const List<double> presets = [0.5, 0.75, 1.0, 1.25, 1.5];
  static const double normal = 1.0;

  static double sanitize(double? raw) {
    if (raw == null) return normal;
    for (final preset in presets) {
      if ((preset - raw).abs() < 0.001) return preset;
    }
    return normal;
  }

  static String label(double speed) {
    final value = sanitize(speed);
    if (value == value.roundToDouble()) {
      return '${value.toStringAsFixed(0)}×';
    }
    return '$value×';
  }
}
