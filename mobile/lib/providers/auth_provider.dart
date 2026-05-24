import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_client.dart';
import '../data/models/user_model.dart';
import '../data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient apiClient; // 🔥 Dışarıdan enjekte edilen ortak istemci
  late final AuthService _authService;

  AuthProvider(this.apiClient) {
    _authService = AuthService(apiClient);
  }

  UserModel? currentUser;
  String? token;
  bool isLoading = false;
  bool isInitialized = false;

  bool get isLoggedIn => token != null && token!.trim().isNotEmpty && currentUser != null;
  bool get isAdmin => currentUser?.role == 'admin';

  /// Uygulama açıldığında kayıtlı kullanıcıyı yükle ve doğrula
  Future<void> loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('token');
    final storedUser = prefs.getString('user');

    // Eğer veri yoksa veya boşsa diski temiz tut ve çık
    if (storedToken == null || storedToken.trim().isEmpty || storedUser == null) {
      await logout();
      isInitialized = true;
      notifyListeners();
      return;
    }

    token = storedToken;
    try {
      currentUser = UserModel.fromJson(Map<String, dynamic>.from(jsonDecode(storedUser)));
      apiClient.setToken(token!); // Ortak istemciye token kilitlendi
      print("✅ Hafızadan başarıyla yüklendi: ${currentUser?.email}");
    } catch (e) {
      debugPrint("Depolanan kullanıcı yüklenirken hata: $e");
      await logout(); // Veri bozuksa koruma amaçlı çıkış yap
    }
    isInitialized = true;
    notifyListeners();
  }

  /// Giriş İşlemi
  Future<bool> login(String email, String password) async {
    isLoading = true;
    notifyListeners();
    try {
      final data = await _authService.login(email: email, password: password);
      if (data != null && data.containsKey('access_token')) {
        token = data['access_token'];
        currentUser = UserModel.fromJson(Map<String, dynamic>.from(data['user']));
        
        apiClient.setToken(token!); // Ortak istemciye tanımlandı
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token!);
        await prefs.setString('user', jsonEncode(data['user']));
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Kayıt İşlemi
  Future<bool> register({required String fullName, required String email, required String password}) async {
    isLoading = true;
    notifyListeners();
    try {
      final data = await _authService.register(fullName: fullName, email: email, password: password);
      return data != null && (data.containsKey('id') || data.containsKey('user'));
    } catch (e) {
      rethrow; 
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Çıkış İşlemi
  Future<void> logout() async {
    token = null;
    currentUser = null;
    apiClient.clearToken(); // API katmanındaki token silindi
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    notifyListeners();
    print("🚪 Oturum başarıyla sıfırlandı.");
  }
}