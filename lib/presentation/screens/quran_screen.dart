import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../data/models/quran.dart';
import '../../data/services/quran_audio_service.dart';
import '../../data/services/text_to_speech_service.dart';
import '../providers/providers.dart';
import '../widgets/memorial_donation_sheet.dart';

class QuranScreen extends ConsumerWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahsAsync = ref.watch(surahsProvider);
    final lastReadAsync = ref.watch(lastReadProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kur\'an-ı Kerim'),
        actions: [
          IconButton(
            tooltip: 'Hatim bağışla',
            onPressed: () => showMemorialDonationSheet(
              context: context,
              ref: ref,
              initialKey: 'hatimCount',
              title: 'Hatim Bağışla',
              note:
                  'Tamamlanan hatmi kayıtlı vefat hatırası kişilerinden birine ekleyebilirsin.',
            ),
            icon: const Icon(Icons.volunteer_activism_outlined),
          ),
        ],
      ),
      body: surahsAsync.when(
        data: (surahs) {
          if (surahs.isEmpty) {
            return _buildEmptyState(ref);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            itemCount: surahs.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildContinueCard(context, ref, lastReadAsync, surahs);
              }
              return _buildSurahCard(context, ref, surahs[index - 1]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildErrorState(ref),
      ),
    );
  }

  Widget _buildContinueCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<Map<String, int>?> lastReadAsync,
    List<Surah> surahs,
  ) {
    return lastReadAsync.when(
      data: (lastRead) {
        if (lastRead == null) return const SizedBox.shrink();

        final surahId = lastRead['surah'];
        final verseId = lastRead['verse'];
        final surah = surahs.where((s) => s.id == surahId).firstOrNull;
        if (surah == null || verseId == null) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.only(bottom: AppDimensions.spacingMD),
          child: ListTile(
            leading: Icon(Icons.bookmark, color: AppColors.accent),
            title: const Text('Kaldığın yerden devam et'),
            subtitle: Text('${surah.englishName} - $verseId. ayet'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SurahDetailScreen(
                    surah: surah,
                    initialVerse: verseId,
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSurahCard(BuildContext context, WidgetRef ref, Surah surah) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingSM),
      child: InkWell(
        onTap: () {
          ref.read(selectedSurahProvider.notifier).state = surah;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SurahDetailScreen(surah: surah),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingMD),
          child: Row(
            children: [
              // Surah Number
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Center(
                  child: Text(
                    '${surah.id}',
                    style: GoogleFonts.notoSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMD),

              // Surah Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            surah.englishName,
                            style: GoogleFonts.notoSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacingSM,
                            vertical: AppDimensions.spacingXS,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(
                                AppDimensions.radiusSmall),
                          ),
                          child: Text(
                            surah.revelationType == 'Meccan'
                                ? 'Mekki'
                                : 'Medeni',
                            style: GoogleFonts.notoSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      surah.name,
                      style: GoogleFonts.amiri(
                        fontSize: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      '${surah.numberOfAyahs} ayet',
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Play Button
              IconButton(
                icon: Icon(
                  Icons.play_circle_outline,
                  color: AppColors.primary,
                ),
                onPressed: () => _playRecitation(context, ref, surah),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppDimensions.spacingMD),
          Text(
            'Sureler yüklenemedi',
            style: GoogleFonts.notoSans(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMD),
          ElevatedButton(
            onPressed: () => ref.invalidate(surahsProvider),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref) {
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
            'Bir hata oluştu',
            style: GoogleFonts.notoSans(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMD),
          ElevatedButton(
            onPressed: () => ref.invalidate(surahsProvider),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Future<void> _playRecitation(
    BuildContext context,
    WidgetRef ref,
    Surah surah,
  ) async {
    await ref.read(textToSpeechProvider).stop();
    final started = await ref.read(quranAudioProvider).playSurah(surah.id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          started
              ? '${surah.englishName} gerçek kıraat sesiyle okunuyor'
              : 'Kıraat sesi başlatılamadı. İnternet bağlantısını kontrol edin.',
        ),
        backgroundColor: started ? null : AppColors.error,
      ),
    );
  }
}

class SurahDetailScreen extends ConsumerStatefulWidget {
  final Surah surah;
  final int? initialVerse;

  const SurahDetailScreen({
    super.key,
    required this.surah,
    this.initialVerse,
  });

  @override
  ConsumerState<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends ConsumerState<SurahDetailScreen> {
  final _scrollController = ScrollController();
  bool _didScrollToInitialVerse = false;
  bool _donationPromptShown = false;
  late final TextToSpeechService _speechService;
  late final QuranAudioService _quranAudioService;

  @override
  void initState() {
    super.initState();
    _speechService = ref.read(textToSpeechProvider);
    _quranAudioService = ref.read(quranAudioService);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _donationPromptShown) return;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    if (max - current < 240) {
      _donationPromptShown = true;
      _maybePromptDonation();
    }
  }

  Future<void> _maybePromptDonation() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    final surah = widget.surah;
    final isYasin = surah.id == 36;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.volunteer_activism, color: AppColors.primary),
            const SizedBox(width: AppDimensions.spacingSM),
            Text(isYasin ? 'Yasin tamamlandı' : '${surah.englishName} tamamlandı'),
          ],
        ),
        content: Text(
          isYasin
              ? 'Yasin-i Şerif\'i okudunuz. Bu sevabı vefat hatırası kişilerinden birine bağışlamak ister misiniz?'
              : '${surah.englishName} suresini okudunuz. Bu sevabı hatim olarak veya vefat hatırasına bağışlamak ister misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hayır'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.volunteer_activism),
            label: const Text('Bağışla'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await showMemorialDonationSheet(
      context: context,
      ref: ref,
      initialKey: isYasin ? 'yasinCount' : 'hatimCount',
      title: isYasin ? 'Yasin Bağışla' : 'Hatim Bağışla',
      note: 'Okunan ${surah.englishName} sevabı kayıtlı kişilerden birine bağışlanacak.',
    );
  }

  @override
  void dispose() {
    _speechService.stop();
    _quranAudioService.stop();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surah = widget.surah;
    final versesAsync = ref.watch(versesProvider(surah.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(surah.englishName),
      ),
      body: Column(
        children: [
          // Surah Header
          Container(
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: Column(
              children: [
                Text(
                  surah.name,
                  style: GoogleFonts.amiri(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingSM),
                Text(
                  surah.englishNameTranslation,
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingSM),
                Text(
                  '${surah.numberOfAyahs} Ayet • ${surah.revelationType == 'Meccan' ? 'Mekki' : 'Medeni'}',
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          versesAsync.maybeWhen(
            data: (verses) => _buildSurahAudioBar(context, ref, verses),
            orElse: () => const SizedBox.shrink(),
          ),

          // Verses
          Expanded(
            child: versesAsync.when(
              data: (verses) {
                if (verses.isEmpty) {
                  return _buildEmptyState();
                }
                _scrollToInitialVerse(verses);
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppDimensions.screenPadding),
                  itemCount: verses.length + 1,
                  itemBuilder: (context, index) {
                    if (index == verses.length) {
                      return _buildSurahFooter(verses.length);
                    }
                    return _buildVerseCard(
                        context, ref, verses[index], index + 1);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _buildErrorState(ref),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahAudioBar(
    BuildContext context,
    WidgetRef ref,
    List<Verse> verses,
  ) {
    if (verses.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.screenPadding,
        AppDimensions.spacingMD,
        AppDimensions.screenPadding,
        AppDimensions.spacingSM,
      ),
      color: AppColors.background,
      child: Wrap(
        spacing: AppDimensions.spacingSM,
        runSpacing: AppDimensions.spacingSM,
        alignment: WrapAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: () => _speakSurah(context, ref, true),
            icon: const Icon(Icons.volume_up),
            label: const Text('Arapça Kıraat'),
          ),
          OutlinedButton.icon(
            onPressed: () => _speakSurah(context, ref, false),
            icon: const Icon(Icons.record_voice_over),
            label: const Text('Türkçe Meal'),
          ),
          if (widget.surah.id == 36)
            OutlinedButton.icon(
              onPressed: () => showMemorialDonationSheet(
                context: context,
                ref: ref,
                initialKey: 'yasinCount',
                title: 'Yasin Bağışla',
                note:
                    'Okunan Yasin-i Şerif bağışını kayıtlı kişilerden birine ekleyebilirsin.',
              ),
              icon: const Icon(Icons.volunteer_activism_outlined),
              label: const Text('Yasin Bağışla'),
            ),
          IconButton(
            tooltip: 'Sesi durdur',
            onPressed: () {
              ref.read(textToSpeechProvider).stop();
              ref.read(quranAudioProvider).stop();
            },
            icon: const Icon(Icons.stop_circle_outlined),
          ),
        ],
      ),
    );
  }

  Future<void> _speakSurah(
    BuildContext context,
    WidgetRef ref,
    bool arabic,
  ) async {
    if (arabic) {
      await ref.read(textToSpeechProvider).stop();
      final started = await ref.read(quranAudioProvider).playSurah(
            widget.surah.id,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              started
                  ? '${widget.surah.englishName} gerçek kıraat sesiyle okunuyor'
                  : 'Kıraat sesi başlatılamadı. İnternet bağlantısını kontrol edin.',
            ),
            backgroundColor: started ? null : AppColors.error,
          ),
        );
      }
      return;
    }

    await ref.read(textToSpeechProvider).stop();
    final started = await ref.read(quranAudioProvider).playTurkishMeal(
          widget.surah.id,
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            started
                ? '${widget.surah.englishName} Türkçe meal sesiyle okunuyor'
                : 'Türkçe meal sesi başlatılamadı. İnternet bağlantısını kontrol edin.',
          ),
          backgroundColor: started ? null : AppColors.error,
        ),
      );
    }
  }

  void _scrollToInitialVerse(List<Verse> verses) {
    if (_didScrollToInitialVerse || widget.initialVerse == null) return;

    final index =
        verses.indexWhere((verse) => verse.verseKey == widget.initialVerse);
    if (index < 0) return;

    _didScrollToInitialVerse = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo((index * 190).toDouble());
    });
  }

  Widget _buildVerseCard(
      BuildContext context, WidgetRef ref, Verse verse, int number) {
    final isInitialVerse = verse.verseKey == widget.initialVerse;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingMD),
      padding: const EdgeInsets.all(AppDimensions.spacingMD),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: isInitialVerse
            ? Border.all(color: AppColors.accent, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Buradan devam et',
                icon:
                    Icon(Icons.bookmark_add_outlined, color: AppColors.accent),
                onPressed: () async {
                  final storage = ref.read(localStorageProvider);
                  await storage.init();
                  await storage.saveLastRead(widget.surah.id, verse.verseKey);
                  ref.invalidate(lastReadProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Son okunan ayet kaydedildi')),
                    );
                  }
                },
              ),
              const SizedBox(width: AppDimensions.spacingSM),
              Expanded(
                child: Text(
                  verse.text,
                  style: GoogleFonts.amiri(
                    fontSize: 24,
                    height: 1.8,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          if (verse.translation != null) ...[
            const SizedBox(height: AppDimensions.spacingMD),
            const Divider(),
            const SizedBox(height: AppDimensions.spacingSM),
            Text(
              verse.translation!,
              style: GoogleFonts.notoSans(
                fontSize: 14,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'Ayetler yüklenemedi',
        style: GoogleFonts.notoSans(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildSurahFooter(int verseCount) {
    final surah = widget.surah;
    final isYasin = surah.id == 36;
    return Column(
      children: [
        const SizedBox(height: AppDimensions.spacingMD),
        Icon(Icons.volunteer_activism,
            color: AppColors.primary, size: 40),
        const SizedBox(height: AppDimensions.spacingSM),
        Text(
          '$verseCount ayet tamamlandı',
          style: GoogleFonts.notoSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingSM),
        ElevatedButton.icon(
          onPressed: _donationPromptShown
              ? null
              : () {
                  _donationPromptShown = true;
                  _maybePromptDonation();
                },
          icon: const Icon(Icons.volunteer_activism_outlined),
          label: Text(isYasin ? 'Yasin Bağışla' : 'Hatim Bağışla'),
        ),
        const SizedBox(height: AppDimensions.spacingXL),
      ],
    );
  }

  Widget _buildErrorState(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: AppDimensions.spacingMD),
          Text(
            'Ayetler yüklenemedi',
            style: GoogleFonts.notoSans(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.spacingMD),
          ElevatedButton(
            onPressed: () => ref.invalidate(versesProvider(widget.surah.id)),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }
}
