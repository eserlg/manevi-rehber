import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../data/models/occasion_message.dart';
import '../../data/services/app_share_service.dart';
import '../providers/providers.dart';

const List<MapEntry<String, String?>> _messageCategories = [
  MapEntry<String, String?>('Tümü', null),
  MapEntry<String, String?>('Bayram', 'bayram'),
  MapEntry<String, String?>('Kandil', 'kandil'),
  MapEntry<String, String?>('Cuma', 'cuma'),
];

class OccasionMessagesScreen extends ConsumerStatefulWidget {
  const OccasionMessagesScreen({super.key});

  @override
  ConsumerState<OccasionMessagesScreen> createState() =>
      _OccasionMessagesScreenState();
}

class _OccasionMessagesScreenState
    extends ConsumerState<OccasionMessagesScreen> {
  String? _selectedCategory;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(occasionMessagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesajlar'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Mesaj ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPadding,
              ),
              children: _messageCategories
                  .map(
                    (category) => _buildCategoryChip(
                      category.key,
                      category.value,
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMD),
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                final filtered = _filterMessages(messages);
                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPadding,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _buildMessageCard(filtered[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _buildEmptyState(),
            ),
          ),
        ],
      ),
    );
  }

  List<OccasionMessage> _filterMessages(List<OccasionMessage> messages) {
    final query = _searchQuery.trim().toLowerCase();
    return messages.where((message) {
      final categoryMatches =
          _selectedCategory == null || message.category == _selectedCategory;
      final queryMatches = query.isEmpty ||
          message.title.toLowerCase().contains(query) ||
          message.text.toLowerCase().contains(query);
      return categoryMatches && queryMatches;
    }).toList();
  }

  Widget _buildCategoryChip(String label, String? category) {
    final selected = _selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.only(right: AppDimensions.spacingSM),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => setState(() => _selectedCategory = category),
        label: Text(label),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surfaceVariant,
        labelStyle: GoogleFonts.notoSans(
          color: selected ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(
          color:
              selected ? AppColors.primary : AppColors.primary.withOpacity(0.1),
        ),
      ),
    );
  }

  Widget _buildMessageCard(OccasionMessage message) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingMD),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingSM,
                    vertical: AppDimensions.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  child: Text(
                    message.categoryLabel,
                    style: GoogleFonts.notoSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Kopyala',
                  onPressed: () => _copyMessage(message),
                  icon: const Icon(Icons.copy_outlined),
                ),
                IconButton(
                  tooltip: 'Paylaş',
                  onPressed: () => _shareMessage(message),
                  icon: const Icon(Icons.share_outlined),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingSM),
            Text(
              message.title,
              style: GoogleFonts.notoSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingSM),
            Text(
              message.text,
              style: GoogleFonts.notoSans(
                fontSize: 15,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingMD),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _shareMessage(message),
                icon: const Icon(Icons.share),
                label: const Text('Sosyal Medyada Paylaş'),
              ),
            ),
          ],
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
            Icons.mark_chat_unread_outlined,
            size: 56,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppDimensions.spacingMD),
          Text(
            'Mesaj bulunamadı',
            style: GoogleFonts.notoSans(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyMessage(OccasionMessage message) async {
    await AppShareService.copyText(
      context: context,
      text: _formatMessage(message),
      message: 'Mesaj panoya kopyalandı.',
    );
  }

  Future<void> _shareMessage(OccasionMessage message) async {
    final text = _formatMessage(message);
    await AppShareService.shareText(
      context: context,
      text: text,
      subject: message.title,
      fallbackMessage:
          'Bu tarayıcı paylaşımı açamadı; mesaj panoya kopyalandı.',
    );
  }

  String _formatMessage(OccasionMessage message) {
    return '${message.text}\n\nManevi Rehber';
  }
}
