/// Zikr (remembrance of Allah) model
class Zikr {
  final String id;
  final String name;
  final String arabic;
  final String meaning;
  final int targetCount;
  final int currentCount;
  final String category;
  final bool isCustom;

  Zikr({
    required this.id,
    required this.name,
    required this.arabic,
    required this.meaning,
    required this.targetCount,
    this.currentCount = 0,
    this.category = 'default',
    this.isCustom = false,
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

  factory Zikr.salavat() {
    return Zikr(
      id: 'sallallahu_aleyhi_ve_sellem',
      name: 'Sallallahu Aleyhi ve Sellem',
      arabic: 'صَلَّى اللّٰهُ عَلَيْهِ وَسَلَّمَ',
      meaning: 'Allah\'ın salât ve selâmı onun üzerine olsun',
      targetCount: 33,
      category: 'salavat',
    );
  }

  factory Zikr.estagfirullah() {
    return Zikr(
      id: 'estagfirullah',
      name: 'Estağfirullah',
      arabic: 'أَسْتَغْفِرُ اللّٰهَ',
      meaning: 'Allah\'tan bağışlanma dilerim',
      targetCount: 100,
      category: 'istigfar',
    );
  }

  factory Zikr.lahavle() {
    return Zikr(
      id: 'la_havle_ve_la_kuvvete_illa_billah',
      name: 'La Havle Vela Kuvvete İlla Billah',
      arabic: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللّٰهِ',
      meaning: 'Güç ve kuvvet yalnız Allah\'ındır',
      targetCount: 33,
      category: 'tesbih',
    );
  }

  factory Zikr.subhanallahiVeBihamdihi() {
    return Zikr(
      id: 'subhanallahi_ve_bihamdihi',
      name: 'Subhanallahi ve Bihamdihi',
      arabic: 'سُبْحَانَ اللّٰهِ وَبِحَمْدِهِ',
      meaning: 'Allah\'ı hamd ile tenzih ederim',
      targetCount: 100,
      category: 'tesbih',
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
    bool? isCustom,
  }) {
    return Zikr(
      id: id ?? this.id,
      name: name ?? this.name,
      arabic: arabic ?? this.arabic,
      meaning: meaning ?? this.meaning,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      category: category ?? this.category,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  bool get isCompleted => currentCount >= targetCount;

  int get completedCycles {
    if (targetCount <= 0) return 0;
    return currentCount ~/ targetCount;
  }

  double get progress {
    if (targetCount <= 0 || currentCount <= 0) return 0;
    final remainder = currentCount % targetCount;
    if (remainder == 0) return 1;
    return remainder / targetCount;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'arabic': arabic,
        'meaning': meaning,
        'targetCount': targetCount,
        'category': category,
        'isCustom': isCustom,
      };

  factory Zikr.fromJson(Map<String, dynamic> json) {
    return Zikr(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      arabic: json['arabic']?.toString() ?? '',
      meaning: json['meaning']?.toString() ?? '',
      targetCount: _asInt(json['targetCount']) ?? 33,
      category: json['category']?.toString() ?? 'custom',
      isCustom: json['isCustom'] == true,
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static List<Zikr> get defaultZikrs => [
        Zikr.subhanallah(),
        Zikr.elhamdulillah(),
        Zikr.allahuEkber(),
        Zikr.laIlheIllallah(),
        Zikr.salavat(),
        Zikr.estagfirullah(),
        Zikr.lahavle(),
        Zikr.subhanallahiVeBihamdihi(),
      ];
}