import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../data/models/movie_model.dart';
import '../data/services/movie_service.dart';

class MovieProvider extends ChangeNotifier {
  final ApiClient apiClient = ApiClient();
  late final MovieService _movieService = MovieService(apiClient);

  // Uygulama genelinde kullanılacak listeler
  List<MovieModel> cinemaMovies = [];
  List<MovieModel> theaterMovies = [];

  bool isLoading = false;
  String? errorMessage;

  // Ana ekranda hem sinemaları hem tiyatroları tek seferde çeken ana fonksiyon
  Future<void> fetchAllCategories() async {
    isLoading = true;
    errorMessage = null;
    // Kullanıcıya yükleniyor bilgisini hemen verelim
    notifyListeners();

    try {
      // 1. Sinema verilerini çek ve modele çevir
      final cinemaData = await _movieService.getMovies(contentType: 'cinema');
      cinemaMovies = cinemaData.map((json) => MovieModel.fromJson(json)).toList();

      // 2. Tiyatro verilerini çek ve modele çevir
      final theaterData = await _movieService.getMovies(contentType: 'theater');
      theaterMovies = theaterData.map((json) => MovieModel.fromJson(json)).toList();

    } catch (e) {
      errorMessage = "Veriler yüklenirken bir hata oluştu: ${e.toString()}";
      print("MovieProvider Error: $e");
    } finally {
      isLoading = false;
      // İşlem bittiğinde arayüzü güncelle
      notifyListeners();
    }
  }

  // Sadece sinemaları güncellemek istersen (Örn: filtreleme yaparken)
  Future<void> fetchCinemaOnly() async {
    try {
      final data = await _movieService.getMovies(contentType: 'cinema');
      cinemaMovies = data.map((json) => MovieModel.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      print("Cinema Fetch Error: $e");
    }
  }

  // Sadece tiyatroları güncellemek istersen
  Future<void> fetchTheaterOnly() async {
    try {
      final data = await _movieService.getMovies(contentType: 'theater');
      theaterMovies = data.map((json) => MovieModel.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      print("Theater Fetch Error: $e");
    }
  }
}