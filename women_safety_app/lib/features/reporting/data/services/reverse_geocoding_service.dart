import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ReverseGeocodingService {
  Future<Map<String, String>> getLocationDetails({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(
      "https://nominatim.openstreetmap.org/reverse"
      "?format=jsonv2"
      "&addressdetails=1"
      "&lat=$latitude"
      "&lon=$longitude"
      "&zoom=18",
    );

    final response = await http.get(
      uri,
      headers: {
        "User-Agent": "WomenSafetyMonitoringApp/1.0",
        "Accept-Language": "en",
      },
    );

    if (response.statusCode != 200) {
      debugPrint("===== REVERSE GEOCODING FAILED =====");
      debugPrint("STATUS: ${response.statusCode}");
      debugPrint("BODY: ${response.body}");

      return {};
    }

    final data = jsonDecode(response.body);

    debugPrint("===== NOMINATIM RESPONSE =====");
    debugPrint(response.body);

    final address = data["address"] ?? {};

    // ==============================
    // REGION
    // ==============================
    final region = _firstNonEmpty([
      address["state"],
      address["region"],
    ]);

    // ==============================
    // DISTRICT
    // ==============================
    final district = _firstNonEmpty([
      address["county"],
      address["district"],
      address["municipality"],
      address["city_district"],
    ]);

    // ==============================
    // WARD
    // ==============================
    final ward = _firstNonEmpty([
      address["ward"],
      address["suburb"],
      address["neighbourhood"],
    ]);

    // ==============================
    // STREET / ROAD
    // ==============================
    final street = _firstNonEmpty([
      address["road"],
      address["street"],
    ]);

    // ==============================
    // VILLAGE / LOCALITY
    // ==============================
    final village = _firstNonEmpty([
      address["village"],
      address["town"],
      address["city"],
      address["municipality"],
    ]);

    // ==============================
    // COUNTRY
    // ==============================
    final country = _firstNonEmpty([
      address["country"],
    ]);

    /*
     * Build a readable location.
     *
     * Example:
     * Geita, Nyang'hwale, Kharumwa, Busengwa
     */
    final locationParts = <String>[
      region,
      district,
      ward,
      village,
      street,
    ];

    final uniqueParts = <String>[];

    for (final part in locationParts) {
      final cleaned = part.trim();

      if (cleaned.isEmpty) {
        continue;
      }

      if (!uniqueParts.any(
        (existing) =>
            existing.toLowerCase() == cleaned.toLowerCase(),
      )) {
        uniqueParts.add(cleaned);
      }
    }

    final locationName = uniqueParts.join(", ");

    debugPrint("===== LOCATION DETAILS =====");
    debugPrint("REGION: $region");
    debugPrint("DISTRICT: $district");
    debugPrint("WARD: $ward");
    debugPrint("VILLAGE: $village");
    debugPrint("STREET: $street");
    debugPrint("COUNTRY: $country");
    debugPrint("LOCATION NAME: $locationName");

    return {
      "region": region,
      "district": district,
      "ward": ward,
      "village": village,
      "street": street,
      "country": country,
      "location_name": locationName,
    };
  }

  String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      if (value == null) {
        continue;
      }

      final text = value.toString().trim();

      if (text.isNotEmpty) {
        return text;
      }
    }

    return "";
  }
}