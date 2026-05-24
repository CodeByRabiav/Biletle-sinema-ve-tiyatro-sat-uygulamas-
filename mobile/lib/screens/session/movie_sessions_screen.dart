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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    // Türkiye genelindeki tüm seansları çekiyoruz
    Future.microtask(() =>
        context.read<SessionProvider>().fetchSessionsByMovie(widget.movie.id));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Seansları salon adına göre gruplayan fonksiyon
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
      backgroundColor: const Color(0xFF121212), // Premium Koyu Antrasit
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.movie.title,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔥 ARAMA ÇUBUĞU (SEARCH BAR)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              style: const TextStyle(color: Colors.white),
              cursorColor: const Color(0xFFFFD600),
              decoration: InputDecoration(
                hintText: "Salon veya Şehir Ara...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFFFD600)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05), // Hafif saydam koyu kutu
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Color(0xFFFFD600), width: 1.5),
                ),
              ),
            ),
          ),

          // SEANSLAR LİSTESİ
          Expanded(
            child: sessionProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD600)))
                : _buildContent(sessionProvider.sessions),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<SessionModel> sessions) {
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, color: Colors.white.withOpacity(0.3), size: 60),
            const SizedBox(height: 16),
            const Text(
              "Bu film için henüz seans bulunamadı.",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final grouped = _groupSessionsByHall(sessions);
    List<String> hallNames = grouped.keys.toList();

    // 🔥 SENİN İSTEDİĞİN AKILLI SIRALAMA (Eşleşenleri Üste Çıkarma)
    if (_searchQuery.isNotEmpty) {
      List<String> matched = hallNames.where((name) => name.toLowerCase().contains(_searchQuery)).toList();
      List<String> unMatched = hallNames.where((name) => !name.toLowerCase().contains(_searchQuery)).toList();
      
      // Eşleşenleri listenin en başına koy, eşleşmeyenleri de arkasına ekle
      hallNames = [...matched, ...unMatched];
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: hallNames.length,
      itemBuilder: (context, index) {
        String hallName = hallNames[index];
        List<SessionModel> hallSessions = grouped[hallName]!;
        
        // Arama yapılıyorsa ve bu salon eşleşenlerden biriyse ona hafif bir parlama efekti verebiliriz
        bool isMatched = _searchQuery.isNotEmpty && hallName.toLowerCase().contains(_searchQuery);

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: isMatched ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.04), // Eşleşenler biraz daha aydınlık
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isMatched ? const Color(0xFFFFD600).withOpacity(0.5) : Colors.white.withOpacity(0.05),
              width: 1
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SALON ADI
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: isMatched ? const Color(0xFFFFD600) : Colors.white54, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hallName,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              
              Divider(height: 1, color: Colors.white.withOpacity(0.1)),
              
              // SAATLER
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: hallSessions.map((s) => _buildTimeSlot(s)).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeSlot(SessionModel session) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SeatSelectionScreen(
                sessionId: session.id ?? 0,
                hallId: session.hallId ?? 0,
                movieTitle: widget.movie.title,
                hallName: session.hallName ?? "Bilinmeyen Salon",
                price: (session.price ?? 0).toDouble(),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(10),
        splashColor: const Color(0xFFFFD600).withOpacity(0.3),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4), // İçi koyu
            border: Border.all(color: const Color(0xFFFFD600).withOpacity(0.6), width: 1), // Çerçevesi hafif sarı
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            session.time ?? "00:00",
            style: const TextStyle(
              color: Color(0xFFFFD600), // Yazı sarı
              fontWeight: FontWeight.bold, 
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}