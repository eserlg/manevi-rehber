import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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
            },
          ),
        );

  Future<List<MosquePlace>> findNearbyMosques({
    required double latitude,
    required double longitude,
    int radiusMeters = 5000,
    int limit = 8,
  }) async {
    final radii = <int>{
      radiusMeters,
      15000,
      30000,
    };

    for (final radius in radii) {
      final places = await _queryNearbyMosques(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radius,
        limit: limit,
      );
      if (places.isNotEmpty) return places;

      if (kIsWeb) continue;

      final searchPlaces = await _queryNominatimMosques(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radius,
        limit: limit,
      );
      if (searchPlaces.isNotEmpty) return searchPlaces;
    }

    return const [];
  }

  Future<List<MosquePlace>> _queryNominatimMosques({
    required double latitude,
    required double longitude,
    required int radiusMeters,
    required int limit,
  }) async {
    final latDelta = radiusMeters / 111000;
    final lonScale = cos(_toRadians(latitude)).abs().clamp(0.25, 1.0);
    final lonDelta = radiusMeters / (111000 * lonScale);
    final viewbox = [
      longitude - lonDelta,
      latitude + latDelta,
      longitude + lonDelta,
      latitude - latDelta,
    ].map((value) => value.toStringAsFixed(6)).join(',');

    for (final query in const ['cami', 'camii', 'mescit', 'mosque']) {
      try {
        final response = await _dio.get(
          'https://nominatim.openstreetmap.org/search',
          queryParameters: {
            'format': 'jsonv2',
            'q': query,
            'limit': (limit * 3).toString(),
            'bounded': '1',
            'viewbox': viewbox,
            'addressdetails': '1',
            'namedetails': '1',
          },
        );

        final results = response.data is List
            ? response.data as List<dynamic>
            : const <dynamic>[];
        final places = _placesFromNominatimResults(
          results,
          latitude: latitude,
          longitude: longitude,
          limit: limit,
        );
        if (places.isNotEmpty) return places;
      } catch (_) {
        continue;
      }
    }

    return const [];
  }

  Future<List<MosquePlace>> _queryNearbyMosques({
    required double latitude,
    required double longitude,
    required int radiusMeters,
    required int limit,
  }) async {
    final overpassLimit = max(limit * 8, 40);
    final query = '''
[out:json][timeout:15];
(
  nwr(around:$radiusMeters,$latitude,$longitude)["amenity"="place_of_worship"]["religion"="muslim"];
  nwr(around:$radiusMeters,$latitude,$longitude)["building"="mosque"];
);
out center tags $overpassLimit;
''';

    Response<dynamic>? response;
    for (final endpoint in const [
      'https://overpass-api.de/api/interpreter',
      'https://overpass.kumi.systems/api/interpreter',
      'https://overpass.osm.ch/api/interpreter',
    ]) {
      try {
        response = await _dio.post(
          endpoint,
          data: {'data': query},
          options: Options(
            contentType: Headers.formUrlEncodedContentType,
            responseType: ResponseType.json,
          ),
        );
        break;
      } catch (_) {
        continue;
      }
    }

    if (response == null) return const [];

    final data = response.data;
    if (data is! Map<String, dynamic>) return const [];

    final List<dynamic> elements = data['elements'] ?? [];
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

  List<MosquePlace> _placesFromNominatimResults(
    List<dynamic> results, {
    required double latitude,
    required double longitude,
    required int limit,
  }) {
    final seen = <String>{};
    final places = <MosquePlace>[];

    for (final item in results.whereType<Map<String, dynamic>>()) {
      final lat = _asDouble(item['lat']);
      final lon = _asDouble(item['lon']);
      if (lat == null || lon == null) continue;

      final id =
          '${item['osm_type'] ?? 'n'}-${item['osm_id'] ?? places.length}';
      if (!seen.add(id)) continue;

      final distance = _distanceKm(latitude, longitude, lat, lon);
      final name = _nameFromNominatim(item);
      final address = _addressFromNominatim(item);
      places.add(
        MosquePlace(
          id: id,
          name: name,
          address: address,
          latitude: lat,
          longitude: lon,
          distanceKm: distance,
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

  String _nameFromNominatim(Map<String, dynamic> item) {
    final namedetails = item['namedetails'];
    if (namedetails is Map<String, dynamic>) {
      final name = namedetails['name']?.toString().trim();
      if (name != null && name.isNotEmpty) return name;
    }

    final name = item['name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;

    final displayName = item['display_name']?.toString().trim();
    final firstPart = displayName?.split(',').first.trim();
    if (firstPart != null && firstPart.isNotEmpty) return firstPart;

    return 'Cami';
  }

  String? _addressFromNominatim(Map<String, dynamic> item) {
    final address = item['address'];
    if (address is Map<String, dynamic>) {
      final parts = [
        address['road'],
        address['neighbourhood'],
        address['suburb'],
        address['town'] ?? address['city'] ?? address['province'],
      ]
          .map((item) => item?.toString().trim())
          .where((item) => item != null && item.isNotEmpty)
          .cast<String>()
          .toList();
      if (parts.isNotEmpty) return parts.join(', ');
    }

    final displayName = item['display_name']?.toString().trim();
    if (displayName == null || displayName.isEmpty) return null;
    return displayName.split(',').skip(1).take(3).join(',').trim();
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
