import 'package:flutter/material.dart';

import '../core/network/api_client.dart';
import '../data/models/reservation_model.dart';
import '../data/services/my_reservations_service.dart';

class MyReservationsProvider extends ChangeNotifier {
  final ApiClient apiClient = ApiClient();
  late final MyReservationsService _service = MyReservationsService(apiClient);

  List<ReservationModel> reservations = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchMyReservations(String token) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await _service.getMyReservations(token);
      reservations = data
          .map((item) => ReservationModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      errorMessage = 'Rezervasyonlar alınamadı: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}