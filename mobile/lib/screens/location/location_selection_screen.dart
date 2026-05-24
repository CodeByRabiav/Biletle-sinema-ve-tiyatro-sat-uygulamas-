import 'package:flutter/material.dart';
import '../venue/venue_list_screen.dart';

class LocationSelectionScreen extends StatefulWidget {
  final String venueType;

  const LocationSelectionScreen({
    super.key,
    required this.venueType,
  });

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();

  // Biletinial tarzı popüler şehirler listesi
  final List<Map<String, String>> _popularCities = [
    {'name': 'İstanbul', 'icon': '🌆'},
    {'name': 'Ankara', 'icon': '🏛️'},
    {'name': 'İzmir', 'icon': '🌊'},
    {'name': 'Bursa', 'icon': '🏔️'},
    {'name': 'Antalya', 'icon': '☀️'},
    {'name': 'Trabzon', 'icon': '🌲'},
  ];

  @override
  void dispose() {
    _cityController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  void _continue(String city, String district) {
    if (city.isEmpty || district.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şehir ve ilçe seçimi zorunludur')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VenueListScreen(
          venueType: widget.venueType,
          city: city,
          district: district,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.venueType == 'cinema' ? 'Sinema Ara' : 'Tiyatro Ara';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🏙️ POPÜLER ŞEHİRLER BAŞLIĞI
            const Text(
              "Popüler Şehirler",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            
            // YATAY ŞEHİR LİSTESİ
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _popularCities.length,
                itemBuilder: (context, index) {
                  final city = _popularCities[index];
                  return GestureDetector(
                    onTap: () => setState(() => _cityController.text = city['name']!),
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 15),
                      decoration: BoxDecoration(
                        color: _cityController.text == city['name'] 
                            ? Colors.red.shade50 
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: _cityController.text == city['name'] 
                              ? Colors.red 
                              : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(city['icon']!, style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 8),
                          Text(
                            city['name']!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _cityController.text == city['name'] 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 40),

            // 🔍 ARAMA FORMU
            const Text(
              "Konum Bilgileri",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            _buildModernTextField(
              controller: _cityController,
              label: "Şehir",
              icon: Icons.location_city,
              hint: "Örn: Trabzon",
            ),
            const SizedBox(height: 15),
            _buildModernTextField(
              controller: _districtController,
              label: "İlçe",
              icon: Icons.map_outlined,
              hint: "Örn: Ortahisar",
            ),

            const SizedBox(height: 40),

            // 🚀 LİSTELE BUTONU
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () => _continue(_cityController.text, _districtController.text),
                child: const Text(
                  'Salonları Listele',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.redAccent),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}