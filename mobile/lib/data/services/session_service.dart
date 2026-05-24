import '../../core/network/api_client.dart';

class SessionService {
  final ApiClient apiClient;

  SessionService(this.apiClient);

  Future<List<dynamic>> getSessionsByMovie(int movieId) async {
    final response = await apiClient.dio.get('/sessions/movie/$movieId');
    return List<dynamic>.from(response.data);
  }

  Future<List<dynamic>> getSessionsByHall(int hallId) async {
    final response = await apiClient.dio.get('/sessions/hall/$hallId');
    return List<dynamic>.from(response.data);
  }
}