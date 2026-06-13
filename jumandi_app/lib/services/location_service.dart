import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'reverse_geocode_service.dart';

class LocationDetails {
  const LocationDetails({
    this.position,
    this.address,
    this.errorMessage,
    this.needsSettings = false,
  });

  final Position? position;
  final String? address;
  final String? errorMessage;
  final bool needsSettings;

  bool get hasPosition => position != null;
}

class LocationService {
  final _geocode = ReverseGeocodeService();

  Future<bool> ensurePermission({bool requestIfNeeded = true}) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (requestIfNeeded &&
        (permission == LocationPermission.denied ||
            permission == LocationPermission.unableToDetermine)) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<LocationDetails> getCurrentLocationDetails() async {
    final positionResult = await _resolvePosition();
    if (positionResult.position == null) {
      return LocationDetails(
        errorMessage: positionResult.errorMessage,
        needsSettings: positionResult.needsSettings,
      );
    }

    final position = positionResult.position!;
    final address = await _geocode.getAddress(position.latitude, position.longitude);
    return LocationDetails(position: position, address: address);
  }

  Future<LocationDetails> getCurrentPositionDetails() async {
    final positionResult = await _resolvePosition();
    if (positionResult.position == null) {
      return LocationDetails(
        errorMessage: positionResult.errorMessage,
        needsSettings: positionResult.needsSettings,
      );
    }
    return LocationDetails(position: positionResult.position);
  }

  Future<Position?> getCurrentPosition() async {
    final result = await _resolvePosition();
    return result.position;
  }

  Future<_PositionResult> _resolvePosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const _PositionResult(
        errorMessage: 'Turn on location services on your device, then tap retry.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return const _PositionResult(
        errorMessage: 'Location access denied. Tap below to allow it.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      return const _PositionResult(
        errorMessage: 'Location is blocked. Open settings and allow location for this app.',
        needsSettings: true,
      );
    }

    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on TimeoutException {
      position = await Geolocator.getLastKnownPosition();
    } catch (_) {
      position = await Geolocator.getLastKnownPosition();
    }

    if (position == null) {
      return const _PositionResult(
        errorMessage: 'Could not get a GPS fix. Move near a window and tap retry.',
      );
    }

    return _PositionResult(position: position);
  }

  Future<String?> getAddress(double lat, double lng) {
    return _geocode.getAddress(lat, lng);
  }

  Future<void> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }

  StreamSubscription<Position>? watchPosition(void Function(Position) onUpdate) {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(onUpdate);
  }
}

class _PositionResult {
  const _PositionResult({
    this.position,
    this.errorMessage,
    this.needsSettings = false,
  });

  final Position? position;
  final String? errorMessage;
  final bool needsSettings;
}
