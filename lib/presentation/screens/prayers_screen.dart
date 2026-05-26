import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../data/models/prayer.dart';
import '../../data/services/app_share_service.dart';
import '../../data/services/quran_audio_service.dart';
import '../../data/services/text_to_speech_service.dart';
import '../providers/providers.dart';

const List<MapEntry<String, String?>> _prayerCategories = [
  MapEntry<String, String?>('Tümü', null),
  MapEntry<String, String?>('Favoriler', 'favorites'),
  MapEntry<String, String?>('Sabah', 'sabah'),
  MapEntry<String, String?>('Akşam', 'aksam'),
  MapEntry<String, String?>('Günlük', 'gunluk'),
  MapEntry<String, String?>('Yemek', 'yemek'),
  MapEntry<String, String?>('Hastalık', 'hastalik'),
  MapEntry<String, String?>('Korunma', 'korunma'),
  MapEntry<String, String?>('Namaz', 'namaz'),
  MapEntry<String, String?>('Aile', 'aile'),
  MapEntry<String, String?>('Yolculuk', 'yolculuk'),
];

class PrayersScreen extends ConsumerStatefulWidget {
  const PrayersScreen({super.key});

  @override
  ConsumerState<PrayersScreen> createState() => _PrayersScreenState();
}

class _PrayersScreenState extends ConsumerState<PrayersScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final TextToSpeechService _speechService;

  static const Map<String, List<QuranAudioReference>> _quranPrayerAudio = {
    '6': [QuranAudioReference(113, 1, 5)],
    '7': [QuranAudioReference(114, 1, 6)],
    '8': [QuranAudioReference(112, 1, 4)],
    '9': [QuranAudioReference(2, 255)],
    '10': [QuranAudioReference(1, 1, 7)],
    '11': [QuranAudioReference(2, 201)],
    '12': [QuranAudioReference(7, 23)],
    '13': [QuranAudioReference(20, 25, 28)],
    '14': [QuranAudioReference(21, 87)],
    '15': [QuranAudioReference(21, 83)],
    '21': [QuranAudioReference(43, 13, 14)],
    '35': [QuranAudioReference(17, 24)],
    '36': [QuranAudioReference(20, 114)],
    '42': [QuranAudioReference(25, 74)],
  };

  @override
  void initState() {
    super.initState();
    _speechService = ref.read(textToSpeechProvider);
  }

  @override
  void dispose() {
    _speechService.stop();
    ref.read(quranAudioProvider).stop();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prayersAsync = ref.watch(filteredPrayersProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dualar'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
              },
              decoration: InputDecoration(
                hintText: 'Dua ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Category Filter
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPadding,
              ),
              children: _prayerCategories
                  .map(
                    (category) => _buildCategoryChip(
                      category.key,
                      category.value,
                      selectedCategory,
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMD),

          // Prayer List
          Expanded(
            child: prayersAsync.when(
              data: (prayers) {
                if (prayers.isEmpty) {
                  return _buildEmptyState();
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPadding,
                  ),
                  itemCount: prayers.length,
                  itemBuilder: (context, index) {
                    return _buildPrayerCard(prayers[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _buildErrorState(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? category, String? selected) {
    final isSelected = category == selected;

    return Padding(
      padding: const EdgeInsets.only(right: AppDimensions.spacingSM),
      child: GestureDetector(
        onTap: () {
          ref.read(selectedCategoryProvider.notifier).state = category;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingMD,
            vertical: AppDimensions.spacingSM,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          ),
          child: Text(
            label,
            style: GoogleFonts.notoSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerCard(Prayer prayer) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingMD),
      child: InkWell(
        onTap: () => _showPrayerDetail(prayer),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      prayer.title,
                      style: GoogleFonts.notoSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: prayer.isFavorite
                        ? 'Favorilerden çıkar'
                        : 'Favorilere ekle',
                    icon: Icon(
                      prayer.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: prayer.isFavorite
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                    onPressed: () => _toggleFavorite(prayer),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingSM),
              Text(
                prayer.arabic,
                style: GoogleFonts.amiri(
                  fontSize: 24,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: AppDimensions.spacingSM),
              Text(
                prayer.turkish,
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppDimensions.spacingSM),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacingSM,
                      vertical: AppDimensions.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.5),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSmall),
                    ),
                    child: Text(
                      _categoryLabel(prayer.category).toUpperCase(),
                      style: GoogleFonts.notoSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _sharePrayer(prayer),
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('Paylaş'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppDimensions.spacingMD),
          Text(
            'Dua bulunamadı',
            style: GoogleFonts.notoSans(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: AppDimensions.spacingMD),
          Text(
            'Dualar yüklenemedi',
            style: GoogleFonts.notoSans(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMD),
          ElevatedButton(
            onPressed: () => ref.invalidate(dailyPrayersProvider),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFavorite(Prayer prayer) async {
    HapticFeedback.lightImpact();
    final isFavorite =
        await ref.read(favoritePrayerIdsProvider.notifier).toggle(prayer.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite
              ? '${prayer.title} favorilere eklendi'
              : '${prayer.title} favorilerden çıkarıldı',
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _sharePrayer(Prayer prayer) async {
    final text = _formatPrayerShareText(prayer);
    await AppShareService.shareText(
      context: context,
      text: text,
      subject: prayer.title,
      fallbackMessage: 'Bu tarayıcı paylaşımı açamadı; dua panoya kopyalandı.',
    );
  }

  void _showPrayerDetail(Prayer prayer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusLarge),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: AppDimensions.spacingSM),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            prayer.title,
                            style: GoogleFonts.notoSans(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Paylaş',
                          icon: const Icon(Icons.share),
                          onPressed: () => _sharePrayer(prayer),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingLG),

                    Wrap(
                      spacing: AppDimensions.spacingSM,
                      runSpacing: AppDimensions.spacingSM,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _speakPrayer(prayer, true),
                          icon: const Icon(Icons.volume_up),
                          label: const Text('Arapça Dinle'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _speakPrayer(prayer, false),
                          icon: const Icon(Icons.record_voice_over),
                          label: const Text('Türkçe Dinle'),
                        ),
                        IconButton(
                          tooltip: 'Sesi durdur',
                          onPressed: _stopPrayerAudio,
                          icon: const Icon(Icons.stop_circle_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingLG),

                    // Arabic
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimensions.spacingLG),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.3),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                      child: Text(
                        prayer.arabic,
                        style: GoogleFonts.amiri(
                          fontSize: 32,
                          height: 1.8,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingLG),

                    // Turkish Translation
                    Text(
                      'Türkçe Meali',
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingSM),
                    Text(
                      prayer.turkish,
                      style: GoogleFonts.notoSans(
                        fontSize: 18,
                        height: 1.6,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (prayer.meaning.isNotEmpty) ...[
                      const SizedBox(height: AppDimensions.spacingLG),
                      Text(
                        'Anlamı',
                        style: GoogleFonts.notoSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingSM),
                      Text(
                        prayer.meaning,
                        style: GoogleFonts.notoSans(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _speakPrayer(Prayer prayer, bool arabic) async {
    var started = false;

    if (arabic) {
      final references = _quranPrayerAudio[prayer.id];
      if (references != null) {
        started = await ref.read(quranAudioProvider).playReferences(references);
      }
    } else {
      final wholeSurahId = switch (prayer.id) {
        '6' => 113,
        '7' => 114,
        '8' => 112,
        '10' => 1,
        _ => null,
      };
      if (wholeSurahId != null) {
        started =
            await ref.read(quranAudioProvider).playTurkishMeal(wholeSurahId);
      }
    }

    if (!started) {
      started = await ref.read(textToSpeechProvider).speak(
            arabic ? prayer.arabic : prayer.turkish,
            arabic ? SpeechLanguage.arabic : SpeechLanguage.turkish,
          );
    }

    if (!started && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Ses başlatılamadı. Telefonun sesini açıp tekrar deneyin.',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _stopPrayerAudio() async {
    await ref.read(quranAudioProvider).stop();
    await ref.read(textToSpeechProvider).stop();
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'sabah':
        return 'Sabah';
      case 'aksam':
        return 'Akşam';
      case 'gunluk':
        return 'Günlük';
      case 'yemek':
        return 'Yemek';
      case 'hastalik':
        return 'Hastalık';
      case 'korunma':
        return 'Korunma';
      case 'namaz':
        return 'Namaz';
      case 'aile':
        return 'Aile';
      case 'yolculuk':
        return 'Yolculuk';
      default:
        return category;
    }
  }

  String _formatPrayerShareText(Prayer prayer) {
    final buffer = StringBuffer()
      ..writeln(prayer.title)
      ..writeln()
      ..writeln(prayer.arabic)
      ..writeln()
      ..writeln(prayer.turkish);

    if (prayer.meaning.trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(prayer.meaning);
    }

    buffer
      ..writeln()
      ..write('Manevi Rehber');

    return buffer.toString();
  }
}
