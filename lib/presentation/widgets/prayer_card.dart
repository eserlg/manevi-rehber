import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';

class PrayerCard extends StatelessWidget {
  final String title;
  final String time;
  final bool isNext;
  final bool isCurrent;
  final VoidCallback? onTap;

  const PrayerCard({
    super.key,
    required this.title,
    required this.time,
    this.isNext = false,
    this.isCurrent = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 128;
          final padding =
              compact ? AppDimensions.spacingSM : AppDimensions.spacingMD;

          return Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: isCurrent
                  ? AppColors.primary.withOpacity(0.2)
                  : isNext
                      ? AppColors.softBlue.withOpacity(0.3)
                      : AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(
                color: isCurrent
                    ? AppColors.primary
                    : isNext
                        ? AppColors.softBlue
                        : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _statusBadge(compact),
                      ),
                    ),
                    Icon(
                      Icons.access_time_rounded,
                      size: compact ? 15 : 16,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSans(
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    time,
                    maxLines: 1,
                    style: GoogleFonts.amiri(
                      fontSize: compact ? 25 : 30,
                      height: 1,
                      fontWeight: FontWeight.bold,
                      color:
                          isCurrent ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statusBadge(bool compact) {
    final label = isCurrent
        ? 'Şimdi'
        : isNext
            ? 'Sonraki'
            : null;
    if (label == null) return const SizedBox(height: 24);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppDimensions.spacingXS : AppDimensions.spacingSM,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.primary : AppColors.softBlue,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.notoSans(
          fontSize: compact ? 9 : 10,
          fontWeight: FontWeight.w600,
          color: isCurrent ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }
}
