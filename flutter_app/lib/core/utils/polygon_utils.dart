import 'package:latlong2/latlong.dart';

/// Returns true if segment (p1→p2) intersects segment (p3→p4).
bool _segmentsIntersect(LatLng p1, LatLng p2, LatLng p3, LatLng p4) {
  double d(LatLng a, LatLng b, LatLng c) {
    return (c.longitude - a.longitude) * (b.latitude - a.latitude) -
        (b.longitude - a.longitude) * (c.latitude - a.latitude);
  }

  final d1 = d(p3, p4, p1);
  final d2 = d(p3, p4, p2);
  final d3 = d(p1, p2, p3);
  final d4 = d(p1, p2, p4);

  if (((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
      ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0))) {
    return true;
  }
  return false;
}

/// Returns true if [point] is inside [polygon] (ray casting algorithm).
bool _pointInPolygon(LatLng point, List<LatLng> polygon) {
  int intersections = 0;
  final n = polygon.length;
  for (int i = 0; i < n; i++) {
    final a = polygon[i];
    final b = polygon[(i + 1) % n];
    if ((a.latitude <= point.latitude && point.latitude < b.latitude ||
            b.latitude <= point.latitude && point.latitude < a.latitude) &&
        point.longitude <
            (b.longitude - a.longitude) *
                    (point.latitude - a.latitude) /
                    (b.latitude - a.latitude) +
                a.longitude) {
      intersections++;
    }
  }
  return intersections % 2 == 1;
}

/// Returns true if polygon A and polygon B overlap (share any area).
/// Handles: edge intersections AND full containment in either direction.
bool polygonsOverlap(List<LatLng> a, List<LatLng> b) {
  if (a.length < 3 || b.length < 3) return false;

  // Check edge intersections
  for (int i = 0; i < a.length; i++) {
    for (int j = 0; j < b.length; j++) {
      if (_segmentsIntersect(
        a[i],
        a[(i + 1) % a.length],
        b[j],
        b[(j + 1) % b.length],
      )) {
        return true;
      }
    }
  }

  // Check if one polygon is fully inside the other
  if (_pointInPolygon(a[0], b)) return true;
  if (_pointInPolygon(b[0], a)) return true;

  return false;
}
