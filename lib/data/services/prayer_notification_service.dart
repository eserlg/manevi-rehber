import 'dart:convert';

import '../models/prayer_times.dart';
import 'browser_notifications_stub.dart'
    if (dart.library.js_interop) 'browser_notifications_web.dart';

class PrayerNotificationService {
  Future<bool> requestPermission() async {
    final permission = await requestBrowserNotificationPermission();
    return permission == 'granted';
  }

  Future<bool> showTestNotification() async {
    final permission = await requestBrowserNotificationPermission();
    if (permission != 'granted') return false;
    return showBrowserTestNotification();
  }

  Future<bool> schedulePrayerNotifications({
    required PrayerTimes prayerTimes,
    required int leadMinutes,
    required bool enabled,
  }) async {
    if (!enabled) {
      clearBrowserPrayerNotifications();
      return true;
    }

    final notifications = _buildNotifications(prayerTimes, leadMinutes);
    if (notifications.isEmpty) return false;

    return scheduleBrowserPrayerNotifications(jsonEncode(notifications));
  }

  List<Map<String, String>> _buildNotifications(
    PrayerTimes prayerTimes,
    int leadMinutes,
  ) {
    final now = DateTime.now();
    final prayers = {
      'İmsak': prayerTimes.imsak,
      'Öğle': prayerTimes.ogle,
      'İkindi': prayerTimes.ikindi,
      'Akşam': prayerTimes.aksam,
      'Yatsı': prayerTimes.yatsi,
    };

    final notifications = <Map<String, String>>[];
    for (final entry in prayers.entries) {
      final time = _timeToday(entry.value);
      if (time == null) continue;

      var prayerDate = DateTime(
        now.year,
        now.month,
        now.day,
        time.$1,
        time.$2,
      );
      if (prayerDate.isBefore(now)) {
        prayerDate = prayerDate.add(const Duration(days: 1));
      }

      var notifyAt = prayerDate.subtract(Duration(minutes: leadMinutes));
      if (!notifyAt.isAfter(now)) {
        if (!prayerDate.isAfter(now)) continue;
        notifyAt = now.add(const Duration(seconds: 3));
      }

      notifications.add({
        'title': '${entry.key} namazı yaklaşıyor',
        'body': '${entry.key} vaktine $leadMinutes dakika kaldı.',
        'tag': 'prayer-${entry.key}',
        'notifyAt': notifyAt.toIso8601String(),
      });
    }

    return notifications;
  }

  (int, int)? _timeToday(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;

    return (hour, minute);
  }
}
