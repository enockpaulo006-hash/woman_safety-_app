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
      "&lat=$latitude"
      "&lon=$longitude",
    );

    final response = await http.get(
      uri,
      headers: {
        "User-Agent": "WomenSafetyMonitoringApp/1.0",
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

    final ward = address["suburb"] ??
    address["city_district"] ??
    address["neighbourhood"] ??
    "";

    final district = address["county"] ??
    address["municipality"] ??
    "";

    final region = address["state"] ?? "";

    final country = address["country"] ?? "";

    final locationName = [
     ward,
     district,
     region,
    ]
    .where((e) => e.toString().trim().isNotEmpty)
    .join(", ");

    debugPrint("WARD: $ward");
    debugPrint("DISTRICT: $district");
    debugPrint("REGION: $region");
    debugPrint("LOCATION NAME: $locationName");

    return {
      "ward": ward,
      "district": district,
      "region": region,
      "country": country,
      "location_name": locationName,
};
  }
}