import 'package:geolocator/geolocator.dart';

import '../models/address.dart';

/// Abstraction over "where is this device right now" — a one-shot GPS fix,
/// distinct from [LocationTracker] (which simulates a *driver* moving along
/// a route). Behind an interface for the same reason as the other services:
/// so a fake can be injected in tests, and so a different location provider
/// can replace [GeolocatorDeviceLocationService] without touching UI code.
abstract class DeviceLocationService {
  /// The device's current position, or null if location services are off,
  /// permission was denied, or a fix couldn't be obtained.
  Future<GeoPoint?> getCurrentLocation();
}

class GeolocatorDeviceLocationService implements DeviceLocationService {
  @override
  Future<GeoPoint?> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      return GeoPoint(position.latitude, position.longitude);
    } catch (_) {
      // Any platform-specific failure (timeout, no provider, etc.) is
      // reported to the caller the same way as "unavailable" — the UI falls
      // back to manual address entry / pin drop either way.
      return null;
    }
  }
}
