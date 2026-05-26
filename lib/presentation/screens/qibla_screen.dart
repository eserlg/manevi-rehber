import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../data/models/qibla.dart';
import '../../data/services/browser_compass_stub.dart'
    if (dart.library.js_interop) '../../data/services/browser_compass_web.dart';
import '../providers/providers.dart';
import '../widgets/compass_widget.dart';

class QiblaScreen extends ConsumerStatefulWidget {
  const QiblaScreen({super.key});

  @override
  ConsumerState<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends ConsumerState<QiblaScreen> {
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  Timer? _sensorFallbackTimer;
  double _currentHeading = 0;
  MagnetometerEvent? _lastMagnetometer;
  AccelerometerEvent? _lastAccelerometer;
  bool _isLoading = true;
  bool _hasLiveCompass = false;
  String _compassMessage = 'Pusula başlatılıyor...';

  @override
  void initState() {
    super.initState();
    _initCompass();
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

    _startBrowserCompass();
    _sensorFallbackTimer = Timer(const Duration(seconds: 3), _useStaticCompass);

    try {
      _magnetometerSubscription = magnetometerEventStream().listen(
        (event) {
          _sensorFallbackTimer?.cancel();
          _lastMagnetometer = event;
          _updateHeadingFromNativeSensors();
        },
        onError: (_) => _useStaticCompass(),
      );

      _accelerometerSubscription = accelerometerEventStream().listen(
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
    if (mounted) {
      setState(() {
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
            ? 'Pusula verisi bekleniyor...'
            : 'Bu cihazda pusula sensörü desteklenmiyor.';
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
    if (magnetometer == null) return;

    var heading = atan2(magnetometer.y, magnetometer.x) * 180 / pi;
    final accelerometer = _lastAccelerometer;
    if (accelerometer != null) {
      final tilt = sqrt(
        accelerometer.x * accelerometer.x +
            accelerometer.y * accelerometer.y +
            accelerometer.z * accelerometer.z,
      );
      if (tilt > 0) {
        final flatness =
            (accelerometer.z.abs() / tilt).clamp(0.0, 1.0).toDouble();
        heading += accelerometer.y.sign.toDouble() * (1 - flatness) * 6;
      }
    }

    _setLiveHeading(
      _normalize360(heading),
      'Telefonu yatay tutup ortadaki oku Kıble işaretiyle hizalayın.',
    );
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

  @override
  Widget build(BuildContext context) {
    final position = ref.watch(currentPositionProvider);
    final qiblaDirection = position != null
        ? QiblaDirection.calculate(
            latitude: position.latitude,
            longitude: position.longitude,
          )
        : QiblaDirection.calculate(
            latitude: defaultLatitude,
            longitude: defaultLongitude,
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
                if (!_hasLiveCompass) ...[
                  const SizedBox(height: AppDimensions.spacingMD),
                  ElevatedButton.icon(
                    onPressed: _requestAndStartBrowserCompass,
                    icon: const Icon(Icons.explore),
                    label: const Text('Pusulayı Başlat'),
                  ),
                  const SizedBox(height: AppDimensions.spacingMD),
                  _buildManualHeadingPanel(),
                  const SizedBox(height: AppDimensions.spacingMD),
                ],
                const SizedBox(height: AppDimensions.spacingLG),
                _buildInfoPanel(qiblaDir),
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
}
