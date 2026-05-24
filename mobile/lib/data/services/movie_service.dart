import '../../core/network/api_client.dart';

class MovieService {
  final ApiClient apiClient;

  MovieService(this.apiClient);

  // İsteğe bağlı contentType parametresi eklendi
  Future<List<dynamic>> getMovies({String? contentType}) async {
    // Eğer contentType doluysa query parameter olarak ekle
    String endpoint = '/movies';
    if (contentType != null && contentType.isNotEmpty) {
      endpoint += '?content_type=$contentType';
    }

    final response = await apiClient.dio.get(endpoint);
    return List.from(response.data);
  }
}