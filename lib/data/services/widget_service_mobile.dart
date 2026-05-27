import 'package:flutter/services.dart';
import '../models/prayer_times.dart';

class PrayerWidgetService {
  static const _channel = MethodChannel('home_widget');

  Future<void> updatePrayerTimes(
    PrayerTimes prayerTimes, {
    String? verseReference,
    String? verseText,
  }) async {
    try {
      final nextPrayer = prayerTimes.getNextPrayer();
      await _saveWidgetData('city', prayerTimes.city);
      await _saveWidgetData('next_prayer', nextPrayer);
      await _saveWidgetData(
          'next_prayer_time', prayerTimes.getNextPrayerTime());
      await _saveWidgetData('verse_reference', verseReference ?? 'Günün Ayeti');
      await _saveWidgetData(
        'verse_text',
        _normalizeVerseText(verseText ?? 'Allah’ı anmak kalplere huzur verir.'),
      );
      await _saveWidgetData(
        'time_until_next',
        _formatDuration(prayerTimes.getTimeUntilNextPrayer()),
      );
      await _channel.invokeMethod('updateWidget', {
        'android': 'PrayerHomeWidgetProvider',
      });
    } catch (_) {
      // Widget updates are best-effort and should never block app data loading.
    }
  }

  Future<void> _saveWidgetData(String id, String data) async {
    await _channel.invokeMethod<bool>('saveWidgetData', {
      'id': id,
      'data': data,
    });
  }

  String _normalizeVerseText(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ').trim();

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}s ${minutes}dk kaldı';
    }
    return '${minutes}dk kaldı';
  }
}
