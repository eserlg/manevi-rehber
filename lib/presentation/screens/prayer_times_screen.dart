import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../data/models/prayer_tracking.dart';
import '../providers/providers.dart';
import '../widgets/prayer_card.dart';

class PrayerTimesScreen extends ConsumerStatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  ConsumerState<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends ConsumerState<PrayerTimesScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prayerTimesAsync = ref.watch(prayerTimesProvider);
    final city = ref.watch(currentCityProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Namaz Vakitleri'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(prayerTimesProvider),
          ),
        ],
      ),
      body: prayerTimesAsync.when(
        data: (prayerTimes) {
          if (prayerTimes == null) {
            return _buildErrorState();
          }
          return _buildContent(prayerTimes, city);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildErrorState(),
      ),
    );
  }

  Widget _buildContent(prayerTimes, String city) {
    final prayers = prayerTimes.allPrayers;
    final nextPrayer = prayerTimes.getNextPrayer();
    final timeUntilNextPrayer = prayerTimes.getTimeUntilNextPrayer();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(prayerTimesProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        children: [
          // Location Card
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingMD),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: AppColors.primary),
                const SizedBox(width: AppDimensions.spacingSM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        city,
                        style: GoogleFonts.notoSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        prayerTimes.date,
                        style: GoogleFonts.notoSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingMD,
                    vertical: AppDimensions.spacingSM,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  child: Text(
                    prayerTimes.hijriDate,
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingLG),

          // Next Prayer Highlight
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingLG),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sonraki Namaz',
                        style: GoogleFonts.notoSans(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingXS),
                      Text(
                        nextPrayer,
                        style: GoogleFonts.amiri(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        prayerTimes.getNextPrayerTime(),
                        style: GoogleFonts.amiri(
                          fontSize: 24,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingXS),
                      Text(
                        '$nextPrayer namazına ${_formatCountdown(timeUntilNextPrayer)} kaldı',
                        style: GoogleFonts.notoSans(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingMD),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.timer, color: Colors.white, size: 32),
                      const SizedBox(height: AppDimensions.spacingXS),
                      Text(
                        _formatCountdown(prayerTimes.getTimeUntilNextPrayer()),
                        style: GoogleFonts.notoSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingLG),

          _buildPrayerTrackingCard(),
          const SizedBox(height: AppDimensions.spacingLG),

          // All Prayer Times
          Text(
            'Tüm Vakitler',
            style: GoogleFonts.notoSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMD),

          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 420;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppDimensions.spacingMD,
                  mainAxisSpacing: AppDimensions.spacingMD,
                  childAspectRatio: compact ? 1.2 : 1.4,
                ),
                itemCount: prayers.length,
                itemBuilder: (context, index) {
                  final entry = prayers.entries.elementAt(index);
                  return PrayerCard(
                    title: entry.key,
                    time: entry.value,
                    isCurrent: entry.key == nextPrayer,
                    isNext: _isNextPrayer(
                      entry.key,
                      nextPrayer,
                      prayers.keys.toList(),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTrackingCard() {
    final tracking = ref.watch(prayerTrackingProvider);
    final prayedToday = tracking.prayedForDate(DateTime.now());
    final completed = tracking.completedForDate(DateTime.now());
    final progress = tracking.progressForDate(DateTime.now());
    final weeklyFullDays = tracking.completedDaysInLast(7);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingLG),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.primary.withOpacity(0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingSM),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Icon(Icons.task_alt, color: AppColors.primary),
              ),
              const SizedBox(width: AppDimensions.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bugünkü Namaz Takibi',
                      style: GoogleFonts.notoSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '$completed/5 tamamlandı • Son 7 günde $weeklyFullDays tam gün',
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _showQadaSheet,
                icon: const Icon(Icons.history),
                label: const Text('Kaza'),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMD),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceVariant,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMD),
          Wrap(
            spacing: AppDimensions.spacingSM,
            runSpacing: AppDimensions.spacingSM,
            children: PrayerTrackingState.trackablePrayers.map((prayer) {
              final selected = prayedToday.contains(prayer);
              return FilterChip(
                selected: selected,
                label: Text(_prayerDisplayName(prayer)),
                avatar: Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 18,
                ),
                selectedColor: AppColors.primary.withOpacity(0.16),
                checkmarkColor: AppColors.primary,
                onSelected: (_) {
                  ref.read(prayerTrackingProvider.notifier).toggleToday(prayer);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _showQadaSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLarge),
        ),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final tracking = ref.watch(prayerTrackingProvider);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.screenPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.history, color: AppColors.primary),
                        const SizedBox(width: AppDimensions.spacingSM),
                        Expanded(
                          child: Text(
                            'Kaza Namazı Takibi',
                            style: GoogleFonts.notoSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          'Toplam ${tracking.totalQadaDebt}',
                          style: GoogleFonts.notoSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingSM),
                    Text(
                      'Kılınan kazaları düşebilir, eksiklerini artırarak kişisel takip tutabilirsin. Veriler sadece cihazda saklanır.',
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingMD),
                    for (final prayer in PrayerTrackingState.trackablePrayers)
                      _buildQadaRow(ref, tracking, prayer),
                    const SizedBox(height: AppDimensions.spacingMD),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQadaRow(
    WidgetRef ref,
    PrayerTrackingState tracking,
    String prayer,
  ) {
    final value = tracking.qadaDebt[prayer] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingSM),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _prayerDisplayName(prayer),
              style: GoogleFonts.notoSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton.outlined(
            tooltip: 'Azalt',
            onPressed: value == 0
                ? null
                : () => ref
                    .read(prayerTrackingProvider.notifier)
                    .adjustQada(prayer, -1),
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 52,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Artır',
            onPressed: () =>
                ref.read(prayerTrackingProvider.notifier).adjustQada(prayer, 1),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  String _prayerDisplayName(String prayer) {
    return prayer == 'İmsak' ? 'Sabah' : prayer;
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppDimensions.spacingMD),
            Text(
              'Konum alınamadı',
              style: GoogleFonts.notoSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingSM),
            Text(
              'Lütfen konum iznini aktif edin',
              style: GoogleFonts.notoSans(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingLG),
            ElevatedButton(
              onPressed: () => ref.invalidate(prayerTimesProvider),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  bool _isNextPrayer(
      String current, String nextPrayer, List<String> allPrayers) {
    final currentIndex = allPrayers.indexOf(current);
    final nextIndex = allPrayers.indexOf(nextPrayer);

    if (nextIndex == 0) return currentIndex == allPrayers.length - 1;
    return currentIndex == (nextIndex - 1) % allPrayers.length;
  }

  String _formatCountdown(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}s ${minutes}dk';
    }
    return '${minutes}dk ${seconds}sn';
  }
}
