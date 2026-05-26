import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/models/qibla.dart';

class CompassService {
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  
  double _heading = 0;
  double _pitch = 0;
  double _roll = 0;

  Stream<double> get compassStream {
    return Stream.periodic(const Duration(milliseconds: 50), (_) => _heading);
  }

  Future<bool> requestPermission() async {
    var status = await Permission.sensors.status;
    if (status.isDenied) {
      status = await Permission.sensors.request();
    }
    return status.isGranted;
  }

  void startListening() {
    // Listen to magnetometer for heading
    _magnetometerSubscription = magnetometerEventStream().listen((event) {
      _updateHeading(event);
    });
    
    // Listen to accelerometer for pitch/roll
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      _pitch = event.x * pi / 180;
      _roll = event.y * pi / 180;
    });
  }

  void _updateHeading(MagnetometerEvent event) {
    // Calculate heading from magnetometer data
    double heading = atan2(event.y, event.x);
    heading = heading * 180 / pi;
    heading = (heading + 360) % 360;
    
    _heading = heading;
  }

  void stopListening() {
    _magnetometerSubscription?.cancel();
    _accelerometerSubscription?.cancel();
  }

  void dispose() {
    stopListening();
  }

  /// Calculate Qibla direction for given coordinates
  static QiblaDirection calculateQibla({
    required double latitude,
    required double longitude,
  }) {
    return QiblaDirection.calculate(
      latitude: latitude,
      longitude: longitude,
    );
  }
}