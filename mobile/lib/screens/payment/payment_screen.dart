import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';

class PaymentScreen extends StatefulWidget {
  final int reservationId;
  const PaymentScreen({super.key, required this.reservationId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool isPaid = false;
  String? ticketCode;
  bool isProcessing = false;

  // 🔥 YENİ: Kartları Hafızada Tutmak İçin Değişkenler
  bool saveCard = false;
  List<Map<String, dynamic>> savedCards = [];

  // Form alanlarını kodla doldurabilmek için Controller'lar ekledik
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedCards(); // Ekran açıldığında kayıtlı kartları getir
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  // Cihaz hafızasından kayıtlı kartları çeken fonksiyon
  Future<void> _loadSavedCards() async {
    final prefs = await SharedPreferences.getInstance();
    final cardsStr = prefs.getString('my_saved_cards');
    if (cardsStr != null) {
      setState(() {
        savedCards = List<Map<String, dynamic>>.from(jsonDecode(cardsStr));
      });
    }
  }

  // Test işlemlerini hızlandırmak için rastgele kart dolduran fonksiyon
  void _fillTestCard() {
    setState(() {
      _nameController.text = "RABİA VURAL";
      _numberController.text = "4543123456789012";
      _expiryController.text = "12/28";
      _cvvController.text = "123";
    });
  }

  // Kayıtlı kartlardan birine tıklandığında formu dolduran fonksiyon
  void _selectSavedCard(Map<String, dynamic> card) {
    setState(() {
      _nameController.text = card['name'] ?? '';
      _numberController.text = card['number'] ?? '';
      _expiryController.text = card['expiry'] ?? '';
      _cvvController.text = ''; // Güvenlik gereği CVV asla kaydedilmez/otomatik dolmaz!
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Kart bilgileri dolduruldu, lütfen CVV giriniz.")),
    );
  }

  Future<void> _confirmPayment() async {
    // Boş alan kontrolü
    if (_nameController.text.isEmpty || _numberController.text.isEmpty || _cvvController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen tüm alanları doldurun")));
      return;
    }

    setState(() => isProcessing = true);
    final token = context.read<AuthProvider>().token;

    try {
      final response = await Dio().post(
        'http://127.0.0.1:5000/tickets/purchase/${widget.reservationId}',
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (!mounted) return; 

      if (response.statusCode == 201) {
        // 🔥 Eğer "Kartı Kaydet" seçiliyse, bilgileri cihaz hafızasına yazıyoruz
        if (saveCard) {
          final prefs = await SharedPreferences.getInstance();
          final newCard = {
            'name': _nameController.text,
            'number': _numberController.text,
            'expiry': _expiryController.text,
          };
          
          // Aynı kart numarasından zaten varsa tekrar ekleme
          if (!savedCards.any((c) => c['number'] == newCard['number'])) {
            savedCards.add(newCard);
            await prefs.setString('my_saved_cards', jsonEncode(savedCards));
          }
        }

        setState(() {
          isPaid = true;
          ticketCode = response.data['ticket_code'] ?? "TKT-${widget.reservationId}"; 
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isPaid ? "Biletiniz" : "Güvenli Ödeme")),
      body: Center(
        child: isPaid ? _buildTicketUI() : _buildPaymentUI(),
      ),
    );
  }

  Widget _buildPaymentUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          
          // 🔥 KAYITLI KARTLAR LİSTESİ (Eğer kart varsa görünür)
          if (savedCards.isNotEmpty) ...[
            const Text("Kayıtlı Kartlarım", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: savedCards.length,
                itemBuilder: (context, index) {
                  final card = savedCards[index];
                  // Kart numarasının sadece son 4 hanesini gösteriyoruz (Güvenlik simülasyonu)
                  final last4 = card['number'].toString().length >= 4 
                      ? card['number'].toString().substring(card['number'].toString().length - 4) 
                      : "****";
                      
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      avatar: const Icon(Icons.credit_card, size: 16),
                      label: Text("**** $last4"),
                      onPressed: () => _selectSavedCard(card),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 30),
          ],

          // 📝 KART BİLGİLERİ GİRİŞ FORMLARI
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Kart Üzerindeki İsim', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _numberController,
            decoration: const InputDecoration(labelText: 'Kart Numarası', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
            maxLength: 16,
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _expiryController,
                  decoration: const InputDecoration(labelText: 'Son Kullanma (AA/YY)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.datetime,
                  maxLength: 5,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: TextField(
                  controller: _cvvController,
                  decoration: const InputDecoration(labelText: 'CVV', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 3,
                ),
              ),
            ],
          ),
          
          // 🔥 KARTI KAYDET CHECKBOX'I
          CheckboxListTile(
            title: const Text("Bu kartı sonraki alışverişlerim için kaydet"),
            value: saveCard,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (bool? value) {
              setState(() {
                saveCard = value ?? false;
              });
            },
          ),
          const SizedBox(height: 10),
          
          // 💳 ÖDEMEYİ ONAYLA BUTONU
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blueAccent, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: isProcessing ? null : _confirmPayment,
            child: isProcessing 
                ? const CircularProgressIndicator(color: Colors.white) 
                : const Text("150 TL Öde ve Bileti Al", style: TextStyle(fontSize: 18, color: Colors.white)),
          ),

          const SizedBox(height: 20),
          
          
        ],
      ),
    );
  }

  Widget _buildTicketUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 80),
        const SizedBox(height: 10),
        const Text("Ödeme Başarılı!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const Text("Biletiniz Oluşturuldu", style: TextStyle(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 20),
        QrImageView(data: ticketCode ?? "N/A", size: 200),
        const SizedBox(height: 30),
        ElevatedButton(
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
          child: const Text("Ana Sayfaya Dön", style: TextStyle(fontSize: 16)),
        )
      ],
    );
  }
}