class MovieModel {
  final int id;
  final String title;
  final String? description;
  final int duration;
  final String category;
  final String? imageUrl;
  final bool isActive;
  final String contentType; 
  final String? cast; // 🔥 KADRO İÇİN EKLENEN SÜTUN
  final String? trailerUrl;

  MovieModel({
    required this.id,
    required this.title,
    this.description,
    required this.duration,
    required this.category,
    this.imageUrl,
    required this.isActive,
    required this.contentType, 
    this.cast, // 🔥 KADRO İÇİN EKLENDİ
    this.trailerUrl,
  });

  factory MovieModel.fromJson(Map<String, dynamic> json) {
    return MovieModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      duration: json['duration'] ?? 0,
      category: json['category'] ?? '',
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? json['poster_url'],
      isActive: json['is_active'] ?? true,
      contentType: json['content_type'] ?? 'cinema', 
      cast: json['cast']?.toString(), // 🔥 BACKEND'DEN GELEN KADROYU (CAST) OKUR
      trailerUrl: json['trailer_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'duration': duration,
      'category': category,
      'image_url': imageUrl,
      'is_active': isActive,
      'content_type': contentType,
      'cast': cast, // 🔥 JSON'A ÇEVİRİRKEN KADROYU DA EKLER
      'trailer_url': trailerUrl,
    };
  }
}