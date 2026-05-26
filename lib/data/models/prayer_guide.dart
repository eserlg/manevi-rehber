class PrayerGuide {
  final String id;
  final String category;
  final String title;
  final String subtitle;
  final String totalRakat;
  final String shortDescription;
  final List<String> highlights;
  final List<PrayerGuideSection> sections;

  const PrayerGuide({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.totalRakat,
    required this.shortDescription,
    required this.highlights,
    required this.sections,
  });

  factory PrayerGuide.fromJson(Map<String, dynamic> json) {
    return PrayerGuide(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? 'genel',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      totalRakat: json['totalRakat']?.toString() ?? '',
      shortDescription: json['shortDescription']?.toString() ?? '',
      highlights: (json['highlights'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      sections: (json['sections'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((item) => PrayerGuideSection.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
    );
  }

  String get categoryLabel {
    switch (category) {
      case 'gunluk':
        return 'Günlük';
      case 'cuma':
        return 'Cuma';
      case 'cemaat':
        return 'Cemaat';
      case 'ozel':
        return 'Özel';
      case 'cenaze':
        return 'Cenaze';
      case 'nafile':
        return 'Nafile';
      default:
        return 'Genel';
    }
  }
}

class PrayerGuideSection {
  final String title;
  final String body;
  final List<String> items;

  const PrayerGuideSection({
    required this.title,
    required this.body,
    required this.items,
  });

  factory PrayerGuideSection.fromJson(Map<String, dynamic> json) {
    return PrayerGuideSection(
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}
