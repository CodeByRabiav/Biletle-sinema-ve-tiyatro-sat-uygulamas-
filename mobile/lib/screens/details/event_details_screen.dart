import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // 🔥 kIsWeb (Web kontrolü) için eklendi
import 'dart:ui'; 
import 'package:url_launcher/url_launcher.dart'; // Mobil için dışarı yönlendirme paketi
import 'package:youtube_player_iframe/youtube_player_iframe.dart'; // Web için Popup paketi
import '../../data/models/movie_model.dart';
import '../session/movie_sessions_screen.dart'; 

class EventDetailsScreen extends StatefulWidget {
  final MovieModel movie;

  const EventDetailsScreen({super.key, required this.movie});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  int _selectedTabIndex = 0; 

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    
    // 🔥 FRAGMAN BUTONU KONTROLÜ
    final String cat = movie.category?.toLowerCase() ?? "";
    
    // Eğer fragman linki BOŞ DEĞİLSE ve Kategori Sinema ise butonu göster
    final bool hasTrailer = movie.trailerUrl != null && movie.trailerUrl!.trim().isNotEmpty;
    final bool isCinema = (movie.contentType == 'cinema' || cat.contains('film') || cat.contains('sinema') || cat.contains('animasyon') || cat.contains('aksiyon')) && hasTrailer;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. ÜST RESİM ALANI (BULANIK ARKA PLAN + TAM AFİŞ)
                Stack(
                  children: [
                    SizedBox(
                      height: 400, 
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            movie.imageUrl ?? 'https://via.placeholder.com/400x600',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade900),
                          ),
                          BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              color: Colors.black.withOpacity(0.6), 
                            ),
                          ),
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 10, bottom: 30),
                              child: Image.network(
                                movie.imageUrl ?? 'https://via.placeholder.com/400x600',
                                fit: BoxFit.contain, 
                                errorBuilder: (context, error, stackTrace) => const Center(
                                  child: Icon(Icons.movie_creation_outlined, color: Colors.white54, size: 60)
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0, left: 0, right: 0,
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.white.withOpacity(0.0), Colors.white],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SafeArea(
                      child: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),

                    //   FRAGMAN BUTONU (WEB'DE POPUP, MOBİLDE DIŞ LİNK)
                    if (isCinema)
                      Positioned(
                        bottom: 30,
                        right: 20,
                        child: GestureDetector(
                          onTap: () async {
                            final String urlString = movie.trailerUrl!;

                            // SİHİRLİ KONTROL BAŞLIYOR
                            if (kIsWeb) {
                              //  EĞER WEB'DEYSEK (Chrome): Eski usül şık Popup aç
                              String extractYoutubeId(String url) {
                                if (url.length == 11) return url;
                                final regExp = RegExp(r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})');
                                final match = regExp.firstMatch(url);
                                return match?.group(1) ?? url;
                              }
                              String videoId = extractYoutubeId(urlString);
                              _showTrailer(context, videoId);
                            } else {
                              // 📱 EĞER MOBİLDEYSEK (Android/iOS): Cihazı dondurmamak için güvenli dış link aç
                              final Uri url = Uri.parse(urlString);
                              try {
                                await launchUrl(
                                  url,
                                  mode: LaunchMode.externalApplication,
                                );
                              } catch (e) {
                                debugPrint("Link açılamadı: $e");
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Fragman linki açılamadı!')),
                                );
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD600), // Tok Sarı
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.play_circle_fill, color: Colors.black87, size: 22),
                                SizedBox(width: 6),
                                Text("Fragman İzle", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // 2. ETKİNLİK BAŞLIĞI VE ETİKETLER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildTag(movie.category ?? "Bilinmiyor"),
                          const SizedBox(width: 8),
                          _buildTag("${movie.duration ?? '0'} dk"), 
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                const Divider(thickness: 1, color: Color(0xFFEEEEEE)),

                // 3. SEKMELER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                  child: Row(
                    children: [
                      _buildTabButton("Detay", 0),
                      _buildTabButton("Kadro", 1),
                      _buildTabButton("Kurallar", 2),
                    ],
                  ),
                ),

                // 4. SEKME İÇERİĞİ
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                  child: _buildTabContent(movie),
                ),
              ],
            ),
          ),

          // 5. SABİT ALT BAR (BİLETİNİ AL) 
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, -5))
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD600), // Tok Sarı
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MovieSessionsScreen(movie: movie), 
                        ),
                      );
                    },
                    child: const Text(
                      "BİLETİNİ AL",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- YARDIMCI METOTLAR ---

  Widget _buildTabButton(String title, int index) {
    bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Padding(
        padding: const EdgeInsets.only(right: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.black87 : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 4,
              width: 25,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFFD600) : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(MovieModel movie) {
    if (_selectedTabIndex == 0) {
      return Text(
        movie.description ?? "Bu etkinlik için açıklama bulunmamaktadır.",
        style: TextStyle(fontSize: 15, height: 1.6, color: Colors.grey.shade800),
      );
    } else if (_selectedTabIndex == 1) {
      return _buildCastSection(movie.cast);
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("• Etkinlik saatinden 15 dakika önce mekanda hazır bulununuz.", style: TextStyle(height: 1.8, color: Colors.grey.shade800)),
          Text("• Satın alınan biletlerde iptal veya iade yapılamamaktadır.", style: TextStyle(height: 1.8, color: Colors.grey.shade800)),
        ],
      );
    }
  }

  Widget _buildCastSection(String? castData) {
    if (castData == null || castData.trim().isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 50, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                "Bu etkinlik için kadro bilgisi girilmemiştir.",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    List<String> castList = castData.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12.0),
          child: Text(
            "Oyuncular / Kadro",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: castList.map((actorName) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100, 
                borderRadius: BorderRadius.circular(20), 
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.black54), 
                  const SizedBox(width: 8),
                  Text(
                    actorName,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD600).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }

  // POPUP FONKSİYONU 
  void _showTrailer(BuildContext context, String trailerId) {
    final controller = YoutubePlayerController.fromVideoId(
      videoId: trailerId,
      autoPlay: true,
      params: const YoutubePlayerParams(showControls: true, mute: false, showFullscreenButton: true),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        contentPadding: EdgeInsets.zero,
        insetPadding: const EdgeInsets.all(10),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: AspectRatio(
          aspectRatio: 16 / 9,
          child: YoutubePlayer(controller: controller),
        ),
      ),
    );
  }
}