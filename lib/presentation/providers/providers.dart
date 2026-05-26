import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/prayer_times.dart';
import '../../data/models/prayer.dart';
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
    await ref.read(prayerWidgetServiceProvider).updatePrayerTimes(prayerTimes);
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

  ZikrNotifier(this._storage) : super(Zikr.defaultZikirs) {
    _loadProgress();
  }

  void _loadProgress() {
    final progress = _storage.getZikrProgress();
    if (progress.isNotEmpty) {
      state = state.map((zikr) {
        final savedCount = progress[zikr.id];
        if (savedCount != null) {
          return zikr.copyWith(currentCount: savedCount);
        }
        return zikr;
      }).toList();
    }
  }

  void increment(String zikrId) {
    state = state.map((zikr) {
      if (zikr.id == zikrId && zikr.currentCount < zikr.targetCount) {
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

// Navigation
final selectedTabProvider = StateProvider<int>((ref) => 0);
final activeUserProvider = StateProvider<String?>(
  (ref) => ref.read(localStorageProvider).getActiveUser(),
);
final memorialRefreshProvider = StateProvider<int>((ref) => 0);

// Quran resume
final lastReadProvider = FutureProvider<Map<String, int>?>((ref) async {
  final storage = ref.watch(localStorageProvider);
  await storage.init();
  return storage.getLastRead();
});
