import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/constants/city_coordinates.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_themes.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/prayer_times_screen.dart';
import 'presentation/screens/zikr_screen.dart';
import 'presentation/screens/prayers_screen.dart';
import 'presentation/screens/quran_screen.dart';
import 'presentation/screens/qibla_screen.dart';
import 'presentation/screens/sirah_screen.dart';
import 'presentation/screens/prayer_guide_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/providers/providers.dart';
import 'core/constants/colors.dart';
import 'data/services/local_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');
  final storage = LocalStorageService();
  await storage.init();

  runApp(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
      ],
      child: const ManeviRehberApp(),
    ),
  );
}

class ManeviRehberApp extends ConsumerWidget {
  const ManeviRehberApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'Manevi Rehber',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(themeMode),
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [
        Locale('tr', 'TR'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final textScale =
            mediaQuery.textScaler.scale(1).clamp(0.9, 1.12).toDouble();
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: TextScaler.linear(textScale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  @override
  Widget build(BuildContext context) {
    final activeUser = ref.watch(activeUserProvider);
    return activeUser == null ? const LoginScreen() : const MainScreen();
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _controller.text.trim();
    if (username.isEmpty) return;

    final storage = ref.read(localStorageProvider);
    await storage.setActiveUser(username);
    ref.read(activeUserProvider.notifier).state = username;
  }

  @override
  Widget build(BuildContext context) {
    final knownUsers = ref.read(localStorageProvider).getKnownUsers();

    return Scaffold(
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.mosque, size: 56, color: AppColors.primary),
                  const SizedBox(height: 18),
                  Text(
                    'Manevi Rehber',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kişisel verilerin için kullanıcı adınla giriş yap',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _login(),
                    decoration: const InputDecoration(
                      labelText: 'Kullanıcı adı',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: _login,
                    icon: const Icon(Icons.login),
                    label: const Text('Giriş Yap'),
                  ),
                  if (knownUsers.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: knownUsers
                          .map(
                            (user) => ActionChip(
                              label: Text(user),
                              onPressed: () {
                                _controller.text = user;
                                _login();
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storage = ref.read(localStorageProvider);
      final savedCity = storage.getCity();
      if (savedCity == null || savedCity.isEmpty) return;

      ref.read(currentCityProvider.notifier).state = savedCity;

      final city = findCityCoordinate(savedCity);
      if (city != null && !storage.isAutoLocationEnabled()) {
        ref.read(currentPositionProvider.notifier).state =
            _positionForCity(city);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedTab = ref.watch(selectedTabProvider);
    final colors = ref.watch(themeColorsProvider);

    final screens = [
      const HomeScreen(),
      const PrayerTimesScreen(),
      const ZikrScreen(),
      const PrayersScreen(),
      const QuranScreen(),
      const QiblaScreen(),
      const SirahScreen(),
      const PrayerGuideScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: selectedTab,
        children: screens,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: colors.primary.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home,
                      label: 'Ana Sayfa',
                      isSelected: selectedTab == 0,
                      colors: colors,
                      onTap: () => ref.read(selectedTabProvider.notifier).state = 0,
                    ),
                    _buildNavItem(
                      icon: Icons.schedule_outlined,
                      activeIcon: Icons.schedule,
                      label: 'Vakitler',
                      isSelected: selectedTab == 1,
                      colors: colors,
                      onTap: () => ref.read(selectedTabProvider.notifier).state = 1,
                    ),
                    _buildNavItem(
                      icon: Icons.auto_awesome_outlined,
                      activeIcon: Icons.auto_awesome,
                      label: 'Zikir',
                      isSelected: selectedTab == 2,
                      colors: colors,
                      onTap: () => ref.read(selectedTabProvider.notifier).state = 2,
                    ),
                    _buildNavItem(
                      icon: Icons.menu_book_outlined,
                      activeIcon: Icons.menu_book,
                      label: 'Dualar',
                      isSelected: selectedTab == 3,
                      colors: colors,
                      onTap: () => ref.read(selectedTabProvider.notifier).state = 3,
                    ),
                    _buildNavItem(
                      icon: Icons.auto_stories_outlined,
                      activeIcon: Icons.auto_stories,
                      label: 'Kur\'an',
                      isSelected: selectedTab == 4,
                      colors: colors,
                      onTap: () => ref.read(selectedTabProvider.notifier).state = 4,
                    ),
                    _buildNavItem(
                      icon: Icons.explore_outlined,
                      activeIcon: Icons.explore,
                      label: 'Kıble',
                      isSelected: selectedTab == 5,
                      colors: colors,
                      onTap: () => ref.read(selectedTabProvider.notifier).state = 5,
                    ),
                    _buildNavItem(
                      icon: Icons.history_edu_outlined,
                      activeIcon: Icons.history_edu,
                      label: 'Siyer',
                      isSelected: selectedTab == 6,
                      colors: colors,
                      onTap: () => ref.read(selectedTabProvider.notifier).state = 6,
                    ),
                    _buildNavItem(
                      icon: Icons.mosque_outlined,
                      activeIcon: Icons.mosque,
                      label: 'Namaz',
                      isSelected: selectedTab == 7,
                      colors: colors,
                      onTap: () => ref.read(selectedTabProvider.notifier).state = 7,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          );
        },
        backgroundColor: colors.primary,
        child: const Icon(Icons.settings, color: Colors.white),
      ),
    );
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

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required ThemeColors colors,
    required VoidCallback onTap,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 430;
    final isVeryCompact = width < 370;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 2 : 6,
            vertical: isVeryCompact ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? colors.primary : colors.textSecondary,
                size: isVeryCompact ? 18 : (isCompact ? 20 : 22),
              ),
              SizedBox(height: isVeryCompact ? 1 : 2),
              SizedBox(
                height: isVeryCompact ? 20 : 22,
                child: Center(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isVeryCompact ? 7.8 : (isCompact ? 8.5 : 9.5),
                      height: 1.05,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? colors.primary
                          : colors.textSecondary,
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
}
