/// Zikr (remembrance of Allah) model
class Zikr {
  final String id;
  final String name;
  final String arabic;
  final String meaning;
  final int targetCount;
  final int currentCount;
  final String category;

  Zikr({
    required this.id,
    required this.name,
    required this.arabic,
    required this.meaning,
    required this.targetCount,
    this.currentCount = 0,
    this.category = 'default',
  });

  factory Zikr.subhanallah() {
    return Zikr(
      id: 'subhanallah',
      name: 'Subhanallah',
      arabic: 'سُبْحَانَ اللّٰهِ',
      meaning: 'Allah\'ı noksan sıfatlardan tenzih ederim',
      targetCount: 33,
      category: 'tesbih',
    );
  }

  factory Zikr.elhamdulillah() {
    return Zikr(
      id: 'elhamdulillah',
      name: 'Elhamdülillah',
      arabic: 'اَلْحَمْدُ لِلّٰهِ',
      meaning: 'Allah\'a hamd olsun',
      targetCount: 33,
      category: 'tesbih',
    );
  }

  factory Zikr.allahuEkber() {
    return Zikr(
      id: 'allahu_ekber',
      name: 'Allahu Ekber',
      arabic: 'اَللّٰهُ أَكْبَرُ',
      meaning: 'Allah en büyüktür',
      targetCount: 33,
      category: 'tesbih',
    );
  }

  factory Zikr.laIlheIllallah() {
    return Zikr(
      id: 'la_ilahe_illallah',
      name: 'La İlahe İllallah',
      arabic: 'لَا إِلٰهَ إِلَّا اللّٰهُ',
      meaning: 'Allah\'tan başka ilah yoktur',
      targetCount: 33,
      category: 'kelime',
    );
  }

  Zikr copyWith({
    String? id,
    String? name,
    String? arabic,
    String? meaning,
    int? targetCount,
    int? currentCount,
    String? category,
  }) {
    return Zikr(
      id: id ?? this.id,
      name: name ?? this.name,
      arabic: arabic ?? this.arabic,
      meaning: meaning ?? this.meaning,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      category: category ?? this.category,
    );
  }

  bool get isCompleted => currentCount >= targetCount;

  double get progress => currentCount / targetCount;

  static List<Zikr> get defaultZikirs => [
        Zikr.subhanallah(),
        Zikr.elhamdulillah(),
        Zikr.allahuEkber(),
        Zikr.laIlheIllallah(),
      ];
}
