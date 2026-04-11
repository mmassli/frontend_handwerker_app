import 'package:dio/dio.dart';

// ═══════════════════════════════════════════════════════════════
// GEOCODING RESULT
// ═══════════════════════════════════════════════════════════════

class GeocodingResult {
  final double lat;
  final double lng;
  final String normalizedAddress;
  final String? postleitzahl;
  final String? street;
  final String? city;

  const GeocodingResult({
    required this.lat,
    required this.lng,
    required this.normalizedAddress,
    this.postleitzahl,
    this.street,
    this.city,
  });
}

// ═══════════════════════════════════════════════════════════════
// GEOCODING SERVICE — OpenStreetMap Nominatim (no API key)
// ═══════════════════════════════════════════════════════════════

class GeocodingService {
  static final GeocodingService _instance = GeocodingService._internal();
  factory GeocodingService() => _instance;

  late final Dio _dio;

  GeocodingService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://nominatim.openstreetmap.org',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          // Nominatim requires a User-Agent header
          'User-Agent': 'HandwerkerApp/1.0',
          'Accept-Language': 'de,en;q=0.8',
          'Accept': 'application/json',
        },
      ),
    );
  }

  /// Geocodes a free-text address string using Nominatim.
  /// Returns [GeocodingResult] on success, or null if no result found.
  /// Throws on network error (caller should handle).
  Future<GeocodingResult?> geocode(String addressText) async {
    final trimmed = addressText.trim();
    if (trimmed.isEmpty) return null;

    final response = await _dio.get(
      '/search',
      queryParameters: {
        'q': trimmed,
        'format': 'json',
        'limit': 1,
        'addressdetails': 1,
        'countrycodes': 'de',
      },
    );

    final data = response.data;
    if (data is! List || data.isEmpty) return null;

    final first = data[0] as Map<String, dynamic>;
    final lat = double.tryParse(first['lat'] as String? ?? '');
    final lon = double.tryParse(first['lon'] as String? ?? '');
    if (lat == null || lon == null) return null;

    final addressDetails = first['address'] as Map<String, dynamic>?;
    final plz = addressDetails?['postcode'] as String?;
    final displayName = first['display_name'] as String? ?? trimmed;

    // Build street from road + house_number
    final road = addressDetails?['road'] as String? ?? '';
    final houseNumber = addressDetails?['house_number'] as String? ?? '';
    final street = [road, houseNumber].where((s) => s.isNotEmpty).join(' ');

    // City: prefer city → town → village → municipality
    final city = (addressDetails?['city'] ??
            addressDetails?['town'] ??
            addressDetails?['village'] ??
            addressDetails?['municipality']) as String?;

    return GeocodingResult(
      lat: lat,
      lng: lon,
      normalizedAddress: displayName,
      postleitzahl: plz,
      street: street.isNotEmpty ? street : null,
      city: city,
    );
  }
}

