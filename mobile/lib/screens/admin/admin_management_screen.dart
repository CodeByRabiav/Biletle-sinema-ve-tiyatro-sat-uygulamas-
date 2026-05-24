import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../providers/auth_provider.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  final _dio = Dio();
  
  // Salon Formu Kontrolleri
  final _hallName = TextEditingController();
  final _city = TextEditingController();
  final _district = TextEditingController();
  final _rows = TextEditingController();
  final _cols = TextEditingController();
  String _vType = 'cinema';

  // Film/Tiyatro Formu Kontrolleri
  final _title = TextEditingController();
  final _cat = TextEditingController();
  final _dur = TextEditingController();
  String _cType = 'cinema';

  Future<void> _postData(String endpoint, Map<String, dynamic> data) async {
    final token = context.read<AuthProvider>().token;
    try {
      await _dio.post(
        'http://127.0.0.1:5000/$endpoint',
        data: data,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Başarıyla eklendi!")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Yönetim Paneli'),
          bottom: const TabBar(tabs: [Tab(text: "Salon"), Tab(text: "İçerik")]),
        ),
        body: TabBarView(
          children: [
            _buildHallForm(),
            _buildMovieForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildHallForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(controller: _hallName, decoration: const InputDecoration(labelText: 'Salon Adı')),
          TextField(controller: _city, decoration: const InputDecoration(labelText: 'Şehir')),
          TextField(controller: _district, decoration: const InputDecoration(labelText: 'İlçe')),
          DropdownButton<String>(
            value: _vType,
            items: const [DropdownMenuItem(value: 'cinema', child: Text("Sinema")), DropdownMenuItem(value: 'theater', child: Text("Tiyatro"))],
            onChanged: (v) => setState(() => _vType = v!),
          ),
          Row(
            children: [
              Expanded(child: TextField(controller: _rows, decoration: const InputDecoration(labelText: 'Satır'), keyboardType: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _cols, decoration: const InputDecoration(labelText: 'Sütun'), keyboardType: TextInputType.number)),
            ],
          ),
          ElevatedButton(
            onPressed: () => _postData('halls', {
              "name": _hallName.text, "city": _city.text, "district": _district.text,
              "venue_type": _vType, "row_count": int.parse(_rows.text), "column_count": int.parse(_cols.text)
            }),
            child: const Text("Salon ve Koltukları Oluştur"),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Başlık (Film/Oyun)')),
          TextField(controller: _cat, decoration: const InputDecoration(labelText: 'Kategori')),
          TextField(controller: _dur, decoration: const InputDecoration(labelText: 'Süre (dk)'), keyboardType: TextInputType.number),
          DropdownButton<String>(
            value: _cType,
            items: const [DropdownMenuItem(value: 'cinema', child: Text("Film")), DropdownMenuItem(value: 'theater', child: Text("Tiyatro Oyunu"))],
            onChanged: (v) => setState(() => _cType = v!),
          ),
          ElevatedButton(
            onPressed: () => _postData('movies', {
              "title": _title.text, "category": _cat.text, "duration": int.parse(_dur.text), "content_type": _cType
            }),
            child: const Text("İçeriği Kaydet"),
          ),
        ],
      ),
    );
  }
}