import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/my_reservations_provider.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        context.read<MyReservationsProvider>().fetchMyReservations(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MyReservationsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rezervasyonlarım'),
      ),
      body: Builder(
        builder: (_) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(child: Text(provider.errorMessage!));
          }

          if (provider.reservations.isEmpty) {
            return const Center(child: Text('Henüz rezervasyon bulunmuyor'));
          }

          return ListView.builder(
            itemCount: provider.reservations.length,
            itemBuilder: (context, index) {
              final reservation = provider.reservations[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('Rezervasyon #${reservation.id}'),
                  subtitle: Text(
                    'Durum: ${reservation.status} • Ödeme: ${reservation.paymentStatus}',
                  ),
                  trailing: Text('${reservation.totalPrice.toStringAsFixed(0)} ₺'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}