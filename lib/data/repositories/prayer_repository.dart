import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import '../models/prayer_times.dart';
import '../models/quran.dart';

class PrayerRepository {
  final Dio _dio;

  PrayerRepository() : _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// Get prayer times from Aladhan API
  Future<PrayerTimes?> getPrayerTimes({
    required double latitude,
    required double longitude,
    required String city,
    String? date,
  }) async {
    try {
      final queryParams = {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'method': '3', // Turkey calculation method
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
        return verses
            .map((json) => Verse.fromJson(json, surahId))
            .toList();
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
        return verses.map((json) => Verse.fromJson(json['verse'], surahId)).toList();
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
      final jsonString = await rootBundle.loadString('assets/data/quran_tr.json');
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
