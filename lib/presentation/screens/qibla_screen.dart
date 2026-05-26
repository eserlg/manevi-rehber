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

class _QiblaScreenState extends ConsumerState<QiblaScreen>
    with SingleTickerProviderStateMixin {
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  Timer? _sensorFallbackTimer;
  double _currentHeading = 0;
  double _pitch = 0;
  double _roll = 0;
  bool _isLoading = true;
  bool _hasLiveCompass = false;
  String _compassMessage = 'Pusula başlatılıyor...';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initCompass();
    _initAnimation();
  }

  void _initAnimation() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initCompass() async {
    _sensorFallbackTimer?.cancel();
    await _magnetometerSubscription?.cancel();
    await _accelerometerSubscription?.cancel();

    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasLiveCompass = false;
        _compassMessage = 'Pusula başlatılıyor...';
      });
    }

    _startBrowserCompass();
    _sensorFallbackTimer = Timer(const Duration(seconds: 3), _useStaticCompass);

    try {
      _magnetometerSubscription = magnetometerEventStream().listen(
        (event) {
          _sensorFallbackTimer?.cancel();
          var heading = atan2(event.y, event.x) * 180 / pi;
          heading = (heading + 360) % 360;

          if (!mounted) return;
          setState(() {
            _currentHeading = heading;
            _isLoading = false;
            _hasLiveCompass = true;
          });
        },
        onError: (_) => _useStaticCompass(),
      );

      _accelerometerSubscription = accelerometerEventStream().listen(
        (event) {
          if (!mounted) return;
          setState(() {
            _pitch = event.x * pi / 180;
            _roll = event.y * pi / 180;
          });
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
      if (!mounted) return;

      setState(() {
        _currentHeading = heading;
        _isLoading = false;
        _hasLiveCompass = true;
        _compassMessage =
            'Telefonu yatay tutup ortadaki oku Kıble işaretiyle hizalayın.';
      });
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

  @override
  void dispose() {
    _sensorFallbackTimer?.cancel();
    _magnetometerSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    stopBrowserCompass();
    _pulseController.dispose();
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
                const SizedBox(height: AppDimensions.spacingLG),
                if (!_hasLiveCompass) ...[
                  ElevatedButton.icon(
                    onPressed: _requestAndStartBrowserCompass,
                    icon: const Icon(Icons.explore),
                    label: const Text('Pusulayı Başlat'),
                  ),
                  const SizedBox(height: AppDimensions.spacingMD),
                ],
                _buildInfoPanel(qiblaDir),
              ],
            ),
          ),
        );
      },
    );
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
