import 'package:geolocator/geolocator.dart';

import '../config/app_config.dart';

/// Handles GPS position acquisition with mock-location and accuracy checks.
class GpsService {
  /// Acquire a high-accuracy position.
  ///
  /// Returns `null` if:
  /// - permissions are denied,
  /// - the location is mocked,
  /// - accuracy exceeds [AppConfig.gpsAccuracyThreshold].
  Future<Position?> getCurrentPosition() async {
    // Check service
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    // Check permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return null;
    }

    // Get position
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );

    // Reject mocked locations
    if (position.isMocked) return null;

    // Reject coarse fixes
    if (position.accuracy > AppConfig.gpsAccuracyThreshold) return null;

    return position;
  }
}
