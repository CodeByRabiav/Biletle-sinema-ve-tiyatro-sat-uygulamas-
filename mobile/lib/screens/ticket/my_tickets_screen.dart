import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/my_tickets_provider.dart';
import '../auth/login_screen.dart';
import 'ticket_screen.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final authProvider = context.read<AuthProvider>();
      
      if (!authProvider.isLoggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }

      if (authProvider.token != null) {
        context.read<MyTicketsProvider>().fetchMyTickets(authProvider.token!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MyTicketsProvider>();
    final authProvider = context.read<AuthProvider>(); // 🔥 Oturum kapatma için eklendi

    return Scaffold(
      backgroundColor: Colors.grey.shade50, 
      appBar: AppBar(
        title: const Text('Biletlerim', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        
        // 🔥 GÜNCELLENDİ: Sağ üst köşeye şık Çıkış Yap butonu eklendi
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
            tooltip: 'Oturumu Kapat',
            onPressed: () async {
              // Kullanıcıya emin olup olmadığını soran onay kutusu
              final bool? confirmLogout = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text("Oturumu Kapat", style: TextStyle(fontWeight: FontWeight.bold)),
                    content: const Text("Hesabınızdan çıkış yapmak istediğinize emin misiniz?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Vazgeç", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Çıkış Yap", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  );
                },
              );

              // Eğer kullanıcı çıkışı onayladıysa
              if (confirmLogout == true && mounted) {
                await authProvider.logout(); // Jetonu ve kullanıcı verilerini sıfırlar
                
                if (mounted) {
                  // Biletlerim sayfasını kapatıp ana sayfaya tertemiz döndürür
                  Navigator.pop(context, true); 
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Başarıyla çıkış yapıldı."),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      body: Builder(
        builder: (_) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD600))); 
          }

          if (provider.errorMessage != null) {
            return Center(child: Text(provider.errorMessage!, style: const TextStyle(color: Colors.redAccent)));
          }

          if (provider.tickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.confirmation_number_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'Henüz aktif bir biletin bulunmuyor.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD600), 
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      elevation: 0,
                    ),
                    child: const Text("Keşfetmeye Başla", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.tickets.length,
            itemBuilder: (context, index) {
              final ticket = provider.tickets[index];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TicketScreen(ticket: ticket),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 56, 56, 55), 
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch, 
                        children: [
                          
                          // SOL TARAF: FİLM AFİŞİ ALANI
                          SizedBox(
                            width: 100, 
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (ticket.imageUrl != null && ticket.imageUrl!.isNotEmpty)
                                  Image.network(
                                    ticket.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: const Color.fromARGB(255, 235, 236, 124), 
                                      child: const Icon(Icons.movie, color: Colors.white24, size: 40)
                                    ),
                                  )
                                else
                                  Container(
                                    color: const Color.fromARGB(255, 7, 7, 7), 
                                    child: const Icon(Icons.movie, color: Colors.white24, size: 40)
                                  ),
                                
                                Positioned(
                                  left: 0, top: 0, bottom: 0,
                                  child: Container(width: 6, color: const Color(0xFFFFD600)),
                                ),
                              ],
                            ),
                          ),
                          
                          // SAĞ TARAF: BİLET BİLGİLERİ
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "SİNEMA BİLETİ",
                                        style: TextStyle(
                                          color: Color(0xFFFFD600), 
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      Icon(Icons.qr_code_2, color: Colors.white.withOpacity(0.5), size: 18),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  Text(
                                    ticket.movieTitle ?? 'Bilinmeyen Etkinlik', 
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                                  
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "PNR Kodu",
                                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            ticket.ticketCode,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Rezervasyon: #${ticket.reservationId}',
                                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
                                          ),
                                        ],
                                      ),
                                      
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFD600).withOpacity(0.15), 
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFFFFD600), width: 1), 
                                        ),
                                        child: const Text(
                                          "GEÇERLİ",
                                          style: TextStyle(color: Color(0xFFFFD600), fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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