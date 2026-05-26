import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../data/models/zikr.dart';

class ZikrCounter extends StatelessWidget {
  final Zikr zikr;
  final VoidCallback onIncrement;
  final VoidCallback onReset;

  const ZikrCounter({
    super.key,
    required this.zikr,
    required this.onIncrement,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onIncrement();
      },
      onLongPress: onReset,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 470;
          final circleSize = compact ? 118.0 : 180.0;
          final strokeWidth = compact ? 9.0 : 12.0;
          final arabicSize = compact ? 38.0 : 48.0;
          final countSize = compact ? 44.0 : 64.0;
          final outerPadding =
              compact ? AppDimensions.spacingMD : AppDimensions.spacingXL;
          final largeGap =
              compact ? AppDimensions.spacingMD : AppDimensions.spacingXL;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(outerPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      zikr.arabic,
                      style: GoogleFonts.amiri(
                        fontSize: arabicSize,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimensions.spacingSM),
                    Text(
                      zikr.meaning,
                      style: GoogleFonts.notoSans(
                        fontSize: compact ? 14 : 16,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: largeGap),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: circleSize,
                          height: circleSize,
                          child: CircularProgressIndicator(
                            value: zikr.progress,
                            strokeWidth: strokeWidth,
                            backgroundColor: AppColors.surfaceVariant,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              zikr.isCompleted
                                  ? AppColors.success
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${zikr.currentCount}',
                              style: GoogleFonts.amiri(
                                fontSize: countSize,
                                fontWeight: FontWeight.bold,
                                color: zikr.isCompleted
                                    ? AppColors.success
                                    : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '/ ${zikr.targetCount}',
                              style: GoogleFonts.notoSans(
                                fontSize: compact ? 13 : 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(
                      height: compact ? AppDimensions.spacingMD : largeGap,
                    ),
                    if (zikr.isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacingLG,
                          vertical: AppDimensions.spacingSM,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusLarge,
                          ),
                        ),
                        child: Text(
                          'Tamamlandı',
                          style: GoogleFonts.notoSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      )
                    else
                      Text(
                        'Saymak için tıklayın',
                        style: GoogleFonts.notoSans(
                          fontSize: 14,
                          color: AppColors.textHint,
                        ),
                      ),
                    const SizedBox(height: AppDimensions.spacingSM),
                    Text(
                      'Sıfırlamak için uzun basın',
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
