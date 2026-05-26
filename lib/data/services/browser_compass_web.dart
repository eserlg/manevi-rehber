import 'dart:js_interop';

@JS('ruhHuzurRequestOrientationPermission')
external JSPromise<JSString> _requestOrientationPermission();

@JS('ruhHuzurStartCompass')
external JSBoolean _startCompass(JSFunction callback);

@JS('ruhHuzurStopCompass')
external void _stopCompass();

JSFunction? _headingCallback;

Future<String> requestBrowserCompassPermission() async {
  try {
    final result = await _requestOrientationPermission().toDart;
    return result.toDart;
  } catch (_) {
    return 'denied';
  }
}

bool startBrowserCompass(void Function(double heading) onHeading) {
  try {
    _headingCallback = ((JSNumber heading) {
      onHeading(heading.toDartDouble);
    }).toJS;
    return _startCompass(_headingCallback!).toDart;
  } catch (_) {
    return false;
  }
}

void stopBrowserCompass() {
  try {
    _stopCompass();
  } catch (_) {}
}
