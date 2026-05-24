import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../data/models/hall_model.dart';
import '../data/services/hall_service.dart';
import '../data/services/reservation_service.dart';

class ReservationProvider extends ChangeNotifier {
  final ApiClient apiClient; // 🔥 Ortak API istemcisi dışarıdan enjekte ediliyor
  late final HallService _hallService;
  late final ReservationService _reservationService;

  ReservationProvider(this.apiClient) {
    _hallService = HallService(apiClient);
    _reservationService = ReservationService(apiClient);
  }

  HallModel? hall;
  List<int> occupiedSeatIds = []; 
  List<int> selectedSeatIds = []; 

  bool isLoading = false;
  bool isSubmitting = false;
  String? errorMessage;

  Future<void> loadSeatData({required int hallId, required int sessionId}) async {
    isLoading = true;
    errorMessage = null;
    selectedSeatIds = []; 
    notifyListeners();

    try {
      final hallData = await _hallService.getHallDetail(hallId);
      hall = HallModel.fromJson(hallData);

      final List<dynamic> occupiedData = await _reservationService.getOccupiedSeats(sessionId);
      occupiedSeatIds = []; 
      
      for (var item in occupiedData) {
        try {
          if (item is Map) {
            var seatIdValue = item['seat_id'] ?? item['id'];
            if (seatIdValue != null) {
              occupiedSeatIds.add(int.parse(seatIdValue.toString()));
            }
          } else {
            occupiedSeatIds.add(int.parse(item.toString()));
          }
        } catch (e) {
          print("⚠️ Atlanan hatalı veri: $item");
        }
      }
      print("✅ BAŞARILI: Dolu Koltuk ID'leri: $occupiedSeatIds"); 
    } catch (e) {
      errorMessage = "Koltuk bilgileri yüklenemedi: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void toggleSeat(int seatId) {
    if (occupiedSeatIds.contains(seatId)) return;

    if (selectedSeatIds.contains(seatId)) {
      selectedSeatIds.remove(seatId);
    } else {
      if (selectedSeatIds.length < 5) {
        selectedSeatIds.add(seatId);
      } else {
        errorMessage = "Aynı anda en fazla 5 koltuk seçebilirsiniz.";
      }
    }
    notifyListeners();
  }

  void clearSelections() {
    selectedSeatIds.clear();
    notifyListeners();
  }

  Future<Map<String, dynamic>?> createReservation({
    required String token,
    required int sessionId,
  }) async {
    if (selectedSeatIds.isEmpty) {
      errorMessage = "Lütfen en az bir koltuk seçiniz.";
      notifyListeners();
      return null;
    }

    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _reservationService.createReservation(
        token: token,
        sessionId: sessionId,
        seatIds: selectedSeatIds,
      );
      return {"reservation": response["reservation"] ?? response};
    } on DioException catch (e) {
      // 🔒 Olası bir 401 yetki hatasında hafızadaki sahte/eski token'ı uçuruyoruz
      if (e.response?.statusCode == 401) {
        apiClient.clearToken();
        errorMessage = "Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.";
        return null;
      }
      if (e.response?.statusCode == 409) {
        return {"conflicted_seat_ids": e.response?.data["conflicted_seat_ids"] ?? []};
      }
      errorMessage = e.response?.data?['error'] ?? "Rezervasyon oluşturulurken bir hata oluştu.";
      return null;
    } catch (e) {
      errorMessage = "Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.";
      return null;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}