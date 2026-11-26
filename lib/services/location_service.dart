import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../models/shelter.dart';

enum LocationIssue { serviceDisabled, denied, deniedForever, timeout, unknown }

class LocationException implements Exception {
  final LocationIssue issue;
  final String message;
  const LocationException(this.issue, this.message);

  @override
  String toString() => message;
}

class LocationService {
  // 1) GPS switched on?  2) permission?  3) read the position.
  static Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        LocationIssue.serviceDisabled,
        'Location services are turned off. Please enable GPS.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException(
          LocationIssue.denied,
          'Location permission denied. Walk photos need a location.',
        );
      }
    }

    // "Don't ask again" on Android / "Don't Allow" on iOS:
    // the system dialog will not appear any more, only Settings can help.
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        LocationIssue.deniedForever,
        'Location permission is blocked. Allow it in the app settings.',
      );
    }

    try {
      // Same as desiredAccuracy: LocationAccuracy.high
      // (desiredAccuracy is deprecated in geolocator 10+).
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } on TimeoutException {
      throw const LocationException(
        LocationIssue.timeout,
        'Could not get a GPS fix in 20 seconds. Try again near a window.',
      );
    } catch (_) {
      throw const LocationException(
        LocationIssue.unknown,
        'Could not read your location.',
      );
    }
  }

  static double distanceToShelter(Position p) => Geolocator.distanceBetween(
    p.latitude,
    p.longitude,
    Shelter.latitude,
    Shelter.longitude,
  );

  static Future<bool> openLocationSettings() =>
      Geolocator.openLocationSettings();

  static Future<bool> openAppSettings() => Geolocator.openAppSettings();
}
