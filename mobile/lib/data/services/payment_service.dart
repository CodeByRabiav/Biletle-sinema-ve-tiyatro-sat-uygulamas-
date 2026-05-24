import '../../core/network/api_client.dart';

class PaymentService {
  final ApiClient apiClient;

  PaymentService(this.apiClient);

  Future<Map<String, dynamic>> payReservation({
    required String token,
    required int reservationId,
    required String cardHolder,
    required String cardNumber,
    required String expiryDate,
    required String cvv,
  }) async {
    apiClient.setToken(token);

    final response = await apiClient.dio.post(
      '/reservations/$reservationId/pay',
      data: {
        'card_holder': cardHolder,
        'card_number': cardNumber,
        'expiry_date': expiryDate,
        'cvv': cvv,
      },
    );

    return Map<String, dynamic>.from(response.data);
  }
}