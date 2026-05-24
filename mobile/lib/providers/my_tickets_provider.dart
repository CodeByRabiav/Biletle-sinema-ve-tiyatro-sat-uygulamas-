import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../data/models/ticket_model.dart';
import '../data/services/ticket_service.dart';

class MyTicketsProvider extends ChangeNotifier {
  final ApiClient apiClient = ApiClient();
  late final TicketService _ticketService = TicketService(apiClient);

  List<TicketModel> tickets = [];
  TicketModel? selectedTicket; // Tekil bilet detayı için eklendi
  bool isLoading = false;
  String? errorMessage;

  // Tüm biletleri listeleme (Biletlerim ekranı için)
  Future<void> fetchMyTickets(String token) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      apiClient.setToken(token); // Token'ı apiClient'a set ediyoruz
      final data = await _ticketService.getMyTickets(token);
      tickets = data
          .map((item) => TicketModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      errorMessage = 'Biletler alınamadı: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Belirli bir biletin detayını çekme (QR ekranı için)
  Future<void> fetchTicketDetail(String token, int ticketId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Backend'deki get_ticket_detail rotasını çağıracak bir servis metodu olduğunu varsayıyoruz
      final data = await _ticketService.getTicketDetail(token, ticketId);
      selectedTicket = TicketModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      errorMessage = 'Bilet detayı alınamadı: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}