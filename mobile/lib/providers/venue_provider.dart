import 'package:flutter/material.dart';

import '../core/network/api_client.dart';
import '../data/models/venue_model.dart';
import '../data/services/venue_service.dart';

class VenueProvider extends ChangeNotifier {
  final ApiClient apiClient = ApiClient();
  late final VenueService _venueService = VenueService(apiClient);

  List<VenueModel> venues = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchVenues({
    required String venueType,
    required String city,
    required String district,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await _venueService.getFilteredVenues(
        venueType: venueType,
        city: city,
        district: district,
      );

      venues = data
          .map((item) => VenueModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      errorMessage = 'Salonlar alınamadı: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    venues = [];
    errorMessage = null;
    notifyListeners();
  }
}