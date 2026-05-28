import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../data/models/prayer_guide.dart';

class PrayerGuideScreen extends StatefulWidget {
  const PrayerGuideScreen({super.key});

  @override
  State<PrayerGuideScreen> createState() => _PrayerGuideScreenState();
}

class _PrayerGuideScreenState extends State<PrayerGuideScreen> {
  static const _learningProgressKey = 'quran_learning_step_index';
  late final Future<List<PrayerGuide>> _guidesFuture;
  String _selectedCategory = 'tum';
  int _learningStepIndex = 0;

  static const _categories = [
    ('tum', 'Tümü'),
    ('gunluk', 'Günlük'),
    ('cuma', 'Cuma'),
    ('ozel', 'Özel'),
    ('cenaze', 'Cenaze'),
    ('nafile', 'Nafile'),
    ('okunanlar', 'Sure/Dua'),
    ('ogreniyorum', 'Kur’an Öğreniyorum'),
  ];

  @override
  void initState() {
    super.initState();
    _guidesFuture = _loadGuides();
    _loadLearningProgress();
  }

  Future<void> _loadLearningProgress() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _learningStepIndex = prefs
              .getInt(_learningProgressKey)
              ?.clamp(0, _quranLearningSteps.length - 1)
              .toInt() ??
          0;
    });
  }

  Future<void> _saveLearningProgress(int index) async {
    final safeIndex = index.clamp(0, _quranLearningSteps.length - 1).toInt();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_learningProgressKey, safeIndex);
    if (!mounted) return;
    setState(() => _learningStepIndex = safeIndex);
  }

  Future<List<PrayerGuide>> _loadGuides() async {
    final jsonString =
        await rootBundle.loadString('assets/data/prayer_guides.json');
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList
        .whereType<Map>()
        .map((json) => PrayerGuide.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Namaz Rehberi'),
      ),
      body: FutureBuilder<List<PrayerGuide>>(
        future: _guidesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.screenPadding),
                child: Text(
                  'Namaz rehberi yüklenemedi',
                  style: GoogleFonts.notoSans(color: AppColors.textSecondary),
                ),
              ),
            );
          }

          final guides = snapshot.data ?? [];
          final filteredGuides = _selectedCategory == 'tum'
              ? guides
              : guides
                  .where((guide) => guide.category == _selectedCategory)
                  .toList();

          return ListView(
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            children: [
              _buildHeader(),
              const SizedBox(height: AppDimensions.spacingMD),
              _buildCategoryChips(),
              const SizedBox(height: AppDimensions.spacingMD),
              if (_selectedCategory == 'okunanlar')
                _buildPrayerTextsSection()
              else if (_selectedCategory == 'ogreniyorum')
                _buildQuranLearningSection()
              else
                for (final guide in filteredGuides) _buildGuideCard(guide),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingLG),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingSM),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: const Icon(Icons.mosque, color: Colors.white),
              ),
              const SizedBox(width: AppDimensions.spacingMD),
              Expanded(
                child: Text(
                  'Rekat ve Okuma Bilgileri',
                  style: GoogleFonts.amiri(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMD),
          Text(
            'Günlük, özel ve nafile namazlar için kısa rekat düzeni, okunacak sure ve dualar.',
            style: GoogleFonts.notoSans(
              fontSize: 13,
              height: 1.45,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSM),
          Text(
            'Not: Mezhep ve yerel uygulamalarda farklılık olabilir; kesin hüküm için güvenilir ilmihal veya din görevlisine başvurulmalıdır.',
            style: GoogleFonts.notoSans(
              fontSize: 12,
              height: 1.45,
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: AppDimensions.spacingSM,
      runSpacing: AppDimensions.spacingSM,
      children: [
        for (final category in _categories)
          ChoiceChip(
            label: Text(category.$2),
            selected: _selectedCategory == category.$1,
            selectedColor: AppColors.primary,
            labelStyle: GoogleFonts.notoSans(
              color: _selectedCategory == category.$1
                  ? Colors.white
                  : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: AppColors.surfaceVariant,
            side: const BorderSide(color: Colors.transparent),
            onSelected: (_) {
              setState(() => _selectedCategory = category.$1);
            },
          ),
      ],
    );
  }

  Widget _buildGuideCard(PrayerGuide guide) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingMD),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMD,
          vertical: AppDimensions.spacingSM,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppDimensions.spacingMD,
          0,
          AppDimensions.spacingMD,
          AppDimensions.spacingMD,
        ),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          child:
              Icon(_iconForCategory(guide.category), color: AppColors.primary),
        ),
        title: Text(
          guide.title,
          style: GoogleFonts.notoSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppDimensions.spacingXS),
          child: Text(
            guide.subtitle,
            style: GoogleFonts.notoSans(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        children: [
          _buildSummary(guide),
          const SizedBox(height: AppDimensions.spacingMD),
          for (final section in guide.sections) _buildSection(section),
        ],
      ),
    );
  }

  Widget _buildPrayerTextsSection() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.spacingMD),
          margin: const EdgeInsets.only(bottom: AppDimensions.spacingMD),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border:
                Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
          ),
          child: Text(
            'Namazda sık okunan sure ve dualar Arapça metin, okunuş ve Türkçe anlamıyla burada. Ezber için kısa surelerden başlayabilirsin.',
            style: GoogleFonts.notoSans(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        for (final item in _prayerTexts) _buildPrayerTextCard(item),
      ],
    );
  }

  Widget _buildPrayerTextCard(_PrayerText item) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingMD),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMD,
          vertical: AppDimensions.spacingSM,
        ),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Icon(item.icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.visible,
          style: GoogleFonts.notoSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          item.usage,
          style: GoogleFonts.notoSans(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppDimensions.spacingMD,
          0,
          AppDimensions.spacingMD,
          AppDimensions.spacingMD,
        ),
        children: [
          Text(
            item.arabic,
            textAlign: TextAlign.right,
            style: GoogleFonts.amiri(
              fontSize: 26,
              height: 1.8,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMD),
          _labelBlock('Okunuş', item.transliteration),
          const SizedBox(height: AppDimensions.spacingSM),
          _labelBlock('Türkçe anlamı', item.meaning),
        ],
      ),
    );
  }

  Widget _buildQuranLearningSection() {
    final currentStep = _quranLearningSteps[_learningStepIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacingMD),
          margin: const EdgeInsets.only(bottom: AppDimensions.spacingMD),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border:
                Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.school_outlined, color: AppColors.primary),
                  const SizedBox(width: AppDimensions.spacingSM),
                  Expanded(
                    child: Text(
                      'Kaldığın yer: ${currentStep.title}',
                      style: GoogleFonts.notoSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingSM),
              LinearProgressIndicator(
                value: (_learningStepIndex + 1) / _quranLearningSteps.length,
                minHeight: 8,
                color: AppColors.primary,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
              ),
              const SizedBox(height: AppDimensions.spacingSM),
              Text(
                'Önce Elif-Ba cüzü gibi harf, hareke ve okunuş temelinden başlar; sonra kısa surelerle Kur’an okuma pratiğine geçirir.',
                style: GoogleFonts.notoSans(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        for (var index = 0; index < _quranLearningSteps.length; index += 1)
          _buildQuranLearningCard(_quranLearningSteps[index], index),
      ],
    );
  }

  Widget _buildQuranLearningCard(_QuranLearningStep step, int index) {
    final isCurrent = index == _learningStepIndex;
    final isCompleted = index < _learningStepIndex;

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingMD),
      child: ExpansionTile(
        initiallyExpanded: isCurrent,
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMD,
          vertical: AppDimensions.spacingSM,
        ),
        leading: CircleAvatar(
          backgroundColor: isCurrent
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.1),
          child: Icon(
            isCompleted ? Icons.check : step.icon,
            color: isCurrent ? Colors.white : AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(
          step.title,
          style: GoogleFonts.notoSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          step.subtitle,
          style: GoogleFonts.notoSans(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppDimensions.spacingMD,
          0,
          AppDimensions.spacingMD,
          AppDimensions.spacingMD,
        ),
        children: [
          if (step.letters.isNotEmpty) ...[
            _buildLetterGrid(step.letters),
            const SizedBox(height: AppDimensions.spacingMD),
          ],
          Text(
            step.arabic,
            textAlign: TextAlign.right,
            style: GoogleFonts.amiri(
              fontSize: 30,
              height: 1.8,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMD),
          _labelBlock('Okunuş', step.transliteration),
          const SizedBox(height: AppDimensions.spacingSM),
          _labelBlock('Türkçe anlatım', step.explanation),
          if (step.practice.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingSM),
            _buildPracticeList(step.practice),
          ],
          const SizedBox(height: AppDimensions.spacingMD),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _saveLearningProgress(index),
                  icon: const Icon(Icons.bookmark_border),
                  label: const Text('Kaldığım Yer'),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingSM),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _saveLearningProgress(index + 1),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Sonraki'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLetterGrid(List<_LetterItem> letters) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: letters.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: AppDimensions.spacingSM,
        crossAxisSpacing: AppDimensions.spacingSM,
        childAspectRatio: 0.86,
      ),
      itemBuilder: (context, index) {
        final letter = letters[index];
        return Container(
          padding: const EdgeInsets.all(AppDimensions.spacingSM),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                letter.arabic,
                textAlign: TextAlign.center,
                style: GoogleFonts.amiri(
                  fontSize: 32,
                  height: 1,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXS),
              Text(
                letter.name,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                letter.sound,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPracticeList(List<String> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingMD),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alıştırma',
            style: GoogleFonts.notoSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSM),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spacingXS),
              child: Text(
                item,
                style: GoogleFonts.notoSans(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _labelBlock(String label, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingMD),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.notoSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            text,
            style: GoogleFonts.notoSans(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(PrayerGuide guide) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingMD),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.format_list_numbered,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppDimensions.spacingSM),
              Text(
                guide.totalRakat,
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingSM),
          Text(
            guide.shortDescription,
            style: GoogleFonts.notoSans(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSM),
          Wrap(
            spacing: AppDimensions.spacingSM,
            runSpacing: AppDimensions.spacingSM,
            children: [
              for (final highlight in guide.highlights)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingSM,
                    vertical: AppDimensions.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusCircle),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(
                    highlight,
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(PrayerGuideSection section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 18,
                color: AppColors.accent,
              ),
              const SizedBox(width: AppDimensions.spacingSM),
              Expanded(
                child: Text(
                  section.title,
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (section.body.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingSM),
            Text(
              section.body,
              style: GoogleFonts.notoSans(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppDimensions.spacingSM),
          for (final item in section.items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spacingSM),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: const Icon(
                      Icons.brightness_1,
                      size: 7,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingSM),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.notoSans(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'gunluk':
        return Icons.schedule;
      case 'cuma':
        return Icons.groups_2_outlined;
      case 'ozel':
        return Icons.celebration_outlined;
      case 'cenaze':
        return Icons.volunteer_activism_outlined;
      case 'nafile':
        return Icons.nights_stay_outlined;
      default:
        return Icons.mosque;
    }
  }
}

class _PrayerText {
  final String title;
  final String usage;
  final String arabic;
  final String transliteration;
  final String meaning;
  final IconData icon;

  const _PrayerText({
    required this.title,
    required this.usage,
    required this.arabic,
    required this.transliteration,
    required this.meaning,
    required this.icon,
  });
}

class _QuranLearningStep {
  final String title;
  final String subtitle;
  final List<_LetterItem> letters;
  final String arabic;
  final String transliteration;
  final String explanation;
  final List<String> practice;
  final IconData icon;

  const _QuranLearningStep({
    required this.title,
    required this.subtitle,
    this.letters = const [],
    required this.arabic,
    required this.transliteration,
    required this.explanation,
    this.practice = const [],
    required this.icon,
  });
}

class _LetterItem {
  final String arabic;
  final String name;
  final String sound;

  const _LetterItem(this.arabic, this.name, this.sound);
}

const _quranLearningSteps = [
  _QuranLearningStep(
    title: '1. Harfler: Elif Grubu',
    subtitle: 'Elif, Be, Te, Se, Cim, Ha, Hı',
    letters: [
      _LetterItem('ا', 'Elif', 'a/e uzatma'),
      _LetterItem('ب', 'Be', 'b'),
      _LetterItem('ت', 'Te', 't'),
      _LetterItem('ث', 'Se', 'peltek s'),
      _LetterItem('ج', 'Cim', 'c'),
      _LetterItem('ح', 'Ha', 'boğazdan h'),
      _LetterItem('خ', 'Hı', 'hırıltılı h'),
    ],
    arabic: 'ا ب ت ث\nج ح خ',
    transliteration: 'Elif, Be, Te, Se. Cim, Ha, Hı.',
    explanation:
        'Bu ilk grup Elif-Ba cüzünün başlangıcıdır. Harfin adını, şeklini ve yaklaşık sesini birlikte tanı. Harfleri önce tek tek, sonra soldan sağa değil Arapça yönüyle sağdan sola takip et.',
    practice: [
      'ا harfi çoğu zaman uzatma görevindedir.',
      'ب ت ث aynı gövdeye benzer; noktaların yeri harfi değiştirir.',
      'ج ح خ aynı aile gibidir; nokta ve boğaz sesi farkına dikkat et.',
    ],
    icon: Icons.abc,
  ),
  _QuranLearningStep(
    title: '2. Harfler: Dal-Sad Grubu',
    subtitle: 'Dal, Zel, Ra, Ze, Sin, Şın, Sad, Dad',
    letters: [
      _LetterItem('د', 'Dal', 'd'),
      _LetterItem('ذ', 'Zel', 'peltek z'),
      _LetterItem('ر', 'Ra', 'r'),
      _LetterItem('ز', 'Ze', 'z'),
      _LetterItem('س', 'Sin', 's'),
      _LetterItem('ش', 'Şın', 'ş'),
      _LetterItem('ص', 'Sad', 'kalın s'),
      _LetterItem('ض', 'Dad', 'kalın d/z'),
    ],
    arabic: 'د ذ ر ز\nس ش ص ض',
    transliteration: 'Dal, Zel, Ra, Ze. Sin, Şın, Sad, Dad.',
    explanation:
        'Bu grupta ince ve kalın sesleri ayırmaya başlıyoruz. Sad ve Dad kalın okunur; Sin ve Şın ise daha tanıdık ince seslerdir.',
    practice: [
      'س ile ش farkını noktalardan takip et.',
      'ص ve ض harflerinde sesi kalınlaştırmaya çalış.',
      'ر harfi kelime içinde bazen ince, bazen kalın duyulabilir.',
    ],
    icon: Icons.grid_view,
  ),
  _QuranLearningStep(
    title: '3. Harfler: Ta-Kef Grubu',
    subtitle: 'Tı, Zı, Ayn, Ğayn, Fe, Kaf, Kef',
    letters: [
      _LetterItem('ط', 'Tı', 'kalın t'),
      _LetterItem('ظ', 'Zı', 'kalın z'),
      _LetterItem('ع', 'Ayn', 'boğaz sesi'),
      _LetterItem('غ', 'Ğayn', 'ğ/gırtlak'),
      _LetterItem('ف', 'Fe', 'f'),
      _LetterItem('ق', 'Kaf', 'kalın k'),
      _LetterItem('ك', 'Kef', 'k'),
    ],
    arabic: 'ط ظ ع غ\nف ق ك',
    transliteration: 'Tı, Zı, Ayn, Ğayn. Fe, Kaf, Kef.',
    explanation:
        'Ayn ve Ğayn Türkçede birebir karşılığı olmayan boğaz harfleridir. Kaf daha kalın, Kef daha ince okunur.',
    practice: [
      'ق için sesi ağız arkasından çıkar.',
      'ك için Türkçedeki k sesine yakın oku.',
      'ع harfinde acele etme; sesi boğazdan başlatmayı dene.',
    ],
    icon: Icons.record_voice_over_outlined,
  ),
  _QuranLearningStep(
    title: '4. Harfler: Lam-Ye Grubu',
    subtitle: 'Lam, Mim, Nun, He, Vav, Ye, Hemze',
    letters: [
      _LetterItem('ل', 'Lam', 'l'),
      _LetterItem('م', 'Mim', 'm'),
      _LetterItem('ن', 'Nun', 'n'),
      _LetterItem('ه', 'He', 'h'),
      _LetterItem('و', 'Vav', 'v/u'),
      _LetterItem('ي', 'Ye', 'y/i'),
      _LetterItem('ء', 'Hemze', 'kesik ses'),
    ],
    arabic: 'ل م ن ه\nو ي ء',
    transliteration: 'Lam, Mim, Nun, He. Vav, Ye, Hemze.',
    explanation:
        'Bu grupla temel harfleri tamamlıyoruz. Vav ve Ye hem harf hem de uzatma görevinde karşına çıkar.',
    practice: [
      'م ve ن burundan gelen seslere hazırlık yapar.',
      'و bazen “v”, bazen “uu” uzatması verir.',
      'ي bazen “y”, bazen “ii” uzatması verir.',
    ],
    icon: Icons.done_all,
  ),
  _QuranLearningStep(
    title: '5. Harekeler',
    subtitle: 'Üstün, esre ve ötre',
    arabic: 'بَ بِ بُ\nتَ تِ تُ\nجَ جِ جُ',
    transliteration: 'Be, bi, bu. Te, ti, tu. Ce, ci, cu.',
    explanation:
        'Üstün kısa “e/a”, esre kısa “i”, ötre kısa “u” sesi verir. Harfi hızlıca değil, tane tane okuyarak ilerle.',
    practice: [
      'بَ = be, بِ = bi, بُ = bu',
      'تَ = te, تِ = ti, تُ = tu',
      'جَ = ce, جِ = ci, جُ = cu',
    ],
    icon: Icons.tune,
  ),
  _QuranLearningStep(
    title: '6. Cezm ve Sükun',
    subtitle: 'Harfi durdurarak okuma',
    arabic: 'اَبْ اَتْ اَحْ\nمِنْ عَنْ قُلْ',
    transliteration: 'Eb, et, eh. Min, an, kul.',
    explanation:
        'Cezmli harf kendinden önceki sesle birleşir ve durdurularak okunur. Bu ders kelimeleri akıcı okumaya geçiştir.',
    practice: [
      'اَبْ okurken “e-b” diye kapat.',
      'مِنْ kelimesinde ن harfinde duruş vardır.',
      'قُلْ kelimesinde ل cezimlidir.',
    ],
    icon: Icons.stop_circle_outlined,
  ),
  _QuranLearningStep(
    title: '7. Şedde',
    subtitle: 'Harf iki kere okunur gibi tutulur',
    arabic: 'رَبَّنَا\nاِيَّاكَ\nاَللّٰهُ',
    transliteration: 'Rabbena, iyyake, Allah.',
    explanation:
        'Şedde harfi güçlendirir. Önce harfi kısa tut, sonra devamındaki harekeyi oku. “Rab-be-na” gibi parçalara ayırmak öğrenmeyi kolaylaştırır.',
    practice: [
      'رَبَّنَا = Rab-be-na',
      'اِيَّاكَ = iy-ya-ke',
      'اَللّٰهُ kelimesinde lam şeddelidir.',
    ],
    icon: Icons.compress,
  ),
  _QuranLearningStep(
    title: '8. Uzatma Harfleri',
    subtitle: 'Elif, vav ve ye ile med',
    arabic: 'قَالَ\nنُورٌ\nفِيهِ',
    transliteration: 'Kaa-le, nuur, fii-hi.',
    explanation:
        'Med harfleri sesi uzatır. Elif “aa”, vav “uu”, ye “ii” uzatması verir. Kısa sesle uzun sesi ayırmak kıraat için önemlidir.',
    practice: [
      'قَالَ kelimesinde elif sesi uzatır.',
      'نُورٌ kelimesinde vav “uu” sesi verir.',
      'فِيهِ kelimesinde ye “ii” sesi verir.',
    ],
    icon: Icons.keyboard_double_arrow_right,
  ),
  _QuranLearningStep(
    title: '9. Tenvin',
    subtitle: 'İki üstün, iki esre, iki ötre',
    arabic: 'ـً  ـٍ  ـٌ\nكِتَابًا  نُورٍ  اَحَدٌ',
    transliteration: 'En, in, ün. Kitaben, nurin, ehadün.',
    explanation:
        'Tenvin kelime sonuna n sesi katar. Kısa surelerde çok sık gelir; özellikle durarak okurken hocadan/dinleme kaydından kontrol etmek faydalıdır.',
    practice: [
      'ـً genelde “en/an” gibi duyulur.',
      'ـٍ “in”, ـٌ “ün/un” sesi verir.',
      'اَحَدٌ kelimesi “ehadün” diye çalışılır.',
    ],
    icon: Icons.more_horiz,
  ),
  _QuranLearningStep(
    title: '10. Kısa Sureye Geçiş',
    subtitle: 'İhlas suresiyle okuma pratiği',
    arabic: 'قُلْ هُوَ اللّٰهُ اَحَدٌ\nاَللّٰهُ الصَّمَدُ',
    transliteration: 'Kul hüvellahu ehad. Allahus-samed.',
    explanation:
        'Artık harfleri kelime içinde takip ederek kısa sureye geç. Önce Arapça metne bak, sonra okunuş desteğiyle kontrol et.',
    practice: [
      'قُلْ kelimesinde cezm var.',
      'اللّٰهُ kelimesinde şedde var.',
      'اَحَدٌ kelimesinde tenvin var.',
    ],
    icon: Icons.menu_book_outlined,
  ),
  _QuranLearningStep(
    title: '11. Kur’an Okuma Pratiği',
    subtitle: 'Fatiha ile düzenli tekrar',
    arabic:
        'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيمِ\nاَلْحَمْدُ لِلّٰهِ رَبِّ الْعَالَمِينَ',
    transliteration: 'Bismillahirrahmanirrahim. Elhamdülillahi rabbil alemin.',
    explanation:
        'Bu bölümden sonra Kur’an sekmesinde sureleri ayet ayet takip edebilirsin. Uygulama Kur’an tarafında son okuduğun yeri ayrıca saklar.',
    practice: [
      'Önce Fatiha’yı satır satır takip et.',
      'Takıldığın yerde Sure/Dua bölümünden okunuşa dön.',
      'Sonra Kur’an sekmesinde kaldığın yerden okumaya devam et.',
    ],
    icon: Icons.auto_stories_outlined,
  ),
];

const _prayerTexts = [
  _PrayerText(
    title: 'Sübhaneke',
    usage: 'Namaza başlarken okunur',
    arabic:
        'سُبْحَانَكَ اللّٰهُمَّ وَبِحَمْدِكَ وَتَبَارَكَ اسْمُكَ وَتَعَالٰى جَدُّكَ وَلَا إِلٰهَ غَيْرُكَ',
    transliteration:
        'Sübhânekellâhümme ve bihamdik. Ve tebârekesmük. Ve teâlâ ceddük. Ve lâ ilâhe ğayruk.',
    meaning:
        'Allahım! Seni eksik sıfatlardan tenzih ederim. Sana hamd ederim. İsmin mübarektir, şanın yücedir. Senden başka ilah yoktur.',
    icon: Icons.front_hand_outlined,
  ),
  _PrayerText(
    title: 'Fâtiha Suresi',
    usage: 'Her rekatta okunur',
    arabic:
        'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيمِ\nاَلْحَمْدُ لِلّٰهِ رَبِّ الْعَالَمِينَ\nاَلرَّحْمٰنِ الرَّحِيمِ\nمَالِكِ يَوْمِ الدِّينِ\nاِيَّاكَ نَعْبُدُ وَاِيَّاكَ نَسْتَعِينُ\nاِهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ\nصِرَاطَ الَّذِينَ اَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ',
    transliteration:
        'Bismillahirrahmanirrahim. Elhamdülillahi rabbil alemin. Errahmanirrahim. Maliki yevmiddin. İyyake na’budü ve iyyake nestein. İhdinessıratal müstakim. Sıratallezine en’amte aleyhim ğayril mağdubi aleyhim veleddallin.',
    meaning:
        'Rahman ve Rahim olan Allah’ın adıyla. Hamd alemlerin Rabbi Allah’a mahsustur. O Rahman ve Rahim’dir. Din gününün sahibidir. Yalnız Sana kulluk eder, yalnız Senden yardım dileriz. Bizi dosdoğru yola ilet.',
    icon: Icons.menu_book_outlined,
  ),
  _PrayerText(
    title: 'Ettehiyyatü',
    usage: 'Oturuluşlarda okunur',
    arabic:
        'اَلتَّحِيَّاتُ لِلّٰهِ وَالصَّلَوَاتُ وَالطَّيِّبَاتُ، اَلسَّلَامُ عَلَيْكَ اَيُّهَا النَّبِيُّ وَرَحْمَةُ اللّٰهِ وَبَرَكَاتُهُ، اَلسَّلَامُ عَلَيْنَا وَعَلٰى عِبَادِ اللّٰهِ الصَّالِحِينَ، اَشْهَدُ اَنْ لَا اِلٰهَ اِلَّا اللّٰهُ وَاَشْهَدُ اَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ',
    transliteration:
        'Ettehiyyâtü lillâhi vessalavâtü vettayyibât. Esselâmü aleyke eyyühennebiyyü ve rahmetullahi ve berekâtüh. Esselâmü aleynâ ve alâ ibâdillâhis-sâlihîn. Eşhedü en lâ ilâhe illallah ve eşhedü enne Muhammeden abdühû ve rasûlüh.',
    meaning:
        'Bütün hürmetler, dualar ve güzel sözler Allah içindir. Ey Peygamber! Allah’ın selamı, rahmeti ve bereketi üzerine olsun. Selam bizim ve Allah’ın salih kulları üzerine olsun. Allah’tan başka ilah olmadığına, Muhammed’in O’nun kulu ve elçisi olduğuna şahitlik ederim.',
    icon: Icons.airline_seat_recline_normal,
  ),
  _PrayerText(
    title: 'Salli ve Barik',
    usage: 'Son oturuşta okunur',
    arabic:
        'اَللّٰهُمَّ صَلِّ عَلٰى مُحَمَّدٍ وَعَلٰى اٰلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلٰى اِبْرَاهِيمَ وَعَلٰى اٰلِ اِبْرَاهِيمَ اِنَّكَ حَمِيدٌ مَجِيدٌ\nاَللّٰهُمَّ بَارِكْ عَلٰى مُحَمَّدٍ وَعَلٰى اٰلِ مُحَمَّدٍ كَمَا بَارَكْتَ عَلٰى اِبْرَاهِيمَ وَعَلٰى اٰلِ اِبْرَاهِيمَ اِنَّكَ حَمِيدٌ مَجِيدٌ',
    transliteration:
        'Allahümme salli alâ Muhammedin ve alâ âli Muhammed... Allahümme bârik alâ Muhammedin ve alâ âli Muhammed...',
    meaning:
        'Allahım! Hz. Muhammed’e ve ailesine rahmet ve bereket eyle; Hz. İbrahim’e ve ailesine rahmet ve bereket ettiğin gibi. Şüphesiz Sen hamde layık ve yücesin.',
    icon: Icons.volunteer_activism_outlined,
  ),
  _PrayerText(
    title: 'Rabbena Duaları',
    usage: 'Son oturuşta okunur',
    arabic:
        'رَبَّنَا اٰتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْاٰخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ\nرَبَّنَا اغْفِرْ لِي وَلِوَالِدَيَّ وَلِلْمُؤْمِنِينَ يَوْمَ يَقُومُ الْحِسَابُ',
    transliteration:
        'Rabbenâ âtinâ fiddünyâ haseneten ve fil âhireti haseneten ve kınâ azâbennâr. Rabbenağfirlî ve li-vâlideyye ve lil-mü’minîne yevme yekûmül hisâb.',
    meaning:
        'Rabbimiz! Bize dünyada da ahirette de iyilik ver ve bizi ateş azabından koru. Rabbimiz! Hesap görüleceği gün beni, anne babamı ve müminleri bağışla.',
    icon: Icons.favorite_border,
  ),
  _PrayerText(
    title: 'Kunut Duaları',
    usage: 'Vitir namazının üçüncü rekatında okunur',
    arabic:
        'اَللّٰهُمَّ اِنَّا نَسْتَعِينُكَ وَنَسْتَغْفِرُكَ وَنَسْتَهْدِيكَ وَنُؤْمِنُ بِكَ وَنَتُوبُ اِلَيْكَ وَنَتَوَكَّلُ عَلَيْكَ وَنُثْنِي عَلَيْكَ الْخَيْرَ كُلَّهُ نَشْكُرُكَ وَلَا نَكْفُرُكَ',
    transliteration:
        'Allahümme innâ nesteînüke ve nestağfirüke ve nestehdîk. Ve nü’minü bike ve netûbü ileyk. Ve netevekkelü aleyk...',
    meaning:
        'Allahım! Senden yardım, bağışlanma ve hidayet dileriz. Sana iman eder, Sana tövbe eder, Sana güveniriz. Seni hayırla överiz; Sana şükreder, nankörlük etmeyiz.',
    icon: Icons.nights_stay_outlined,
  ),
  _PrayerText(
    title: 'İhlas, Felak ve Nas',
    usage: 'Kısa sure olarak namazda ve korunma niyetiyle okunur',
    arabic:
        'قُلْ هُوَ اللّٰهُ اَحَدٌ...\nقُلْ اَعُوذُ بِرَبِّ الْفَلَقِ...\nقُلْ اَعُوذُ بِرَبِّ النَّاسِ...',
    transliteration:
        'Kul hüvallâhü ehad... Kul eûzü bi-rabbil felak... Kul eûzü bi-rabbin nâs...',
    meaning:
        'İhlas Allah’ın birliğini bildirir. Felak ve Nas sureleri Allah’a sığınmayı öğretir.',
    icon: Icons.shield_outlined,
  ),
  _PrayerText(
    title: 'Kevser Suresi',
    usage: 'Kısa sure olarak namazda sık okunur',
    arabic:
        'إِنَّا أَعْطَيْنَاكَ الْكَوْثَرَ\nفَصَلِّ لِرَبِّكَ وَانْحَرْ\nإِنَّ شَانِئَكَ هُوَ الْأَبْتَرُ',
    transliteration:
        'İnnâ a‘taynâkel kevser. Fe salli li-rabbike venhar. İnne şânieke hüvel ebter.',
    meaning:
        'Şüphesiz biz sana Kevser’i verdik. Öyleyse Rabbin için namaz kıl ve kurban kes. Asıl sonu kesik olan, sana kin tutandır.',
    icon: Icons.water_drop_outlined,
  ),
  _PrayerText(
    title: 'Asr Suresi',
    usage: 'Kısa sure olarak namazda okunabilir',
    arabic:
        'وَالْعَصْرِ\nإِنَّ الْإِنْسَانَ لَفِي خُسْرٍ\nإِلَّا الَّذِينَ آمَنُوا وَعَمِلُوا الصَّالِحَاتِ وَتَوَاصَوْا بِالْحَقِّ وَتَوَاصَوْا بِالصَّبْرِ',
    transliteration:
        'Vel asr. İnnel insâne lefî husr. İllellezîne âmenû ve amilûs-sâlihâti ve tevâsav bil hakkı ve tevâsav bis-sabr.',
    meaning:
        'Asra yemin olsun ki insan ziyandadır. Ancak iman edip salih amel işleyen, hakkı ve sabrı tavsiye edenler başka.',
    icon: Icons.hourglass_bottom_outlined,
  ),
  _PrayerText(
    title: 'Kafirun Suresi',
    usage: 'Tevhid bilinci için namazda okunabilir',
    arabic:
        'قُلْ يَا أَيُّهَا الْكَافِرُونَ\nلَا أَعْبُدُ مَا تَعْبُدُونَ\nوَلَا أَنْتُمْ عَابِدُونَ مَا أَعْبُدُ\nوَلَا أَنَا عَابِدٌ مَا عَبَدْتُمْ\nوَلَا أَنْتُمْ عَابِدُونَ مَا أَعْبُدُ\nلَكُمْ دِينُكُمْ وَلِيَ دِينِ',
    transliteration:
        'Kul yâ eyyühel kâfirûn. Lâ a‘budu mâ ta‘budûn... Leküm dînüküm ve liye dîn.',
    meaning:
        'De ki: Ey inkârcılar! Ben sizin kulluk ettiklerinize kulluk etmem. Sizin dininiz size, benim dinim banadır.',
    icon: Icons.verified_outlined,
  ),
  _PrayerText(
    title: 'Nasr Suresi',
    usage: 'Kısa sure olarak namazda okunabilir',
    arabic:
        'إِذَا جَاءَ نَصْرُ اللَّهِ وَالْفَتْحُ\nوَرَأَيْتَ النَّاسَ يَدْخُلُونَ فِي دِينِ اللَّهِ أَفْوَاجًا\nفَسَبِّحْ بِحَمْدِ رَبِّكَ وَاسْتَغْفِرْهُ إِنَّهُ كَانَ تَوَّابًا',
    transliteration:
        'İzâ câe nasrullâhi vel feth. Ve raeytennâse yedhulûne fî dînillâhi efvâcâ. Fe sebbih bi hamdi rabbike vestağfirh.',
    meaning:
        'Allah’ın yardımı ve fetih geldiğinde Rabbini hamd ile tesbih et ve O’ndan bağışlanma dile. Şüphesiz O, tövbeleri çok kabul edendir.',
    icon: Icons.flag_outlined,
  ),
];
