import '../../core/network/api_client.dart';

class HallService {
  final ApiClient apiClient;

  HallService(this.apiClient);

  /// Tüm salonları getirir
  Future<List<dynamic>> getAllHalls() async {
    final response = await apiClient.dio.get('/halls');
    return List<dynamic>.from(response.data);
  }

  /// Şehir ve Mekan Türüne (cinema/theater) göre filtreleme yapar
  /// Biletinial akışının ana sorgusudur.
  Future<List<dynamic>> filterHalls({String? city, String? venueType}) async {
    final response = await apiClient.dio.get(
      '/halls/filter',
      queryParameters: {
        if (city != null) 'city': city,
        if (venueType != null) 'venue_type': venueType,
      },
    );
    return List<dynamic>.from(response.data);
  }

  /// Veritabanındaki benzersiz şehir listesini getirir (Dropdown için)
  Future<List<String>> getCities() async {
    final response = await apiClient.dio.get('/halls/cities');
    return List<String>.from(response.data);
  }

  /// Belirli bir salonun detaylarını ve koltuklarını getirir
  Future<Map<String, dynamic>> getHallDetail(int hallId) async {
    final response = await apiClient.dio.get('/halls/$hallId');
    return Map<String, dynamic>.from(response.data);
  }

  /// Seçilen salonda oynatılan tüm seansları ve film bilgilerini getirir
  Future<Map<String, dynamic>> getHallSessions(int hallId) async {
    final response = await apiClient.dio.get('/halls/$hallId/sessions');
    return Map<String, dynamic>.from(response.data);
  }

  /// Konum tabanlı yakın mekanları getirir
  Future<List<dynamic>> getNearbyHalls({
    required double lat,
    required double lon,
    double radius = 5.0,
    String? venueType,
  }) async {
    final response = await apiClient.dio.get(
      '/halls/nearby',
      queryParameters: {
        'lat': lat,
        'lon': lon,
        'radius': radius,
        if (venueType != null) 'venue_type': venueType,
      },
    );
    return List<dynamic>.from(response.data);
  }
}