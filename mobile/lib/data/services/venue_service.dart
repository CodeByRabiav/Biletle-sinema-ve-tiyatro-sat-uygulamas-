import '../../core/network/api_client.dart';

class VenueService {
  final ApiClient apiClient;

  VenueService(this.apiClient);

  Future<List<dynamic>> getFilteredVenues({
    required String venueType,
    required String city,
    required String district,
  }) async {
    final response = await apiClient.dio.get(
      '/halls/filter',
      queryParameters: {
        'venue_type': venueType,
        'city': city,
        'district': district,
      },
    );

    return List<dynamic>.from(response.data);
  }
}