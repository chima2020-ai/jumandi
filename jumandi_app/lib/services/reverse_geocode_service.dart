import 'package:dio/dio.dart';

class ReverseGeocodeService {
  ReverseGeocodeService()
      : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: const {'User-Agent': 'JumandiApp/1.0 (gas delivery)'},
          ),
        );

  final Dio _dio;

  Future<String?> getAddress(double lat, double lng) async {
    final nominatim = await _fromNominatim(lat, lng);
    if (nominatim != null && nominatim.isNotEmpty) return nominatim;
    return _fromBigDataCloud(lat, lng);
  }

  Future<String?> _fromNominatim(double lat, double lng) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'jsonv2',
          'lat': lat,
          'lon': lng,
          'addressdetails': 1,
        },
      );
      final data = response.data;
      if (data == null) return null;

      final formatted = _formatAddress(data['address'] as Map<String, dynamic>?);
      if (formatted != null && formatted.isNotEmpty) return formatted;

      final display = data['display_name'] as String?;
      return display?.isNotEmpty == true ? display : null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _fromBigDataCloud(double lat, double lng) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.bigdatacloud.net/data/reverse-geocode-client',
        queryParameters: {
          'latitude': lat,
          'longitude': lng,
          'localityLanguage': 'en',
        },
      );
      final data = response.data;
      if (data == null) return null;

      final parts = <String>[
        if (data['locality'] case final String v when v.isNotEmpty) v,
        if (data['city'] case final String v when v.isNotEmpty) v,
        if (data['principalSubdivision'] case final String v when v.isNotEmpty) v,
        if (data['countryName'] case final String v when v.isNotEmpty) v,
      ].toSet().toList();

      if (parts.isNotEmpty) return parts.join(', ');
      final display = data['display_name'] as String?;
      return display?.isNotEmpty == true ? display : null;
    } catch (_) {
      return null;
    }
  }

  String? _formatAddress(Map<String, dynamic>? addr) {
    if (addr == null) return null;

    final house = addr['house_number'] as String?;
    final road = addr['road'] as String? ?? addr['pedestrian'] as String?;
    final area = addr['suburb'] as String? ??
        addr['neighbourhood'] as String? ??
        addr['quarter'] as String?;
    final city = addr['city'] as String? ??
        addr['town'] as String? ??
        addr['village'] as String? ??
        addr['county'] as String?;
    final state = addr['state'] as String?;
    final country = addr['country'] as String?;

    final line1Parts = [house, road].whereType<String>().where((s) => s.isNotEmpty);
    final line1 = line1Parts.join(' ');

    final line2Parts = [area, city, state, country]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    if (line1.isNotEmpty && line2Parts.isNotEmpty) {
      return '$line1, ${line2Parts.join(', ')}';
    }
    if (line1.isNotEmpty) return line1;
    if (line2Parts.isNotEmpty) return line2Parts.join(', ');
    return null;
  }
}
