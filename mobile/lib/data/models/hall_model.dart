import 'seat_model.dart';

class HallModel {
  final int id;
  final String name;
  final int rowCount;
  final int columnCount;
  final List<SeatModel> seats;

  HallModel({
    required this.id,
    required this.name,
    required this.rowCount,
    required this.columnCount,
    required this.seats,
  });

  factory HallModel.fromJson(Map<String, dynamic> json) {
    // Koltuk verisi null gelirse boş liste ata, yoksa map'le
    var list = json['seats'] as List?;
    List<SeatModel> seatList = list != null 
        ? list.map((i) => SeatModel.fromJson(i)).toList() 
        : [];

    return HallModel(
      id: json['id'],
      name: json['name'] ?? "Bilinmeyen Salon",
      rowCount: json['row_count'] ?? 0,
      columnCount: json['column_count'] ?? 0,
      seats: seatList,
    );
  }
}