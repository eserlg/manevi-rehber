class OccasionMessage {
  final String id;
  final String category;
  final String title;
  final String text;

  const OccasionMessage({
    required this.id,
    required this.category,
    required this.title,
    required this.text,
  });

  factory OccasionMessage.fromJson(Map<String, dynamic> json) {
    return OccasionMessage(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? 'genel',
      title: json['title']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
    );
  }

  String get categoryLabel {
    switch (category) {
      case 'bayram':
        return 'Bayram';
      case 'kandil':
        return 'Kandil';
      case 'cuma':
        return 'Cuma';
      default:
        return 'Genel';
    }
  }
}
