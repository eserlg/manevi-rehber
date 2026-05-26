import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/city_coordinates.dart';
import '../../core/constants/dimensions.dart';
import '../../data/services/app_share_service.dart';
import '../providers/providers.dart';

const String _playStoreUrl =
    'https://play.google.com/store/apps/details?id=com.example.ruh_huzur';
const String _appStoreUrl =
    'https://apps.apple.com/tr/search?term=Manevi%20Rehber';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _autoLocationEnabled = true;
  bool _notificationsEnabled = true;
  bool _isLocating = false;
  int _notificationLeadMinutes = 10;
  int _appRating = 0;
  String _selectedCity = 'İstanbul';

  @override
  void initState() {
    super.initState();
    final storage = ref.read(localStorageProvider);
    _autoLocationEnabled = storage.isAutoLocationEnabled();
    _notificationsEnabled = storage.arePrayerNotificationsEnabled();
    _notificationLeadMinutes = storage.getNotificationLeadMinutes();
    _appRating = storage.getAppRating();
    _selectedCity = storage.getCity() ?? ref.read(currentCityProvider);
  }

  @override
  Widget build(BuildContext context) {
    final activeUser = ref.watch(activeUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        children: [
          _buildSectionTitle('Profil'),
          _buildSettingsTile(
            icon: Icons.person,
            title: activeUser ?? 'Misafir',
            subtitle: 'Kişisel veriler bu profile kaydediliyor',
            trailing: const Icon(Icons.logout),
            onTap: () async {
              await ref.read(localStorageProvider).clearActiveUser();
              ref.read(activeUserProvider.notifier).state = null;
              if (context.mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(height: AppDimensions.spacingLG),
          _buildSectionTitle('Konum'),
          _buildSettingsTile(
            icon: Icons.location_on,
            title: 'Şehir',
            subtitle: _selectedCity,
            onTap: _showCityPicker,
          ),
          _buildSettingsTile(
            icon: Icons.my_location,
            title: 'Otomatik Konum',
            subtitle:
                _isLocating ? 'Konum alınıyor...' : 'GPS ile konum belirle',
            trailing: _isLocating
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Switch(
                    value: _autoLocationEnabled,
                    onChanged: _toggleAutoLocation,
                    activeColor: AppColors.primary,
                  ),
          ),
          const SizedBox(height: AppDimensions.spacingLG),
          _buildSectionTitle('Bildirimler'),
          _buildSettingsTile(
            icon: Icons.notifications,
            title: 'Namaz Bildirimleri',
            subtitle: _notificationsEnabled
                ? 'Namaz vakitlerinde bildirim al'
                : 'Bildirimler kapalı',
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,
              activeColor: AppColors.primary,
            ),
          ),
          _buildSettingsTile(
            icon: Icons.access_time,
            title: 'Bildirim Öncesi Süre',
            subtitle: '$_notificationLeadMinutes dakika önce',
            onTap: _showNotificationLeadPicker,
          ),
          const SizedBox(height: AppDimensions.spacingLG),
          _buildSectionTitle('Hakkında'),
          _buildSettingsTile(
            icon: Icons.info,
            title: 'Uygulama Hakkında',
            subtitle: 'Manevi Rehber v1.0.0',
            onTap: _showAboutDialog,
          ),
          _buildSettingsTile(
            icon: Icons.privacy_tip,
            title: 'Gizlilik Politikası',
            subtitle: 'Veri kullanımı hakkında',
            onTap: () => _showInfoSheet(
              title: 'Gizlilik Politikası',
              icon: Icons.privacy_tip,
              paragraphs: const [
                'Manevi Rehber, kişisel ayarlarını ve okuma/zikir ilerlemeni cihazında yerel olarak saklar.',
                'Kullanıcı adı, seçilen şehir, bildirim ayarı, Kur\'an okuma konumu, zikir ve vefat hatırası kayıtları profil bazlı tutulur.',
                'Konum izni yalnızca namaz vakitleri ve kıble hesaplamasını iyileştirmek için kullanılır. Veriler dış bir hesaba gönderilmez.',
              ],
            ),
          ),
          _buildSettingsTile(
            icon: Icons.description,
            title: 'Kullanım Şartları',
            subtitle: 'Uygulama koşulları',
            onTap: () => _showInfoSheet(
              title: 'Kullanım Şartları',
              icon: Icons.description,
              paragraphs: const [
                'Bu uygulama ibadet takibi, dua, zikir ve bilgilendirme amacıyla hazırlanmıştır.',
                'Namaz vakitleri ve kıble bilgisi konum, cihaz sensörleri ve servis yanıtlarına bağlı olarak küçük farklılıklar gösterebilir.',
                'Dini içerikler dikkatle hazırlanmıştır; kritik konularda resmi kaynaklar ve ehil kişilerden teyit alınması önerilir.',
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingLG),
          _buildSectionTitle('Destek'),
          _buildSettingsTile(
            icon: Icons.star,
            title: 'Uygulamayı Değerlendir',
            subtitle: _appRating > 0
                ? '$_appRating yıldız kaydedildi'
                : 'Puanını cihazında kaydet',
            onTap: _showRatingSheet,
          ),
          _buildSettingsTile(
            icon: Icons.feedback,
            title: 'Geri Bildirim Gönder',
            subtitle: 'Öneri veya şikayet',
            onTap: _showFeedbackSheet,
          ),
          _buildSettingsTile(
            icon: Icons.share,
            title: 'Uygulamayı Paylaş',
            subtitle: 'Arkadaşlarınla paylaş',
            onTap: _shareApp,
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAutoLocation(bool enabled) async {
    if (!enabled) {
      setState(() => _autoLocationEnabled = false);
      await ref.read(localStorageProvider).setAutoLocationEnabled(false);
      _showSnack('Otomatik konum kapatıldı.');
      return;
    }

    setState(() => _isLocating = true);

    try {
      final position =
          await ref.read(locationServiceProvider).getCurrentLocation();

      if (!mounted) return;

      if (position == null) {
        setState(() {
          _autoLocationEnabled = false;
          _isLocating = false;
        });
        await ref.read(localStorageProvider).setAutoLocationEnabled(false);
        _showSnack('Konum alınamadı. Cihaz konum iznini kontrol edin.');
        return;
      }

      final cityName =
          await ref.read(locationServiceProvider).getCityName(position);
      final displayCity = cityName == 'Bilinmeyen' ? 'Mevcut Konum' : cityName;

      ref.read(currentPositionProvider.notifier).state = position;
      ref.read(currentCityProvider.notifier).state = displayCity;
      ref.invalidate(prayerTimesProvider);

      await ref.read(localStorageProvider).setAutoLocationEnabled(true);
      await ref.read(localStorageProvider).saveCity(displayCity);
      await ref.read(localStorageProvider).saveLastLocation(
            latitude: position.latitude,
            longitude: position.longitude,
          );

      setState(() {
        _autoLocationEnabled = true;
        _selectedCity = displayCity;
        _isLocating = false;
      });
      _showSnack('Konum ayarı güncellendi.');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _autoLocationEnabled = false;
        _isLocating = false;
      });
      await ref.read(localStorageProvider).setAutoLocationEnabled(false);
      _showSnack('Konum alınırken bir sorun oluştu.');
    }
  }

  Future<void> _toggleNotifications(bool enabled) async {
    if (enabled) {
      final granted = await _requestNotificationPermission();
      if (!mounted) return;

      if (!granted) {
        setState(() => _notificationsEnabled = false);
        await ref
            .read(localStorageProvider)
            .setPrayerNotificationsEnabled(false);
        _showSnack('Bildirim izni verilmedi.');
        return;
      }
    }

    setState(() => _notificationsEnabled = enabled);
    await ref.read(localStorageProvider).setPrayerNotificationsEnabled(enabled);
    _showSnack(enabled
        ? 'Namaz bildirimleri açıldı.'
        : 'Namaz bildirimleri kapatıldı.');
  }

  Future<bool> _requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (_) {
      return true;
    }
  }

  Future<void> _showCityPicker() async {
    final searchController = TextEditingController();

    final selected = await showModalBottomSheet<CityCoordinate>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLarge),
        ),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final query = searchController.text.toLowerCase();
          final filteredCities = cityCoordinates.where((city) {
            final name = city.name.toLowerCase();
            final region = city.region.toLowerCase();
            return name.contains(query) || region.contains(query);
          }).toList();

          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.82,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppDimensions.screenPadding),
                    child: Column(
                      children: [
                        _buildSheetTitle(
                          'Şehir Seç',
                          Icons.location_city,
                        ),
                        const SizedBox(height: AppDimensions.spacingMD),
                        TextField(
                          controller: searchController,
                          onChanged: (_) => setModalState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'İl ara...',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredCities.length,
                      itemBuilder: (context, index) {
                        final city = filteredCities[index];
                        return ListTile(
                          title: Text(city.name),
                          subtitle: Text(city.region),
                          trailing: _selectedCity == city.name
                              ? const Icon(
                                  Icons.check,
                                  color: AppColors.primary,
                                )
                              : null,
                          onTap: () => Navigator.pop(context, city),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    searchController.dispose();

    if (selected == null) return;

    await ref.read(localStorageProvider).saveCity(selected.name);
    await ref.read(localStorageProvider).setAutoLocationEnabled(false);
    ref.read(currentCityProvider.notifier).state = selected.name;
    ref.read(currentPositionProvider.notifier).state =
        _positionForCity(selected);
    ref.invalidate(prayerTimesProvider);

    setState(() {
      _selectedCity = selected.name;
      _autoLocationEnabled = false;
    });

    _showSnack('${selected.name} seçildi.');
  }

  Future<void> _showNotificationLeadPicker() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLarge),
        ),
      ),
      builder: (context) {
        const options = [5, 10, 15, 20, 30, 45, 60];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSheetTitle('Bildirim Süresi', Icons.access_time),
                const SizedBox(height: AppDimensions.spacingMD),
                ...options.map(
                  (minutes) => RadioListTile<int>(
                    value: minutes,
                    groupValue: _notificationLeadMinutes,
                    activeColor: AppColors.primary,
                    title: Text('$minutes dakika önce'),
                    onChanged: (value) => Navigator.pop(context, value),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) return;

    await ref.read(localStorageProvider).setNotificationLeadMinutes(selected);
    setState(() => _notificationLeadMinutes = selected);
    _showSnack('Bildirim süresi güncellendi.');
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingMD),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingMD),
            Text(
              'Manevi Rehber',
              style: GoogleFonts.amiri(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Sürüm 1.0.0',
              style: GoogleFonts.notoSans(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingMD),
            Text(
              'Müslümanların günlük hayatlarında namaz vakitleri, zikir, dua, Kur\'an okuma ve kıble takibi konusunda yardımcı olmak için tasarlanmıştır.',
              style: GoogleFonts.notoSans(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showInfoSheet({
    required String title,
    required IconData icon,
    required List<String> paragraphs,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLarge),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSheetTitle(title, icon),
              const SizedBox(height: AppDimensions.spacingMD),
              ...paragraphs.map(
                (paragraph) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppDimensions.spacingMD),
                  child: Text(
                    paragraph,
                    style: GoogleFonts.notoSans(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRatingSheet() async {
    var selectedRating = _appRating;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLarge),
        ),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSheetTitle('Uygulamayı Değerlendir', Icons.star),
                const SizedBox(height: AppDimensions.spacingLG),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final star = index + 1;
                    return IconButton(
                      onPressed: () {
                        setModalState(() => selectedRating = star);
                      },
                      icon: Icon(
                        star <= selectedRating ? Icons.star : Icons.star_border,
                        color: AppColors.accent,
                        size: 36,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: AppDimensions.spacingLG),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedRating == 0
                        ? null
                        : () async {
                            await ref
                                .read(localStorageProvider)
                                .saveAppRating(selectedRating);
                            if (!mounted) return;
                            setState(() => _appRating = selectedRating);
                            Navigator.pop(sheetContext);
                            _showSnack('Değerlendirmen kaydedildi.');
                          },
                    child: const Text('Kaydet'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showFeedbackSheet() async {
    final controller = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLarge),
        ),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: AppDimensions.screenPadding,
          right: AppDimensions.screenPadding,
          top: AppDimensions.screenPadding,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom +
              AppDimensions.screenPadding,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSheetTitle('Geri Bildirim Gönder', Icons.feedback),
              const SizedBox(height: AppDimensions.spacingMD),
              TextField(
                controller: controller,
                minLines: 4,
                maxLines: 6,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Önerini veya yaşadığın sorunu yaz...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingMD),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final message = controller.text.trim();
                    if (message.isEmpty) {
                      _showSnack('Lütfen kısa bir mesaj yaz.');
                      return;
                    }

                    await ref
                        .read(localStorageProvider)
                        .addFeedbackMessage(message);
                    if (!mounted) return;
                    Navigator.pop(sheetContext);
                    _showSnack('Geri bildirimin kaydedildi.');
                  },
                  child: const Text('Gönder'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    controller.dispose();
  }

  void _shareApp() {
    _showAppShareSheet(_appShareText);
  }

  String get _appShareText =>
      'Manevi Rehber uygulamasını dene: namaz vakitleri, Kur\'an, zikir, dua, kıble ve dini günler tek yerde.\n\n'
      'Android: $_playStoreUrl\n'
      'iPhone: $_appStoreUrl';

  Future<void> _shareAppText(String text) async {
    await AppShareService.shareText(
      context: context,
      text: text,
      subject: 'Manevi Rehber',
      fallbackMessage:
          'Bu tarayıcı paylaşımı açamadı; paylaşım metni panoya kopyalandı.',
    );
  }

  Future<void> _openStoreLink(String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      if (!mounted) return;
      await AppShareService.copyText(
        context: context,
        text: url,
        message: 'Link açılamadı, panoya kopyalandı.',
      );
    }
  }

  void _showAppShareSheet(String text) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLarge),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSheetTitle('Uygulamayı Paylaş', Icons.share),
              const SizedBox(height: AppDimensions.spacingMD),
              _buildStoreButton(
                icon: Icons.android,
                title: 'Google Play Store',
                subtitle: _playStoreUrl,
                onTap: () => _openStoreLink(_playStoreUrl),
              ),
              const SizedBox(height: AppDimensions.spacingSM),
              _buildStoreButton(
                icon: Icons.phone_iphone,
                title: 'App Store',
                subtitle: _appStoreUrl,
                onTap: () => _openStoreLink(_appStoreUrl),
              ),
              const SizedBox(height: AppDimensions.spacingMD),
              OutlinedButton.icon(
                onPressed: () => _shareAppText(text),
                icon: const Icon(Icons.ios_share),
                label: const Text('Sosyal Medyada Paylaş'),
              ),
              const SizedBox(height: AppDimensions.spacingSM),
              TextButton.icon(
                onPressed: () async {
                  await AppShareService.copyText(
                    context: context,
                    text: text,
                    message: 'Paylaşım metni panoya kopyalandı.',
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Metni Kopyala'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingMD),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(color: AppColors.primary.withOpacity(0.14)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingSM),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
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
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spacingSM),
            Icon(
              Icons.open_in_new,
              color: AppColors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppDimensions.spacingSM,
        top: AppDimensions.spacingMD,
      ),
      child: Text(
        title,
        style: GoogleFonts.notoSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingSM),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppDimensions.spacingSM),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: GoogleFonts.notoSans(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.notoSans(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSheetTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacingSM),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: AppDimensions.spacingMD),
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
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Position _positionForCity(CityCoordinate city) {
    return Position(
      latitude: city.latitude,
      longitude: city.longitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}
