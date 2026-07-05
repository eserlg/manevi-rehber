import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../data/models/prayer_times.dart';
import '../../data/models/quran.dart';
import '../../data/services/app_share_service.dart';
import '../providers/providers.dart';
import '../widgets/memorial_donation_sheet.dart';
import 'live_stream_screen.dart';
import 'occasion_messages_screen.dart';
import 'widgets_screen.dart';
import 'yasin_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _freeAdhanAudioUrl =
      'https://upload.wikimedia.org/wikipedia/commons/transcoded/b/b0/Beautiful_adhan.ogg/Beautiful_adhan.ogg.mp3';
  Timer? _timer;
  late final Future<List<_ReligiousDay>> _religiousDaysFuture;
  List<Map<String, dynamic>> _memorialRecords = [];
  int _lastMemorialRefresh = 0;

  @override
  void initState() {
    super.initState();
    _religiousDaysFuture = _loadReligiousDays();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initLocation();
      _loadMemorialRecord();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final storage = ref.read(localStorageProvider);
    final savedCity = storage.getCity();
    final savedLocation = storage.getLastLocation();

    if (!storage.isAutoLocationEnabled()) {
      if (savedCity != null && savedCity.isNotEmpty) {
        ref.read(currentCityProvider.notifier).state = savedCity;
      }
      return;
    }

    final locationService = ref.read(locationServiceProvider);
    final position = await locationService.getCurrentLocation();

    if (position != null) {
      final city = await locationService.getCityName(position);
      ref.read(currentPositionProvider.notifier).state = position;
      ref.read(currentCityProvider.notifier).state =
          city == 'Bilinmeyen' ? savedCity ?? 'Mevcut Konum' : city;
      await storage.saveLastLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (city != 'Bilinmeyen') await storage.saveCity(city);
    } else {
      if (savedLocation != null) {
        ref.read(currentPositionProvider.notifier).state = _positionFromCoords(
          savedLocation['latitude']!,
          savedLocation['longitude']!,
        );
        ref.read(currentCityProvider.notifier).state =
            savedCity ?? 'Mevcut Konum';
        return;
      }

      ref.read(currentCityProvider.notifier).state = savedCity ?? 'İstanbul';
    }
  }

  Position _positionFromCoords(double latitude, double longitude) {
    return Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  Future<void> _loadMemorialRecord() async {
    final storage = ref.read(localStorageProvider);
    await storage.init();
    if (!mounted) return;
    setState(() {
      _memorialRecords = storage.getMemorialRecords();
    });
  }

  Future<void> _saveMemorialRecords(
    List<Map<String, dynamic>> records,
  ) async {
    final storage = ref.read(localStorageProvider);
    await storage.saveMemorialRecords(records);
    if (!mounted) return;
    setState(() {
      _memorialRecords = records;
    });
  }

  @override
  Widget build(BuildContext context) {
    final prayerTimesAsync = ref.watch(prayerTimesProvider);
    final city = ref.watch(currentCityProvider);
    final memorialRefresh = ref.watch(memorialRefreshProvider);

    if (memorialRefresh != _lastMemorialRefresh) {
      _lastMemorialRefresh = memorialRefresh;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadMemorialRecord();
      });
    }

    return Scaffold(
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
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: _HomePatternPainter()),
            ),
            SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(prayerTimesProvider);
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 720;
                    final horizontalPadding = wide
                        ? AppDimensions.spacingLG
                        : AppDimensions.screenPadding;

                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        AppDimensions.screenPadding,
                        horizontalPadding,
                        AppDimensions.spacingXL,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1080),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(city),
                              const SizedBox(height: AppDimensions.spacingLG),
                              prayerTimesAsync.when(
                                data: (prayerTimes) =>
                                    _buildPrayerTimesCard(prayerTimes),
                                loading: () => _buildLoadingCard(),
                                error: (_, __) => _buildErrorCard(),
                              ),
                              const SizedBox(height: AppDimensions.spacingLG),
                              _buildPrayerTrackingSummary(),
                              const SizedBox(height: AppDimensions.spacingLG),
                              _buildQuickActions(),
                              const SizedBox(height: AppDimensions.spacingLG),
                              _buildReligiousDays(),
                              const SizedBox(height: AppDimensions.spacingLG),
                              _buildMemorialCard(),
                              const SizedBox(height: AppDimensions.spacingLG),
                              _buildVerseOfDay(),
                              const SizedBox(height: AppDimensions.spacingLG),
                              _buildHadithOfDay(),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String city) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manevi Rehber',
              style: GoogleFonts.amiri(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXS),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppDimensions.spacingXS),
                Text(
                  city,
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          child: InkWell(
            onTap: _showNotificationPanel,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingSM),
              child: Icon(
                ref.read(localStorageProvider).arePrayerNotificationsEnabled()
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showNotificationPanel() async {
    final storage = ref.read(localStorageProvider);
    var notificationsEnabled = storage.arePrayerNotificationsEnabled();
    var leadMinutes = storage.getNotificationLeadMinutes();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLarge),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.screenPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.spacingSM),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSmall,
                          ),
                        ),
                        child: Icon(
                          notificationsEnabled
                              ? Icons.notifications_active
                              : Icons.notifications_off,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingMD),
                      Expanded(
                        child: Text(
                          'Namaz Bildirimleri',
                          style: GoogleFonts.notoSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Switch(
                        value: notificationsEnabled,
                        activeColor: AppColors.primary,
                        onChanged: (value) async {
                          if (value) {
                            final granted =
                                await _requestNotificationPermission();
                            if (!granted) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Bildirim izni verilmedi'),
                                  ),
                                );
                              }
                              return;
                            }
                          }

                          await storage.setPrayerNotificationsEnabled(value);
                          ref.invalidate(prayerTimesProvider);
                          setModalState(() => notificationsEnabled = value);
                          if (mounted) setState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingLG),
                  Text(
                    'Bildirim Öncesi Süre',
                    style: GoogleFonts.notoSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingSM),
                  Wrap(
                    spacing: AppDimensions.spacingSM,
                    runSpacing: AppDimensions.spacingSM,
                    children: [5, 10, 15, 20, 30, 45, 60].map((minutes) {
                      final selected = minutes == leadMinutes;
                      return ChoiceChip(
                        label: Text('$minutes dk'),
                        selected: selected,
                        selectedColor: AppColors.primary.withOpacity(0.18),
                        onSelected: (_) async {
                          await storage.setNotificationLeadMinutes(minutes);
                          ref.invalidate(prayerTimesProvider);
                          setModalState(() => leadMinutes = minutes);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppDimensions.spacingLG),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimensions.spacingMD),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.06),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMedium),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.volume_up_outlined,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: AppDimensions.spacingSM),
                            Expanded(
                              child: Text(
                                'Ücretsiz ezan sesi',
                                style: GoogleFonts.notoSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spacingXS),
                        Text(
                          'CC0 lisanslı Wikimedia kaynağı. PWA’da önizleme olarak çalar; özel bildirim sesi native sürümde bağlanır.',
                          style: GoogleFonts.notoSans(
                            fontSize: 12,
                            height: 1.35,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingSM),
                        Wrap(
                          spacing: AppDimensions.spacingSM,
                          runSpacing: AppDimensions.spacingSM,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _playFreeAdhanPreview,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Dinle'),
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  ref.read(quranAudioProvider).stop(),
                              icon: const Icon(Icons.stop_circle_outlined),
                              label: const Text('Durdur'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingLG),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimensions.spacingMD),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: AppDimensions.spacingSM),
                        Expanded(
                          child: Text(
                            'PWA bildirimleri uygulama açıkken veya arka planda canlı kaldığında çalışır. Telefon uygulamayı uykuya alırsa kesin alarm için native Android/iOS sürümü gerekir.',
                            style: GoogleFonts.notoSans(
                              fontSize: 12,
                              height: 1.35,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingMD),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final shown = await ref
                            .read(prayerNotificationServiceProvider)
                            .showTestNotification();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              shown
                                  ? 'Test bildirimi gönderildi.'
                                  : 'Bildirim gönderilemedi. PWA bildirimi veya tarayıcı izni kapalı olabilir.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: const Text('Test bildirimi gönder'),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingMD),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.check),
                      label: const Text('Tamam'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _requestNotificationPermission() async {
    try {
      final webGranted =
          await ref.read(prayerNotificationServiceProvider).requestPermission();
      if (webGranted) return true;

      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (_) {
      return true;
    }
  }

  Future<void> _playFreeAdhanPreview() async {
    final started = await ref.read(quranAudioProvider).playUrl(
          _freeAdhanAudioUrl,
        );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          started
              ? 'Ezan sesi oynatılıyor.'
              : 'Ezan sesi başlatılamadı. Bağlantıyı kontrol edin.',
        ),
      ),
    );
  }

  Widget _buildPrayerTimesCard(PrayerTimes? prayerTimes) {
    if (prayerTimes == null) {
      return _buildErrorCard();
    }

    final nextPrayer = prayerTimes.getNextPrayer();
    final nextPrayerTime = prayerTimes.getNextPrayerTime();
    final timeUntil = prayerTimes.getTimeUntilNextPrayer();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingLG),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            AppColors.primaryLight,
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.26),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 520;

          final prayerInfo = Column(
            crossAxisAlignment:
                wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingMD,
                  vertical: AppDimensions.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusCircle),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: Text(
                  'Sonraki Namaz',
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.92),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingSM),
              Text(
                nextPrayer,
                style: GoogleFonts.amiri(
                  fontSize: wide ? 44 : 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                nextPrayerTime,
                style: GoogleFonts.amiri(
                  fontSize: wide ? 32 : 28,
                  color: Colors.white.withOpacity(0.92),
                ),
              ),
            ],
          );

          final countdown = Container(
            padding: const EdgeInsets.all(AppDimensions.spacingMD),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  wide ? CrossAxisAlignment.end : CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer, color: Colors.white, size: 20),
                    const SizedBox(width: AppDimensions.spacingSM),
                    Text(
                      _formatDuration(timeUntil),
                      style: GoogleFonts.notoSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingSM),
                Text(
                  prayerTimes.hijriDate,
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.82),
                  ),
                ),
              ],
            ),
          );

          if (wide) {
            return Row(
              children: [
                Expanded(child: prayerInfo),
                const SizedBox(width: AppDimensions.spacingLG),
                countdown,
              ],
            );
          }

          return Column(
            children: [
              prayerInfo,
              const SizedBox(height: AppDimensions.spacingMD),
              countdown,
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingLG),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: AppDimensions.spacingSM),
          Text(
            'Namaz vakitleri yüklenemedi',
            style: GoogleFonts.notoSans(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMD),
          TextButton(
            onPressed: () {
              ref.invalidate(prayerTimesProvider);
            },
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTrackingSummary() {
    final tracking = ref.watch(prayerTrackingProvider);
    final completed = tracking.completedForDate(DateTime.now());
    final weeklyFullDays = tracking.completedDaysInLast(7);
    final progress = tracking.progressForDate(DateTime.now());

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ref.read(selectedTabProvider.notifier).state = 1,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spacingLG),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.88),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            border: Border.all(color: AppColors.primary.withOpacity(0.14)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withOpacity(0.06),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 58,
                    height: 58,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 7,
                      backgroundColor: AppColors.surfaceVariant,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    '$completed/5',
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppDimensions.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Namaz Takibi',
                      style: GoogleFonts.notoSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      'Bugün $completed vakit işaretlendi. Son 7 günde $weeklyFullDays gün tam.',
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (tracking.totalQadaDebt > 0) ...[
                      const SizedBox(height: AppDimensions.spacingXS),
                      Text(
                        'Kaza takibi: ${tracking.totalQadaDebt} kayıt',
                        style: GoogleFonts.notoSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickActionData(
        icon: Icons.auto_awesome,
        title: 'Zikir',
        subtitle: 'Tesbihat',
        color: AppColors.accent,
        onTap: () => ref.read(selectedTabProvider.notifier).state = 2,
      ),
      _QuickActionData(
        icon: Icons.menu_book,
        title: 'Dualar',
        subtitle: 'Günlük Dua',
        color: AppColors.info,
        onTap: () => ref.read(selectedTabProvider.notifier).state = 3,
      ),
      _QuickActionData(
        icon: Icons.auto_stories,
        title: 'Yasin',
        subtitle: 'Yasin-i Şerif oku',
        color: AppColors.primary,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const YasinScreen(),
            ),
          );
        },
      ),
      _QuickActionData(
        icon: Icons.celebration_outlined,
        title: 'Mesajlar',
        subtitle: 'Bayram, Kandil ve Cuma',
        color: AppColors.primary,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OccasionMessagesScreen(),
            ),
          );
        },
      ),
      _QuickActionData(
        icon: Icons.live_tv_outlined,
        title: 'Canlı Yayın',
        subtitle: 'Mekke, Medine ve kıraat',
        color: AppColors.primaryDark,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LiveStreamScreen(),
            ),
          );
        },
      ),
      _QuickActionData(
        icon: Icons.widgets_outlined,
        title: 'Widgetler',
        subtitle: 'Ayet ve vakit ekranları',
        color: AppColors.primaryLight,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WidgetsScreen(),
            ),
          );
        },
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return Row(
            children: [
              for (var index = 0; index < actions.length; index += 1) ...[
                if (index > 0) const SizedBox(width: AppDimensions.spacingMD),
                Expanded(
                  child: _buildQuickActionCard(
                    icon: actions[index].icon,
                    title: actions[index].title,
                    subtitle: actions[index].subtitle,
                    color: actions[index].color,
                    onTap: actions[index].onTap,
                  ),
                ),
              ],
            ],
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppDimensions.spacingMD,
            mainAxisSpacing: AppDimensions.spacingMD,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildQuickActionCard(
              icon: action.icon,
              title: action.title,
              subtitle: action.subtitle,
              color: action.color,
              onTap: action.onTap,
            );
          },
        );
      },
    );
  }

  Widget _buildMemorialCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacingLG),
          decoration: BoxDecoration(
            color: AppColors.primaryDark.withOpacity(0.06),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            border: Border.all(color: AppColors.primary.withOpacity(0.16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.volunteer_activism,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppDimensions.spacingSM),
                  Expanded(
                    child: Text(
                      'Vefat Hatırası',
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Bağış Yap',
                    onPressed: _memorialRecords.isEmpty
                        ? null
                        : () => showMemorialDonationSheet(
                              context: context,
                              ref: ref,
                              title: 'Vefat Hatırasına Bağış',
                              note:
                                  'Tesbih, Yasin veya Hatim bağışını kayıtlı kişilerden birine ekleyebilirsin.',
                            ),
                    icon: const Icon(Icons.volunteer_activism_outlined),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showMemorialDialog(),
                    icon: const Icon(Icons.person_add_alt_1, size: 18),
                    label: const Text('Kişi Ekle'),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingMD),
              Text(
                _memorialRecords.isEmpty
                    ? 'Yakının için vefat tarihi ekleyebilir; ruhuna bağışlanan tesbih, Yasin ve hatimleri ayrı ayrı takip edebilirsin.'
                    : '${_memorialRecords.length} kişi için bağışlanan tesbih, Yasin ve hatimler takip ediliyor.',
                style: GoogleFonts.notoSans(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (_memorialRecords.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.spacingSM),
          ..._memorialRecords.map(_buildMemorialPersonCard),
        ],
      ],
    );
  }

  Widget _buildMemorialPersonCard(Map<String, dynamic> record) {
    final deathDate = DateTime.tryParse(record['deathDate']?.toString() ?? '');
    if (deathDate == null) return const SizedBox.shrink();

    final id = record['id']?.toString() ?? '';
    final name = record['name']?.toString().trim() ?? '';
    final tasbihCount = _asInt(record['tasbihCount']);
    final yasinCount = _asInt(record['yasinCount']);
    final hatimCount = _asInt(record['hatimCount']);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final deathDay = DateTime(deathDate.year, deathDate.month, deathDate.day);
    final daysPassed = todayDate.difference(deathDay).inDays;

    return Container(
      margin: const EdgeInsets.only(top: AppDimensions.spacingSM),
      padding: const EdgeInsets.all(AppDimensions.spacingLG),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.primary.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.volunteer_activism,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppDimensions.spacingSM),
              Expanded(
                child: Text(
                  name.isEmpty ? 'Vefat Hatırası' : name,
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Düzenle',
                onPressed: () => _showMemorialDialog(record: record),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingSM),
          Text(
            daysPassed == 0
                ? 'Bugün vefat etti'
                : 'Vefatının üzerinden $daysPassed gün geçti',
            style: GoogleFonts.amiri(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          Text(
            'Vefat tarihi: ${_formatDate(deathDate)}',
            style: GoogleFonts.notoSans(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMD),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 420;
              final counters = [
                _buildMemorialCounter(
                  title: 'Tesbih',
                  value: tasbihCount,
                  compact: compact,
                  onIncrement: () =>
                      _incrementMemorialCount(id, 'tasbihCount', 33),
                  onDecrement: () =>
                      _decrementMemorialCount(id, 'tasbihCount', 33),
                  onManual: () => _manualEditCount(id, 'tasbihCount'),
                ),
                _buildMemorialCounter(
                  title: 'Yasin',
                  value: yasinCount,
                  compact: compact,
                  onIncrement: () =>
                      _incrementMemorialCount(id, 'yasinCount', 1),
                  onDecrement: () =>
                      _decrementMemorialCount(id, 'yasinCount', 1),
                  onManual: () => _manualEditCount(id, 'yasinCount'),
                ),
                _buildMemorialCounter(
                  title: 'Hatim',
                  value: hatimCount,
                  compact: compact,
                  onIncrement: () =>
                      _incrementMemorialCount(id, 'hatimCount', 1),
                  onDecrement: () =>
                      _decrementMemorialCount(id, 'hatimCount', 1),
                  onManual: () => _manualEditCount(id, 'hatimCount'),
                ),
              ];

              return Row(
                children: [
                  Expanded(child: counters[0]),
                  SizedBox(
                    width: compact
                        ? AppDimensions.spacingXS
                        : AppDimensions.spacingSM,
                  ),
                  Expanded(child: counters[1]),
                  SizedBox(
                    width: compact
                        ? AppDimensions.spacingXS
                        : AppDimensions.spacingSM,
                  ),
                  Expanded(child: counters[2]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMemorialCounter({
    required String title,
    required int value,
    bool compact = false,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    required VoidCallback onManual,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppDimensions.spacingXS : AppDimensions.spacingMD,
        vertical: compact ? AppDimensions.spacingSM : AppDimensions.spacingMD,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: GoogleFonts.amiri(
              fontSize: compact ? 22 : 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.notoSans(
              fontSize: compact ? 11 : 12,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(
            height: compact ? AppDimensions.spacingXS : AppDimensions.spacingSM,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _counterButton(
                  icon: Icons.remove_circle_outline,
                  tooltip: 'Düşür',
                  compact: compact,
                  color: AppColors.error,
                  onTap: onDecrement,
                ),
              ),
              Expanded(
                child: _counterButton(
                  icon: Icons.edit_outlined,
                  tooltip: 'Düzenle',
                  compact: compact,
                  color: AppColors.textSecondary,
                  onTap: onManual,
                ),
              ),
              Expanded(
                child: _counterButton(
                  icon: Icons.add_circle_outline,
                  tooltip: 'Ekle',
                  compact: compact,
                  color: AppColors.primary,
                  onTap: onIncrement,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _counterButton({
    required IconData icon,
    required String tooltip,
    required bool compact,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 22 : 26),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Tooltip(
            message: tooltip,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: compact ? 22 : 26, color: color),
                SizedBox(height: compact ? 1 : 2),
                Text(
                  tooltip,
                  style: GoogleFonts.notoSans(
                    fontSize: compact ? 8.5 : 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _incrementMemorialCount(
    String recordId,
    String key,
    int amount,
  ) async {
    final records = _memorialRecords.map(Map<String, dynamic>.from).toList();
    final index = records.indexWhere((record) => record['id'] == recordId);
    if (index < 0) return;

    records[index][key] = _asInt(records[index][key]) + amount;
    await _saveMemorialRecords(records);
  }

  Future<void> _decrementMemorialCount(
    String recordId,
    String key,
    int amount,
  ) async {
    final records = _memorialRecords.map(Map<String, dynamic>.from).toList();
    final index = records.indexWhere((record) => record['id'] == recordId);
    if (index < 0) return;

    final current = _asInt(records[index][key]);
    if (current <= 0) return;
    records[index][key] = (current - amount).clamp(0, current).toInt();
    await _saveMemorialRecords(records);
  }

  Future<void> _manualEditCount(
    String recordId,
    String key,
  ) async {
    final record = _memorialRecords.firstWhere(
      (r) => r['id'] == recordId,
      orElse: () => <String, dynamic>{},
    );
    final current = _asInt(record[key]);
    final controller = TextEditingController(text: '$current');
    final labelMap = {
      'tasbihCount': 'Tesbih',
      'yasinCount': 'Yasin',
      'hatimCount': 'Hatim',
    };
    final label = labelMap[key] ?? key;

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$label sayacını düzenle'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: label,
            hintText: '$current',
            prefixIcon: const Icon(Icons.edit_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              Navigator.pop(dialogContext, value);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (result == null) return;
    final clamped = result.clamp(0, 999999).toInt();
    final records = _memorialRecords.map(Map<String, dynamic>.from).toList();
    final index = records.indexWhere((r) => r['id'] == recordId);
    if (index < 0) return;
    records[index][key] = clamped;
    await _saveMemorialRecords(records);
  }

  Future<void> _showMemorialDialog({
    Map<String, dynamic>? record,
  }) async {
    final nameController =
        TextEditingController(text: record?['name']?.toString() ?? '');
    DateTime selectedDate =
        DateTime.tryParse(record?['deathDate']?.toString() ?? '') ??
            DateTime.now();

    final savedRecords = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              scrollable: true,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingLG,
                vertical: AppDimensions.spacingLG,
              ),
              contentPadding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingLG,
                AppDimensions.spacingSM,
                AppDimensions.spacingLG,
                AppDimensions.spacingSM,
              ),
              actionsPadding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingMD,
                0,
                AppDimensions.spacingMD,
                AppDimensions.spacingMD,
              ),
              actionsOverflowButtonSpacing: AppDimensions.spacingSM,
              title: Text(record == null ? 'Kişi Ekle' : 'Vefat Hatırası'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Adı soyadı',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingSM),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    leading:
                        Icon(Icons.calendar_month, color: AppColors.primary),
                    title: const Text('Vefat tarihi'),
                    subtitle: Text(_formatDate(selectedDate)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                if (record != null)
                  TextButton(
                    onPressed: () async {
                      final records = _memorialRecords
                          .where((item) => item['id'] != record['id'])
                          .map(Map<String, dynamic>.from)
                          .toList();
                      Navigator.pop(dialogContext, records);
                    },
                    child: const Text('Sil'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Vazgeç'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final records = _memorialRecords
                        .map(Map<String, dynamic>.from)
                        .toList();
                    final nextRecord = Map<String, dynamic>.from(record ?? {});
                    nextRecord['id'] =
                        nextRecord['id']?.toString() ?? _newMemorialId();
                    nextRecord['name'] = nameController.text.trim();
                    nextRecord['deathDate'] = selectedDate.toIso8601String();
                    nextRecord['tasbihCount'] =
                        _asInt(nextRecord['tasbihCount']);
                    nextRecord['yasinCount'] = _asInt(nextRecord['yasinCount']);
                    nextRecord['hatimCount'] = _asInt(nextRecord['hatimCount']);

                    final index = records.indexWhere(
                      (item) => item['id'] == nextRecord['id'],
                    );
                    if (index >= 0) {
                      records[index] = nextRecord;
                    } else {
                      records.add(nextRecord);
                    }
                    Navigator.pop(dialogContext, records);
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    if (savedRecords != null && mounted) {
      await _saveMemorialRecords(savedRecords);
    }
  }

  Widget _buildReligiousDays() {
    return FutureBuilder<List<_ReligiousDay>>(
      future: _religiousDaysFuture,
      builder: (context, snapshot) {
        final days = snapshot.data ?? [];
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        final upcoming = _visibleReligiousDays(days, todayDate);

        if (upcoming.isEmpty) return const SizedBox.shrink();

        final next = upcoming.first;
        final daysLeft = next.date.difference(todayDate).inDays;

        return Container(
          padding: const EdgeInsets.all(AppDimensions.spacingLG),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            border: Border.all(color: AppColors.primary.withOpacity(0.16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_month,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: AppDimensions.spacingSM),
                  Text(
                    'Dini Günler',
                    style: GoogleFonts.notoSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingMD),
              Text(
                next.name,
                style: GoogleFonts.amiri(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              Text(
                '${_formatDate(next.date)} - ${_formatDaysLeft(daysLeft)}',
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              if (upcoming.length > 1) ...[
                const SizedBox(height: AppDimensions.spacingMD),
                for (final day in upcoming.skip(1))
                  Padding(
                    padding:
                        const EdgeInsets.only(top: AppDimensions.spacingXS),
                    child: Text(
                      '${day.name}: ${_formatDate(day.date)}',
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Container(
          constraints: const BoxConstraints(minHeight: 122),
          padding: const EdgeInsets.all(AppDimensions.spacingMD),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.20),
                AppColors.surface.withOpacity(0.76),
              ],
            ),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(color: color.withOpacity(0.34)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.10),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingSM),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: AppDimensions.spacingSM),
              Text(
                title,
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
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

  Widget _buildVerseOfDay() {
    final verseAsync = ref.watch(verseOfDayProvider);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingLG),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote, color: AppColors.primary, size: 20),
              const SizedBox(width: AppDimensions.spacingSM),
              Expanded(
                child: Text(
                  'Günün Ayeti',
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              verseAsync.maybeWhen(
                data: (verse) {
                  if (verse == null) return const SizedBox.shrink();
                  return IconButton(
                    tooltip: 'Paylaş',
                    onPressed: () => _shareVerseOfDay(verse),
                    icon: const Icon(Icons.share_outlined),
                    color: AppColors.primary,
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMD),
          verseAsync.when(
            data: (verse) {
              if (verse == null) return const SizedBox();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    verse.text,
                    style: GoogleFonts.amiri(
                      fontSize: 22,
                      height: 1.8,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  if (verse.translation != null &&
                      verse.translation!.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.spacingMD),
                    Divider(color: AppColors.primary.withOpacity(0.18)),
                    const SizedBox(height: AppDimensions.spacingSM),
                    Text(
                      verse.translation!,
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        height: 1.55,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Text(
              'Ayet yüklenemedi',
              style: GoogleFonts.notoSans(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHadithOfDay() {
    final hadith =
        _dailyHadiths[_dayOfYear(DateTime.now()) % _dailyHadiths.length];

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingLG),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.accent.withOpacity(0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote, color: AppColors.accent, size: 20),
              const SizedBox(width: AppDimensions.spacingSM),
              Expanded(
                child: Text(
                  'Günün Hadisi',
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Paylaş',
                onPressed: () => _shareHadithOfDay(hadith),
                icon: const Icon(Icons.share_outlined),
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMD),
          Text(
            hadith.text,
            style: GoogleFonts.notoSans(
              fontSize: 16,
              height: 1.55,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSM),
          Text(
            hadith.source,
            style: GoogleFonts.notoSans(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareVerseOfDay(Verse verse) async {
    final text = [
      'Günün Ayeti',
      '',
      verse.text,
      if (verse.translation != null && verse.translation!.isNotEmpty) ...[
        '',
        verse.translation!,
      ],
      '',
      'Manevi Rehber',
      'https://manevi-rehber.vercel.app',
    ].join('\n');

    await AppShareService.shareText(
      context: context,
      text: text,
      subject: 'Günün Ayeti',
      fallbackMessage: 'Ayet paylaşım metni panoya kopyalandı.',
    );
  }

  Future<void> _shareHadithOfDay(_DailyHadith hadith) async {
    final text = [
      'Günün Hadisi',
      '',
      hadith.text,
      '',
      hadith.source,
      '',
      'Manevi Rehber',
      'https://manevi-rehber.vercel.app',
    ].join('\n');

    await AppShareService.shareText(
      context: context,
      text: text,
      subject: 'Günün Hadisi',
      fallbackMessage: 'Hadis paylaşım metni panoya kopyalandı.',
    );
  }

  int _dayOfYear(DateTime date) {
    return date.difference(DateTime(date.year)).inDays;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<List<_ReligiousDay>> _loadReligiousDays() async {
    final jsonString =
        await rootBundle.loadString('assets/data/religious_days_2026.json');
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => _ReligiousDay.fromJson(json)).toList();
  }

  List<_ReligiousDay> _visibleReligiousDays(
    List<_ReligiousDay> days,
    DateTime todayDate,
  ) {
    final upcoming =
        days.where((day) => !day.date.isBefore(todayDate)).toList();
    if (upcoming.isEmpty) return [];

    final family = _bayramFamily(upcoming.first.name);
    if (family == null) return upcoming.take(3).toList();

    return upcoming.where((day) => day.name.startsWith(family)).toList();
  }

  String? _bayramFamily(String name) {
    if (name.startsWith('Ramazan Bayramı')) return 'Ramazan Bayramı';
    if (name.startsWith('Kurban Bayramı')) return 'Kurban Bayramı';
    return null;
  }

  String _formatDaysLeft(int days) {
    if (days == 0) return 'Bugün';
    if (days == 1) return 'Yarın';
    return '$days gün kaldı';
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _newMemorialId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

class _ReligiousDay {
  final String name;
  final DateTime date;

  _ReligiousDay({
    required this.name,
    required this.date,
  });

  factory _ReligiousDay.fromJson(Map<String, dynamic> json) {
    return _ReligiousDay(
      name: json['name'] ?? '',
      date: DateTime.parse(json['date']),
    );
  }
}

class _DailyHadith {
  final String text;
  final String source;

  const _DailyHadith({
    required this.text,
    required this.source,
  });
}

const _dailyHadiths = [
  _DailyHadith(
    text: 'Ameller niyetlere göredir; herkese ancak niyet ettiği vardır.',
    source: 'Buhârî, Bedü’l-vahy 1; Müslim, İmâre 155',
  ),
  _DailyHadith(
    text: 'Müslüman, insanların elinden ve dilinden güvende olduğu kimsedir.',
    source: 'Buhârî, Îmân 4; Müslim, Îmân 64',
  ),
  _DailyHadith(
    text: 'Kolaylaştırın, zorlaştırmayın; müjdeleyin, nefret ettirmeyin.',
    source: 'Buhârî, İlim 11; Müslim, Cihâd 6',
  ),
  _DailyHadith(
    text: 'Sizin en hayırlınız Kur’an’ı öğrenen ve öğretendir.',
    source: 'Buhârî, Fezâilü’l-Kur’ân 21',
  ),
  _DailyHadith(
    text: 'Temizlik imanın yarısıdır.',
    source: 'Müslim, Tahâret 1',
  ),
  _DailyHadith(
    text:
        'Allah sizin suretlerinize ve mallarınıza değil, kalplerinize ve amellerinize bakar.',
    source: 'Müslim, Birr 34',
  ),
  _DailyHadith(
    text: 'Merhamet etmeyene merhamet olunmaz.',
    source: 'Buhârî, Edeb 18; Müslim, Fezâil 65',
  ),
];

class _QuickActionData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

class _HomePatternPainter extends CustomPainter {
  const _HomePatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.primary.withOpacity(0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final archPaint = Paint()
      ..color = AppColors.accent.withOpacity(0.045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (var x = -size.height; x < size.width; x += 72) {
      canvas.drawLine(
        Offset(x.toDouble(), size.height),
        Offset(x + size.height * 0.55, 0),
        linePaint,
      );
    }

    for (var x = 64.0; x < size.width; x += 220) {
      final rect = Rect.fromLTWH(x, 72, 160, 160);
      canvas.drawArc(rect, pi, pi, false, archPaint);
      canvas.drawLine(
        Offset(x, 152),
        Offset(x, 210),
        archPaint,
      );
      canvas.drawLine(
        Offset(x + 160, 152),
        Offset(x + 160, 210),
        archPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
