import 'movie_model.dart';

class SessionModel {
  final int? id;
  final int? hallId;
  final String? hallName; // Backend'den gelen salon adı
  final String? date;     // "2024-05-20" gibi tarih formatı
  final String? time;     // "19:30" formatı
  final double? price;
  final String? movieTitle;
  final String? imageUrl;
  final String? category;
  final String? genre;
  final String? rating;
  final String? duration;

  SessionModel({
    this.id,
    this.hallId,
    this.hallName,
    this.date,
    this.time,
    this.price,
    this.movieTitle,
    this.imageUrl,
    this.category,
    this.genre,
    this.rating,
    this.duration,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'] as int?,
      hallId: json['hall_id'] as int?,
      hallName: json['hall_name']?.toString(), // Backend'deki "hall_name" anahtarı
      date: json['start_time']?.toString(),   // Backend'deki tam tarih/saat verisi
      time: json['time']?.toString(),         // Sadece saat verisi (HH:mm)
      price: json['price'] != null ? (json['price'] as num).toDouble() : 0.0,
      movieTitle: json['movie_title']?.toString(),
      imageUrl: json['image_url']?.toString(),
      category: json['category']?.toString(),
      genre: json['genre']?.toString(),
      rating: json['rating']?.toString(),
      duration: json['duration']?.toString(),
    );
  }

  /// VenueSessionsScreen'den EventDetailsScreen'e geçerken veya 
  /// genel film bilgilerine ihtiyaç duyulduğunda kullanılır.
  MovieModel toMovieModel() {
    return MovieModel(
      id: id ?? 0,
      title: movieTitle ?? "Bilinmeyen",
      // Süre bilgisindeki rakam dışı karakterleri temizler (örn: "120 dk" -> 120)
      duration: int.tryParse(duration?.replaceAll(RegExp(r'[^0-9]'), '') ?? '90') ?? 90,
      category: category ?? "Genel",
      imageUrl: imageUrl,
      isActive: true,
      contentType: category?.toLowerCase() == 'tiyatro' ? 'theater' : 'cinema',
    );
  }
}