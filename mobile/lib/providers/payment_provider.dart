import 'package:flutter/material.dart';

import '../core/network/api_client.dart';
import '../data/models/ticket_model.dart';
import '../data/services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  final ApiClient apiClient = ApiClient();
  late final PaymentService _paymentService = PaymentService(apiClient);

  bool isLoading = false;
  String? errorMessage;
  TicketModel? lastTicket;

  Future<TicketModel?> payReservation({
    required String token,
    required int reservationId,
    required String cardHolder,
    required String cardNumber,
    required String expiryDate,
    required String cvv,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _paymentService.payReservation(
        token: token,
        reservationId: reservationId,
        cardHolder: cardHolder,
        cardNumber: cardNumber,
        expiryDate: expiryDate,
        cvv: cvv,
      );

      lastTicket = TicketModel.fromJson(
        Map<String, dynamic>.from(result['ticket']),
      );

      return lastTicket;
    } catch (e) {
      errorMessage = 'Ödeme başarısız: $e';
      notifyListeners();
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}