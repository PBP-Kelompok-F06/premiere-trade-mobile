import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:premiere_trade/rumor/models/rumor_model.dart';

class EditRumorFormPage extends StatefulWidget {
  final Rumor rumor; // Data rumor lama dilempar ke sini

  const EditRumorFormPage({super.key, required this.rumor});

  @override
  State<EditRumorFormPage> createState() => _EditRumorFormPageState();
}

class _EditRumorFormPageState extends State<EditRumorFormPage> {
  final _formKey = GlobalKey<FormState>();
  late String _content;

  List<dynamic> _clubAsalList = [];
  List<dynamic> _clubTujuanList = [];
  List<dynamic> _playerList = [];

  String? _selectedClubAsalId;
  String? _selectedClubTujuanId;
  String? _selectedPlayerId;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 1. Isi data awal dari Rumor yang diedit
    _content = widget.rumor.content;
    _selectedClubAsalId = widget.rumor.clubAsalId;
    _selectedClubTujuanId = widget.rumor.clubTujuanId;
    _selectedPlayerId = widget.rumor.pemainId;

    // 2. Load data dropdown
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    final request = context.read<CookieRequest>();
    try {
      // Load List Semua Klub (untuk Dropdown 1)
      final allClubs = await request.get('http://localhost:8000/rumors/get-designated-clubs/');
      
      // Load List Klub Tujuan & Pemain berdasarkan Klub Asal yang lama (untuk Dropdown 2 & 3)
      final designatedClubs = await request.get('http://localhost:8000/rumors/get-designated-clubs/?club_asal=$_selectedClubAsalId');
      final players = await request.get('http://localhost:8000/rumors/get-players/?club_id=$_selectedClubAsalId');

      if (mounted) {
        setState(() {
          _clubAsalList = allClubs;
          _clubTujuanList = designatedClubs;
          _playerList = players;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading edit data: $e");
    }
  }

  // Logic saat Klub Asal diganti (sama kayak Create)
  Future<void> _onClubAsalChanged(String? clubId) async {
    if (clubId == null) return;
    setState(() {
      _selectedClubAsalId = clubId;
      _selectedClubTujuanId = null; // Reset pilihan
      _selectedPlayerId = null;     // Reset pilihan
      _clubTujuanList = [];
      _playerList = [];
    });

    final request = context.read<CookieRequest>();
    try {
      final clubsRes = await request.get('http://localhost:8000/rumors/get-designated-clubs/?club_asal=$clubId');
      final playersRes = await request.get('http://localhost:8000/rumors/get-players/?club_id=$clubId');

      if (mounted) {
        setState(() {
          _clubTujuanList = clubsRes;
          _playerList = playersRes;
        });
      }
    } catch (e) {
      print("Error fetching dependent data: $e");
    }
  }

  // Helper untuk menerjemahkan status ke Bahasa Indonesia
  String _translateStatus(String status) {
    if (status == 'verified') return 'Terverifikasi';
    if (status == 'denied') return 'Ditolak';
    return status;
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Rumor')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- [BARU] WARNING BOX (Persis seperti Django Template) ---
              if (widget.rumor.status == 'verified' || widget.rumor.status == 'denied') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.yellow[100], // bg-yellow-100
                    borderRadius: BorderRadius.circular(8),
                    // Border kiri tebal (border-l-4 border-yellow-500)
                    border: Border(
                      left: BorderSide(
                        color: Colors.yellow[700]!, 
                        width: 4.0,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.yellow[900], fontSize: 14), // text-yellow-800
                          children: [
                            const TextSpan(text: "⚠️ Rumor ini berstatus "),
                            TextSpan(
                              text: _translateStatus(widget.rumor.status),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const TextSpan(text: ".\n"), // Line break
                            const TextSpan(
                              text: "Mengedit rumor akan mengubah status menjadi ",
                            ),
                            const TextSpan(
                              text: "Menunggu Verifikasi",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const TextSpan(text: " untuk diverifikasi ulang."),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // -------------------------------------------------------------

              // DROPDOWN KLUB ASAL
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Klub Asal", border: OutlineInputBorder()),
                value: _selectedClubAsalId,
                items: _clubAsalList.map<DropdownMenuItem<String>>((item) {
                  return DropdownMenuItem<String>(
                    value: item['id'].toString(),
                    child: Text(item['name']),
                  );
                }).toList(),
                onChanged: _onClubAsalChanged,
                validator: (v) => v == null ? "Pilih klub asal" : null,
              ),
              const SizedBox(height: 16),

              // DROPDOWN KLUB TUJUAN
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Klub Tujuan", border: OutlineInputBorder()),
                value: _selectedClubTujuanId,
                items: _clubTujuanList.map<DropdownMenuItem<String>>((item) {
                  return DropdownMenuItem<String>(
                    value: item['id'].toString(),
                    child: Text(item['name']),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedClubTujuanId = val),
                validator: (v) => v == null ? "Pilih klub tujuan" : null,
                hint: const Text("Pilih Klub Asal Dulu"),
              ),
              const SizedBox(height: 16),

              // DROPDOWN PEMAIN
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Pemain", border: OutlineInputBorder()),
                value: _selectedPlayerId,
                items: _playerList.map<DropdownMenuItem<String>>((item) {
                  return DropdownMenuItem<String>(
                    value: item['id'].toString(),
                    child: Text(item['nama_pemain']),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedPlayerId = val),
                validator: (v) => v == null ? "Pilih pemain" : null,
                hint: const Text("Pilih Klub Asal Dulu"),
              ),
              const SizedBox(height: 16),

              // CONTENT
              TextFormField(
                initialValue: _content, // Pre-fill konten lama
                decoration: const InputDecoration(
                  labelText: "Detail Rumor",
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                onChanged: (val) => _content = val,
                validator: (val) => val!.isEmpty ? "Konten tidak boleh kosong" : null,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                        final response = await request.postJson(
                          "http://localhost:8000/rumors/${widget.rumor.id}/edit-flutter/",
                          jsonEncode({
                            'club_asal': _selectedClubAsalId,
                            'club_tujuan': _selectedClubTujuanId,
                            'pemain': _selectedPlayerId,
                            'content': _content,
                          }),
                        );

                        if (context.mounted) {
                            if (response['status'] == 'success') {
                                Navigator.pop(context, true); // True = perlu refresh
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Rumor berhasil diupdate!")));
                            } else {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: ${response['message']}")));
                            }
                        }
                    }
                  },
                  child: const Text("Simpan Perubahan"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}