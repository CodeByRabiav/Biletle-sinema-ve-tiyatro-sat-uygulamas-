import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../data/models/session_model.dart';

class SessionProvider extends ChangeNotifier {
  List<SessionModel> _sessions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SessionModel> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Ana ekranda vs. tüm seansları getirmek istersen diye eski fonksiyon (İsteğe bağlı)
  Future<void> fetchAllSessions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Kendi API url'ine göre düzenlemeyi unutma
      final response = await Dio().get("http://127.0.0.1:5000/sessions");
      
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        _sessions = data.map((json) => SessionModel.fromJson(json)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔥 YENİ: Sadece belirli bir filme (Movie) ait seansları getiren fonksiyon
  // EventDetailsScreen'den -> MovieSessionsScreen'e geçerken bu tetiklenir.
  Future<void> fetchSessionsByMovie(int movieId) async {
    _isLoading = true;
    _errorMessage = null;
    // Listeyi temizleyelim ki eski filmin seansları görünmesin
    _sessions = []; 
    notifyListeners();

    try {
      // Backend'deki /sessions/movie/<movie_id> rotasını kullanıyoruz
      // DİKKAT: Emülatör kullanıyorsan 10.0.2.2, Chrome Web kullanıyorsan 127.0.0.1 yapmalısın.
      final response = await Dio().get("http://127.0.0.1:5000/sessions/movie/$movieId");
      
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        _sessions = data.map((json) => SessionModel.fromJson(json)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Belirli bir salona (Venue/Hall) göre filtreleme yapmak istersen (VenueListScreen için)
  Future<void> fetchSessionsByHall(int hallId) async {
    _isLoading = true;
    _errorMessage = null;
    _sessions = [];
    notifyListeners();

    try {
      final response = await Dio().get("http://127.0.0.1:5000/sessions/hall/$hallId");
      
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        _sessions = data.map((json) => SessionModel.fromJson(json)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}