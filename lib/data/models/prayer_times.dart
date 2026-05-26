/// Prayer times model
class PrayerTimes {
  final String imsak;
  final String gunes;
  final String ogle;
  final String ikindi;
  final String aksam;
  final String yatsi;
  final String date;
  final String hijriDate;
  final String city;
  final double latitude;
  final double longitude;

  PrayerTimes({
    required this.imsak,
    required this.gunes,
    required this.ogle,
    required this.ikindi,
    required this.aksam,
    required this.yatsi,
    required this.date,
    required this.hijriDate,
    required this.city,
    required this.latitude,
    required this.longitude,
  });

  factory PrayerTimes.fromJson(Map<String, dynamic> json, String city, double lat, double lng) {
    final timings = json['data']['timings'];
    final dateInfo = json['data']['date'];
    final hijriMonthNumber = dateInfo['hijri']['month']['number'] ?? 1;
    final hijriMonthName = _hijriMonthName(hijriMonthNumber);
    
    return PrayerTimes(
      imsak: timings['Imsak'] ?? '00:00',
      gunes: timings['Sunrise'] ?? '00:00',
      ogle: timings['Dhuhr'] ?? '00:00',
      ikindi: timings['Asr'] ?? '00:00',
      aksam: timings['Maghrib'] ?? '00:00',
      yatsi: timings['Isha'] ?? '00:00',
      date: dateInfo['readable'] ?? '',
      hijriDate: '${dateInfo['hijri']['day']} $hijriMonthName ${dateInfo['hijri']['year']}',
      city: city,
      latitude: lat,
      longitude: lng,
    );
  }

  static String _hijriMonthName(int month) {
    const months = [
      'Muharrem',
      'Safer',
      'Rebiülevvel',
      'Rebiülahir',
      'Cemaziyelevvel',
      'Cemaziyelahir',
      'Receb',
      'Şaban',
      'Ramazan',
      'Şevval',
      'Zilkade',
      'Zilhicce',
    ];
    if (month < 1 || month > months.length) return '';
    return months[month - 1];
  }

  Map<String, String> get allPrayers => {
    'İmsak': imsak,
    'Güneş': gunes,
    'Öğle': ogle,
    'İkindi': ikindi,
    'Akşam': aksam,
    'Yatsı': yatsi,
  };

  String getNextPrayer() {
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    final prayers = [
      ('İmsak', imsak),
      ('Güneş', gunes),
      ('Öğle', ogle),
      ('İkindi', ikindi),
      ('Akşam', aksam),
      ('Yatsı', yatsi),
    ];

    for (final prayer in prayers) {
      if (_compareTimes(currentTime, prayer.$2) < 0) {
        return prayer.$1;
      }
    }
    
    return 'İmsak'; // Next day
  }

  String getNextPrayerTime() {
    final nextPrayer = getNextPrayer();
    switch (nextPrayer) {
      case 'İmsak': return imsak;
      case 'Güneş': return gunes;
      case 'Öğle': return ogle;
      case 'İkindi': return ikindi;
      case 'Akşam': return aksam;
      case 'Yatsı': return yatsi;
      default: return imsak;
    }
  }

  int _compareTimes(String time1, String time2) {
    final t1 = time1.split(':');
    final t2 = time2.split(':');
    final h1 = int.parse(t1[0]);
    final h2 = int.parse(t2[0]);
    final m1 = int.parse(t1[1]);
    final m2 = int.parse(t2[1]);
    return (h1 * 60 + m1) - (h2 * 60 + m2);
  }

  Duration getTimeUntilNextPrayer() {
    final now = DateTime.now();
    final nextTime = getNextPrayerTime();
    final parts = nextTime.split(':');
    var nextDateTime = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
    
    if (nextDateTime.isBefore(now)) {
      nextDateTime = nextDateTime.add(const Duration(days: 1));
    }
    
    return nextDateTime.difference(now);
  }
}
