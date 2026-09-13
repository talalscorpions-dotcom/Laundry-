/// A minimal lat/lng pair. Kept dependency-free (no maps package) so the
/// domain model doesn't require a map SDK/API key just to compile — swap in
/// `google_maps_flutter`'s `LatLng` (or similar) when wiring a real map.
class GeoPoint {
  const GeoPoint(this.lat, this.lng);

  final double lat;
  final double lng;

  /// Linear interpolation between this point and [other] at [t] (0..1).
  /// Good enough for the short intra-city hops this demo simulates; a real
  /// integration would follow an actual routed polyline instead.
  GeoPoint lerp(GeoPoint other, double t) {
    return GeoPoint(
      lat + (other.lat - lat) * t,
      lng + (other.lng - lng) * t,
    );
  }
}

class Address {
  const Address({
    required this.id,
    required this.label,
    required this.line1,
    required this.city,
    required this.location,
  });

  final String id;
  final String label; // e.g. Home, Office
  final String line1;
  final String city;
  final GeoPoint location;
}
