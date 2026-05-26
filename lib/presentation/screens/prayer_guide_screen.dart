import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../data/models/prayer_guide.dart';

class PrayerGuideScreen extends StatefulWidget {
  const PrayerGuideScreen({super.key});

  @override
  State<PrayerGuideScreen> createState() => _PrayerGuideScreenState();
}

class _PrayerGuideScreenState extends State<PrayerGuideScreen> {
  late final Future<List<PrayerGuide>> _guidesFuture;
  String _selectedCategory = 'tum';

  static const _categories = [
    ('tum', 'Tümü'),
    ('gunluk', 'Günlük'),
    ('cuma', 'Cuma'),
    ('ozel', 'Özel'),
    ('cenaze', 'Cenaze'),
    ('nafile', 'Nafile'),
  ];

  @override
  void initState() {
    super.initState();
    _guidesFuture = _loadGuides();
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final category in _categories)
            Padding(
              padding: const EdgeInsets.only(right: AppDimensions.spacingSM),
              child: ChoiceChip(
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
            ),
        ],
      ),
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
