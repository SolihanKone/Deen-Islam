import 'dart:math' as math;

/// Bearing in degrees from true north (0–360) from [lat],[lon] to the Kaaba.
double qiblaBearing(double lat, double lon) {
  const kabahLat = 21.422487;
  const kabahLon = 39.826206;
  final latR = lat * math.pi / 180;
  final lonR = lon * math.pi / 180;
  final kLatR = kabahLat * math.pi / 180;
  final kLonR = kabahLon * math.pi / 180;
  final y = math.sin(kLonR - lonR);
  final x = math.cos(latR) * math.tan(kLatR) -
      math.sin(latR) * math.cos(kLonR - lonR);
  var brng = math.atan2(y, x) * 180 / math.pi;
  brng = (brng + 360) % 360;
  return brng;
}

/// Smallest difference between two headings in [-180, 180].
double headingDelta(double from, double to) {
  var d = (to - from) % 360;
  if (d > 180) d -= 360;
  if (d < -180) d += 360;
  return d;
}
