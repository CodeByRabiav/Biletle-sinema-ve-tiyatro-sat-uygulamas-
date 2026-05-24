class SeatModel {
  final int id;
  final int hallId;
  final String rowLabel;
  final int seatNumber;

  SeatModel({
    required this.id,
    required this.hallId,
    required this.rowLabel,
    required this.seatNumber,
  });

  factory SeatModel.fromJson(Map<String, dynamic> json) {
    return SeatModel(
      id: json['id'],
      hallId: json['hall_id'],
      rowLabel: json['row_label'] ?? "",
      seatNumber: json['seat_number'] ?? 0,
    );
  }

  // Arayüzde "A-1", "B-5" gibi göstermek istersen yardımcı getter
  String get label => '$rowLabel-$seatNumber';
}