/// Daily prayer model
class Prayer {
  final String id;
  final String title;
  final String arabic;
  final String turkish;
  final String meaning;
  final String category;
  final bool isFavorite;
  final String? description;

  Prayer({
    required this.id,
    required this.title,
    required this.arabic,
    required this.turkish,
    required this.meaning,
    required this.category,
    this.isFavorite = false,
    this.description,
  });

  factory Prayer.fromJson(Map<String, dynamic> json) {
    return Prayer(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      arabic: json['arabic'] ?? '',
      turkish: json['turkish'] ?? '',
      meaning: json['meaning'] ?? '',
      category: json['category'] ?? 'general',
      isFavorite: json['isFavorite'] ?? false,
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'arabic': arabic,
      'turkish': turkish,
      'meaning': meaning,
      'category': category,
      'isFavorite': isFavorite,
      'description': description,
    };
  }

  Prayer copyWith({
    String? id,
    String? title,
    String? arabic,
    String? turkish,
    String? meaning,
    String? category,
    bool? isFavorite,
    String? description,
  }) {
    return Prayer(
      id: id ?? this.id,
      title: title ?? this.title,
      arabic: arabic ?? this.arabic,
      turkish: turkish ?? this.turkish,
      meaning: meaning ?? this.meaning,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      description: description ?? this.description,
    );
  }
}
