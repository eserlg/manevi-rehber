import 'dart:math';

/// Qibla direction model
class QiblaDirection {
  final double latitude;
  final double longitude;
  final double qiblaDirection; // degrees from north
  final double distance; // km to Mecca

  QiblaDirection({
    required this.latitude,
    required this.longitude,
    required this.qiblaDirection,
    required this.distance,
  });

  factory QiblaDirection.calculate({
    required double latitude,
    required double longitude,
  }) {
    // Kaabe coordinates (Makkah)
    const double kabahLatitude = 21.4225;
    const double kabahLongitude = 39.8264;

    // Convert to radians
    final double lat1 = _toRadians(latitude);
    final double lon1 = _toRadians(longitude);
    final double lat2 = _toRadians(kabahLatitude);
    final double lon2 = _toRadians(kabahLongitude);

    // Calculate Qibla direction
    final double dLon = lon2 - lon1;

    final double y = sin(dLon) * cos(lat2);
    final double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    double qiblaRad = atan2(y, x);
    double qiblaDeg = _toDegrees(qiblaRad);

    // Normalize to 0-360
    qiblaDeg = (qiblaDeg + 360) % 360;

    // Calculate distance using Haversine formula
    final double distance = _calculateDistance(lat1, lon1, lat2, lon2);

    return QiblaDirection(
      latitude: latitude,
      longitude: longitude,
      qiblaDirection: qiblaDeg,
      distance: distance,
    );
  }

  static double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  static double _toDegrees(double radians) {
    return radians * 180 / pi;
  }

  static double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km

    final double dLat = lat2 - lat1;
    final double dLon = lon2 - lon1;

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  String get compassDirection {
    if (qiblaDirection >= 337.5 || qiblaDirection < 22.5) return 'K';
    if (qiblaDirection >= 22.5 && qiblaDirection < 67.5) return 'KD';
    if (qiblaDirection >= 67.5 && qiblaDirection < 112.5) return 'D';
    if (qiblaDirection >= 112.5 && qiblaDirection < 157.5) return 'GD';
    if (qiblaDirection >= 157.5 && qiblaDirection < 202.5) return 'G';
    if (qiblaDirection >= 202.5 && qiblaDirection < 247.5) return 'GB';
    if (qiblaDirection >= 247.5 && qiblaDirection < 292.5) return 'B';
    if (qiblaDirection >= 292.5 && qiblaDirection < 337.5) return 'KB';
    return '?';
  }

  String get fullDirectionName {
    switch (compassDirection) {
      case 'K':
        return 'Kuzey';
      case 'KD':
        return 'Kuzeydoğu';
      case 'D':
        return 'Doğu';
      case 'GD':
        return 'Güneydoğu';
      case 'G':
        return 'Güney';
      case 'GB':
        return 'Güneybatı';
      case 'B':
        return 'Batı';
      case 'KB':
        return 'Kuzeybatı';
      default:
        return 'Bilinmeyen';
    }
  }

  String get formattedDistance {
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)} m';
    }
    return '${distance.toStringAsFixed(1)} km';
  }
}
