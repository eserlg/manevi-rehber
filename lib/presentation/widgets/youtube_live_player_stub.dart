import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';

class YoutubeLivePlayer extends StatelessWidget {
  final String videoId;
  final String title;

  const YoutubeLivePlayer({
    super.key,
    required this.videoId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingLG),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.ondemand_video,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(height: AppDimensions.spacingMD),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  'Canlı oynatıcı PWA/web sürümünde uygulama içinde açılır.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    height: 1.35,
                    color: Colors.white.withValues(alpha: 0.74),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
