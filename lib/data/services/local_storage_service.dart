import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/occasion_message.dart';
import '../models/prayer.dart';
import '../models/zikr.dart';

class LocalStorageService {
  static const String _activeUserKey = 'active_user';
  static const String _knownUsersKey = 'known_users';
  static const String _zikrKey = 'zikr_progress';
  static const String _favoritesKey = 'favorite_prayers';
  static const String _lastReadKey = 'last_read_surah';
  static const String _memorialKey = 'memorial_record';
  static const String _cityKey = 'selected_city';
  static const String _lastLocationKey = 'last_location';
  static const String _onboardingKey = 'onboarding_completed';
  static const String _autoLocationKey = 'auto_location_enabled';
  static const String _notificationsKey = 'prayer_notifications_enabled';
  static const String _notificationLeadKey = 'notification_lead_minutes';
  static const String _prayerTrackingKey = 'prayer_tracking';
  static const String _qadaDebtKey = 'qada_debt';
  static const String _appRatingKey = 'app_rating';
  static const String _feedbackKey = 'feedback_messages';
  static const String _customZikrsKey = 'custom_zikrs';
  static const String _themeModeKey = 'theme_mode';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  String _scopedKey(String key) {
    final user = _prefs?.getString(_activeUserKey);
    if (user == null || user.isEmpty) return key;
    return 'user_${user.toLowerCase()}_$key';
  }

  String? getActiveUser() {
    return _prefs?.getString(_activeUserKey);
  }

  Future<void> setActiveUser(String username) async {
    final prefs = await _ensurePrefs();
    final normalized = username.trim();
    await prefs.setString(_activeUserKey, normalized);

    final users = prefs.getStringList(_knownUsersKey) ?? [];
    if (!users.contains(normalized)) {
      await prefs.setStringList(_knownUsersKey, [...users, normalized]);
    }
  }

  Future<void> clearActiveUser() async {
    final prefs = await _ensurePrefs();
    await prefs.remove(_activeUserKey);
  }

  List<String> getKnownUsers() {
    return _prefs?.getStringList(_knownUsersKey) ?? [];
  }

  // Custom Zikrs
  Future<void> setThemeMode(String mode) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(_scopedKey(_themeModeKey), mode);
  }

  String getThemeMode() {
    return _prefs?.getString(_scopedKey(_themeModeKey)) ?? 'meadow';
  }

  Future<void> saveCustomZikrs(List<Zikr> zikrs) async {
    final prefs = await _ensurePrefs();
    final encoded =
        jsonEncode(zikrs.map((zikr) => zikr.toJson()).toList());
    await prefs.setString(_scopedKey(_customZikrsKey), encoded);
  }

  List<Zikr> getCustomZikrs() {
    final data = _prefs?.getString(_scopedKey(_customZikrsKey));
    if (data == null) return [];
    try {
      final decoded = jsonDecode(data);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((item) => Zikr.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addCustomZikr(Zikr zikr) async {
    final zikrs = getCustomZikrs();
    final index =
        zikrs.indexWhere((element) => element.id == zikr.id);
    if (index >= 0) {
      zikrs[index] = zikr;
    } else {
      zikrs.add(zikr);
    }
    await saveCustomZikrs(zikrs);
  }

  Future<void> deleteCustomZikr(String zikrId) async {
    final zikrs = getCustomZikrs().where((z) => z.id != zikrId).toList();
    await saveCustomZikrs(zikrs);
    final progress = getZikrProgress();
    if (progress.containsKey(zikrId)) {
      progress.remove(zikrId);
      await saveZikrProgress(progress);
    }
  }

// Zikr Progress
  Future<void> saveZikrProgress(Map<String, int> progress) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(_scopedKey(_zikrKey), jsonEncode(progress));
  }

  Map<String, int> getZikrProgress() {
    final data = _prefs?.getString(_scopedKey(_zikrKey));
    if (data == null) return {};
    try {
      final decoded = jsonDecode(data);
      if (decoded is! Map) return {};
      return decoded.map((key, value) {
        final v = _asInt(value);
        return MapEntry(key.toString(), v);
      });
    } catch (_) {
      return {};
    }
  }

  // Favorite Prayers
  Future<void> saveFavorites(List<String> prayerIds) async {
    final prefs = await _ensurePrefs();
    await prefs.setStringList(_scopedKey(_favoritesKey), prayerIds);
  }

  List<String> getFavorites() {
    return _prefs?.getStringList(_scopedKey(_favoritesKey)) ?? [];
  }

  // Last Read Surah
  Future<void> saveLastRead(int surahId, int verseId) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(
      _scopedKey(_lastReadKey),
      jsonEncode({'surah': surahId, 'verse': verseId}),
    );
  }

  Map<String, int>? getLastRead() {
    final data = _prefs?.getString(_scopedKey(_lastReadKey));
    if (data == null) return null;
    try {
      final decoded = jsonDecode(data);
      if (decoded is! Map) return null;
      return decoded.map((key, value) {
        final v = int.tryParse(value?.toString() ?? '') ?? 0;
        return MapEntry(key.toString(), v);
      });
    } catch (_) {
      return null;
    }
  }

  // Memorial Record
  Future<void> saveMemorialRecord(Map<String, dynamic> record) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(_scopedKey(_memorialKey), jsonEncode(record));
  }

  Map<String, dynamic>? getMemorialRecord() {
    final records = getMemorialRecords();
    if (records.isNotEmpty) return records.first;

    final data = _prefs?.getString(_scopedKey(_memorialKey));
    if (data != null) {
      return Map<String, dynamic>.from(jsonDecode(data));
    }
    return null;
  }

  Future<void> saveMemorialRecords(
    List<Map<String, dynamic>> records,
  ) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(
      _scopedKey(_memorialKey),
      jsonEncode({'records': records}),
    );
  }

  List<Map<String, dynamic>> getMemorialRecords() {
    final data = _prefs?.getString(_scopedKey(_memorialKey));
    if (data == null) return [];

    final decoded = jsonDecode(data);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((record) => _normalizeMemorialRecord(record))
          .toList();
    }

    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      final records = map['records'];

      if (records is List) {
        return records
            .whereType<Map>()
            .map((record) => _normalizeMemorialRecord(record))
            .toList();
      }

      if (map.containsKey('deathDate')) {
        return [_normalizeMemorialRecord(map)];
      }
    }

    return [];
  }

  Map<String, dynamic> _normalizeMemorialRecord(Map<dynamic, dynamic> record) {
    final normalized = Map<String, dynamic>.from(record);
    final identity =
        '${normalized['name'] ?? ''}_${normalized['deathDate'] ?? ''}';

    normalized['id'] = normalized['id']?.toString().isNotEmpty == true
        ? normalized['id'].toString()
        : 'memorial_${identity.hashCode.abs()}';
    normalized['tasbihCount'] = _asInt(normalized['tasbihCount']);
    normalized['yasinCount'] = _asInt(normalized['yasinCount']);
    normalized['hatimCount'] = _asInt(normalized['hatimCount']);
    return normalized;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  // Selected City
  Future<void> saveCity(String city) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(_scopedKey(_cityKey), city);
  }

  String? getCity() {
    return _prefs?.getString(_scopedKey(_cityKey));
  }

  Future<void> saveLastLocation({
    required double latitude,
    required double longitude,
  }) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(
      _scopedKey(_lastLocationKey),
      jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
      }),
    );
  }

  Map<String, double>? getLastLocation() {
    final data = _prefs?.getString(_scopedKey(_lastLocationKey));
    if (data == null) return null;

    final decoded = jsonDecode(data);
    if (decoded is! Map) return null;

    final latitude = decoded['latitude'];
    final longitude = decoded['longitude'];
    if (latitude is! num || longitude is! num) return null;

    return {
      'latitude': latitude.toDouble(),
      'longitude': longitude.toDouble(),
    };
  }

  // Settings
  Future<void> setAutoLocationEnabled(bool enabled) async {
    final prefs = await _ensurePrefs();
    await prefs.setBool(_scopedKey(_autoLocationKey), enabled);
  }

  bool isAutoLocationEnabled() {
    return _prefs?.getBool(_scopedKey(_autoLocationKey)) ?? true;
  }

  Future<void> setPrayerNotificationsEnabled(bool enabled) async {
    final prefs = await _ensurePrefs();
    await prefs.setBool(_scopedKey(_notificationsKey), enabled);
  }

  bool arePrayerNotificationsEnabled() {
    return _prefs?.getBool(_scopedKey(_notificationsKey)) ?? true;
  }

  Future<void> setNotificationLeadMinutes(int minutes) async {
    final prefs = await _ensurePrefs();
    await prefs.setInt(_scopedKey(_notificationLeadKey), minutes);
  }

  int getNotificationLeadMinutes() {
    return _prefs?.getInt(_scopedKey(_notificationLeadKey)) ?? 10;
  }

  Future<void> savePrayerTracking(Map<String, List<String>> tracking) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(_scopedKey(_prayerTrackingKey), jsonEncode(tracking));
  }

  Map<String, List<String>> getPrayerTracking() {
    final data = _prefs?.getString(_scopedKey(_prayerTrackingKey));
    if (data == null) return {};

    final decoded = jsonDecode(data);
    if (decoded is! Map) return {};

    return decoded.map((key, value) {
      final prayers = <String>[];
      if (value is List) {
        prayers.addAll(value.map((item) => item.toString()));
      }
      return MapEntry(key.toString(), prayers.toList());
    });
  }

  Future<void> saveQadaDebt(Map<String, int> debt) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(_scopedKey(_qadaDebtKey), jsonEncode(debt));
  }

  Map<String, int> getQadaDebt() {
    final data = _prefs?.getString(_scopedKey(_qadaDebtKey));
    if (data == null) return {};

    final decoded = jsonDecode(data);
    if (decoded is! Map) return {};

    return decoded.map((key, value) {
      return MapEntry(key.toString(), _asInt(value));
    });
  }

  Future<void> saveAppRating(int rating) async {
    final prefs = await _ensurePrefs();
    await prefs.setInt(_scopedKey(_appRatingKey), rating);
  }

  int getAppRating() {
    return _prefs?.getInt(_scopedKey(_appRatingKey)) ?? 0;
  }

  Future<void> addFeedbackMessage(String message) async {
    final prefs = await _ensurePrefs();
    final messages = prefs.getStringList(_scopedKey(_feedbackKey)) ?? [];
    await prefs.setStringList(
      _scopedKey(_feedbackKey),
      [...messages, message],
    );
  }

  List<String> getFeedbackMessages() {
    return _prefs?.getStringList(_scopedKey(_feedbackKey)) ?? [];
  }

  // Onboarding
  Future<void> setOnboardingCompleted(bool completed) async {
    final prefs = await _ensurePrefs();
    await prefs.setBool(_scopedKey(_onboardingKey), completed);
  }

  bool isOnboardingCompleted() {
    return _prefs?.getBool(_scopedKey(_onboardingKey)) ?? false;
  }

  // Load daily prayers from assets
  Future<List<Prayer>> loadDailyPrayers() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/daily_prayers.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Prayer.fromJson(json)).toList();
    } catch (e) {
      return _getDefaultPrayers();
    }
  }

  Future<List<OccasionMessage>> loadOccasionMessages() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/data/occasion_messages.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .whereType<Map>()
          .map((item) => OccasionMessage.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<Prayer> _getDefaultPrayers() {
    return [
      Prayer(
        id: '1',
        title: 'Sabah Duası',
        arabic:
            'اَللّٰهُمَّ بِكَ اَصْبَحْنَا وَبِكَ اَمْسَيْنَا وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَاِلَيْكَ النُّشُوْرُ',
        turkish:
            'Allah\'ım! Sabahleyin Sana kavuşarak, akşamleyin Sana kavuşarak uyandık. Diriltilişimiz de Sanadır. Dönüşümüz de Sanadır.',
        meaning: 'Sabah namazından sonra okunur',
        category: 'sabah',
      ),
      Prayer(
        id: '2',
        title: 'Akşam Duası',
        arabic:
            'اَللّٰهُمَّ بِكَ اَمْسَيْنَا وَبِكَ اَصْبَحْنَا وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَاِلَيْكَ الْمَصِيْرُ',
        turkish:
            'Allah\'ım! Akşamleyin Sana kavuşarak, sabahleyin Sana kavuşarak uyandık. Diriltilişimiz de Sanadır. Dönüşümüz de Sanadır.',
        meaning: 'Akşam namazından sonra okunur',
        category: 'aksam',
      ),
      Prayer(
        id: '3',
        title: 'Yemek Duası',
        arabic: 'بِسْمِ اللّٰهِ وَعَلَى بَرَكَةِ اللّٰهِ',
        turkish: 'Allah\'ın adıyla ve Allah\'ın bereketiyle',
        meaning: 'Yemek yerken',
        category: 'yemek',
      ),
      Prayer(
        id: '4',
        title: 'İstiğfar',
        arabic:
            'اَسْتَغْفِرُاللّٰهَ الْعَظِيمَ الَّذِي لَا اِلٰهَ اِلَّا هُوَ الْحَىُّ الْقَيُّوْمُ وَاَتُوبُ اِلَيْهِ',
        turkish:
            'Bağışlanma diliyorum, yüce Allah\'tan. O\'ndan başka ilah yoktur, diri, kendi kendine var olandır ve O\'na tövbe ediyorum.',
        meaning: 'Günlük istiğfar duası',
        category: 'gunluk',
      ),
    ];
  }
}
