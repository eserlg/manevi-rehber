import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../data/models/prayer_times.dart';
import '../providers/providers.dart';
import '../widgets/memorial_donation_sheet.dart';
import 'occasion_messages_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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
    } else {
      // Default to Istanbul
      ref.read(currentCityProvider.notifier).state = savedCity ?? 'İstanbul';
    }
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(prayerTimesProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(city),
                const SizedBox(height: AppDimensions.spacingLG),

                // Prayer Times Card
                prayerTimesAsync.when(
                  data: (prayerTimes) => _buildPrayerTimesCard(prayerTimes),
                  loading: () => _buildLoadingCard(),
                  error: (_, __) => _buildErrorCard(),
                ),
                const SizedBox(height: AppDimensions.spacingLG),

                // Quick Actions
                _buildQuickActions(),
                const SizedBox(height: AppDimensions.spacingLG),

                _buildReligiousDays(),
                const SizedBox(height: AppDimensions.spacingLG),

                _buildMemorialCard(),
                const SizedBox(height: AppDimensions.spacingLG),

                // Verse of the Day
                _buildVerseOfDay(),
              ],
            ),
          ),
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
                          setModalState(() => leadMinutes = minutes);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppDimensions.spacingLG),
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
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (_) {
      return true;
    }
  }

  Widget _buildPrayerTimesCard(PrayerTimes? prayerTimes) {
    if (prayerTimes == null) {
      return _buildErrorCard();
    }

    final nextPrayer = prayerTimes.getNextPrayer();
    final nextPrayerTime = prayerTimes.getNextPrayerTime();
    final timeUntil = prayerTimes.getTimeUntilNextPrayer();

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingLG),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Next Prayer
          Text(
            'Sonraki Namaz',
            style: GoogleFonts.notoSans(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSM),
          Text(
            nextPrayer,
            style: GoogleFonts.amiri(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            nextPrayerTime,
            style: GoogleFonts.amiri(
              fontSize: 28,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMD),

          // Countdown
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingMD,
              vertical: AppDimensions.spacingSM,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer, color: Colors.white, size: 20),
                const SizedBox(width: AppDimensions.spacingSM),
                Text(
                  _formatDuration(timeUntil),
                  style: GoogleFonts.notoSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMD),

          // Hijri Date
          Text(
            prayerTimes.hijriDate,
            style: GoogleFonts.notoSans(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
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

  Widget _buildQuickActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.auto_awesome,
                title: 'Zikir',
                subtitle: 'Tesbihat',
                color: AppColors.accent,
                onTap: () => ref.read(selectedTabProvider.notifier).state = 2,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingMD),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.menu_book,
                title: 'Dualar',
                subtitle: 'Günlük Duası',
                color: AppColors.softBlue,
                onTap: () => ref.read(selectedTabProvider.notifier).state = 3,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingMD),
        SizedBox(
          width: double.infinity,
          child: _buildQuickActionCard(
            icon: Icons.celebration_outlined,
            title: 'Mesajlar',
            subtitle: 'Bayram, Kandil ve Cuma mesajları',
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
        ),
      ],
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
                  actionLabel: '+33',
                  onTap: () => _incrementMemorialCount(id, 'tasbihCount', 33),
                ),
                _buildMemorialCounter(
                  title: 'Yasin',
                  value: yasinCount,
                  actionLabel: '+1',
                  onTap: () => _incrementMemorialCount(id, 'yasinCount', 1),
                ),
                _buildMemorialCounter(
                  title: 'Hatim',
                  value: hatimCount,
                  actionLabel: '+1',
                  onTap: () => _incrementMemorialCount(id, 'hatimCount', 1),
                ),
              ];

              if (compact) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: counters[0]),
                        const SizedBox(width: AppDimensions.spacingSM),
                        Expanded(child: counters[1]),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingSM),
                    counters[2],
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: counters[0]),
                  const SizedBox(width: AppDimensions.spacingSM),
                  Expanded(child: counters[1]),
                  const SizedBox(width: AppDimensions.spacingSM),
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
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMD),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: GoogleFonts.amiri(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.notoSans(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSM),
          TextButton(
            onPressed: onTap,
            child: Text(actionLabel),
          ),
        ],
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
        final upcoming =
            days.where((day) => !day.date.isBefore(todayDate)).take(3).toList();

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingMD),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingSM),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
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
              Text(
                'Günün Ayeti',
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
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
