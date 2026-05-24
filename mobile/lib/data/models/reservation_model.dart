class ReservationModel {
  final int id;
  final int userId;
  final int sessionId;
  final String status;
  final double totalPrice;
  final String paymentStatus;
  final String? createdAt;

  ReservationModel({
    required this.id,
    required this.userId,
    required this.sessionId,
    required this.status,
    required this.totalPrice,
    required this.paymentStatus,
    this.createdAt,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'],
      userId: json['user_id'],
      sessionId: json['session_id'],
      status: json['status'],
      totalPrice: (json['total_price'] as num).toDouble(),
      paymentStatus: json['payment_status'],
      createdAt: json['created_at'],
    );
  }
}