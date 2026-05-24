import 'package:flutter/material.dart';
import '../location/location_selection_screen.dart';

class CategorySelectionScreen extends StatelessWidget {
  // Ana sayfadan gelen kategori bilgisini tutacak değişken
  final String selectedVenueType; 

  const CategorySelectionScreen({
    super.key, 
    required this.selectedVenueType // Kategori artık zorunlu bir parametre
  });

  @override
  Widget build(BuildContext context) {
    // Bu ekran artık sadece bir geçiş veya onay ekranı gibi çalışabilir 
    // veya doğrudan il/ilçe formunu burada gösterebilirsin.
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedVenueType == 'cinema' ? 'Sinema Arama' : 'Tiyatro Arama'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${selectedVenueType == 'cinema' ? 'Sinema' : 'Tiyatro'} kategorisi için konum seçiniz.",
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LocationSelectionScreen(
                        venueType: selectedVenueType, // Seçili kategoriyi gönderiyoruz
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.location_on),
                label: const Text('İl ve İlçe Seçimine Git'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}