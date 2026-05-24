import '../../core/network/api_client.dart';

class MyReservationsService {
  final ApiClient apiClient;

  MyReservationsService(this.apiClient);

  Future<List<dynamic>> getMyReservations(String token) async {
    apiClient.setToken(token);

    final response = await apiClient.dio.get('/reservations/my');
    return List<dynamic>.from(response.data);
  }
}