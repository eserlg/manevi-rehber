import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import 'clipboard_writer.dart';

class AppShareService {
  AppShareService._();

  static Future<void> shareText({
    required BuildContext context,
    required String text,
    required String subject,
    String fallbackMessage =
        'Bu tarayıcı doğrudan paylaşımı desteklemedi; metin panoya kopyalandı.',
  }) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: subject,
          sharePositionOrigin: _shareOrigin(context),
          mailToFallbackEnabled: false,
          downloadFallbackEnabled: false,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      await copyText(
        context: context,
        text: text,
        message: fallbackMessage,
      );
    }
  }

  static Future<void> copyText({
    required BuildContext context,
    required String text,
    String message = 'Metin panoya kopyalandı.',
  }) async {
    final copied = await writeClipboardText(text);

    if (!context.mounted) return;

    if (!copied) {
      _showManualCopySheet(context, text);
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  static Rect? _shareOrigin(BuildContext context) {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      return null;
    }

    final offset = renderObject.localToGlobal(Offset.zero);
    return offset & renderObject.size;
  }

  static void _showManualCopySheet(BuildContext context, String text) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLarge),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppDimensions.screenPadding,
            right: AppDimensions.screenPadding,
            top: AppDimensions.screenPadding,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom +
                AppDimensions.screenPadding,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.72,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      child: const Icon(
                        Icons.content_copy,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingMD),
                    const Expanded(
                      child: Text(
                        'Paylaşım Metni',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingMD),
                const Text(
                  'Tarayıcı otomatik kopyalamayı engelledi. Metni seçip kopyalayabilirsiniz.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingMD),
                Flexible(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      text,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingMD),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final copied = await writeClipboardText(text);
                          if (!sheetContext.mounted) return;

                          if (copied) {
                            Navigator.pop(sheetContext);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text('Metin panoya kopyalandı.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                          } else {
                            ScaffoldMessenger.of(sheetContext)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Kopyalama engellendi. Metni seçerek kopyalayabilirsiniz.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                          }
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Kopyala'),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingSM),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text('Tamam'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
