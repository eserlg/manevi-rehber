class PrayerTrackingState {
  static const trackablePrayers = ['İmsak', 'Öğle', 'İkindi', 'Akşam', 'Yatsı'];

  final Map<String, Set<String>> prayedByDate;
  final Map<String, int> qadaDebt;

  const PrayerTrackingState({
    required this.prayedByDate,
    required this.qadaDebt,
  });

  factory PrayerTrackingState.empty() {
    return PrayerTrackingState(
      prayedByDate: const {},
      qadaDebt: {
        for (final prayer in trackablePrayers) prayer: 0,
      },
    );
  }

  Set<String> prayedForDate(DateTime date) {
    return prayedByDate[_dateKey(date)] ?? <String>{};
  }

  int completedForDate(DateTime date) {
    return prayedForDate(date).where(trackablePrayers.contains).length;
  }

  double progressForDate(DateTime date) {
    return completedForDate(date) / trackablePrayers.length;
  }

  int get totalQadaDebt {
    return qadaDebt.values.fold(0, (sum, value) => sum + value);
  }

  int completedDaysInLast(int days) {
    final today = DateTime.now();
    var count = 0;

    for (var index = 0; index < days; index += 1) {
      final date = today.subtract(Duration(days: index));
      if (completedForDate(date) == trackablePrayers.length) {
        count += 1;
      }
    }

    return count;
  }

  PrayerTrackingState copyWith({
    Map<String, Set<String>>? prayedByDate,
    Map<String, int>? qadaDebt,
  }) {
    return PrayerTrackingState(
      prayedByDate: prayedByDate ?? this.prayedByDate,
      qadaDebt: qadaDebt ?? this.qadaDebt,
    );
  }

  static String dateKey(DateTime date) => _dateKey(date);

  static String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
