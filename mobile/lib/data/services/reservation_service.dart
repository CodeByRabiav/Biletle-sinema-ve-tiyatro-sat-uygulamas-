import 'package:dio/dio.dart'; // 🔥 Dio paketini ekledik (Options kullanabilmek için)
import '../../core/network/api_client.dart';

class ReservationService {
  final ApiClient apiClient;

  ReservationService(this.apiClient);

  Future<List<dynamic>> getOccupiedSeats(int sessionId) async {
    final response = await apiClient.dio.get(
      '/reservations/session/$sessionId/occupied-seats',
    );
    return List<dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> createReservation({
    required String token,
    required int sessionId,
    required List<int> seatIds,
  }) async {
    // 🔥 ESKİ HALİ: apiClient.setToken(token); -> Mobilde uçuyordu.
    
    // 🔥 YENI HALI: Token'ı doğrudan bu isteğin (POST) kafasına gömüyoruz!
    final response = await apiClient.dio.post(
      '/reservations',
      data: {
        'session_id': sessionId,
        'seat_ids': seatIds,
      },
      // ApiClient'a yeni yazdığımız o güvenli metodu buraya bağlıyoruz:
      options: apiClient.getOptionsWithToken(token), 
    );

    return Map<String, dynamic>.from(response.data);
  }
}