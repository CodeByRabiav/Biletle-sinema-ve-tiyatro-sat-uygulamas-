import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reservation_provider.dart';
import '../../data/models/seat_model.dart'; 
import '../payment/payment_screen.dart';
import '../auth/login_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final int sessionId;
  final int hallId;
  final String movieTitle;
  final String hallName;
  final double price;

  const SeatSelectionScreen({
    super.key,
    required this.sessionId,
    required this.hallId,
    required this.movieTitle,
    required this.hallName,
    required this.price,
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ReservationProvider>().loadSeatData(
            hallId: widget.hallId,
            sessionId: widget.sessionId,
          );
    });
  }

  // 🔥 MOBİL NAVİGASYON AKIŞI TAMAMEN REFACTOR EDİLDİ
  void _onContinuePressed() async {
    final authProvider = context.read<AuthProvider>();
    final reservationProvider = context.read<ReservationProvider>();

    if (reservationProvider.selectedSeatIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen en az bir koltuk seçiniz.")),
      );
      return;
    }

    // 1. ADIM: Giriş yapılmamışsa Login sayfasına at ve sonucunu bekle
    if (!authProvider.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Devam etmek için giriş yapmalısınız.")),
      );
      
      // Giriş ekranından dönecek true/false cevabını bekliyoruz
      final bool? loggedIn = await Navigator.push<bool>(
        context, 
        MaterialPageRoute(builder: (_) => const LoginScreen())
      );

      // Eğer kullanıcı giriş yapmadan geri tuşuna bastıysa işlemi durdur
      if (loggedIn != true || !authProvider.isLoggedIn) {
        return; 
      }
    }

    // 2. ADIM: Giriş var veya başarıyla yapılıp dönüldüyse, yükleniyor indicator'ı aç
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD600)));
      },
    );

    // Backend'e token ile istek gönderiliyor
    final result = await reservationProvider.createReservation(
      token: authProvider.token ?? "",
      sessionId: widget.sessionId,
    );

    // Yükleniyor penceresini kapat
    if (mounted) Navigator.pop(context);

    // Başarılı Kilitleme -> Ödeme ekranına yönlendir
    if (result != null && result.containsKey("reservation")) {
      final reservationId = result["reservation"]["id"];
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PaymentScreen(reservationId: reservationId)),
        );
      }
    } 
    // Başarısız Kilitleme (Race Condition)
    else if (result != null && result.containsKey("conflicted_seat_ids")) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Üzgünüz, seçtiğiniz koltuk az önce başkası tarafından alındı veya inceleniyor. Lütfen başka bir koltuk seçin."),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
        reservationProvider.clearSelections();
        reservationProvider.loadSeatData(hallId: widget.hallId, sessionId: widget.sessionId);
      }
    } 
    // Diğer Hatalar (Örn: 401 Yetkisiz Hatası)
    else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(reservationProvider.errorMessage ?? "Oturum hatası oluştu. Lütfen tekrar giriş yapın."),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reservationProvider = context.watch<ReservationProvider>();
    final hall = reservationProvider.hall;

    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        title: Text(widget.movieTitle, style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      body: reservationProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD600)))
          : hall == null
              ? const Center(child: Text("Salon bilgisi yüklenemedi."))
              : Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return InteractiveViewer(
                            boundaryMargin: const EdgeInsets.all(100), 
                            minScale: 0.5,
                            maxScale: 3.0,
                            constrained: false, 
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth,
                                minHeight: constraints.maxHeight,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center, 
                                  children: [
                                    _buildScreenIndicator(),
                                    _buildSeatGrid(reservationProvider),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                      ),
                    ),
                    _buildSeatLegend(),
                    _buildBottomBar(reservationProvider),
                  ],
                ),
    );
  }

  Widget _buildScreenIndicator() {
    return Column(
      children: [
        Container(
          height: 8, width: 300, 
          decoration: BoxDecoration(
            color: Colors.grey.shade300, 
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: const Color(0xFFFFD600).withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5)) 
            ]
          ),
        ),
        const SizedBox(height: 15),
        const Text("P E R D E", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 8)),
        const SizedBox(height: 40), 
      ],
    );
  }

  Widget _buildSeatGrid(ReservationProvider provider) {
    final hall = provider.hall!;

    if (hall.seats.isEmpty) {
      return const Center(child: Text("Bu seans için koltuk verisi bulunamadı.", style: TextStyle(color: Colors.grey)));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(hall.rowCount, (rowIndex) {
        String rowLabel = String.fromCharCode(65 + rowIndex); 
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 15.0), 
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                alignment: Alignment.center,
                margin: const EdgeInsets.only(right: 15),
                child: Text(rowLabel, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black38)),
              ),

              ...List.generate(hall.columnCount, (colIndex) {
                int seatNumber = colIndex + 1;
                
                SeatModel? currentSeat;
                for (var s in hall.seats) {
                  if (s.rowLabel?.toUpperCase() == rowLabel && s.seatNumber == seatNumber) {
                    currentSeat = s;
                    break;
                  }
                }

                if (currentSeat == null) {
                  return Container(
                    width: 55, 
                    height: 55, 
                    margin: const EdgeInsets.symmetric(horizontal: 8) 
                  ); 
                }

                int safeSeatId = currentSeat.id ?? 0;
                bool isOccupied = provider.occupiedSeatIds.contains(safeSeatId);
                bool isSelected = provider.selectedSeatIds.contains(safeSeatId);

                return GestureDetector(
                  onTap: isOccupied ? null : () => provider.toggleSeat(safeSeatId),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 55, height: 55, 
                    margin: const EdgeInsets.symmetric(horizontal: 8), 
                    decoration: BoxDecoration(
                      color: isOccupied 
                          ? Colors.grey.shade400 
                          : isSelected 
                              ? const Color(0xFFFFD600) 
                              : const Color(0xFFFFF59D), 
                      
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      
                      border: Border.all(
                        color: isOccupied 
                            ? Colors.grey.shade500 
                            : isSelected 
                                ? Colors.black87 
                                : const Color(0xFFFFD600), 
                        width: 2.0, 
                      ),
                      
                      boxShadow: isSelected ? [
                        BoxShadow(color: const Color(0xFFFFD600).withOpacity(0.6), blurRadius: 12, offset: const Offset(0, 5))
                      ] : [
                        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 5, offset: const Offset(0, 3))
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "${currentSeat.seatNumber}", 
                      style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold, 
                        color: isOccupied ? Colors.white : Colors.black87 
                      )
                    ),
                  ),
                );
              })
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSeatLegend() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25, top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendBox(const Color(0xFFFFF59D), "Boş", const Color(0xFFFFD600), Colors.black87),
          const SizedBox(width: 20),
          _legendBox(const Color(0xFFFFD600), "Seçili", Colors.black87, Colors.black87),
          const SizedBox(width: 20),
          _legendBox(Colors.grey.shade400, "Dolu", Colors.grey.shade500, Colors.grey.shade600),
        ],
      ),
    );
  }

  Widget _legendBox(Color bgColor, String text, Color borderColor, Color textColor) {
    return Row(
      children: [
        Container(
          width: 20, height: 20, 
          decoration: BoxDecoration(
            color: bgColor, 
            border: Border.all(color: borderColor, width: 2.0), 
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6), bottomLeft: Radius.circular(3), bottomRight: Radius.circular(3))
          )
        ), 
        const SizedBox(width: 8), 
        Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor))
      ],
    );
  }

  Widget _buildBottomBar(ReservationProvider provider) {
    int count = provider.selectedSeatIds.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white, 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, -5))]
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              mainAxisSize: MainAxisSize.min, 
              children: [
                Text("$count Koltuk Seçildi", style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)), 
                const SizedBox(height: 2),
                Text("${(count * widget.price).toStringAsFixed(2)} TL", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
              ],
            ),
            ElevatedButton(
              onPressed: count > 0 ? _onContinuePressed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD600), 
                foregroundColor: Colors.black87, 
                disabledBackgroundColor: Colors.grey.shade200,
                disabledForegroundColor: Colors.grey.shade400,
                padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                elevation: count > 0 ? 4 : 0,
                shadowColor: const Color(0xFFFFD600).withOpacity(0.5),
              ),
              child: const Text("DEVAM ET", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)),
            )
          ],
        ),
      ),
    );
  }
}