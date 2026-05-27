import 'dart:math';

import 'package:dio/dio.dart';

import '../models/mosque_place.dart';

class NearbyMosqueService {
  final Dio _dio;

  NearbyMosqueService()
      : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 15),
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'ManeviRehber/1.0',
            },
          ),
        );

  Future<List<MosquePlace>> findNearbyMosques({
    required double latitude,
    required double longitude,
    int radiusMeters = 5000,
    int limit = 8,
  }) async {
    final query = '''
[out:json][timeout:15];
(
  node["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusMeters,$latitude,$longitude);
  way["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusMeters,$latitude,$longitude);
  relation["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusMeters,$latitude,$longitude);
  node["building"="mosque"](around:$radiusMeters,$latitude,$longitude);
  way["building"="mosque"](around:$radiusMeters,$latitude,$longitude);
  relation["building"="mosque"](around:$radiusMeters,$latitude,$longitude);
);
out center tags $limit;
''';

    final response = await _dio.get(
      'https://overpass-api.de/api/interpreter',
      queryParameters: {'data': query},
    );

    final List<dynamic> elements = response.data['elements'] ?? [];
    final seen = <String>{};
    final places = <MosquePlace>[];

    for (final element in elements.whereType<Map<String, dynamic>>()) {
      final type = element['type']?.toString() ?? 'place';
      final id = '$type-${element['id']}';
      if (!seen.add(id)) continue;

      final tags = element['tags'] as Map<String, dynamic>? ?? const {};
      final center = element['center'] as Map<String, dynamic>?;
      final lat = _asDouble(element['lat']) ?? _asDouble(center?['lat']);
      final lon = _asDouble(element['lon']) ?? _asDouble(center?['lon']);
      if (lat == null || lon == null) continue;

      places.add(
        MosquePlace(
          id: id,
          name: _nameFromTags(tags),
          address: _addressFromTags(tags),
          latitude: lat,
          longitude: lon,
          distanceKm: _distanceKm(latitude, longitude, lat, lon),
        ),
      );
    }

    places.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return places.take(limit).toList();
  }

  double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  String _nameFromTags(Map<String, dynamic> tags) {
    final name = tags['name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Cami';
  }

  String? _addressFromTags(Map<String, dynamic> tags) {
    final parts = [
      tags['addr:street'],
      tags['addr:housenumber'],
      tags['addr:neighbourhood'],
      tags['addr:district'],
    ]
        .map((item) => item?.toString().trim())
        .where((item) => item != null && item.isNotEmpty)
        .cast<String>()
        .toList();

    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _toRadians(double degree) => degree * pi / 180;
}
