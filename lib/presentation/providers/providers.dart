import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_themes.dart';
import '../../data/models/prayer_times.dart';
import '../../data/models/prayer.dart';
import '../../data/models/prayer_tracking.dart';
import '../../data/models/occasion_message.dart';
import '../../data/models/quran.dart';
import '../../data/models/zikr.dart';
import '../../data/repositories/prayer_repository.dart';
import '../../data/services/location_service.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/services/quran_audio_service.dart';
import '../../data/services/prayer_notification_service.dart';
import '../../data/services/text_to_speech_service.dart';
import '../../data/services/widget_service.dart';

// Services
final locationServiceProvider = Provider((ref) => LocationService());
final prayerRepositoryProvider = Provider((ref) => PrayerRepository());
final localStorageProvider = Provider((ref) => LocalStorageService());
final prayerWidgetServiceProvider = Provider((ref) => PrayerWidgetService());
final prayerNotificationServiceProvider =
    Provider((ref) => PrayerNotificationService());
final textToSpeechProvider = Provider((ref) => TextToSpeechService());
final quranAudioProvider = Provider((ref) {
  final service = QuranAudioService();
  ref.onDispose(service.dispose);
  return service;
});

// Location State
const defaultLatitude = 41.0082;
const defaultLongitude = 28.9784;

final currentPositionProvider = StateProvider<Position?>((ref) => null);
final currentCityProvider = StateProvider<String>((ref) => 'İstanbul');

// Prayer Times State
final prayerTimesProvider =
    FutureProvider.autoDispose<PrayerTimes?>((ref) async {
  final position = ref.watch(currentPositionProvider);
  final city = ref.watch(currentCityProvider);
  final repository = ref.watch(prayerRepositoryProvider);

  final prayerTimes = await repository.getPrayerTimes(
    latitude: position?.latitude ?? defaultLatitude,
    longitude: position?.longitude ?? defaultLongitude,
    city: city,
  );

  if (prayerTimes != null) {
    Verse? verse;
    try {
      verse = await repository.getVerseOfDay();
    } catch (_) {}

    await ref.read(prayerWidgetServiceProvider).updatePrayerTimes(
          prayerTimes,
          verseReference:
              verse == null ? null : '${verse.surahId}:${verse.verseKey}',
          verseText: verse?.translation,
        );
    final storage = ref.read(localStorageProvider);
    await ref
        .read(prayerNotificationServiceProvider)
        .schedulePrayerNotifications(
          prayerTimes: prayerTimes,
          leadMinutes: storage.getNotificationLeadMinutes(),
          enabled: storage.arePrayerNotificationsEnabled(),
        );
  }

  return prayerTimes;
});

// Zikr State
final zikrListProvider = StateNotifierProvider<ZikrNotifier, List<Zikr>>((ref) {
  final storage = ref.watch(localStorageProvider);
  return ZikrNotifier(storage);
});

class ZikrNotifier extends StateNotifier<List<Zikr>> {
  final LocalStorageService _storage;

  ZikrNotifier(this._storage) : super(Zikr.defaultZikrs) {
    _loadAll();
  }

  void _loadAll() {
    final customZikrs = _storage.getCustomZikrs();
    final all = [...Zikr.defaultZikrs, ...customZikrs];
    final progress = _storage.getZikrProgress();
    state = all.map((zikr) {
      final savedCount = progress[zikr.id];
      if (savedCount != null) {
        return zikr.copyWith(currentCount: savedCount);
      }
      return zikr;
    }).toList();
  }

  void increment(String zikrId) {
    state = state.map((zikr) {
      if (zikr.id == zikrId) {
        final newCount = zikr.currentCount + 1;
        _saveProgress(zikrId, newCount);
        return zikr.copyWith(currentCount: newCount);
      }
      return zikr;
    }).toList();
  }

  void reset(String zikrId) {
    state = state.map((zikr) {
      if (zikr.id == zikrId) {
        _saveProgress(zikrId, 0);
        return zikr.copyWith(currentCount: 0);
      }
      return zikr;
    }).toList();
  }

  Future<void> addCustomZikr(Zikr zikr) async {
    await _storage.addCustomZikr(zikr.copyWith(isCustom: true));
    _loadAll();
  }

  Future<void> updateCustomZikr(Zikr zikr) async {
    final customs = _storage.getCustomZikrs();
    final index = customs.indexWhere((z) => z.id == zikr.id);
    if (index >= 0) {
      customs[index] = zikr.copyWith(isCustom: true);
      await _storage.saveCustomZikrs(customs);
      _loadAll();
    }
  }

  Future<void> deleteCustomZikr(String zikrId) async {
    await _storage.deleteCustomZikr(zikrId);
    state = state.where((zikr) => zikr.id != zikrId).toList();
  }

  void _saveProgress(String zikrId, int count) {
    final progress = _storage.getZikrProgress();
    progress[zikrId] = count;
    _storage.saveZikrProgress(progress);
  }
}

// Selected Zikr
final selectedZikrProvider = StateProvider<Zikr?>((ref) => Zikr.subhanallah());

// Daily Prayers State
final dailyPrayersProvider = FutureProvider<List<Prayer>>((ref) async {
  final storage = ref.watch(localStorageProvider);
  return storage.loadDailyPrayers();
});

final favoritePrayerIdsProvider =
    StateNotifierProvider<FavoritePrayerNotifier, Set<String>>((ref) {
  final storage = ref.watch(localStorageProvider);
  return FavoritePrayerNotifier(storage);
});

class FavoritePrayerNotifier extends StateNotifier<Set<String>> {
  final LocalStorageService _storage;

  FavoritePrayerNotifier(this._storage)
      : super(_storage.getFavorites().toSet());

  Future<bool> toggle(String prayerId) async {
    final next = {...state};
    final isFavorite = next.contains(prayerId);

    if (isFavorite) {
      next.remove(prayerId);
    } else {
      next.add(prayerId);
    }

    state = next;
    await _storage.saveFavorites(next.toList());
    return !isFavorite;
  }
}

final selectedCategoryProvider = StateProvider<String?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredPrayersProvider = Provider<AsyncValue<List<Prayer>>>((ref) {
  final prayersAsync = ref.watch(dailyPrayersProvider);
  final category = ref.watch(selectedCategoryProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final favoriteIds = ref.watch(favoritePrayerIdsProvider);

  return prayersAsync.whenData((prayers) {
    var filtered = prayers
        .map((prayer) => prayer.copyWith(
              isFavorite: favoriteIds.contains(prayer.id),
            ))
        .toList();

    if (category == 'favorites') {
      filtered =
          filtered.where((prayer) => favoriteIds.contains(prayer.id)).toList();
    } else if (category != null) {
      filtered = filtered.where((p) => p.category == category).toList();
    }

    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where((p) =>
              p.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
              p.turkish.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  });
});

final prayerTrackingProvider =
    StateNotifierProvider<PrayerTrackingNotifier, PrayerTrackingState>((ref) {
  final storage = ref.watch(localStorageProvider);
  return PrayerTrackingNotifier(storage);
});

class PrayerTrackingNotifier extends StateNotifier<PrayerTrackingState> {
  final LocalStorageService _storage;

  PrayerTrackingNotifier(this._storage) : super(PrayerTrackingState.empty()) {
    _load();
  }

  void _load() {
    final tracking = _storage.getPrayerTracking().map(
          (date, prayers) => MapEntry(date, prayers.toSet()),
        );
    final qada = {
      for (final prayer in PrayerTrackingState.trackablePrayers)
        prayer: _storage.getQadaDebt()[prayer] ?? 0,
    };

    state = PrayerTrackingState(
      prayedByDate: tracking,
      qadaDebt: qada,
    );
  }

  Future<void> toggleToday(String prayer) async {
    final todayKey = PrayerTrackingState.dateKey(DateTime.now());
    final nextTracking = {
      for (final entry in state.prayedByDate.entries)
        entry.key: {...entry.value},
    };
    final today = nextTracking[todayKey] ?? <String>{};

    if (today.contains(prayer)) {
      today.remove(prayer);
    } else {
      today.add(prayer);
    }

    nextTracking[todayKey] = today;
    state = state.copyWith(prayedByDate: nextTracking);
    await _persistTracking();
  }

  Future<void> adjustQada(String prayer, int delta) async {
    final nextDebt = {...state.qadaDebt};
    final current = nextDebt[prayer] ?? 0;
    nextDebt[prayer] = (current + delta).clamp(0, 9999).toInt();
    state = state.copyWith(qadaDebt: nextDebt);
    await _storage.saveQadaDebt(nextDebt);
  }

  Future<void> _persistTracking() async {
    await _storage.savePrayerTracking(
      state.prayedByDate.map(
        (date, prayers) => MapEntry(date, prayers.toList()..sort()),
      ),
    );
  }
}

final occasionMessagesProvider =
    FutureProvider<List<OccasionMessage>>((ref) async {
  final storage = ref.watch(localStorageProvider);
  return storage.loadOccasionMessages();
});

// Quran State
final surahsProvider = FutureProvider<List<Surah>>((ref) async {
  final repository = ref.watch(prayerRepositoryProvider);
  return repository.getSurahs();
});

final selectedSurahProvider = StateProvider<Surah?>((ref) => null);
final versesProvider =
    FutureProvider.family<List<Verse>, int>((ref, surahId) async {
  final repository = ref.watch(prayerRepositoryProvider);
  return repository.getVerses(surahId);
});

final verseOfDayProvider = FutureProvider<Verse?>((ref) async {
  final repository = ref.watch(prayerRepositoryProvider);
  return repository.getVerseOfDay();
});

// Widget verses — her seferinde farklı verse seç (rotation + shuffle)
final widgetVersesProvider =
    StateNotifierProvider<WidgetVersesNotifier, List<WidgetVerse>>((ref) {
  final verseAsync = ref.watch(verseOfDayProvider).valueOrNull;
  return WidgetVersesNotifier(verseAsync);
});

class WidgetVerse {
  final String reference;
  final String text;
  const WidgetVerse({required this.reference, required this.text});
}

class WidgetVersesNotifier extends StateNotifier<List<WidgetVerse>> {
  WidgetVersesNotifier(Verse? dailyVerse)
      : super(_buildInitial(dailyVerse));

  static const _pool = [
    WidgetVerse(
      reference: 'Bakara 2:152',
      text:
          'Öyleyse yalnız beni anın ki ben de sizi anayım. Bana şükredin, sakın nankörlük etmeyin.',
    ),
    WidgetVerse(
      reference: 'Ra\'d 13:28',
      text: 'Bilesiniz ki kalpler ancak Allah\'ı anmakla huzur bulur.',
    ),
    WidgetVerse(
      reference: 'İnşirah 94:5-6',
      text: 'Şüphesiz güçlükle beraber bir kolaylık vardır.',
    ),
    WidgetVerse(
      reference: 'Zümer 39:53',
      text: 'Allah\'ın rahmetinden ümidinizi kesmeyin.',
    ),
    WidgetVerse(
      reference: 'Duha 93:5',
      text: 'Rabbin sana verecek ve sen hoşnut olacaksın.',
    ),
    WidgetVerse(
      reference: 'Talak 65:3',
      text: 'Kim Allah\'a tevekkül ederse Allah ona yeter.',
    ),
    WidgetVerse(
      reference: 'Bakara 2:153',
      text: 'Ey iman edenler! Sabır ve namazla Allah\'tan yardım isteyin.',
    ),
    WidgetVerse(
      reference: 'Fecr 89:27-28',
      text: 'Ey huzura kavuşmuş nefis! Rabbine, razı edilmiş ve razı olmuş olarak dön.',
    ),
    WidgetVerse(
      reference: 'Şems 91:9',
      text: 'Nefsini arındıran kurtuluşa ermiştir.',
    ),
    WidgetVerse(
      reference: 'Ankebut 29:69',
      text: 'Bizim uğrumuzda cihad edenleri elbette yollarımıza ulaştıracağız.',
    ),
    WidgetVerse(
      reference: 'Hadid 57:3',
      text: 'O, ilk ve sondur, zahiri ve batındır. O her şeyi bilir.',
    ),
    WidgetVerse(
      reference: 'Nahl 16:97',
      text:
          'Erkek olsun kadın olsun, mümin olarak iyi işler yapan kimseye güzel bir hayat yaşatacağız.',
    ),
  ];

  static List<WidgetVerse> _buildInitial(Verse? dailyVerse) {
    final verses = <WidgetVerse>[];
    if (dailyVerse != null &&
        (dailyVerse.translation ?? '').trim().isNotEmpty) {
      verses.add(WidgetVerse(
        reference: '${dailyVerse.surahId}:${dailyVerse.verseKey}',
        text: dailyVerse.translation!.trim().replaceAll(RegExp(r'\s+'), ' '),
      ));
    }
    verses.addAll(_pool);
    verses.shuffle();
    return verses;
  }

  void rotate(Verse? dailyVerse) {
    state = _buildInitial(dailyVerse);
  }
}

// Navigation
final selectedTabProvider = StateProvider<int>((ref) => 0);
final activeUserProvider = StateProvider<String?>(
  (ref) => ref.read(localStorageProvider).getActiveUser(),
);
final memorialRefreshProvider = StateProvider<int>((ref) => 0);

// Theme
final themeModeProvider = StateProvider<AppThemeMode>((ref) {
  final stored = ref.read(localStorageProvider).getThemeMode();
  return AppThemeMode.values.firstWhere(
    (m) => m.name == stored,
    orElse: () => AppThemeMode.meadow,
  );
});

final themeColorsProvider = Provider<ThemeColors>(
    (ref) => AppThemes.colors(ref.watch(themeModeProvider)));

// Quran resume
final lastReadProvider = FutureProvider<Map<String, int>?>((ref) async {
  final storage = ref.watch(localStorageProvider);
  await storage.init();
  return storage.getLastRead();
});
