import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../core/theme/app_themes.dart';
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
    final widgetVerses = ref.watch(widgetVersesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Widgetler'),
        actions: [
          IconButton(
            tooltip: 'Ayetleri yenile',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(widgetVersesProvider.notifier).rotate(verse);
              ref.invalidate(verseOfDayProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Ayetler yenilendi'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              AppColors.surface,
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(verseOfDayProvider);
              ref.read(widgetVersesProvider.notifier).rotate(verse);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppDimensions.screenPadding),
              children: [
                _buildIntroCard(context),
                const SizedBox(height: AppDimensions.spacingLG),
                _LockScreenPreview(
                  prayerTimes: prayerTimes,
                  verse: widgetVerses.isNotEmpty ? widgetVerses[0] : null,
                ),
                const SizedBox(height: AppDimensions.spacingLG),
                _NotificationPreview(
                  verse: widgetVerses.length > 1 ? widgetVerses[1] : null,
                ),
                const SizedBox(height: AppDimensions.spacingLG),
                _HomeWidgetPreview(
                  prayerTimes: prayerTimes,
                  verse: widgetVerses.length > 2 ? widgetVerses[2] : null,
                ),
                const SizedBox(height: AppDimensions.spacingLG),
                _PrayerTimesStripPreview(prayerTimes: prayerTimes),
                const SizedBox(height: AppDimensions.spacingLG),
                _VersePostGallery(verses: widgetVerses),
                const SizedBox(height: AppDimensions.spacingLG),
const _TasbihWidgetPreview(),
                const SizedBox(height: AppDimensions.spacingLG),
                const _QiblaMiniWidgetPreview(),
                const SizedBox(height: AppDimensions.spacingLG),
                _buildThemeGalleryPreview(context, ref),
                const SizedBox(height: AppDimensions.spacingLG),
                _buildPlatformCard(context, ref, prayerTimes, verse),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeGalleryPreview(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeModeProvider);

    return _PreviewFrame(
      title: 'Tema Galeri',
      child: SizedBox(
        height: 140,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: AppThemeMode.values.length,
          separatorBuilder: (_, __) =>
              const SizedBox(width: AppDimensions.spacingMD),
          itemBuilder: (context, index) {
            final mode = AppThemeMode.values[index];
            final colors = AppThemes.colors(mode);
            final selected = mode == currentMode;
            return GestureDetector(
              onTap: () async {
                ref.read(themeModeProvider.notifier).state = mode;
                await ref.read(localStorageProvider).setThemeMode(mode.name);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('${AppThemes.label(mode)} teması uygulandı'),
                    backgroundColor: colors.primary,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: SizedBox(
                width: 200,
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusLarge),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colors.gradientStart,
                              colors.gradientEnd,
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              AppThemes.icon(mode),
                              color: colors.primaryDark,
                              size: 28,
                            ),
                            const Spacer(),
                            Text(
                              AppThemes.label(mode),
                              style: GoogleFonts.notoSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                              ),
                            ),
                            Text(
                              AppThemes.subtitle(mode),
                              style: GoogleFonts.notoSans(
                                fontSize: 11,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selected)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Icon(
                            Icons.check_circle,
                            color: colors.primary,
                            size: 22,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
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
  final WidgetVerse? verse;

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
              const _WidgetPhotoBackground(
                assetPath: 'assets/images/widget_blue_mosque.jpg',
              ),
              Container(color: Colors.black.withOpacity(0.18)),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0x80112D3B),
                      const Color(0x20112D3B),
                      const Color(0xB3102D3B),
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
  final WidgetVerse? verse;

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
                    const _WidgetPhotoBackground(
                      assetPath: 'assets/images/widget_quran.jpg',
                    ),
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
  final WidgetVerse? verse;

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
              const _WidgetPhotoBackground(
                assetPath: 'assets/images/widget_kaaba.jpg',
              ),
              Container(color: Colors.black.withOpacity(0.30)),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color(0xEE0A4537),
                      const Color(0xAA126C55),
                      const Color(0x77B98B2E),
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
  final List<WidgetVerse> verses;

  const _VersePostGallery({required this.verses});

  @override
  Widget build(BuildContext context) {
    final items = verses.take(8).toList();

    if (items.isEmpty) {
      return _PreviewFrame(
        title: 'Paylaşımlık Ayet Kartları',
        child: Container(
          height: 292,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.94),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            border: Border.all(color: AppColors.primary.withOpacity(0.14)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported_outlined,
                  color: AppColors.textSecondary, size: 40),
              const SizedBox(height: AppDimensions.spacingSM),
              Text(
                'Ayet kartları yüklenemedi',
                style: GoogleFonts.notoSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

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
  final WidgetVerse item;
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
          _WidgetArtBackground(
            assetPath: palette.assetPath,
            fallbackStyle: palette.fallbackStyle,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: palette.colors,
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.06),
                    Colors.black.withOpacity(0.38),
                  ],
                ),
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
  final String? assetPath;
  final int fallbackStyle;

  const _WidgetArtBackground({
    this.assetPath,
    this.fallbackStyle = 1,
  });

  @override
  Widget build(BuildContext context) {
    if (assetPath != null && assetPath!.isNotEmpty) {
      return _WidgetPhotoBackground(assetPath: assetPath!);
    }

    return CustomPaint(
      painter: _WidgetArtPainter(fallbackStyle),
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

class _WidgetPhotoBackground extends StatelessWidget {
  final String assetPath;

  const _WidgetPhotoBackground({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (context, error, stackTrace) => _fallbackGradient(),
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return _fallbackGradient();
      },
    );
  }

  Widget _fallbackGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF163B4B), Color(0xFF427B83)],
        ),
      ),
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

String _verseReference(WidgetVerse? verse) {
  if (verse == null) return 'Bakara 2:152';
  return verse.reference;
}

String _shortVerse(WidgetVerse? verse) {
  final text = verse?.text.trim();
  if (text == null || text.isEmpty) {
    return 'Öyleyse yalnız beni anın ki ben de sizi anayım. Bana şükredin, sakın nankörlük etmeyin.';
  }
  return text;
}

Future<void> _shareWidgetVerse(BuildContext context, WidgetVerse item) {
  return AppShareService.shareText(
    context: context,
    subject: 'Manevi Rehber ayet kartı',
    text: '${item.reference}\n\n${item.text}\n\nManevi Rehber',
  );
}

class _PostPalette {
  final List<Color> colors;
  final Color actionColor;
  final String? assetPath;
  final int fallbackStyle;

  const _PostPalette({
    required this.colors,
    required this.actionColor,
    this.assetPath,
    this.fallbackStyle = 1,
  });
}

const _postPalettes = [
  _PostPalette(
    colors: [Color(0xEE052A23), Color(0xCC0A4A3B), Color(0xAA7A5A1E)],
    actionColor: Color(0xFF0E6F59),
    assetPath: 'assets/images/widget_mosque_snow.jpg',
  ),
  _PostPalette(
    colors: [Color(0xEE0F2636), Color(0xCC1F5360), Color(0xAA7D672E)],
    actionColor: Color(0xFF153447),
    assetPath: 'assets/images/widget_blue_mosque.jpg',
  ),
  _PostPalette(
    colors: [Color(0xEE3D2A14), Color(0xCC7A5C2E), Color(0xAA153542)],
    actionColor: Color(0xFF5A3F20),
    assetPath: 'assets/images/widget_kaaba.jpg',
  ),
  _PostPalette(
    colors: [Color(0xEE06232C), Color(0xCC0E5645), Color(0xAA173E50)],
    actionColor: Color(0xFF0A2C39),
    assetPath: 'assets/images/widget_sheikh_zayed.jpg',
  ),
  _PostPalette(
    colors: [Color(0xEE094538), Color(0xCC705C22), Color(0xAA0E362D)],
    actionColor: Color(0xFF0E4E43),
    assetPath: 'assets/images/widget_quran.jpg',
  ),
  _PostPalette(
    colors: [Color(0xEE1C2E40), Color(0xCC4A6670), Color(0xAA906C27)],
    actionColor: Color(0xFF314A62),
    assetPath: 'assets/images/widget_sultan_qaboos.jpg',
  ),
];
