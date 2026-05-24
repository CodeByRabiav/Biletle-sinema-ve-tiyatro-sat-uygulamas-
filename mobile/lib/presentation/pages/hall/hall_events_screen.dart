import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/hall_provider.dart';
import '../../../data/models/movie_model.dart'; 
import 'package:mobile/screens/seat/seat_selection_screen.dart';
import 'package:mobile/screens/details/event_details_screen.dart'; 

class HallEventsScreen extends StatefulWidget {
  final int hallId;
  final String hallName;

  const HallEventsScreen({
    super.key,
    required this.hallId,
    required this.hallName,
  });

  @override
  State<HallEventsScreen> createState() => _HallEventsScreenState();
}

class _HallEventsScreenState extends State<HallEventsScreen> {
  Map<String, dynamic>? _hallData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHallSessions();
  }

  Future<void> _loadHallSessions() async {
    final hallProvider = context.read<HallProvider>();
    final data = await hallProvider.fetchSessionsByHall(widget.hallId);
    if (mounted) {
      setState(() {
        _hallData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Temiz bir arkaplan
      appBar: AppBar(
        title: Text(
          widget.hallName, 
          style: const TextStyle(color: Color.fromARGB(221, 241, 227, 227), fontSize: 18, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0), 
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD600))) 
          : _buildEventList(),
    );
  }

  Widget _buildEventList() {
    final sessions = _hallData?['sessions'] as List<dynamic>?;

    if (sessions == null || sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              "Bu mekanda aktif seans bulunmuyor.",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    Map<String, List<dynamic>> groupedByMovie = {};
    for (var session in sessions) {
      final movieTitle = session['movie_title'] ?? "Bilinmeyen Film";
      if (!groupedByMovie.containsKey(movieTitle)) {
        groupedByMovie[movieTitle] = [];
      }
      groupedByMovie[movieTitle]!.add(session);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: groupedByMovie.keys.length,
      itemBuilder: (context, index) {
        String movieTitle = groupedByMovie.keys.elementAt(index);
        List<dynamic> movieSessions = groupedByMovie[movieTitle]!;
        final firstSession = movieSessions.first;

        // 🔥 İŞTE EFSANE HATA BURADAYDI!
        // Backend 'image_url' gönderirken sen 'movie_image_url' arıyordun. Düzeltildi!
        String? imageUrl = firstSession['image_url'];
        bool hasValidImage = imageUrl != null && imageUrl.trim().isNotEmpty;

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 168, 167, 154), // 🔥 VIP ANTRASİT KART RENGİ
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    final movieDetails = MovieModel(
                      id: firstSession['movie_id'] ?? 0,
                      title: movieTitle,
                      category: firstSession['category'] ?? "Etkinlik", 
                      imageUrl: imageUrl, // Düzeltilen link
                      duration: 120, 
                      description: "Seans ekranından yönlendirildi.", 
                      isActive: true, 
                      contentType: "cinema", 
                      cast: firstSession['movie_cast']?.toString(),
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventDetailsScreen(movie: movieDetails),
                      ),
                    );
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔥 AFİŞ ALANI (Premium Gölge Eklendi)
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                            ]
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: hasValidImage
                              ? Image.network(
                                  imageUrl!,
                                  width: 85,
                                  height: 125,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildPlaceholder(),
                                )
                              : _buildPlaceholder(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 5),
                              Text(
                                movieTitle,
                                style: const TextStyle(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold, 
                                  color: Colors.white, // Antrasit üstünde beyaz yazı
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD600).withOpacity(0.15), // Tok Sarı transparan arka plan
                                  border: Border.all(color: const Color(0xFFFFD600).withOpacity(0.5)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "BİLETİNİ AL",
                                  style: TextStyle(
                                    color: Color(0xFFFFD600), // Tok Sarı yazı
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 15.0),
                          child: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white38),
                        )
                      ],
                    ),
                  ),
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(height: 1, color: Colors.white12), // İnce şık bir çizgi
                ),
                
                Row(
                  children: [
                    const Icon(Icons.access_time_filled, size: 16, color: Color(0xFFFFD600)),
                    const SizedBox(width: 8),
                    Text(
                      "Seans Saatleri",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // SEANSLAR
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: movieSessions
                      .map((s) => _buildTimeSlot(s, movieTitle))
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Şık Antrasit Placeholder
  Widget _buildPlaceholder() {
    return Container(
      width: 85,
      height: 125,
      color: Colors.black45, // Resim yoksa simsiyah
      child: const Icon(Icons.movie_creation_outlined, color: Colors.white24, size: 35),
    );
  }

  Widget _buildTimeSlot(dynamic session, String movieTitle) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SeatSelectionScreen(
                sessionId: session['id'],
                hallId: widget.hallId,
                movieTitle: movieTitle,
                hallName: widget.hallName,
                price: double.parse(session['price'].toString()),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.transparent, // İçi boş
            border: Border.all(color: const Color(0xFFFFD600), width: 1.5), // Çerçeve Tok Sarı
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            session['time'] ?? "00:00",
            style: const TextStyle(
              color: Color(0xFFFFD600), // Yazı Tok Sarı
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}