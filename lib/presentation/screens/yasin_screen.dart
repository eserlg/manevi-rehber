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

/// Yasin-i Şerif için özel okuma sayfası.
/// - Sure 36 (Yasin) ayetlerini arapça + Türkçe meal gösterir
/// - Ayet ayet sesli okuma
/// - Sayfa sonuna gelince "Yasin okundu, bağışla?" sorgusu
class YasinScreen extends ConsumerStatefulWidget {
  const YasinScreen({super.key});

  @override
  ConsumerState<YasinScreen> createState() => _YasinScreenState();
}

class _YasinScreenState extends ConsumerState<YasinScreen> {
  static const int _yasinSurahId = 36;
  final ScrollController _scrollController = ScrollController();
  late final TextToSpeechService _speechService;
  late final QuranAudioService _quranAudioService;
  bool _donationPromptShown = false;
  bool _hasReadAll = false;

  @override
  void initState() {
    super.initState();
    _speechService = ref.read(textToSpeechProvider);
    _quranAudioService = ref.read(quranAudioProvider);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _speechService.stop();
    _quranAudioService.stop();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    if (max - current < 240 && !_donationPromptShown) {
      _donationPromptShown = true;
      _hasReadAll = true;
      _maybePromptDonation();
    }
  }

  Future<void> _maybePromptDonation() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    final shouldDonate = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.volunteer_activism, color: AppColors.primary),
            const SizedBox(width: AppDimensions.spacingSM),
            const Text('Yasin tamamlandı'),
          ],
        ),
        content: const Text(
          'Yasin-i Şerif\'i okudunuz. Bu sevabı kayıtlı vefat hatırası kişilerinden birine bağışlamak ister misiniz?',
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
    if (shouldDonate == true && mounted) {
      await showMemorialDonationSheet(
        context: context,
        ref: ref,
        initialKey: 'yasinCount',
        title: 'Yasin Bağışla',
        note:
            'Okunan Yasin-i Şerif sevabı kayıtlı kişilerden birine bağışlanacak.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final surahsAsync = ref.watch(surahsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yasin-i Şerif'),
        actions: [
          IconButton(
            tooltip: 'Yasin Bağışla',
            icon: const Icon(Icons.volunteer_activism_outlined),
            onPressed: () => showMemorialDonationSheet(
              context: context,
              ref: ref,
              initialKey: 'yasinCount',
              title: 'Yasin Bağışla',
              note: 'Okunan Yasin-i Şerif bağışını kayıtlı kişilerden birine ekleyebilirsin.',
            ),
          ),
        ],
      ),
      body: surahsAsync.when(
        data: (surahs) {
          final yasin = surahs.firstWhere(
            (s) => s.id == _yasinSurahId,
            orElse: () => surahs.isNotEmpty
                ? surahs.first
                : Surah(
                    id: _yasinSurahId,
                    name: 'يس',
                    englishName: 'Yasin',
                    englishNameTranslation: 'Ya Sin',
                    numberOfAyahs: 83,
                    revelationType: 'Meccan',
                  ),
          );
          return _buildYasinContent(yasin);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildError(),
      ),
    );
  }

  Widget _buildYasinContent(Surah yasin) {
    final versesAsync = ref.watch(versesProvider(_yasinSurahId));
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
          child: Column(
            children: [
              Text(
                yasin.name,
                style: GoogleFonts.amiri(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingSM),
              Text(
                'Yasin-i Şerif • ${yasin.numberOfAyahs} Ayet',
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXS),
              Text(
                'Surelerden hangisi okursanız okuyun, sonuna geldiğinizde sevabını bağışlayabilirsiniz.',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(
                  fontSize: 11,
                  height: 1.4,
                  color: Colors.white.withOpacity(0.82),
                ),
              ),
            ],
          ),
        ),
        // Audio bar
        versesAsync.maybeWhen(
          data: (verses) => _buildAudioBar(verses),
          orElse: () => const SizedBox.shrink(),
        ),
        // Verses list
        Expanded(
          child: versesAsync.when(
            data: (verses) {
              if (verses.isEmpty) return _buildError();
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppDimensions.screenPadding),
                itemCount: verses.length + 1,
                itemBuilder: (context, index) {
                  if (index == verses.length) {
                    return _buildFooter(verses.length);
                  }
                  return _buildVerseCard(verses[index], index + 1);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _buildError(),
          ),
        ),
      ],
    );
  }

  Widget _buildAudioBar(List<Verse> verses) {
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
            onPressed: () => _speak(true),
            icon: const Icon(Icons.volume_up),
            label: const Text('Arapça Kıraat'),
          ),
          OutlinedButton.icon(
            onPressed: () => _speak(false),
            icon: const Icon(Icons.record_voice_over),
            label: const Text('Türkçe Meal'),
          ),
          IconButton(
            tooltip: 'Sesi durdur',
            onPressed: () {
              _speechService.stop();
              _quranAudioService.stop();
            },
            icon: const Icon(Icons.stop_circle_outlined),
          ),
        ],
      ),
    );
  }

  Future<void> _speak(bool arabic) async {
    await _speechService.stop();
    final started = arabic
        ? await _quranAudioService.playSurah(_yasinSurahId)
        : await _quranAudioService.playTurkishMeal(_yasinSurahId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          started
              ? 'Yasin-i Şerif okunuyor'
              : 'Ses başlatılamadı, interneti kontrol edin.',
        ),
        backgroundColor: started ? null : AppColors.error,
      ),
    );
  }

  Widget _buildVerseCard(Verse verse, int number) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingMD),
      padding: const EdgeInsets.all(AppDimensions.spacingMD),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
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
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
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
              const Spacer(),
              IconButton(
                tooltip: 'Bu ayeti dinle',
                icon: Icon(
                  Icons.play_circle_outline,
                  color: AppColors.primary,
                  size: 24,
                ),
                onPressed: () async {
                  await _speechService.stop();
                  await _quranAudioService.playReferences([
                    QuranAudioReference(_yasinSurahId, verse.verseKey),
                  ]);
                },
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingSM),
          Text(
            verse.text,
            style: GoogleFonts.amiri(
              fontSize: 24,
              height: 1.8,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
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

  Widget _buildFooter(int verseCount) {
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
        if (!_hasReadAll)
          ElevatedButton.icon(
            onPressed: () {
              _hasReadAll = true;
              _maybePromptDonation();
            },
            icon: const Icon(Icons.volunteer_activism_outlined),
            label: const Text('Yasin tamam, bağışla'),
          )
        else
          Text(
            'Bağış için teşekkürler',
            style: GoogleFonts.notoSans(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        const SizedBox(height: AppDimensions.spacingXL),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: AppDimensions.spacingMD),
          Text(
            'Yasin yüklenemedi',
            style: GoogleFonts.notoSans(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.spacingMD),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(surahsProvider);
              ref.invalidate(versesProvider(_yasinSurahId));
            },
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }
}