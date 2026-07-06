import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../widgets/youtube_live_player.dart';

class LiveStreamScreen extends StatelessWidget {
  const LiveStreamScreen({super.key});

  static const _makkahVideoId = 'ueIOUTyRS84';
  static final _makkahLiveUrl =
      Uri.parse('https://www.youtube.com/watch?v=$_makkahVideoId');
  static final _madinahLiveUrl =
      Uri.parse('https://www.youtube.com/@SaudiSunnahTv/live');
  static final _mp3QuranUrl = Uri.parse('https://www.mp3quran.net/tr');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Canlı Yayın'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFDFCF7),
              AppColors.background,
              AppColors.surfaceVariant.withOpacity(0.6),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            children: [
              _buildHero(context),
              const SizedBox(height: AppDimensions.spacingLG),
              _buildMakkahPlayer(context),
              const SizedBox(height: AppDimensions.spacingLG),
              _buildSourceCards(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingLG),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingMD),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: const Icon(
              Icons.live_tv,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mekke Canlı',
                  style: GoogleFonts.amiri(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  'Resmi KSA Qur’an TV canlı yayını. PWA/web sürümünde uygulama içinde izlenir.',
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMakkahPlayer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMD),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const YoutubeLivePlayer(
            videoId: _makkahVideoId,
            title: 'Mekke Canlı Yayın',
          ),
          const SizedBox(height: AppDimensions.spacingMD),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Kâbe ve Mescid-i Haram',
                  style: GoogleFonts.notoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () => _openExternal(_makkahLiveUrl),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(kIsWeb ? 'YouTube' : 'Aç'),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            'Yayın kaynağı YouTube tarafından engellenirse veya yüklenmezse resmi kanalda aç düğmesini kullanın.',
            style: GoogleFonts.notoSans(
              fontSize: 12,
              height: 1.35,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceCards(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Diğer Güvenilir Kaynaklar',
          style: GoogleFonts.notoSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingMD),
        _buildSourceTile(
          icon: Icons.mosque_outlined,
          title: 'Medine Canlı',
          subtitle: 'Mescid-i Nebevi resmi kanal bağlantısı',
          onTap: () => _openExternal(_madinahLiveUrl),
        ),
        _buildSourceTile(
          icon: Icons.graphic_eq,
          title: 'Kur’an Dinle',
          subtitle: 'MP3Quran üzerinde kıraat arşivi',
          onTap: () => _openExternal(_mp3QuranUrl),
        ),
      ],
    );
  }

  Widget _buildSourceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingSM),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.spacingMD),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.10),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingSM),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  child: Icon(icon, color: AppColors.primary),
                ),
                const SizedBox(width: AppDimensions.spacingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.notoSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.notoSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _openExternal(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
