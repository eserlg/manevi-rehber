import 'dart:js_interop';
import 'text_to_speech_service.dart';

@JS('ruhHuzurSpeak')
external JSPromise<JSAny?> _ruhHuzurSpeak(
  JSString text,
  JSString language,
  JSNumber rate,
);

@JS('ruhHuzurStopSpeech')
external void _ruhHuzurStopSpeech();

Future<bool> speakWithBrowserSpeech(
  String text,
  SpeechLanguage language,
  double rate,
) async {
  try {
    await _ruhHuzurSpeak(
      text.toJS,
      _languageCode(language).toJS,
      rate.toJS,
    ).toDart;
    return true;
  } catch (_) {
    return false;
  }
}

void stopBrowserSpeech() {
  try {
    _ruhHuzurStopSpeech();
  } catch (_) {}
}

String _languageCode(SpeechLanguage language) {
  switch (language) {
    case SpeechLanguage.arabic:
      return 'ar-SA';
    case SpeechLanguage.turkish:
      return 'tr-TR';
  }
}
