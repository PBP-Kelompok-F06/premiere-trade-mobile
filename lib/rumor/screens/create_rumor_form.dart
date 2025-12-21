import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

class RumorFormPage extends StatefulWidget {
  const RumorFormPage({super.key});

  @override
  State<RumorFormPage> createState() => _RumorFormPageState();
}

class _RumorFormPageState extends State<RumorFormPage> {
  final _formKey = GlobalKey<FormState>();
  String _content = "";

  // Data List untuk Dropdown
  List<dynamic> _clubAsalList = [];
  List<dynamic> _clubTujuanList = [];
  List<dynamic> _playerList = [];

  // Nilai Terpilih
  String? _selectedClubAsalId;
  String? _selectedClubTujuanId;
  String? _selectedPlayerId;

  @override
  void initState() {
    super.initState();
    _fetchInitialClubs();
  }

  // 1. Fetch semua klub untuk "Club Asal"
  Future<void> _fetchInitialClubs() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.get('http://localhost:8000/rumors/get-designated-clubs/');
      setState(() {
        _clubAsalList = response;
        // Set default ke klub pertama
        if (response.isNotEmpty) {
          _selectedClubAsalId = response[0]['id'].toString();
          // Load Club Tujuan dan Pemain untuk klub pertama
          _onClubAsalChanged(_selectedClubAsalId);
        }
      });
    } catch (e) {
      print("Error fetching clubs: $e");
    }
  }

  // 2. Fetch Klub Tujuan & Pemain saat Club Asal berubah
  Future<void> _onClubAsalChanged(String? clubId) async {
    if (clubId == null) return;
    setState(() {
        _selectedClubAsalId = clubId;
        _selectedClubTujuanId = null; // Reset
        _selectedPlayerId = null; // Reset
        _clubTujuanList = [];
        _playerList = [];
    });

    final request = context.read<CookieRequest>();
    try {
        // Fetch Designated Clubs
        final clubsRes = await request.get('http://localhost:8000/rumors/get-designated-clubs/?club_asal=$clubId');
        // Fetch Players
        final playersRes = await request.get('http://localhost:8000/rumors/get-players/?club_id=$clubId');

        setState(() {
            _clubTujuanList = clubsRes;
            _playerList = playersRes;
            // Set default ke item pertama jika ada
            if (clubsRes.isNotEmpty) {
              _selectedClubTujuanId = clubsRes[0]['id'].toString();
            }
            if (playersRes.isNotEmpty) {
              _selectedPlayerId = playersRes[0]['id'].toString();
            }
        });
    } catch (e) {
        print("Error fetching dependent data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(title: const Text('Buat Rumor Baru')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                hint: const Text("Pilih Klub Tujuan"),
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
                hint: const Text("Pilih Pemain"),
              ),
              const SizedBox(height: 16),

              // CONTENT TEXT AREA
              TextFormField(
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
                          "http://localhost:8000/rumors/create-flutter/",
                          jsonEncode({
                            'club_asal': _selectedClubAsalId,
                            'club_tujuan': _selectedClubTujuanId,
                            'pemain': _selectedPlayerId,
                            'content': _content,
                          }),
                        );

                        if (context.mounted) {
                            if (response['status'] == 'success') {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Rumor berhasil dibuat!")));
                            } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal membuat rumor.")));
                            }
                        }
                    }
                  },
                  child: const Text("Kirim Rumor"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}