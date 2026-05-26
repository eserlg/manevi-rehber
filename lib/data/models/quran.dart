/// Quran surah model
class Surah {
  final int id;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final int numberOfAyahs;
  final String revelationType;

  Surah({
    required this.id,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.numberOfAyahs,
    required this.revelationType,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      id: json['id'] ?? 0,
      name: json['name_arabic'] ?? json['name'] ?? '',
      englishName: json['name_simple'] ?? json['english_name'] ?? '',
      englishNameTranslation: json['translated_name']?['name'] ?? json['english_name_translation'] ?? '',
      numberOfAyahs: json['number_of_verses'] ?? json['verses_count'] ?? 0,
      revelationType: json['revelation_type'] ?? json['type'] ?? '',
    );
  }
}

/// Quran verse model
class Verse {
  final int id;
  final int verseKey;
  final String text;
  final String? translation;
  final int surahId;
  final int juzId;
  final int pageId;

  Verse({
    required this.id,
    required this.verseKey,
    required this.text,
    this.translation,
    required this.surahId,
    this.juzId = 1,
    this.pageId = 1,
  });

  factory Verse.fromJson(Map<String, dynamic> json, int surahId) {
    return Verse(
      id: json['id'] ?? 0,
      verseKey: int.tryParse(json['verse_key']?.toString().split(':').last ?? '1') ?? 1,
      text: json['text_indopak'] ?? json['text'] ?? '',
      translation: json['translation'] ?? json['translated_text'],
      surahId: surahId,
      juzId: json['juz_id'] ?? 1,
      pageId: json['page_id'] ?? 1,
    );
  }
}
