import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../data/models/zikr.dart';
import '../../data/services/quran_audio_service.dart';
import '../../data/services/text_to_speech_service.dart';
import '../providers/providers.dart';
import '../widgets/memorial_donation_sheet.dart';
import '../widgets/zikr_counter.dart';

class ZikrScreen extends ConsumerWidget {
  const ZikrScreen({super.key});

  static const Map<String, String> _wikimediaArabicAudio = {
    'elhamdulillah':
        'https://upload.wikimedia.org/wikipedia/commons/transcoded/7/73/Ar-%D8%A7%D9%84%D8%AD%D9%85%D8%AF_%D9%84%D9%84%D9%87.ogg/Ar-%D8%A7%D9%84%D8%AD%D9%85%D8%AF_%D9%84%D9%84%D9%87.ogg.mp3',
    'allahu_ekber':
        'https://upload.wikimedia.org/wikipedia/commons/transcoded/6/69/Ar-eg-%D8%A7%D9%84%D9%84%D9%87_%D8%A3%D9%83%D8%A8%D8%B1.oga/Ar-eg-%D8%A7%D9%84%D9%84%D9%87_%D8%A3%D9%83%D8%A8%D8%B1.oga.mp3',
  };

  static const Map<String, List<QuranAudioReference>> _quranArabicAudio = {
    'subhanallah': [QuranAudioReference(37, 159)],
    'la_ilahe_illallah': [QuranAudioReference(37, 35)],
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zikrList = ref.watch(zikrListProvider);
    final selectedZikrSeed = ref.watch(selectedZikrProvider);
    final selectedZikr = selectedZikrSeed == null
        ? null
        : zikrList.firstWhere(
            (zikr) => zikr.id == selectedZikrSeed.id,
            orElse: () => selectedZikrSeed,
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zikir'),
        actions: [
          IconButton(
            tooltip: 'Zikir Ekle',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showZikrDialog(context, ref),
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
        child: Column(
          children: [
            // Zikr Selection Tabs
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPadding,
              ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: zikrList.length,
              itemBuilder: (context, index) {
                final zikr = zikrList[index];
                final isSelected = selectedZikr?.id == zikr.id;

                return Padding(
                  padding:
                      const EdgeInsets.only(right: AppDimensions.spacingSM),
                  child: GestureDetector(
                    onTap: () {
                      ref.read(selectedZikrProvider.notifier).state = zikr;
                    },
                    onLongPress: zikr.isCustom
                        ? () => _showCustomZikrMenu(context, ref, zikr)
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingMD,
                        vertical: AppDimensions.spacingSM,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusLarge),
                      ),
                      child: Row(
                        children: [
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.white,
                            ),
                          if (isSelected)
                            const SizedBox(width: AppDimensions.spacingXS),
                          Text(
                            zikr.name,
                            style: GoogleFonts.notoSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacingXS),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.2)
                                  : AppColors.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${zikr.currentCount}',
                              style: GoogleFonts.notoSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
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
          const SizedBox(height: AppDimensions.spacingMD),

          if (selectedZikr != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPadding,
              ),
              child: _buildAudioActions(context, ref, selectedZikr),
            ),
          if (selectedZikr != null)
            const SizedBox(height: AppDimensions.spacingMD),

          // Counter
          Expanded(
            child: selectedZikr != null
                ? Column(
                    children: [
                      Expanded(
                        child: ZikrCounter(
                          zikr: selectedZikr,
                          onIncrement: () {
                            ref
                                .read(zikrListProvider.notifier)
                                .increment(selectedZikr.id);
                          },
                          onReset: () {
                            _resetZikr(context, ref, selectedZikr);
                          },
                        ),
                      ),
                      if (selectedZikr.currentCount > 0)
                        _buildCounterActions(context, ref, selectedZikr),
                    ],
                  )
                : Center(
                    child: Text(
                      'Zikir seçin',
                      style: GoogleFonts.notoSans(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
          ),

          // Daily Progress
          _buildDailyProgress(zikrList),
        ],
      ),
    ),
  );
  }

  Widget _buildAudioActions(BuildContext context, WidgetRef ref, Zikr zikr) {
    return Wrap(
      spacing: AppDimensions.spacingSM,
      runSpacing: AppDimensions.spacingSM,
      alignment: WrapAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: () => _playZikrAudio(
            context,
            ref,
            zikr,
            SpeechLanguage.arabic,
          ),
          icon: const Icon(Icons.volume_up),
          label: const Text('Arapça Dinle'),
        ),
        OutlinedButton.icon(
          onPressed: () => _playZikrAudio(
            context,
            ref,
            zikr,
            SpeechLanguage.turkish,
          ),
          icon: const Icon(Icons.record_voice_over),
          label: const Text('Türkçe Dinle'),
        ),
        IconButton(
          tooltip: 'Sesi durdur',
          onPressed: () async {
            await ref.read(quranAudioProvider).stop();
            await ref.read(textToSpeechProvider).stop();
          },
          icon: const Icon(Icons.stop_circle_outlined),
        ),
      ],
    );
  }

  Future<void> _playZikrAudio(
    BuildContext context,
    WidgetRef ref,
    Zikr zikr,
    SpeechLanguage language,
  ) async {
    var started = false;

    if (language == SpeechLanguage.arabic) {
      final url = _wikimediaArabicAudio[zikr.id];
      if (url != null) {
        started = await ref.read(quranAudioProvider).playUrl(url);
      }

      if (!started) {
        final references = _quranArabicAudio[zikr.id];
        if (references != null) {
          started =
              await ref.read(quranAudioProvider).playReferences(references);
        }
      }
    }

    if (!started && context.mounted) {
      _showSpeechError(context);
    }
  }

  Widget _buildCounterActions(
    BuildContext context,
    WidgetRef ref,
    Zikr zikr,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.screenPadding,
        0,
        AppDimensions.screenPadding,
        AppDimensions.spacingMD,
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppDimensions.spacingSM,
        runSpacing: AppDimensions.spacingSM,
        children: [
          OutlinedButton.icon(
            onPressed: () => _resetZikr(context, ref, zikr),
            icon: const Icon(Icons.restart_alt),
            label: const Text('Sıfırla'),
          ),
          ElevatedButton.icon(
            onPressed: () => _donateCompletedZikr(context, ref, zikr),
            icon: const Icon(Icons.volunteer_activism),
            label: const Text('Bağışla'),
          ),
        ],
      ),
    );
  }

  Future<void> _donateCompletedZikr(
    BuildContext context,
    WidgetRef ref,
    Zikr zikr,
  ) async {
    final result = await showMemorialDonationSheet(
      context: context,
      ref: ref,
      initialKey: 'tasbihCount',
      tasbihAmount:
          zikr.currentCount > 0 ? zikr.currentCount : zikr.targetCount,
      title: 'Bağış Yap',
      note:
          '${zikr.name} sayacındaki mevcut sayıyı tesbih olarak bağışlayabilir; aynı pencereden Yasin veya Hatim bağışı da ekleyebilirsin. Sayaç bağıştan sonra kaldığı yerden devam eder.',
    );

    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sayaç kaldığı yerden devam ediyor.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _resetZikr(BuildContext context, WidgetRef ref, Zikr zikr) {
    ref.read(zikrListProvider.notifier).reset(zikr.id);
    _showResetDialog(context);
  }

  Widget _buildDailyProgress(List<Zikr> zikrList) {
    final totalCount = zikrList.fold<int>(
      0,
      (total, zikr) => total + zikr.currentCount,
    );
    final completedCycles = zikrList.fold<int>(
      0,
      (total, zikr) => total + zikr.completedCycles,
    );
    final targetTotal = zikrList.fold<int>(
      0,
      (total, zikr) => total + zikr.targetCount,
    );
    final progress = targetTotal == 0
        ? 0.0
        : (totalCount / targetTotal).clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingLG),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLarge),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Zikir İlerlemesi',
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$totalCount zikir • $completedCycles tur',
                style: GoogleFonts.notoSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingSM),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Zikir sıfırlandı'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
      ),
    );
  }

  void _showSpeechError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Bu içerik için insan sesi kaydı henüz yok.',
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
      ),
    );
  }

  void _showCustomZikrMenu(
    BuildContext context,
    WidgetRef ref,
    Zikr zikr,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLarge),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingMD),
              child: Text(
                zikr.name,
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: AppColors.primary),
              title: const Text('Düzenle'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showZikrDialog(context, ref, existing: zikr);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Sil'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final confirmed = await _confirmDelete(context, zikr.name);
                if (!confirmed) return;
                await ref.read(zikrListProvider.notifier).deleteCustomZikr(zikr.id);
                ref.read(selectedZikrProvider.notifier).state = null;
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${zikr.name} silindi'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: AppDimensions.spacingSM),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Zikri Sil'),
        content: Text('\"$name\" zikrini silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _showZikrDialog(
    BuildContext context,
    WidgetRef ref, {
    Zikr? existing,
  }) async {
    final isEditing = existing != null;
    final nameController =
        TextEditingController(text: existing?.name ?? '');
    final arabicController =
        TextEditingController(text: existing?.arabic ?? '');
    final meaningController =
        TextEditingController(text: existing?.meaning ?? '');
    var targetCount = existing?.targetCount ?? 33;
    final categoryController =
        TextEditingController(text: existing?.category ?? 'custom');

    final result = await showDialog<Zikr>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          scrollable: true,
          title: Text(isEditing ? 'Zikri Düzenle' : 'Yeni Zikir Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Zikir adı',
                  hintText: 'Subhanallah',
                  prefixIcon: Icon(Icons.text_fields),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingSM),
              TextField(
                controller: arabicController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Arapça (opsiyonel)',
                  prefixIcon: Icon(Icons.translate),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingSM),
              TextField(
                controller: meaningController,
                decoration: const InputDecoration(
                  labelText: 'Anlamı / Türkçesi',
                  prefixIcon: Icon(Icons.lightbulb_outline),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingSM),
              Row(
                children: [
                  const Text('Hedef sayı: '),
                  Expanded(
                    child: Slider(
                      value: targetCount.toDouble(),
                      min: 1,
                      max: 200,
                      divisions: 199,
                      label: '$targetCount',
                      activeColor: AppColors.primary,
                      onChanged: (value) =>
                          setDialogState(() => targetCount = value.round()),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      '$targetCount',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final id = existing?.id ??
                    'custom_${DateTime.now().millisecondsSinceEpoch}';
                Navigator.pop(
                  dialogContext,
                  Zikr(
                    id: id,
                    name: name,
                    arabic: arabicController.text.trim(),
                    meaning: meaningController.text.trim(),
                    targetCount: targetCount,
                    category: categoryController.text.trim().isEmpty
                        ? 'custom'
                        : categoryController.text.trim(),
                    isCustom: true,
                  ),
                );
              },
              child: Text(isEditing ? 'Kaydet' : 'Ekle'),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    arabicController.dispose();
    meaningController.dispose();
    categoryController.dispose();

    if (result == null) return;

    if (isEditing) {
      await ref.read(zikrListProvider.notifier).updateCustomZikr(result);
    } else {
      await ref.read(zikrListProvider.notifier).addCustomZikr(result);
    }
    ref.read(selectedZikrProvider.notifier).state = result;

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isEditing
            ? '${result.name} güncellendi'
            : '${result.name} eklendi'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
