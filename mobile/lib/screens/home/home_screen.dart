import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/movie_provider.dart';
import '../../providers/auth_provider.dart'; 
import '../../providers/hall_provider.dart';
import '../../data/models/movie_model.dart';
import '../details/event_details_screen.dart';
import '../movies/movie_list_screen.dart';
import '../auth/login_screen.dart';
import '../ticket/my_tickets_screen.dart';
import '../../presentation/pages/hall/hall_events_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final hallProvider = context.read<HallProvider>();
      final authProvider = context.read<AuthProvider>();
      
      // Önce yerel hafızadaki oturumu tam doğrula, ardından arayüzü tetikle
      await authProvider.loadUserFromStorage();
      await hallProvider.fetchCities();
      await hallProvider.fetchFilteredHalls();
      
      if (mounted) {
        context.read<MovieProvider>().fetchAllCategories();
      }
    });
  }

  Future<void> _refreshData() async {
    await context.read<MovieProvider>().fetchAllCategories();
    await context.read<HallProvider>().fetchFilteredHalls();
    await context.read<AuthProvider>().loadUserFromStorage();
  }

  @override
  Widget build(BuildContext context) {
    final movieProvider = context.watch<MovieProvider>();
    final hallProvider = context.watch<HallProvider>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: _buildTopHeader(context, hallProvider),
        body: RefreshIndicator(
          onRefresh: _refreshData,
          color: Colors.black87, 
          backgroundColor: const Color(0xFFFFD600), 
          child: TabBarView(
            children: [
              _buildCategoryContent(movieProvider.cinemaMovies, "Sinema", hallProvider, "cinema"),
              _buildCategoryContent(movieProvider.theaterMovies, "Tiyatro", hallProvider, "theater"),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTopHeader(BuildContext context, HallProvider hallProvider) {
    final authProvider = context.watch<AuthProvider>();

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 70,
      title: Row(
        children: [
          GestureDetector(
            onTap: () => _showCityPicker(context, hallProvider),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFFFFD600), size: 20), 
                  const SizedBox(width: 8),
                  Text(
                    hallProvider.selectedCity ?? "Şehir Seç",
                    style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.black54, size: 20),
                ],
              ),
            ),
          ),
          const Spacer(),
          _buildAppBarIconButton(
            icon: Icons.search,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MovieListScreen())),
          ),
          const SizedBox(width: 10),
          
          // 🔥 AKILLI DİNAMİK BUTON ALANI
          _buildAppBarIconButton(
            icon: authProvider.isLoggedIn ? Icons.confirmation_num_outlined : Icons.person_outline,
            onTap: () async {
              if (authProvider.isLoggedIn) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MyTicketsScreen()));
              } else {
                final bool? loggedIn = await Navigator.push<bool>(
                  context, 
                  MaterialPageRoute(builder: (_) => const LoginScreen())
                );
                // Girişten dönüldüğünde üst barın anında tetiklenmesini sağlıyoruz
                if (loggedIn == true && mounted) {
                  setState(() {});
                }
              }
            },
          ),
        ],
      ),
      bottom: TabBar(
        onTap: (index) {
          hallProvider.setVenueType(index == 0 ? "cinema" : "theater");
        },
        indicatorColor: const Color(0xFFFFD600), 
        indicatorWeight: 4,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: Colors.black87,
        unselectedLabelColor: Colors.grey.shade500,
        labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        tabs: const [
          Tab(text: "SİNEMA"),
          Tab(text: "TİYATRO"),
        ],
      ),
    );
  }

  Widget _buildAppBarIconButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black87, size: 22),
      ),
    );
  }

  Widget _buildCategoryContent(List<MovieModel> movies, String categoryName, HallProvider hallProvider, String type) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 25),
          _buildSectionHeader("${hallProvider.selectedCity} $categoryName Mekanları"),
          _buildHallHorizontalList(hallProvider),
          const SizedBox(height: 10),
          _buildSectionHeader("Tüm $categoryName Eserleri"),
          _buildHorizontalEventList(movies),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD600), 
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title, 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHallHorizontalList(HallProvider provider) {
    if (provider.isLoading) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: Color(0xFFFFD600))));
    if (provider.halls.isEmpty) return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Text("Bu şehirde uygun mekan bulunamadı.", style: TextStyle(color: Colors.grey)),
    );

    return SizedBox(
      height: 135,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: provider.halls.length,
        itemBuilder: (context, index) {
          final hall = provider.halls[index];
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 15, bottom: 10, top: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HallEventsScreen(
                        hallId: hall['id'],
                        hallName: hall['name'],
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFFFD600).withOpacity(0.2), shape: BoxShape.circle),
                        child: Icon(provider.selectedVenueType == 'cinema' ? Icons.movie_filter : Icons.theater_comedy, color: Colors.black87, size: 24),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        hall['name'], 
                        textAlign: TextAlign.center, 
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87), 
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalEventList(List<MovieModel> movies) {
    if (movies.isEmpty) return const SizedBox(height: 150, child: Center(child: Text("Gösterilecek veri yok.", style: TextStyle(color: Colors.grey))));
    return SizedBox(
      height: 310, 
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailsScreen(movie: movie))),
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 16, bottom: 10, top: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            movie.imageUrl ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.movie_creation_outlined, color: Colors.grey, size: 40),
                            ),
                          ),
                          Positioned(
                            bottom: 0, left: 0, right: 0,
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie.title, 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87), 
                          maxLines: 2, 
                          overflow: TextOverflow.ellipsis
                        ),
                        const SizedBox(height: 4),
                        Text(
                          movie.category, 
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCityPicker(BuildContext context, HallProvider hallProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("Hangi Şehirde İzlemek İstersin?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                children: hallProvider.cities.map((city) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  title: Text(city, style: TextStyle(fontSize: 16, fontWeight: hallProvider.selectedCity == city ? FontWeight.bold : FontWeight.normal)),
                  trailing: hallProvider.selectedCity == city ? const Icon(Icons.check_circle, color: Color(0xFFFFD600)) : null, 
                  onTap: () {
                    hallProvider.setCity(city);
                    Navigator.pop(context);
                  },
                )).toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}