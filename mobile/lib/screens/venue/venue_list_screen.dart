import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/venue_provider.dart';
import '../venue_sessions/venue_sessions_screen.dart';

class VenueListScreen extends StatefulWidget {
  final String venueType;
  final String city;
  final String district;

  const VenueListScreen({
    super.key,
    required this.venueType,
    required this.city,
    required this.district,
  });

  @override
  State<VenueListScreen> createState() => _VenueListScreenState();
}

class _VenueListScreenState extends State<VenueListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<VenueProvider>().fetchVenues(
            venueType: widget.venueType,
            city: widget.city,
            district: widget.district,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VenueProvider>();
    final isCinema = widget.venueType == 'cinema';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Hafif gri arka plan
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCinema ? 'Sinema Salonları' : 'Tiyatro Sahneleri',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${widget.city} / ${widget.district}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Builder(
        builder: (_) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.red));
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(provider.errorMessage!),
                ],
              ),
            );
          }

          if (provider.venues.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isCinema ? Icons.movie_filter : Icons.theater_comedy, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'Bu konumda uygun salon bulunamadı',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: provider.venues.length,
            itemBuilder: (context, index) {
              final venue = provider.venues[index];

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: isCinema ? Colors.red.shade50 : Colors.deepPurple.shade50,
                    child: Icon(
                      isCinema ? Icons.movie_outlined : Icons.theater_comedy_outlined,
                      color: isCinema ? Colors.red : Colors.deepPurple,
                    ),
                  ),
                  title: Text(
                    venue.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${venue.district}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VenueSessionsScreen(
                          venueId: venue.id,
                          venueName: venue.name,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}