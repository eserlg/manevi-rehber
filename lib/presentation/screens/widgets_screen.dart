import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../data/models/prayer_times.dart';
import '../../data/models/quran.dart';
import '../providers/providers.dart';

class WidgetsScreen extends ConsumerWidget {
  const WidgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerTimes = ref.watch(prayerTimesProvider).valueOrNull;
    final verse = ref.watch(verseOfDayProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Widgetler'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF9FAF4),
              AppColors.background,
              Color(0xFFEAF3ED),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            children: [
              _buildIntroCard(context),
              const SizedBox(height: AppDimensions.spacingLG),
              _LockScreenPreview(prayerTimes: prayerTimes, verse: verse),
              const SizedBox(height: AppDimensions.spacingLG),
              _NotificationPreview(verse: verse),
              const SizedBox(height: AppDimensions.spacingLG),
              _HomeWidgetPreview(prayerTimes: prayerTimes, verse: verse),
              const SizedBox(height: AppDimensions.spacingLG),
              _buildPlatformCard(context, ref, prayerTimes, verse),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingLG),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.94),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.primary.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingMD),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: Icon(Icons.widgets_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: AppDimensions.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ekrana Hazır Widget Tasarımları',
                  style: GoogleFonts.notoSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  'Ayet, namaz vakti ve geri sayım odaklı sade tasarımlar.',
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    height: 1.35,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformCard(
    BuildContext context,
    WidgetRef ref,
    PrayerTimes? prayerTimes,
    Verse? verse,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingLG),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.primary.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Durum',
            style: GoogleFonts.notoSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSM),
          _StatusLine(
            icon: Icons.android,
            title: 'Android ana ekran widgetı',
            value: 'Hazır',
            color: AppColors.success,
          ),
          _StatusLine(
            icon: Icons.lock_outline,
            title: 'iOS kilit ekranı widgetı',
            value: 'Native paket aşaması',
            color: AppColors.accent,
          ),
          _StatusLine(
            icon: Icons.public,
            title: 'PWA kilit ekranı widgetı',
            value: 'Tarayıcı desteklemez',
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppDimensions.spacingMD),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: prayerTimes == null
                  ? null
                  : () async {
                      await ref
                          .read(prayerWidgetServiceProvider)
                          .updatePrayerTimes(
                            prayerTimes,
                            verseReference: verse == null
                                ? null
                                : '${verse.surahId}:${verse.verseKey}',
                            verseText: verse?.translation,
                          );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Android widget verisi güncellendi.'),
                        ),
                      );
                    },
              icon: const Icon(Icons.sync),
              label: const Text('Android widget verisini güncelle'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockScreenPreview extends StatelessWidget {
  final PrayerTimes? prayerTimes;
  final Verse? verse;

  const _LockScreenPreview({
    required this.prayerTimes,
    required this.verse,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final nextPrayer = prayerTimes?.getNextPrayer() ?? 'Yatsı';
    final nextTime = prayerTimes?.getNextPrayerTime() ?? '19:36';
    final countdown = prayerTimes == null
        ? '2:23:04'
        : _formatDuration(prayerTimes!.getTimeUntilNextPrayer());

    return _PreviewFrame(
      title: 'Kilit Ekranı',
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const _SkyMosqueBackground(),
              Container(color: Colors.black.withOpacity(0.10)),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _formatDateTitle(now),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSans(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSans(
                        fontSize: 72,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingLG),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${_verseReference(verse)}\n${_shortVerse(verse)}',
                            style: GoogleFonts.notoSans(
                              fontSize: 13,
                              height: 1.25,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacingMD),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$nextPrayer $nextTime',
                              style: GoogleFonts.notoSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              countdown,
                              style: GoogleFonts.notoSans(
                                fontSize: 24,
                                height: 1.05,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationPreview extends StatelessWidget {
  final Verse? verse;

  const _NotificationPreview({required this.verse});

  @override
  Widget build(BuildContext context) {
    return _PreviewFrame(
      title: 'Ayet Hatırlatması',
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingMD),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1B4D5C),
              Color(0xFF6D8EA0),
              Color(0xFFE8BE78),
            ],
          ),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spacingMD),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.mosque, color: Colors.white),
              ),
              const SizedBox(width: AppDimensions.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manevi Rehber',
                      style: GoogleFonts.notoSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${_shortVerse(verse)}\n-${_verseReference(verse)}',
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        height: 1.25,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'şimdi',
                style: GoogleFonts.notoSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeWidgetPreview extends StatelessWidget {
  final PrayerTimes? prayerTimes;
  final Verse? verse;

  const _HomeWidgetPreview({
    required this.prayerTimes,
    required this.verse,
  });

  @override
  Widget build(BuildContext context) {
    final nextPrayer = prayerTimes?.getNextPrayer() ?? 'Öğle';
    final nextTime = prayerTimes?.getNextPrayerTime() ?? '13:07';
    final countdown = prayerTimes == null
        ? '4s 37dk kaldı'
        : _formatDuration(prayerTimes!.getTimeUntilNextPrayer());

    return _PreviewFrame(
      title: 'Ana Ekran Widgetı',
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingLG),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryDark,
              AppColors.primary,
              AppColors.accent,
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$nextPrayer $nextTime',
                    style: GoogleFonts.notoSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    countdown,
                    style: GoogleFonts.notoSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.88),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingSM),
                  Text(
                    '${_verseReference(verse)} • ${_shortVerse(verse)}',
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      height: 1.3,
                      color: Colors.white.withOpacity(0.90),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spacingMD),
            Icon(Icons.wb_twilight,
                color: Colors.white.withOpacity(0.88), size: 42),
          ],
        ),
      ),
    );
  }
}

class _PreviewFrame extends StatelessWidget {
  final String title;
  final Widget child;

  const _PreviewFrame({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.notoSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingSM),
        child,
      ],
    );
  }
}

class _StatusLine extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatusLine({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingSM),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppDimensions.spacingSM),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.notoSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.notoSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkyMosqueBackground extends StatelessWidget {
  const _SkyMosqueBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SkyMosquePainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _SkyMosquePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0F4C91),
          Color(0xFF6FA8DC),
          Color(0xFFF0C36A),
          Color(0xFF27405D),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    final cloud = Paint()..color = Colors.white.withOpacity(0.28);
    for (var index = 0; index < 12; index += 1) {
      final x = (index * 58.0) % size.width;
      final y = size.height * (0.42 + (index % 4) * 0.07);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: 128,
          height: 42,
        ),
        cloud,
      );
    }

    final mosque = Paint()..color = const Color(0xFF102D3B).withOpacity(0.72);
    final baseTop = size.height * 0.68;
    final baseRect = Rect.fromLTWH(
      size.width * 0.20,
      baseTop,
      size.width * 0.60,
      size.height * 0.18,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(baseRect, const Radius.circular(18)),
      mosque,
    );

    final domeRect = Rect.fromCenter(
      center: Offset(size.width / 2, baseTop + 8),
      width: size.width * 0.38,
      height: size.height * 0.18,
    );
    canvas.drawArc(
        domeRect, math.pi, math.pi, false, mosque..style = PaintingStyle.fill);

    final minaretWidth = size.width * 0.035;
    for (final x in [size.width * 0.17, size.width * 0.83]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - minaretWidth / 2, size.height * 0.42, minaretWidth,
              size.height * 0.34),
          const Radius.circular(10),
        ),
        mosque,
      );
      final path = Path()
        ..moveTo(x, size.height * 0.34)
        ..lineTo(x - minaretWidth, size.height * 0.45)
        ..lineTo(x + minaretWidth, size.height * 0.45)
        ..close();
      canvas.drawPath(path, mosque);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String _formatDateTitle(DateTime date) {
  const months = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];
  const weekdays = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];
  return '${date.day} ${months[date.month - 1]} ${weekdays[date.weekday - 1]}';
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  final seconds = duration.inSeconds % 60;
  if (hours > 0) return '${hours}s ${minutes}dk';
  return '${minutes}dk ${seconds}sn';
}

String _verseReference(Verse? verse) {
  if (verse == null) return 'Bakara 2:152';
  return '${verse.surahId}:${verse.verseKey}';
}

String _shortVerse(Verse? verse) {
  final text = verse?.translation?.trim();
  if (text == null || text.isEmpty) {
    return 'Öyleyse yalnız beni anın ki ben de sizi anayım. Bana şükredin, sakın nankörlük etmeyin.';
  }
  return text.replaceAll(RegExp(r'\s+'), ' ');
}
