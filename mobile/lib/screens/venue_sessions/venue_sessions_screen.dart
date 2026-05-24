import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/session_provider.dart';
import '../../data/models/session_model.dart';
import '../details/event_details_screen.dart';

class VenueSessionsScreen extends StatefulWidget {
  final int venueId;
  final String venueName;

  const VenueSessionsScreen({
    super.key,
    required this.venueId,
    required this.venueName,
  });

  @override
  State<VenueSessionsScreen> createState() => _VenueSessionsScreenState();
}

class _VenueSessionsScreenState extends State<VenueSessionsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      // BuildContext güvenliği için mounted kontrolü ekledik
      if (mounted) {
        context.read<SessionProvider>().fetchSessionsByHall(widget.venueId);
      }
    });
  }

  String formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return "--:--";
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd.MM HH:mm').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SessionProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(widget.venueName, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Builder(
        builder: (_) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          if (provider.errorMessage != null) return Center(child: Text(provider.errorMessage!));
          if (provider.sessions.isEmpty) return const Center(child: Text('Bu salonda aktif seans bulunamadı'));

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.58,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: provider.sessions.length,
            itemBuilder: (context, index) {
              final session = provider.sessions[index];
              
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // Hata Çözümü: EventDetailsScreen artık movie beklediği için session içinden dönüştürüyoruz
                      builder: (_) => EventDetailsScreen(movie: session.toMovieModel()),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(15), 
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: session.imageUrl != null && session.imageUrl!.isNotEmpty
                                  ? Image.network(
                                      session.imageUrl!,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const _PlaceholderImage(),
                                    )
                                  : const _PlaceholderImage(),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(180),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      session.rating ?? "4.5",
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.movieTitle ?? 'İçerik',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              session.genre ?? 'Genel',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 14, color: Colors.blueAccent),
                                    const SizedBox(width: 4),
                                    Text(
                                      session.duration ?? "90 dk",
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                Text(
                                  // session.startTime hatası burada session.date kullanılarak düzeltildi
                                  formatDate(session.date), 
                                  style: const TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey.shade100,
      child: const Icon(Icons.movie_creation_outlined, color: Colors.grey, size: 40),
    );
  }
}