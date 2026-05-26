import 'dart:js_interop';

@JS('ruhHuzurRequestNotificationPermission')
external JSPromise<JSString> _requestNotificationPermission();

@JS('ruhHuzurSchedulePrayerNotifications')
external JSBoolean _schedulePrayerNotifications(JSString payloadJson);

@JS('ruhHuzurClearPrayerNotifications')
external void _clearPrayerNotifications();

Future<String> requestBrowserNotificationPermission() async {
  try {
    final result = await _requestNotificationPermission().toDart;
    return result.toDart;
  } catch (_) {
    return 'denied';
  }
}

Future<bool> scheduleBrowserPrayerNotifications(String payloadJson) async {
  try {
    return _schedulePrayerNotifications(payloadJson.toJS).toDart;
  } catch (_) {
    return false;
  }
}

void clearBrowserPrayerNotifications() {
  try {
    _clearPrayerNotifications();
  } catch (_) {}
}
