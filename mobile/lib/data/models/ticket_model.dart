class TicketModel {
  final int id;
  final int reservationId;
  final String ticketCode;
  final String qrData;
  final String? createdAt;
  final String? movieTitle; 
  final String? imageUrl; // 🔥 FİLM AFİŞİ İÇİN EKLENDİ

  TicketModel({
    required this.id,
    required this.reservationId,
    required this.ticketCode,
    required this.qrData,
    this.createdAt,
    this.movieTitle, 
    this.imageUrl, // 🔥 EKLENDİ
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] ?? 0,
      reservationId: json['reservation_id'] ?? 0,
      ticketCode: json['ticket_code'] ?? '',
      qrData: json['qr_data'] ?? '',
      createdAt: json['created_at'],
      movieTitle: json['movie_title'] ?? json['event_name'] ?? 'Bilinmeyen Etkinlik', 
      // 🔥 Backend'den resim linki 'movie_image', 'image_url' veya 'poster_url' adıyla geliyorsa yakalar
      imageUrl: json['movie_image'] ?? json['image_url'] ?? json['poster_url'], 
    );
  }
}