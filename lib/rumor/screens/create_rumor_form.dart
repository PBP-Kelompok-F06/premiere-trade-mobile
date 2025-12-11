import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
// import 'package:premiere_trade/rumors/screens/rumors_page.dart';

class RumorFormPage extends StatefulWidget {
  const RumorFormPage({super.key});

  @override
  State<RumorFormPage> createState() => _RumorFormPageState();
}

class _RumorFormPageState extends State<RumorFormPage> {
  final _formKey = GlobalKey<FormState>();
  String _content = "";
  // Note: Untuk implementasi penuh, Anda harus fetch ID Pemain, Club Asal, Club Tujuan
  // dari API. Di sini kita siapkan variabelnya.
  String? _selectedPlayerId;
  String? _selectedClubAsalId;
  String? _selectedClubTujuanId;

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
              // TODO: Ganti ini dengan DropdownButtonFormField yang datanya diambil dari API
              TextFormField(
                decoration: const InputDecoration(
                  hintText: "Isi konten rumor...",
                  labelText: "Konten Rumor",
                  border: OutlineInputBorder(),
                ),
                onChanged: (String? value) {
                  setState(() {
                    _content = value!;
                  });
                },
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return "Konten tidak boleh kosong!";
                  }
                  return null;
                },
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // Kirim ke backend
                    // Pastikan Anda menangani logika pemilihan Pemain/Klub sebelum kirim
                    // Endpoint create_rumors mengharapkan field: 'pemain', 'club_asal', 'club_tujuan', 'content'
                    
                    final response = await request.postJson(
                      "http://127.0.0.1:8000/rumors/create/",
                      jsonEncode(<String, String>{
                        'content': _content,
                        // 'pemain': _selectedPlayerId,
                        // 'club_asal': _selectedClubAsalId,
                        // 'club_tujuan': _selectedClubTujuanId,
                      }),
                    );
                    
                    if (context.mounted) {
                      if (response['success'] == true) {
                         Navigator.pop(context); // Kembali ke list
                      } else {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text("Gagal membuat rumor. Periksa input Anda."),
                         ));
                      }
                    }
                  }
                },
                child: const Text("Simpan"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}