import 'package:flutter/material.dart';
import '../data/services/hall_service.dart';

class HallProvider extends ChangeNotifier {
  final HallService _hallService;

  HallProvider(this._hallService);

  // --- Durum Değişkenleri ---
  List<dynamic> _halls = [];
  List<String> _cities = [];
  String? _selectedCity;
  String _selectedVenueType = 'cinema'; // Varsayılan: Sinema
  bool _isLoading = false;

  // --- Getterlar ---
  List<dynamic> get halls => _halls;
  List<String> get cities => _cities;
  String? get selectedCity => _selectedCity;
  String get selectedVenueType => _selectedVenueType;
  bool get isLoading => _isLoading;

  /// Veritabanındaki aktif şehirlerin listesini yükle (Dropdown için)
  Future<void> fetchCities() async {
    try {
      _cities = await _hallService.getCities();
      // Eğer şehir seçilmemişse ve liste doluysa varsayılan olarak ilk şehri ata
      if (_cities.isNotEmpty && _selectedCity == null) {
        _selectedCity = _cities.first;
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Şehirler yüklenirken hata: $e");
    }
  }

  /// Seçilen şehre ve kategoriye (sinema/tiyatro) göre salonları filtrele
  Future<void> fetchFilteredHalls() async {
    // Şehir seçilmeden arama yapma
    if (_selectedCity == null) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      _halls = await _hallService.filterHalls(
        city: _selectedCity,
        venueType: _selectedVenueType,
      );
    } catch (e) {
      debugPrint("Salonlar filtrelenirken hata: $e");
      _halls = []; // Hata durumunda listeyi temizle
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Biletinial Akışı: Seçilen salonda hangi filmler ve seanslar var?
  /// HallEventsScreen bu metodu kullanır.
  Future<Map<String, dynamic>> fetchSessionsByHall(int hallId) async {
    try {
      return await _hallService.getHallSessions(hallId);
    } catch (e) {
      debugPrint("Salon seansları çekilirken hata: $e");
      return {"sessions": []};
    }
  }

  /// Kullanıcı Dropdown'dan şehir seçtiğinde tetiklenir
  void setCity(String city) {
    if (_selectedCity == city) return;
    _selectedCity = city;
    fetchFilteredHalls(); // Listeyi otomatik güncelle
  }

  /// Kullanıcı TabBar'dan kategori değiştirdiğinde tetiklenir
  void setVenueType(String type) {
    if (_selectedVenueType == type) return;
    _selectedVenueType = type;
    fetchFilteredHalls(); // Listeyi otomatik güncelle
  }

  /// Verileri temizle (opsiyonel)
  void clearHalls() {
    _halls = [];
    notifyListeners();
  }
}