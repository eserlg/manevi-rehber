import 'package:flutter_tts/flutter_tts.dart';
import 'browser_speech_stub.dart'
    if (dart.library.js_interop) 'browser_speech_web.dart';

enum SpeechLanguage {
  arabic,
  turkish,
}

class TextToSpeechService {
  final FlutterTts _tts = FlutterTts();

  Future<bool> speak(String text, SpeechLanguage language) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return false;
    final rate = language == SpeechLanguage.arabic ? 0.36 : 0.44;

    final browserHandled =
        await speakWithBrowserSpeech(cleanText, language, rate);
    if (browserHandled) return true;

    try {
      await _tts.stop();
      await _tts.awaitSpeakCompletion(false);
      await _tts.setLanguage(_languageCode(language));
      await _tts.setSpeechRate(rate);
      await _tts.setVolume(1);
      await _tts.setPitch(1);
      await _tts.speak(cleanText);
      return true;
    } catch (_) {
      // Some browsers/devices may not expose the requested voice immediately.
      // Keep the app stable even if the local TTS engine cannot start.
      return false;
    }
  }

  Future<void> stop() async {
    stopBrowserSpeech();
    try {
      await _tts.stop();
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
}
