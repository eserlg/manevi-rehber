import 'package:flutter/services.dart';
import '../models/prayer_times.dart';

class PrayerWidgetService {
  static const _channel = MethodChannel('home_widget');

  Future<void> updatePrayerTimes(PrayerTimes prayerTimes) async {
    try {
      final nextPrayer = prayerTimes.getNextPrayer();
      await _saveWidgetData('city', prayerTimes.city);
      await _saveWidgetData('next_prayer', nextPrayer);
      await _saveWidgetData('next_prayer_time', prayerTimes.getNextPrayerTime());
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

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}s ${minutes}dk kaldı';
    }
    return '${minutes}dk kaldı';
  }
}
