import 'package:flutter_tts/flutter_tts.dart';
import 'browser_speech_stub.dart'
    if (dart.library.js_interop) 'browser_speech_web.dart';

enum SpeechLanguage {
  arabic,
  turkish,
}

class TextToSpeechService {
  final FlutterTts _tts = FlutterTts();
  final Map<SpeechLanguage, Map<String, String>?> _voiceCache = {};
  bool _engineChecked = false;

  Future<bool> speak(String text, SpeechLanguage language) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return false;
    final rate = language == SpeechLanguage.arabic ? 0.44 : 0.50;

    final browserHandled =
        await speakWithBrowserSpeech(cleanText, language, rate);
    if (browserHandled) return true;

    try {
      await _tts.stop();
      await _tts.awaitSpeakCompletion(false);
      await _preferGoogleEngine();
      await _tts.setLanguage(_languageCode(language));
      final voice = await _selectBestVoice(language);
      if (voice != null) {
        await _tts.setVoice(voice);
      }
      await _tts.setSpeechRate(rate);
      await _tts.setVolume(1);
      await _tts.setPitch(language == SpeechLanguage.arabic ? 0.96 : 1.02);
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

  Future<void> _preferGoogleEngine() async {
    if (_engineChecked) return;
    _engineChecked = true;

    try {
      final engines = await _tts.getEngines;
      if (engines is! List) return;

      final googleEngine =
          engines.map((engine) => engine.toString()).firstWhere(
                (engine) => engine.toLowerCase().contains('google'),
                orElse: () => '',
              );

      if (googleEngine.isNotEmpty) {
        await _tts.setEngine(googleEngine);
      }
    } catch (_) {
      // Engine selection is Android-only on some devices.
    }
  }

  Future<Map<String, String>?> _selectBestVoice(
    SpeechLanguage language,
  ) async {
    if (_voiceCache.containsKey(language)) return _voiceCache[language];

    try {
      final voices = await _tts.getVoices;
      if (voices is! List) {
        _voiceCache[language] = null;
        return null;
      }

      final scoredVoices = <_ScoredVoice>[];
      for (final voice in voices) {
        if (voice is! Map) continue;

        final name = voice['name']?.toString() ??
            voice['voice']?.toString() ??
            voice['identifier']?.toString() ??
            '';
        final locale = voice['locale']?.toString() ??
            voice['language']?.toString() ??
            voice['lang']?.toString() ??
            '';

        if (name.isEmpty || locale.isEmpty) continue;

        final score = _voiceScore(
          name: name,
          locale: locale,
          language: language,
        );
        if (score >= 50) {
          scoredVoices.add(
            _ScoredVoice(
              score: score,
              voice: {
                'name': name,
                'locale': locale,
              },
            ),
          );
        }
      }

      scoredVoices.sort((a, b) => b.score.compareTo(a.score));
      final bestVoice = scoredVoices.isEmpty ? null : scoredVoices.first.voice;
      _voiceCache[language] = bestVoice;
      return bestVoice;
    } catch (_) {
      _voiceCache[language] = null;
      return null;
    }
  }

  int _voiceScore({
    required String name,
    required String locale,
    required SpeechLanguage language,
  }) {
    final target = _languageCode(language).toLowerCase();
    final targetPrefix = target.split('-').first;
    final voiceLocale = locale.toLowerCase().replaceAll('_', '-');
    final searchable = '$name $locale'.toLowerCase();
    var score = 0;

    if (voiceLocale == target) {
      score += 100;
    } else if (voiceLocale.startsWith(targetPrefix)) {
      score += 70;
    } else {
      return 0;
    }

    const qualityWords = [
      'natural',
      'neural',
      'enhanced',
      'premium',
      'online',
      'google',
      'microsoft',
      'apple',
      'siri',
    ];
    for (final word in qualityWords) {
      if (searchable.contains(word)) score += 10;
    }

    final preferredNames = switch (language) {
      SpeechLanguage.turkish => [
          'yelda',
          'emel',
          'filiz',
          'ahmet',
          'turkish',
          'türk',
        ],
      SpeechLanguage.arabic => [
          'maged',
          'majed',
          'zeina',
          'laila',
          'layla',
          'hoda',
          'naayf',
          'tarik',
          'salma',
          'mariam',
          'arabic',
          'العربية',
        ],
    };
    for (final namePart in preferredNames) {
      if (searchable.contains(namePart)) score += 12;
    }

    const roboticWords = ['compact', 'espeak', 'pico', 'robot'];
    for (final word in roboticWords) {
      if (searchable.contains(word)) score -= 20;
    }

    return score;
  }
}

class _ScoredVoice {
  final int score;
  final Map<String, String> voice;

  const _ScoredVoice({
    required this.score,
    required this.voice,
  });
}
