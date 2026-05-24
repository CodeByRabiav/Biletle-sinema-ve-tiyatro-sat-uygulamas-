import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/session_provider.dart';
import '../../data/models/movie_model.dart';
import '../../data/models/session_model.dart';
import '../seat/seat_selection_screen.dart';

class MovieSessionsScreen extends StatefulWidget {
  final MovieModel movie;

  const MovieSessionsScreen({super.key, required this.movie});

  @override
  State<MovieSessionsScreen> createState() => _MovieSessionsScreenState();
}

class _MovieSessionsScreenState extends State<MovieSessionsScreen> {
  @override
  void initState() {
    super.initState();
    // Ekrana girildiğinde bu filme ait seansları çek
    Future.microtask(() =>
        context.read<SessionProvider>().fetchSessionsByMovie(widget.movie.id));
  }

  // Gelen karmaşık seans listesini salon adına göre gruplayan yardımcı fonksiyon
  Map<String, List<SessionModel>> _groupSessionsByHall(List<SessionModel> sessions) {
    Map<String, List<SessionModel>> grouped = {};
    for (var session in sessions) {
      final hallName = session.hallName ?? "Bilinmeyen Salon";
      if (!grouped.containsKey(hallName)) {
        grouped[hallName] = [];
      }
      grouped[hallName]!.add(session);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<SessionProvider>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.movie.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: sessionProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
          : sessionProvider.errorMessage != null
              ? Center(child: Text("Hata: ${sessionProvider.errorMessage}"))
              : _buildSessionContent(sessionProvider.sessions),
    );
  }

  Widget _buildSessionContent(List<SessionModel> sessions) {
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text("Bu etkinlik için planlanmış bir seans bulunmuyor.", style: TextStyle(color: Colors.black54, fontSize: 16)),
          ],
        ),
      );
    }

    // Seansları salonlara göre grupluyoruz
    final groupedSessions = _groupSessionsByHall(sessions);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedSessions.keys.length,
      itemBuilder: (context, index) {
        String hallName = groupedSessions.keys.elementAt(index);
        List<SessionModel> hallSessions = groupedSessions[hallName]!;

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Salon Adı Başlığı ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.meeting_room, color: Colors.black54, size: 20),
                    const SizedBox(width: 8),
                    Text(hallName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              
              // --- Seans Saatleri (Kutucuklar) ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: hallSessions.map((session) {
                    return GestureDetector(
                      onTap: () {
                        // Bir saate tıklandığında koltuk seçimine git
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SeatSelectionScreen(
                              sessionId: session.id ?? 0,
                              hallId: session.hallId ?? 0,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.redAccent),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Text(
                          session.time ?? "00:00",
                          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}