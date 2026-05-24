import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/movie_provider.dart';
import '../../data/models/movie_model.dart';
import '../details/event_details_screen.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  String selectedCity = "İstanbul (Tümü)";
  String selectedCategory = "Tümü"; // Sinema, Tiyatro, Tümü

  final List<String> cities = [
    "İstanbul (Tümü)",
    "Ankara",
    "İzmir",
    "Trabzon",
    "Bursa",
    "Antalya",
    "Adana",
    "Eskişehir",
    "Konya"
  ];
  
  final List<String> categories = ["Tümü", "Sinema", "Tiyatro"];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<MovieProvider>().fetchAllCategories());
  }

  @override
  Widget build(BuildContext context) {
    final movieProvider = context.watch<MovieProvider>();

    List<MovieModel> allMovies = [];
    
    if (selectedCategory == "Tümü" || selectedCategory == "Sinema") {
      allMovies.addAll(movieProvider.cinemaMovies);
    }
    if (selectedCategory == "Tümü" || selectedCategory == "Tiyatro") {
      allMovies.addAll(movieProvider.theaterMovies);
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Ana sayfa ile aynı temiz arkaplan
      appBar: AppBar(
        title: const Text("Tüm Etkinlikleri Keşfet", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      body: Column(
        children: [
          // VIP Filtre Alanı
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))
              ],
            ),
            child: _buildFilters(),
          ),
          
          const SizedBox(height: 10),
          
          // Afiş Grid Alanı
          Expanded(
            child: movieProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD600))) // Tok Sarı yükleniyor
                : _buildMovieGrid(allMovies),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: _customDropdown(
              value: selectedCity,
              items: cities,
              icon: Icons.location_on,
              onChanged: (val) => setState(() => selectedCity = val!),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _customDropdown(
              value: selectedCategory,
              items: categories,
              icon: Icons.category_rounded,
              onChanged: (val) => setState(() => selectedCategory = val!),
            ),
          ),
        ],
      ),
    );
  }

  // Özel Tasarım Dropdown
  Widget _customDropdown({
    required String value, 
    required List<String> items, 
    required IconData icon, 
    required Function(String?) onChanged
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
          items: items.map((item) => DropdownMenuItem(
            value: item, 
            child: Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFFFFD600)), // Sarı İkon
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item, 
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildMovieGrid(List<MovieModel> movies) {
    if (movies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text("Kriterlere uygun etkinlik bulunamadı.", style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, 
        childAspectRatio: 0.58, // Afişler dikeyde biraz daha heybetli olsun diye oranı ayarladım
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
      ),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
        
        // 🔥 RESİM HATASINI ÇÖZEN SATIR
        // Eğer URL null veya boşsa bizim güvenli ikonlu kutumuzu çizecek
        bool hasValidImage = movie.imageUrl != null && movie.imageUrl!.trim().isNotEmpty;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EventDetailsScreen(movie: movie),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Afiş Alanı
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: hasValidImage
                      ? Image.network(
                          movie.imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          // Link geçersizse (Örn: 404 Not Found) de bu hatayı yakalayıp çökmesini engelliyoruz
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(), // Link veritabanından boş gelirse
                  ),
                ),
                // Etkinlik Detay Alanı
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                        maxLines: 2, // Film isimleri uzun olabilir, 2 satıra izin verelim
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD600).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          movie.category,
                          style: const TextStyle(color: Color(0xFFFFD600), fontSize: 10, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
  }

  // Resim olmadığında veya hata verdiğinde gösterilecek çok şık Antrasit Placeholder
  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF1A1A1A), // Koyu Antrasit
      width: double.infinity,
      child: const Center(
        child: Icon(Icons.movie_creation_outlined, color: Colors.white24, size: 50),
      ),
    );
  }
}