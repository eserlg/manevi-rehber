import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';

class CompassWidget extends StatelessWidget {
  final double qiblaDirection;
  final double currentHeading;
  final bool isAligned;
  final bool isLiveCompass;

  const CompassWidget({
    super.key,
    required this.qiblaDirection,
    required this.currentHeading,
    this.isAligned = false,
    this.isLiveCompass = true,
  });

  @override
  Widget build(BuildContext context) {
    final relativeAngle = _normalizeAngle(qiblaDirection - currentHeading);
    final isPointingQibla = relativeAngle.abs() < 10;
    final compassSize =
        min(MediaQuery.of(context).size.width - 64, 300.0).clamp(230.0, 300.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compassSize,
          height: compassSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: isPointingQibla
                    ? AppColors.primary.withOpacity(0.35)
                    : Colors.black.withOpacity(0.08),
                blurRadius: 24,
                spreadRadius: isPointingQibla ? 6 : 0,
              ),
            ],
            border: Border.all(
              color: isPointingQibla
                  ? AppColors.primary
                  : AppColors.surfaceVariant,
              width: 4,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: -currentHeading * pi / 180,
                child: CustomPaint(
                  size: Size(compassSize - 24, compassSize - 24),
                  painter: CompassPainter(),
                ),
              ),
              CustomPaint(
                size: Size(compassSize - 36, compassSize - 36),
                painter: AlignmentGuidePainter(
                  color:
                      isPointingQibla ? AppColors.primary : AppColors.textHint,
                ),
              ),
              SizedBox(
                width: compassSize,
                height: compassSize,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: _QiblaMarker(isAligned: isPointingQibla),
                  ),
                ),
              ),
              _CenterDirectionPointer(
                isAligned: isPointingQibla,
                angle: relativeAngle,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacingLG),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingLG,
            vertical: AppDimensions.spacingMD,
          ),
          decoration: BoxDecoration(
            color: isPointingQibla
                ? AppColors.primary.withOpacity(0.12)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          ),
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPointingQibla ? Icons.check_circle : Icons.explore,
                    color: isPointingQibla
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: 24,
                  ),
                  const SizedBox(width: AppDimensions.spacingSM),
                  Text(
                    isPointingQibla ? 'Kıble doğru' : 'Kıble hedefini hizala',
                    style: GoogleFonts.notoSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isPointingQibla
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingSM),
              Text(
                '${qiblaDirection.toStringAsFixed(1)}°',
                style: GoogleFonts.amiri(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                _getDirectionName(qiblaDirection),
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacingMD),
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacingMD),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(color: AppColors.info.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.info, size: 20),
              const SizedBox(width: AppDimensions.spacingSM),
              Expanded(
                child: Text(
                  isLiveCompass
                      ? 'Telefonu elinde tuttuğun yönde yavaşça çevir; ortadaki oku Kıble işaretiyle hizala.'
                      : 'Bu cihazda canlı pusula yok; Kıble işareti kuzeye göre yaklaşık gösteriliyor.',
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _normalizeAngle(double angle) {
    var normalized = (angle + 360) % 360;
    if (normalized > 180) normalized -= 360;
    return normalized;
  }

  String _getDirectionName(double direction) {
    if (direction >= 337.5 || direction < 22.5) return 'Kuzey (K)';
    if (direction >= 22.5 && direction < 67.5) return 'Kuzeydoğu (KD)';
    if (direction >= 67.5 && direction < 112.5) return 'Doğu (D)';
    if (direction >= 112.5 && direction < 157.5) return 'Güneydoğu (GD)';
    if (direction >= 157.5 && direction < 202.5) return 'Güney (G)';
    if (direction >= 202.5 && direction < 247.5) return 'Güneybatı (GB)';
    if (direction >= 247.5 && direction < 292.5) return 'Batı (B)';
    if (direction >= 292.5 && direction < 337.5) return 'Kuzeybatı (KB)';
    return 'Bilinmeyen';
  }
}

class _QiblaMarker extends StatelessWidget {
  final bool isAligned;

  const _QiblaMarker({required this.isAligned});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isAligned ? AppColors.primary : AppColors.accent,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAligned ? Icons.check : Icons.mosque,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            'Kıble',
            style: GoogleFonts.notoSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterDirectionPointer extends StatelessWidget {
  final bool isAligned;
  final double angle;

  const _CenterDirectionPointer({
    required this.isAligned,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle * pi / 180,
      child: Container(
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isAligned ? AppColors.primary : AppColors.secondaryDark,
          boxShadow: [
            BoxShadow(
              color: (isAligned ? AppColors.primary : AppColors.secondaryDark)
                  .withOpacity(0.24),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: const Offset(0, -8),
              child: Icon(
                Icons.navigation,
                color: Colors.white,
                size: 34,
              ),
            ),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.textPrimary,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AlignmentGuidePainter extends CustomPainter {
  final Color color;

  AlignmentGuidePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final top = Offset(size.width / 2, 18);
    final paint = Paint()
      ..color = color.withOpacity(0.45)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, top, paint);
  }

  @override
  bool shouldRepaint(covariant AlignmentGuidePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = size.width / 2 - 10;

    final Paint tickPaint = Paint()
      ..color = AppColors.textSecondary.withOpacity(0.5)
      ..strokeWidth = 1;

    final textStyle = GoogleFonts.notoSans(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    );

    final directions = ['N', 'E', 'S', 'W'];
    final angles = [0.0, 90.0, 180.0, 270.0];

    for (int i = 0; i < 4; i++) {
      final double angle = angles[i] * pi / 180;

      for (int j = 0; j < 8; j++) {
        final double tickAngle = (angles[i] + j * 45) * pi / 180;
        final double innerRadius = radius - (j % 2 == 0 ? 15 : 10);
        final double innerX = centerX + innerRadius * sin(tickAngle);
        final double innerY = centerY - innerRadius * cos(tickAngle);
        final double outerX = centerX + radius * sin(tickAngle);
        final double outerY = centerY - radius * cos(tickAngle);

        canvas.drawLine(
          Offset(innerX, innerY),
          Offset(outerX, outerY),
          tickPaint,
        );
      }

      final textSpan = TextSpan(
        text: directions[i],
        style: i == 0 ? textStyle.copyWith(color: AppColors.accent) : textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final double textX =
          centerX + (radius - 50) * sin(angle) - textPainter.width / 2;
      final double textY =
          centerY - (radius - 50) * cos(angle) - textPainter.height / 2;

      textPainter.paint(canvas, Offset(textX, textY));
    }

    final Paint circlePaint = Paint()
      ..color = AppColors.textSecondary.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(Offset(centerX, centerY), radius, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
