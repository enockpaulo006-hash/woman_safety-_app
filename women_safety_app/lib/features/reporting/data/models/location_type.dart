class LocationType {
  const LocationType({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.sortOrder,
  });

  final String id;
  final String code;
  final String name;
  final String? description;
  final int sortOrder;

  factory LocationType.fromJson(Map<String, dynamic> json) {
    return LocationType(
      id: json["id"] as String,
      code: json["code"] as String,
      name: json["name"] as String,
      description: json["description"] as String?,
      sortOrder: json["sort_order"] as int? ?? 0,
    );
  }
}
