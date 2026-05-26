import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import '../models/prayer_times.dart';
import '../models/quran.dart';

class PrayerRepository {
  final Dio _dio;
  final Map<String, int> _diyanetLocationCache = {};
  List<Map<String, dynamic>>? _diyanetStatesCache;

  PrayerRepository()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));

  /// Get prayer times. Turkish province names use Diyanet-sourced table data
  /// first, then fall back to calculated Aladhan data if the source is down.
  Future<PrayerTimes?> getPrayerTimes({
    required double latitude,
    required double longitude,
    required String city,
    String? date,
  }) async {
    final diyanetTimes = await _getDiyanetPrayerTimes(
      latitude: latitude,
      longitude: longitude,
      city: city,
      date: date,
    );
    if (diyanetTimes != null) return diyanetTimes;

    try {
      final queryParams = {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'method': '13', // Diyanet İşleri Başkanlığı, Turkey
        'school': '0', // Standard calculation
      };

      if (date != null) {
        queryParams['date'] = date;
      }

      final response = await _dio.get(
        'https://api.aladhan.com/v1/timings',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['code'] == 200) {
        return PrayerTimes.fromJson(
          response.data,
          city,
          latitude,
          longitude,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<PrayerTimes?> _getDiyanetPrayerTimes({
    required double latitude,
    required double longitude,
    required String city,
    String? date,
  }) async {
    final locationId = await _resolveDiyanetLocationId(city);
    if (locationId == null) return null;

    try {
      final response = await _dio.get(
        'https://ezanvakti.imsakiyem.com/api/prayer-times/$locationId/monthly',
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode != 200 || response.data['code'] != 200) {
        return null;
      }

      final targetKey = _dateKey(_targetDateFrom(date));
      final List<dynamic> rows = response.data['data'] ?? [];
      final match = _firstWhereOrNull(
        rows.whereType<Map<String, dynamic>>(),
        (row) => (row['date']?.toString() ?? '').startsWith(targetKey),
      );

      if (match == null) return null;

      return PrayerTimes.fromDiyanet(match, city, latitude, longitude);
    } catch (_) {
      return null;
    }
  }

  Future<int?> _resolveDiyanetLocationId(String city) async {
    final normalizedCity = _normalizeTurkish(city);
    if (normalizedCity.isEmpty ||
        normalizedCity == 'mevcut konum' ||
        normalizedCity == 'bilinmeyen') {
      return null;
    }

    final cached = _diyanetLocationCache[normalizedCity];
    if (cached != null) return cached;

    try {
      final states = await _getDiyanetStates();
      final state = _firstWhereOrNull(
        states,
        (item) =>
            _normalizeTurkish(item['name']?.toString() ?? '') == normalizedCity,
      );
      if (state == null) return null;

      final stateId = state['_id']?.toString();
      if (stateId == null || stateId.isEmpty) return null;

      final districtsResponse = await _dio.get(
        'https://ezanvakti.imsakiyem.com/api/locations/districts',
        queryParameters: {'stateId': stateId},
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (districtsResponse.statusCode != 200 ||
          districtsResponse.data['code'] != 200) {
        return null;
      }

      final List<dynamic> districts = districtsResponse.data['data'] ?? [];
      final typedDistricts =
          districts.whereType<Map<String, dynamic>>().toList();
      if (typedDistricts.isEmpty) return null;

      final district = _firstWhereOrNull(
            typedDistricts,
            (item) =>
                _normalizeTurkish(item['name']?.toString() ?? '') ==
                normalizedCity,
          ) ??
          typedDistricts.first;
      final districtId = int.tryParse(district['_id']?.toString() ?? '');
      if (districtId == null) return null;

      _diyanetLocationCache[normalizedCity] = districtId;
      return districtId;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _getDiyanetStates() async {
    final cached = _diyanetStatesCache;
    if (cached != null) return cached;

    final response = await _dio.get(
      'https://ezanvakti.imsakiyem.com/api/locations/states',
      queryParameters: {'countryId': '2'},
      options: Options(headers: {'Accept': 'application/json'}),
    );

    if (response.statusCode != 200 || response.data['code'] != 200) {
      return [];
    }

    final states = (response.data['data'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    _diyanetStatesCache = states;
    return states;
  }

  DateTime _targetDateFrom(String? value) {
    if (value == null || value.trim().isEmpty) return DateTime.now();

    final trimmed = value.trim();
    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return iso;

    final parts = trimmed.split(RegExp(r'[-./]'));
    if (parts.length == 3) {
      final first = int.tryParse(parts[0]);
      final second = int.tryParse(parts[1]);
      final third = int.tryParse(parts[2]);
      if (first != null && second != null && third != null) {
        if (parts[0].length == 4) return DateTime(first, second, third);
        return DateTime(third, second, first);
      }
    }

    return DateTime.now();
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _normalizeTurkish(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('\u0307', '')
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('û', 'u');
  }

  T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T item) test) {
    for (final item in items) {
      if (test(item)) return item;
    }
    return null;
  }

  /// Get all surahs from Quran.com API
  Future<List<Surah>> getSurahs() async {
    final localQuran = await _loadLocalQuran();
    if (localQuran != null) {
      final List<dynamic> surahs = localQuran['surahs'] ?? [];
      return surahs.map((json) => Surah.fromJson(json)).toList();
    }

    try {
      final response = await _dio.get(
        'https://api.quran.com/api/v4/chapters',
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> chapters = response.data['chapters'] ?? [];
        return chapters.map((json) => Surah.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get verses of a surah
  Future<List<Verse>> getVerses(int surahId) async {
    final localQuran = await _loadLocalQuran();
    if (localQuran != null) {
      final List<dynamic> surahs = localQuran['surahs'] ?? [];
      Map<String, dynamic>? surah;
      for (final item in surahs) {
        if (item is Map<String, dynamic> && item['id'] == surahId) {
          surah = item;
          break;
        }
      }

      if (surah != null) {
        final List<dynamic> verses = surah['verses'] ?? [];
        return verses.map((json) => Verse.fromJson(json, surahId)).toList();
      }
    }

    try {
      final response = await _dio.get(
        'https://api.quran.com/api/v4/verses/by_chapter/$surahId',
        queryParameters: {
          'language': 'tr',
          'words': false,
        },
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> verses = response.data['verses'] ?? [];
        return verses
            .map((json) => Verse.fromJson(json['verse'], surahId))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get random verse of the day
  Future<Verse?> getVerseOfDay() async {
    try {
      // Get a random surah (1-114) and verse
      final randomSurah = DateTime.now().millisecondsSinceEpoch % 114 + 1;
      final verses = await getVerses(randomSurah);

      if (verses.isNotEmpty) {
        final randomVerseIndex = DateTime.now().second % verses.length;
        return verses[randomVerseIndex];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _loadLocalQuran() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/data/quran_tr.json');
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
