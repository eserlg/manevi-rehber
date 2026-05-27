import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/city_coordinates.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../data/models/mosque_place.dart';
import '../../data/models/qibla.dart';
import '../../data/services/browser_compass_stub.dart'
    if (dart.library.js_interop) '../../data/services/browser_compass_web.dart';
import '../../data/services/nearby_mosque_service.dart';
import '../providers/providers.dart';
import '../widgets/compass_widget.dart';

class QiblaScreen extends ConsumerStatefulWidget {
  const QiblaScreen({super.key});

  @override
  ConsumerState<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends ConsumerState<QiblaScreen> {
  final NearbyMosqueService _nearbyMosqueService = NearbyMosqueService();
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  Timer? _sensorFallbackTimer;
  double _currentHeading = 0;
  MagnetometerEvent? _lastMagnetometer;
  AccelerometerEvent? _lastAccelerometer;
  Future<List<MosquePlace>>? _nearbyMosquesFuture;
  Position? _mosqueQueryPosition;
  bool _isLoading = true;
  bool _isLocatingMosques = false;
  bool _hasLiveCompass = false;
  String _compassMessage = 'Pusula başlatılıyor...';

  @override
  void initState() {
    super.initState();
    _initCompass();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadNearbyMosques();
    });
  }

  Future<void> _initCompass() async {
    _sensorFallbackTimer?.cancel();
    await _magnetometerSubscription?.cancel();
    await _accelerometerSubscription?.cancel();

    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasLiveCompass = false;
        _lastMagnetometer = null;
        _lastAccelerometer = null;
        _compassMessage = 'Pusula başlatılıyor...';
      });
    }

    if (kIsWeb) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _compassMessage =
            'PWA\'da canlı pusula için Pusulayı Başlat butonuna dokunun.';
      });
      return;
    }

    _sensorFallbackTimer = Timer(const Duration(seconds: 8), _useStaticCompass);

    try {
      _magnetometerSubscription = magnetometerEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen(
        (event) {
          _sensorFallbackTimer?.cancel();
          _lastMagnetometer = event;
          _updateHeadingFromNativeSensors();
        },
        onError: (_) => _useStaticCompass(),
      );

      _accelerometerSubscription = accelerometerEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen(
        (event) {
          _lastAccelerometer = event;
          _updateHeadingFromNativeSensors();
        },
        onError: (_) {},
      );
    } catch (_) {
      _useStaticCompass();
    }
  }

  bool _startBrowserCompass() {
    final started = startBrowserCompass((heading) {
      _sensorFallbackTimer?.cancel();
      _setLiveHeading(
        heading,
        'Telefonu yatay tutup ortadaki oku Kıble işaretiyle hizalayın.',
      );
    });

    if (started && mounted) {
      setState(() {
        _compassMessage = 'Pusula verisi bekleniyor...';
      });
    }

    return started;
  }

  Future<void> _requestAndStartBrowserCompass() async {
    _sensorFallbackTimer?.cancel();
    await _magnetometerSubscription?.cancel();
    await _accelerometerSubscription?.cancel();
    stopBrowserCompass();

    if (mounted) {
      setState(() {
        _hasLiveCompass = false;
        _compassMessage = 'Pusula izni isteniyor...';
      });
    }

    final permission = await requestBrowserCompassPermission();
    if (!mounted) return;

    if (permission == 'granted') {
      final started = _startBrowserCompass();
      setState(() {
        _isLoading = false;
        _compassMessage = started
            ? 'Pusula verisi bekleniyor; telefonu hafifçe sağa sola çevirin.'
            : 'Bu cihazda pusula sensörü desteklenmiyor.';
      });
      if (started) {
        _sensorFallbackTimer = Timer(const Duration(seconds: 6), () {
          if (!mounted || _hasLiveCompass) return;
          setState(() {
            _compassMessage =
                'Sensör izni alındı ama tarayıcı yön verisi göndermedi. HTTPS/PWA iznini kontrol edin veya elle hizalayın.';
          });
        });
      }
      return;
    }

    if (permission == 'insecure') {
      setState(() {
        _isLoading = false;
        _hasLiveCompass = false;
        _compassMessage =
            'Pusula için HTTPS gerekir. Vercel linkinden veya ana ekrana eklenen PWA\'dan açın.';
      });
      return;
    }

    setState(() {
      _isLoading = false;
      _hasLiveCompass = false;
      _compassMessage = permission == 'unsupported'
          ? 'Bu tarayıcı pusula sensörünü desteklemiyor.'
          : 'Pusula izni verilmedi. İzin verirseniz canlı yön gösterilir.';
    });
  }

  void _useStaticCompass() {
    _sensorFallbackTimer?.cancel();
    if (!mounted) return;

    setState(() {
      _currentHeading = 0;
      _isLoading = false;
      _hasLiveCompass = false;
      _compassMessage =
          'Canlı pusula alınamadı; Kıble işareti kuzeye göre yaklaşık gösteriliyor.';
    });
  }

  void _updateHeadingFromNativeSensors() {
    final magnetometer = _lastMagnetometer;
    final accelerometer = _lastAccelerometer;
    if (magnetometer == null) return;

    final heading = accelerometer == null
        ? _normalize360(atan2(magnetometer.y, magnetometer.x) * 180 / pi)
        : _calculateTiltCompensatedHeading(accelerometer, magnetometer);

    _setLiveHeading(
      heading,
      'Telefonu yatay tutup ortadaki oku Kıble işaretiyle hizalayın.',
    );
  }

  double _calculateTiltCompensatedHeading(
    AccelerometerEvent accelerometer,
    MagnetometerEvent magnetometer,
  ) {
    final ax = accelerometer.x;
    final ay = accelerometer.y;
    final az = accelerometer.z;
    final mx = magnetometer.x;
    final my = magnetometer.y;
    final mz = magnetometer.z;

    final roll = atan2(ay, az);
    final pitch = atan2(-ax, ay * sin(roll) + az * cos(roll));

    final compensatedY = mz * sin(roll) - my * cos(roll);
    final compensatedX = mx * cos(pitch) +
        my * sin(pitch) * sin(roll) +
        mz * sin(pitch) * cos(roll);

    final heading = atan2(compensatedY, compensatedX) * 180 / pi;
    return _normalize360(heading);
  }

  void _setLiveHeading(double heading, String message) {
    if (!mounted || !heading.isFinite) return;

    final normalized = _normalize360(heading);
    final nextHeading = _hasLiveCompass
        ? _normalize360(_currentHeading + _shortestDelta(normalized) * 0.28)
        : normalized;

    setState(() {
      _currentHeading = nextHeading;
      _isLoading = false;
      _hasLiveCompass = true;
      _compassMessage = message;
    });
  }

  double _shortestDelta(double targetHeading) {
    var delta = targetHeading - _currentHeading;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;
    return delta;
  }

  double _normalize360(double angle) {
    return ((angle % 360) + 360) % 360;
  }

  @override
  void dispose() {
    _sensorFallbackTimer?.cancel();
    _magnetometerSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    stopBrowserCompass();
    super.dispose();
  }

  Future<void> _loadNearbyMosques({bool requestFreshLocation = false}) async {
    if (_isLocatingMosques) return;

    setState(() => _isLocatingMosques = requestFreshLocation);

    Position? position;
    if (requestFreshLocation) {
      position = await ref.read(locationServiceProvider).getCurrentLocation();
      if (position != null) {
        final cityName =
            await ref.read(locationServiceProvider).getCityName(position);
        if (!mounted) return;
        ref.read(currentPositionProvider.notifier).state = position;
        ref.read(currentCityProvider.notifier).state =
            cityName == 'Bilinmeyen' ? 'Mevcut Konum' : cityName;
      }
    }

    position ??= ref.read(currentPositionProvider) ??
        _positionForSelectedCity(ref.read(currentCityProvider)) ??
        _positionFromCoords(defaultLatitude, defaultLongitude);

    if (!mounted) return;
    setState(() {
      _isLocatingMosques = false;
      _mosqueQueryPosition = position;
      _nearbyMosquesFuture = _findNearbyMosquesWithFallback(position!);
    });
  }

  Future<List<MosquePlace>> _findNearbyMosquesWithFallback(
    Position position,
  ) async {
    final primary = await _nearbyMosqueService.findNearbyMosques(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    if (primary.isNotEmpty) return primary;

    final fallback = _positionForSelectedCity(ref.read(currentCityProvider)) ??
        _nearestCityPosition(position);
    if (_distanceKm(
          position.latitude,
          position.longitude,
          fallback.latitude,
          fallback.longitude,
        ) <
        2) {
      return primary;
    }

    final fallbackPlaces = await _nearbyMosqueService.findNearbyMosques(
      latitude: fallback.latitude,
      longitude: fallback.longitude,
      radiusMeters: 30000,
    );

    if (fallbackPlaces.isNotEmpty && mounted) {
      setState(() => _mosqueQueryPosition = fallback);
    }
    return fallbackPlaces;
  }

  Position? _positionForSelectedCity(String cityName) {
    final city = findCityCoordinate(cityName);
    if (city == null) return null;
    return _positionFromCoords(city.latitude, city.longitude);
  }

  Position _nearestCityPosition(Position position) {
    var nearest = cityCoordinates.first;
    var nearestDistance = double.infinity;

    for (final city in cityCoordinates) {
      final distance = _distanceKm(
        position.latitude,
        position.longitude,
        city.latitude,
        city.longitude,
      );
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = city;
      }
    }

    return _positionFromCoords(nearest.latitude, nearest.longitude);
  }

  Position _positionFromCoords(double latitude, double longitude) {
    return Position(
      latitude: latitude,
      longitude: longitude,
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

  @override
  Widget build(BuildContext context) {
    final currentCity = ref.watch(currentCityProvider);
    final position = ref.watch(currentPositionProvider) ??
        _positionForSelectedCity(currentCity) ??
        _positionFromCoords(defaultLatitude, defaultLongitude);
    final qiblaDirection = QiblaDirection.calculate(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kıble Bulucu'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              AppColors.secondary.withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          child:
              _isLoading ? _buildLoadingState() : _buildContent(qiblaDirection),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppDimensions.spacingMD),
          Text(
            'Pusula kalibre ediliyor...',
            style: GoogleFonts.notoSans(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(QiblaDirection qiblaDir) {
    final relativeAngle =
        _normalizeAngle(qiblaDir.qiblaDirection - _currentHeading);
    final isAligned = relativeAngle.abs() < 10;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppDimensions.spacingLG),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              children: [
                _buildLocationCard(qiblaDir),
                if (!_hasLiveCompass) ...[
                  ElevatedButton.icon(
                    onPressed: _requestAndStartBrowserCompass,
                    icon: const Icon(Icons.explore),
                    label: const Text('Pusulayı Başlat'),
                  ),
                  const SizedBox(height: AppDimensions.spacingSM),
                  _buildManualHeadingPanel(),
                  const SizedBox(height: AppDimensions.spacingMD),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPadding,
                  ),
                  child: CompassWidget(
                    qiblaDirection: qiblaDir.qiblaDirection,
                    currentHeading: _currentHeading,
                    isAligned: isAligned,
                    isLiveCompass: _hasLiveCompass,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingLG),
                _buildInfoPanel(qiblaDir),
                const SizedBox(height: AppDimensions.spacingLG),
                _buildNearbyMosquesPanel(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildManualHeadingPanel() {
    return Container(
      margin:
          const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
      padding: const EdgeInsets.all(AppDimensions.spacingMD),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.primary.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: AppColors.primary, size: 20),
              const SizedBox(width: AppDimensions.spacingSM),
              Expanded(
                child: Text(
                  'Sensör yoksa elle hizala',
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${_currentHeading.round()}°',
                style: GoogleFonts.notoSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          Slider(
            value: _currentHeading.clamp(0, 359).toDouble(),
            min: 0,
            max: 359,
            divisions: 359,
            activeColor: AppColors.primary,
            label: '${_currentHeading.round()}°',
            onChanged: (value) {
              setState(() {
                _currentHeading = value;
                _compassMessage =
                    'Pusula sensörü yoksa telefonu çevirdiğin yönü buradan elle ayarlayabilirsin.';
              });
            },
          ),
          Wrap(
            spacing: AppDimensions.spacingSM,
            runSpacing: AppDimensions.spacingSM,
            children: [
              _headingChip('K', 0),
              _headingChip('D', 90),
              _headingChip('G', 180),
              _headingChip('B', 270),
              OutlinedButton.icon(
                onPressed: () => _nudgeHeading(-10),
                icon: const Icon(Icons.rotate_left),
                label: const Text('-10°'),
              ),
              OutlinedButton.icon(
                onPressed: () => _nudgeHeading(10),
                icon: const Icon(Icons.rotate_right),
                label: const Text('+10°'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headingChip(String label, double heading) {
    return ActionChip(
      label: Text(label),
      avatar: const Icon(Icons.explore, size: 16),
      onPressed: () {
        setState(() => _currentHeading = heading);
      },
    );
  }

  void _nudgeHeading(double delta) {
    setState(() {
      _currentHeading = _normalize360(_currentHeading + delta);
    });
  }

  Widget _buildLocationCard(QiblaDirection qiblaDir) {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.screenPadding),
      padding: const EdgeInsets.all(AppDimensions.spacingMD),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: AppColors.primary),
          const SizedBox(width: AppDimensions.spacingSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ref.watch(currentCityProvider),
                  style: GoogleFonts.notoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${qiblaDir.formattedDistance} uzaklıkta',
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyMosquesPanel() {
    return Container(
      margin:
          const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.primary.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingSM),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Icon(
                  Icons.mosque,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yakındaki Camiler',
                      style: GoogleFonts.notoSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _mosqueQueryPosition == null
                          ? 'Konuma göre en yakın camiler'
                          : 'Seçili konuma göre sıralandı',
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Konumla yenile',
                onPressed: _isLocatingMosques
                    ? null
                    : () => _loadNearbyMosques(requestFreshLocation: true),
                icon: _isLocatingMosques
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMD),
          FutureBuilder<List<MosquePlace>>(
            future: _nearbyMosquesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return _buildMosqueEmptyState(
                  'Camiler yüklenemedi. Konumu yenileyip tekrar deneyin.',
                );
              }

              final mosques = snapshot.data ?? const <MosquePlace>[];
              if (mosques.isEmpty) {
                return _buildMosqueEmptyState(
                  'Yakında kayıtlı cami bulunamadı. Veriler OpenStreetMap kayıtlarına bağlıdır.',
                );
              }

              return Column(
                children: [
                  for (final mosque in mosques.take(5))
                    _buildMosqueTile(mosque),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMosqueEmptyState(String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          message,
          style: GoogleFonts.notoSans(
            fontSize: 13,
            height: 1.35,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingSM),
        OutlinedButton.icon(
          onPressed: _isLocatingMosques
              ? null
              : () => _loadNearbyMosques(requestFreshLocation: true),
          icon: const Icon(Icons.my_location),
          label: const Text('Konumumu Kullan'),
        ),
      ],
    );
  }

  Widget _buildMosqueTile(MosquePlace mosque) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingSM),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingMD),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant.withOpacity(0.55),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mosque.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(
                    mosque.address ?? 'Adres bilgisi yok',
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  mosque.formattedDistance,
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _openMosqueInMaps(mosque),
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text('Harita'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMosqueInMaps(MosquePlace mosque) async {
    final uri = Uri.https(
      'www.google.com',
      '/maps/search/',
      {
        'api': '1',
        'query': '${mosque.latitude},${mosque.longitude}',
      },
    );

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildInfoPanel(QiblaDirection qiblaDir) {
    return Container(
      margin:
          const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                icon: Icons.explore,
                label: 'Yön',
                value: qiblaDir.fullDirectionName,
              ),
              _buildInfoItem(
                icon: Icons.arrow_upward,
                label: 'Açı',
                value: '${qiblaDir.qiblaDirection.toStringAsFixed(1)}°',
              ),
              _buildInfoItem(
                icon: Icons.straighten,
                label: 'Mesafe',
                value: qiblaDir.formattedDistance,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMD),
          Text(
            _compassMessage,
            style: GoogleFonts.notoSans(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: AppDimensions.spacingXS),
        Text(
          label,
          style: GoogleFonts.notoSans(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.notoSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
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

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}
