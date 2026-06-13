/// Map URLs — no API key required.
class MapsConfig {
  MapsConfig._();

  static const defaultLat = 6.5244;
  static const defaultLng = 3.3792;

  /// Opens location in Google Maps (browser / app).
  static String googleMapsLink({required double lat, required double lng}) =>
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

  /// Opens location in OpenStreetMap.
  static String openStreetMapLink({required double lat, required double lng}) =>
      'https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=16/$lat/$lng';

  /// Embeddable OpenStreetMap preview (used on web).
  static String openStreetMapEmbed({required double lat, required double lng}) {
    const delta = 0.025;
    final west = lng - delta;
    final south = lat - delta;
    final east = lng + delta;
    final north = lat + delta;
    return 'https://www.openstreetmap.org/export/embed.html'
        '?bbox=$west,$south,$east,$north&layer=mapnik&marker=$lat,$lng';
  }
}
