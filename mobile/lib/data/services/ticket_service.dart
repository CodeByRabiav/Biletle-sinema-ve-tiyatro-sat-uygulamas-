import '../../core/network/api_client.dart';

class TicketService {
  final ApiClient apiClient;

  TicketService(this.apiClient);

  Future<List<dynamic>> getMyTickets(String token) async {
    apiClient.setToken(token);

    final response = await apiClient.dio.get('/tickets/my');
    return List<dynamic>.from(response.data);
  }

  // Değişiklik burada: { } süslü parantezleri kaldırdık ki provider ile tam uyumlu olsun
  Future<Map<String, dynamic>> getTicketDetail(String token, int ticketId) async {
    apiClient.setToken(token);

    final response = await apiClient.dio.get('/tickets/$ticketId');
    return Map<String, dynamic>.from(response.data);
  }
}