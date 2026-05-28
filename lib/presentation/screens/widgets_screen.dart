import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../data/models/prayer_times.dart';
import '../../data/models/quran.dart';
import '../../data/services/app_share_service.dart';
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
              _PrayerTimesStripPreview(prayerTimes: prayerTimes),
              const SizedBox(height: AppDimensions.spacingLG),
              _VersePostGallery(verse: verse),
              const SizedBox(height: AppDimensions.spacingLG),
              const _TasbihWidgetPreview(),
              const SizedBox(height: AppDimensions.spacingLG),
              const _QiblaMiniWidgetPreview(),
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
              const _PhotoMosqueBackground(),
              Container(color: Colors.black.withOpacity(0.18)),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x66112D3B),
                      Color(0x11112D3B),
                      Color(0xAA102D3B),
                    ],
                  ),
                ),
              ),
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
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: const Stack(
                  fit: StackFit.expand,
                  children: [
                    _PhotoMosqueBackground(),
                    DecoratedBox(
                      decoration: BoxDecoration(color: Color(0x77126C55)),
                    ),
                    Icon(Icons.mosque, color: Colors.white),
                  ],
                ),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          height: 168,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const _PhotoMosqueBackground(),
              Container(color: Colors.black.withOpacity(0.30)),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xDD0A4537),
                      Color(0x99126C55),
                      Color(0x66B98B2E),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppDimensions.spacingLG),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _PrayerTimesStripPreview extends StatelessWidget {
  final PrayerTimes? prayerTimes;

  const _PrayerTimesStripPreview({required this.prayerTimes});

  @override
  Widget build(BuildContext context) {
    final nextPrayer = prayerTimes?.getNextPrayer() ?? 'Öğle';
    final nextTime = prayerTimes?.getNextPrayerTime() ?? '13:07';
    final prayers = [
      ('İmsak', prayerTimes?.imsak ?? '03:42'),
      ('Güneş', prayerTimes?.gunes ?? '05:32'),
      ('Öğle', prayerTimes?.ogle ?? '13:08'),
      ('İkindi', prayerTimes?.ikindi ?? '17:03'),
      ('Akşam', prayerTimes?.aksam ?? '20:30'),
      ('Yatsı', prayerTimes?.yatsi ?? '22:13'),
    ];

    return _PreviewFrame(
      title: 'Vakit Şeridi',
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingMD),
        decoration: BoxDecoration(
          color: const Color(0xFF0E6F59),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.18),
              blurRadius: 22,
              offset: const Offset(0, 12),
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
                    color: Colors.white.withOpacity(0.14),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  child: const Icon(Icons.schedule, color: Colors.white),
                ),
                const SizedBox(width: AppDimensions.spacingSM),
                Expanded(
                  child: Text(
                    '$nextPrayer $nextTime',
                    style: GoogleFonts.notoSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  _formatDuration(
                    prayerTimes?.getTimeUntilNextPrayer() ??
                        const Duration(hours: 2, minutes: 23),
                  ),
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withOpacity(0.88),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingMD),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final prayer in prayers)
                    Container(
                      width: 74,
                      margin: const EdgeInsets.only(
                        right: AppDimensions.spacingSM,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingSM,
                        vertical: AppDimensions.spacingSM,
                      ),
                      decoration: BoxDecoration(
                        color: prayer.$1 == nextPrayer
                            ? Colors.white.withOpacity(0.22)
                            : Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.14),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            prayer.$1,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.notoSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withOpacity(0.82),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            prayer.$2,
                            style: GoogleFonts.notoSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VersePostGallery extends StatelessWidget {
  final Verse? verse;

  const _VersePostGallery({required this.verse});

  @override
  Widget build(BuildContext context) {
    final items = [
      if (verse != null) _verseItemFromDaily(verse),
      ..._curatedWidgetVerses,
    ];

    return _PreviewFrame(
      title: 'Paylaşımlık Ayet Kartları',
      child: SizedBox(
        height: 292,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) =>
              const SizedBox(width: AppDimensions.spacingMD),
          itemBuilder: (context, index) {
            final item = items[index];
            return SizedBox(
              width: 228,
              child: _VersePostCard(
                item: item,
                palette: _postPalettes[index % _postPalettes.length],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _VersePostCard extends StatelessWidget {
  final _WidgetVerse item;
  final _PostPalette palette;

  const _VersePostCard({
    required this.item,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _WidgetArtBackground(style: palette.artStyle),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: palette.colors,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.reference,
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Text(
                  item.text,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSans(
                    fontSize: 17,
                    height: 1.22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingMD),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Manevi Rehber',
                        style: GoogleFonts.notoSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withOpacity(0.82),
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Paylaş',
                      onPressed: () => _shareWidgetVerse(context, item),
                      icon: const Icon(Icons.ios_share, size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.88),
                        foregroundColor: palette.actionColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TasbihWidgetPreview extends StatelessWidget {
  const _TasbihWidgetPreview();

  @override
  Widget build(BuildContext context) {
    return _PreviewFrame(
      title: 'Tesbih Widgetı',
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(AppDimensions.spacingLG),
        decoration: BoxDecoration(
          color: const Color(0xFFF8EFE0),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFD8B66B).withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0E6F59),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0E6F59).withOpacity(0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingLG),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subhanallah',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(
                    '126 zikir • 3 tur',
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingSM),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: const LinearProgressIndicator(
                      minHeight: 8,
                      value: 0.82,
                      backgroundColor: Colors.white,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF0E6F59)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QiblaMiniWidgetPreview extends StatelessWidget {
  const _QiblaMiniWidgetPreview();

  @override
  Widget build(BuildContext context) {
    return _PreviewFrame(
      title: 'Kıble Kısayolu',
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(AppDimensions.spacingLG),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFE8F3EE), Color(0xFFFFF4D8)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.primary.withOpacity(0.16)),
        ),
        child: Row(
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: AppColors.primary.withOpacity(0.20)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.explore,
                    color: AppColors.primary,
                    size: 44,
                  ),
                  Transform.translate(
                    offset: const Offset(16, -20),
                    child: Icon(
                      Icons.mosque,
                      color: AppColors.accent,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spacingLG),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kıble Bulucu',
                    style: GoogleFonts.notoSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(
                    '150.8° • Güneydoğu',
                    style: GoogleFonts.notoSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WidgetArtBackground extends StatelessWidget {
  final int style;

  const _WidgetArtBackground({required this.style});

  @override
  Widget build(BuildContext context) {
    if (style == 0) return const _PhotoMosqueBackground();

    return CustomPaint(
      painter: _WidgetArtPainter(style),
      child: const SizedBox.expand(),
    );
  }
}

class _WidgetArtPainter extends CustomPainter {
  final int style;

  const _WidgetArtPainter(this.style);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final basePalettes = [
      [const Color(0xFF163B4B), const Color(0xFF427B83)],
      [const Color(0xFF7A5A2B), const Color(0xFFDEC27A)],
      [const Color(0xFF0A2C39), const Color(0xFF155D52)],
      [const Color(0xFF0E4E43), const Color(0xFFB88D38)],
      [const Color(0xFF314A62), const Color(0xFFE0B86A)],
    ];
    final colors = basePalettes[(style - 1) % basePalettes.length];
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ).createShader(rect),
    );

    switch (style) {
      case 1:
        _paintArchSunrise(canvas, size);
        break;
      case 2:
        _paintKaaba(canvas, size);
        break;
      case 3:
        _paintNightDome(canvas, size);
        break;
      case 4:
        _paintGeometric(canvas, size);
        break;
      default:
        _paintMinaretSky(canvas, size);
    }
  }

  void _paintArchSunrise(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width * 0.76, size.height * 0.24),
      44,
      Paint()..color = Colors.white.withOpacity(0.16),
    );
    final arch = Path()
      ..moveTo(size.width * 0.18, size.height)
      ..lineTo(size.width * 0.18, size.height * 0.50)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.08,
        size.width * 0.82,
        size.height * 0.50,
      )
      ..lineTo(size.width * 0.82, size.height)
      ..close();
    canvas.drawPath(arch, Paint()..color = Colors.white.withOpacity(0.18));
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.70, size.width, size.height * 0.30),
      Paint()..color = Colors.black.withOpacity(0.10),
    );
  }

  void _paintKaaba(Canvas canvas, Size size) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.52, size.height * 0.78),
        width: size.width * 0.62,
        height: 28,
      ),
      Paint()..color = Colors.black.withOpacity(0.16),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.32,
          size.height * 0.42,
          size.width * 0.40,
          size.height * 0.34,
        ),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFF111111),
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.32,
        size.height * 0.50,
        size.width * 0.40,
        10,
      ),
      Paint()..color = const Color(0xFFD6AC45),
    );
    final starPaint = Paint()..color = Colors.white.withOpacity(0.42);
    for (final point in [
      Offset(size.width * 0.18, size.height * 0.20),
      Offset(size.width * 0.62, size.height * 0.18),
      Offset(size.width * 0.80, size.height * 0.32),
      Offset(size.width * 0.24, size.height * 0.35),
    ]) {
      canvas.drawCircle(point, 2.3, starPaint);
    }
  }

  void _paintNightDome(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.20),
      22,
      Paint()..color = const Color(0xFFF8E7A0),
    );
    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.16),
      22,
      Paint()..color = const Color(0xFF0A2C39),
    );
    final mosquePaint = Paint()..color = Colors.white.withOpacity(0.22);
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.22,
        size.height * 0.52,
        size.width * 0.56,
        size.height * 0.34,
      ),
      3.14,
      3.14,
      true,
      mosquePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.18,
        size.height * 0.68,
        size.width * 0.64,
        size.height * 0.22,
      ),
      mosquePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.16,
        size.height * 0.38,
        10,
        size.height * 0.50,
      ),
      mosquePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.84,
        size.height * 0.34,
        10,
        size.height * 0.54,
      ),
      mosquePaint,
    );
  }

  void _paintGeometric(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.20)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (var x = -size.height; x < size.width; x += 28) {
      canvas.drawLine(
          Offset(x, 0), Offset(x + size.height, size.height), linePaint);
      canvas.drawLine(
          Offset(x + size.height, 0), Offset(x, size.height), linePaint);
    }
    for (var x = 26.0; x < size.width; x += 58) {
      for (var y = 32.0; y < size.height; y += 58) {
        canvas.drawCircle(
            Offset(x, y), 11, Paint()..color = Colors.white.withOpacity(0.10));
        canvas.drawCircle(
            Offset(x, y), 4, Paint()..color = Colors.white.withOpacity(0.20));
      }
    }
  }

  void _paintMinaretSky(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.28),
      46,
      Paint()..color = const Color(0xFFFFD98C).withOpacity(0.74),
    );
    final silhouette = Paint()..color = Colors.black.withOpacity(0.20);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.16,
        size.height * 0.34,
        15,
        size.height * 0.58,
      ),
      silhouette,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.135, size.height * 0.34)
        ..lineTo(size.width * 0.19, size.height * 0.18)
        ..lineTo(size.width * 0.245, size.height * 0.34)
        ..close(),
      silhouette,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.56,
        size.height * 0.52,
        size.width * 0.24,
        size.height * 0.30,
      ),
      silhouette,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.50,
        size.height * 0.38,
        size.width * 0.36,
        size.height * 0.32,
      ),
      3.14,
      3.14,
      true,
      silhouette,
    );
  }

  @override
  bool shouldRepaint(covariant _WidgetArtPainter oldDelegate) {
    return oldDelegate.style != style;
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

class _PhotoMosqueBackground extends StatelessWidget {
  const _PhotoMosqueBackground();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/mosque_widget_background.jpg',
      fit: BoxFit.cover,
      alignment: Alignment.center,
    );
  }
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

_WidgetVerse _verseItemFromDaily(Verse? verse) {
  if (verse == null || (verse.translation ?? '').trim().isEmpty) {
    return _curatedWidgetVerses.first;
  }

  return _WidgetVerse(
    reference: '${verse.surahId}:${verse.verseKey}',
    text: verse.translation!.trim().replaceAll(RegExp(r'\s+'), ' '),
  );
}

Future<void> _shareWidgetVerse(BuildContext context, _WidgetVerse item) {
  return AppShareService.shareText(
    context: context,
    subject: 'Manevi Rehber ayet kartı',
    text: '${item.reference}\n\n${item.text}\n\nManevi Rehber',
  );
}

class _WidgetVerse {
  final String reference;
  final String text;

  const _WidgetVerse({
    required this.reference,
    required this.text,
  });
}

class _PostPalette {
  final List<Color> colors;
  final Color actionColor;
  final int artStyle;

  const _PostPalette({
    required this.colors,
    required this.actionColor,
    required this.artStyle,
  });
}

const _postPalettes = [
  _PostPalette(
    colors: [Color(0xDD073E34), Color(0xAA0E6F59), Color(0x88956F25)],
    actionColor: Color(0xFF0E6F59),
    artStyle: 0,
  ),
  _PostPalette(
    colors: [Color(0xDD153447), Color(0xAA2B6B73), Color(0x889C7B38)],
    actionColor: Color(0xFF153447),
    artStyle: 1,
  ),
  _PostPalette(
    colors: [Color(0xDD5A3F20), Color(0xAA98733A), Color(0x881B4D5C)],
    actionColor: Color(0xFF5A3F20),
    artStyle: 2,
  ),
  _PostPalette(
    colors: [Color(0xDD092B35), Color(0xAA126C55), Color(0x881F5164)],
    actionColor: Color(0xFF0A2C39),
    artStyle: 3,
  ),
  _PostPalette(
    colors: [Color(0xDD0B5C4D), Color(0xAA8C742D), Color(0x8813473E)],
    actionColor: Color(0xFF0E4E43),
    artStyle: 4,
  ),
  _PostPalette(
    colors: [Color(0xDD253C54), Color(0xAA5D7F88), Color(0x88B88D38)],
    actionColor: Color(0xFF314A62),
    artStyle: 5,
  ),
];

const _curatedWidgetVerses = [
  _WidgetVerse(
    reference: 'Bakara 2:152',
    text:
        'Öyleyse yalnız beni anın ki ben de sizi anayım. Bana şükredin, sakın nankörlük etmeyin.',
  ),
  _WidgetVerse(
    reference: 'Ra’d 13:28',
    text: 'Bilesiniz ki kalpler ancak Allah’ı anmakla huzur bulur.',
  ),
  _WidgetVerse(
    reference: 'İnşirah 94:5-6',
    text: 'Şüphesiz güçlükle beraber bir kolaylık vardır.',
  ),
  _WidgetVerse(
    reference: 'Zümer 39:53',
    text: 'Allah’ın rahmetinden ümidinizi kesmeyin.',
  ),
  _WidgetVerse(
    reference: 'Duha 93:5',
    text: 'Rabbin sana verecek ve sen hoşnut olacaksın.',
  ),
  _WidgetVerse(
    reference: 'Talak 65:3',
    text: 'Kim Allah’a tevekkül ederse Allah ona yeter.',
  ),
];
