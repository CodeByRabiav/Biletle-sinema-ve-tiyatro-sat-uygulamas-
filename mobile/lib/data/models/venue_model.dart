class VenueModel {
  final int id;
  final String name;
  final String city;
  final String district;
  final String venueType;
  final int rowCount;
  final int columnCount;

  VenueModel({
    required this.id,
    required this.name,
    required this.city,
    required this.district,
    required this.venueType,
    required this.rowCount,
    required this.columnCount,
  });

  factory VenueModel.fromJson(Map<String, dynamic> json) {
    return VenueModel(
      id: json['id'],
      name: json['name'],
      city: json['city'],
      district: json['district'],
      venueType: json['venue_type'],
      rowCount: json['row_count'],
      columnCount: json['column_count'],
    );
  }
}