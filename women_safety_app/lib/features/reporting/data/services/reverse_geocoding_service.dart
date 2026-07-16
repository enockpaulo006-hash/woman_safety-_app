import 'dart:convert';

import 'package:http/http.dart' as http;

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
      return {};
    }

    final data = jsonDecode(response.body);

    final address = data["address"] ?? {};

    return {
      "ward": address["suburb"] ??
          address["city_district"] ??
          address["neighbourhood"] ??
          "",

      "district": address["county"] ??
          address["municipality"] ??
          "",

      "region": address["state"] ?? "",

      "country": address["country"] ?? "",
    };
  }
}