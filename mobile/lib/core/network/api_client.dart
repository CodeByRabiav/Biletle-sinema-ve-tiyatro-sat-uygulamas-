import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class ApiClient {
  late final Dio dio;

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  // 🔥 MOBİL İÇİN EK DESTEK: İstek atarken token'ı anlık olarak kafaya yerleştiren yardımcı metot
  Options getOptionsWithToken(String token) {
    return Options(
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Jetonu eksiksiz yerleştiriyoruz
      },
    );
  }

  void setToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    dio.options.headers.remove('Authorization');
  }
}