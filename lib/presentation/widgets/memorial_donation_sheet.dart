import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../providers/providers.dart';

class MemorialDonationResult {
  final String recordId;
  final String recordName;
  final String counterKey;
  final String label;
  final int amount;

  const MemorialDonationResult({
    required this.recordId,
    required this.recordName,
    required this.counterKey,
    required this.label,
    required this.amount,
  });
}

class _DonationOption {
  final String key;
  final String title;
  final String subtitle;
  final int amount;
  final IconData icon;

  const _DonationOption({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
  });
}

Future<MemorialDonationResult?> showMemorialDonationSheet({
  required BuildContext context,
  required WidgetRef ref,
  String initialKey = 'tasbihCount',
  int tasbihAmount = 33,
  String title = 'Bağış Yap',
  String? note,
}) async {
  final storage = ref.read(localStorageProvider);
  await storage.init();
  if (!context.mounted) return null;

  final records = storage.getMemorialRecords();

  if (records.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Önce Vefat Hatırası bölümüne kişi ekleyin'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return null;
  }

  final safeTasbihAmount = tasbihAmount <= 0 ? 33 : tasbihAmount;
  final options = [
    _DonationOption(
      key: 'tasbihCount',
      title: 'Tesbih',
      subtitle: '+$safeTasbihAmount',
      amount: safeTasbihAmount,
      icon: Icons.auto_awesome,
    ),
    const _DonationOption(
      key: 'yasinCount',
      title: 'Yasin',
      subtitle: '+1',
      amount: 1,
      icon: Icons.menu_book,
    ),
    const _DonationOption(
      key: 'hatimCount',
      title: 'Hatim',
      subtitle: '+1',
      amount: 1,
      icon: Icons.library_books,
    ),
  ];

  final allowedKeys = options.map((option) => option.key).toSet();
  var selectedKey =
      allowedKeys.contains(initialKey) ? initialKey : 'tasbihCount';
  var selectedRecordId = records.first['id']?.toString() ?? '';
  final manualAmountController = TextEditingController();
  var useManualAmount = false;

  final result = await showModalBottomSheet<MemorialDonationResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppDimensions.radiusLarge),
      ),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final selectedOption =
              options.firstWhere((option) => option.key == selectedKey);
          final selectedRecord = records.firstWhere(
            (record) => record['id']?.toString() == selectedRecordId,
            orElse: () => records.first,
          );
          final manualParsed =
              int.tryParse(manualAmountController.text.trim()) ?? 0;
          final effectiveAmount =
              useManualAmount && manualParsed > 0 ? manualParsed : selectedOption.amount;

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimensions.screenPadding,
                AppDimensions.screenPadding,
                AppDimensions.screenPadding,
                MediaQuery.of(context).viewInsets.bottom +
                    AppDimensions.screenPadding,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.volunteer_activism,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppDimensions.spacingSM),
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.notoSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (note != null && note.trim().isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.spacingSM),
                    Text(
                      note,
                      style: GoogleFonts.notoSans(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppDimensions.spacingLG),
                  Wrap(
                    spacing: AppDimensions.spacingSM,
                    runSpacing: AppDimensions.spacingSM,
                    children: options.map((option) {
                      final selected = option.key == selectedKey;
                      return ChoiceChip(
                        selected: selected,
                        onSelected: (_) {
                          setSheetState(() {
                            selectedKey = option.key;
                            useManualAmount = false;
                          });
                        },
                        avatar: Icon(
                          option.icon,
                          size: 18,
                          color: selected ? Colors.white : AppColors.primary,
                        ),
                        label: Text('${option.title} ${option.subtitle}'),
                        labelStyle: GoogleFonts.notoSans(
                          fontWeight: FontWeight.w600,
                          color:
                              selected ? Colors.white : AppColors.textPrimary,
                        ),
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceVariant,
                        side: BorderSide(
                          color: selected
                              ? AppColors.primary
                              : AppColors.primary.withOpacity(0.12),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppDimensions.spacingMD),
                  Row(
                    children: [
                      Switch(
                        value: useManualAmount,
                        activeColor: AppColors.primary,
                        onChanged: (value) => setSheetState(() {
                          useManualAmount = value;
                          if (value) manualAmountController.clear();
                        }),
                      ),
                      Expanded(
                        child: Text(
                          'Manuel miktar gir',
                          style: GoogleFonts.notoSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (useManualAmount)
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: manualAmountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              isDense: true,
                              hintText: 'Adet',
                            ),
                            onChanged: (_) => setSheetState(() {}),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingLG),
                  Text(
                    'Kime bağışlanacak?',
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingSM),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: SingleChildScrollView(
                      child: Column(
                        children: records.map((record) {
                          final recordId = record['id']?.toString() ?? '';
                          final name = record['name']?.toString().trim();
                          return RadioListTile<String>(
                            value: recordId,
                            groupValue: selectedRecordId,
                            activeColor: AppColors.primary,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              name == null || name.isEmpty
                                  ? 'Vefat Hatırası'
                                  : name,
                              style: GoogleFonts.notoSans(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              _formatDonationPreview(
                                record,
                                selectedOption,
                                overrideAmount: effectiveAmount,
                              ),
                              style: GoogleFonts.notoSans(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            onChanged: (value) {
                              if (value == null) return;
                              setSheetState(() => selectedRecordId = value);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingLG),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: const Text('Vazgeç'),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingSM),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: effectiveAmount <= 0
                              ? null
                              : () {
                                  final name =
                                      selectedRecord['name']?.toString().trim();
                                  Navigator.pop(
                                    sheetContext,
                                    MemorialDonationResult(
                                      recordId: selectedRecordId,
                                      recordName: name == null || name.isEmpty
                                          ? 'Vefat Hatırası'
                                          : name,
                                      counterKey: selectedOption.key,
                                      label: selectedOption.title,
                                      amount: effectiveAmount,
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.volunteer_activism),
                          label: Text(effectiveAmount > 1
                              ? '$effectiveAmount Bağışla'
                              : 'Bağışla'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  manualAmountController.dispose();

  if (result == null) return null;

  final freshRecords = storage.getMemorialRecords();
  final index = freshRecords.indexWhere(
    (record) => record['id']?.toString() == result.recordId,
  );
  if (index < 0) return null;

  final updatedRecord = Map<String, dynamic>.from(freshRecords[index]);
  updatedRecord[result.counterKey] =
      _asInt(updatedRecord[result.counterKey]) + result.amount;
  freshRecords[index] = updatedRecord;

  await storage.saveMemorialRecords(freshRecords);
  ref.read(memorialRefreshProvider.notifier).state++;

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${result.amount} ${result.label} ${result.recordName} için bağışlandı'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  return result;
}

String _formatDonationPreview(
  Map<String, dynamic> record,
  _DonationOption option, {
  int? overrideAmount,
}) {
  final current = _asInt(record[option.key]);
  final amount = overrideAmount ?? option.amount;
  return 'Mevcut $current, bağış sonrası ${current + amount}';
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
