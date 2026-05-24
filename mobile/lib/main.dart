import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/network/api_client.dart';
import 'data/services/hall_service.dart';
import 'providers/hall_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/movie_provider.dart';
import 'providers/session_provider.dart';
import 'providers/reservation_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/my_tickets_provider.dart';
import 'providers/my_reservations_provider.dart';
import 'providers/venue_provider.dart';
import 'screens/home/home_screen.dart';

void main() async {
  // Asenkron başlatma işlemlerinin kilitlenmemesi için garanti satır
  WidgetsFlutterBinding.ensureInitialized();

  // 1. ADIM: Tüm projenin kullanacağı TEK VE ORTAK ApiClient nesnesi
  final sharedApiClient = ApiClient();

  // 2. ADIM: AuthProvider'ı bu ortak istemciyle kurup eski hafızayı tetikliyoruz
  final authProvider = AuthProvider(sharedApiClient);
  await authProvider.loadUserFromStorage();

  runApp(
    MultiProvider(
      providers: [
        // Ortak oluşturduğumuz authProvider'ı değer (value) olarak bağlıyoruz
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        
        // 🔥 ARTIK TÜM SİSTEM AYNI MERKEZDEN YÖNETİLİYOR
        ChangeNotifierProvider(create: (_) => ReservationProvider(sharedApiClient)),
        
        ChangeNotifierProvider(create: (_) => MovieProvider()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => MyTicketsProvider()),
        ChangeNotifierProvider(create: (_) => MyReservationsProvider()),
        ChangeNotifierProvider(create: (_) => VenueProvider()),
        
        ChangeNotifierProvider(
          create: (_) => HallProvider(HallService(sharedApiClient)),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Biletle',
      theme: ThemeData(
        colorSchemeSeed: Colors.red,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      home: const HomeScreen(),
    );
  }
}