import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart'; 
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

  // Data List 
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

  // LOGIKA FETCH DATA 
  Future<void> _fetchInitialClubs() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.get('https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/rumors/get-designated-clubs/');
      setState(() {
        _clubAsalList = response;
        if (response.isNotEmpty) {
          _selectedClubAsalId = response[0]['id'].toString();
          _onClubAsalChanged(_selectedClubAsalId);
        }
      });
    } catch (e) {
      print("Error fetching clubs: $e");
    }
  }

  Future<void> _onClubAsalChanged(String? clubId) async {
    if (clubId == null) return;
    setState(() {
      _selectedClubAsalId = clubId;
      _selectedClubTujuanId = null; 
      _selectedPlayerId = null; 
      _clubTujuanList = [];
      _playerList = [];
    });

    final request = context.read<CookieRequest>();
    try {
      final clubsRes = await request.get('https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/rumors/get-designated-clubs/?club_asal=$clubId');
      final playersRes = await request.get('https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/rumors/get-players/?club_id=$clubId');

      setState(() {
        _clubTujuanList = clubsRes;
        _playerList = playersRes;
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
              // 1. DROPDOWN SEARCH: KLUB ASAL
              DropdownSearch<dynamic>(
                popupProps: PopupProps.menu( 
                  showSearchBox: false,
                  fit: FlexFit.loose,
                  constraints: const BoxConstraints(maxHeight: 300),
                ),
                items: (filter, loadProps) {
                  if (filter == null || filter.isEmpty) {
                    return _clubAsalList;
                  }
                  return _clubAsalList.where((element) => 
                    element['name'].toString().toLowerCase().contains(filter.toLowerCase())
                  ).toList();
                },
                itemAsString: (item) => item['name'], 
                compareFn: (item, selectedItem) => item['id'] == selectedItem['id'],
                selectedItem: _clubAsalList.isEmpty || _selectedClubAsalId == null
                    ? null
                    : _clubAsalList.firstWhere(
                        (item) => item['id'].toString() == _selectedClubAsalId,
                        orElse: () => null),
                decoratorProps: const DropDownDecoratorProps(
                  decoration: InputDecoration(
                    labelText: "Klub Asal",
                    border: OutlineInputBorder(),
                  ),
                ),
                onChanged: (val) {
                  if (val != null) {
                    _onClubAsalChanged(val['id'].toString());
                  }
                },
                validator: (val) => val == null ? "Pilih klub asal" : null,
              ),
              const SizedBox(height: 16),

              // 2. DROPDOWN SEARCH: KLUB TUJUAN
              DropdownSearch<dynamic>(
                popupProps: PopupProps.menu(
                  showSearchBox: false,
                  fit: FlexFit.loose,
                  constraints: const BoxConstraints(maxHeight: 300),
                ),
                items: (filter, loadProps) {
                  if (filter == null || filter.isEmpty) {
                    return _clubTujuanList;
                  }
                  return _clubTujuanList.where((element) => 
                    element['name'].toString().toLowerCase().contains(filter.toLowerCase())
                  ).toList();
                },
                itemAsString: (item) => item['name'],
                compareFn: (item, selectedItem) => item['id'] == selectedItem['id'],
                selectedItem: _clubTujuanList.isEmpty || _selectedClubTujuanId == null
                    ? null
                    : _clubTujuanList.firstWhere(
                        (item) => item['id'].toString() == _selectedClubTujuanId,
                        orElse: () => null),
                decoratorProps: const DropDownDecoratorProps(
                  decoration: InputDecoration(
                    labelText: "Klub Tujuan",
                    border: OutlineInputBorder(),
                  ),
                ),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedClubTujuanId = val['id'].toString());
                  }
                },
                validator: (val) => val == null ? "Pilih klub tujuan" : null,
              ),
              const SizedBox(height: 16),

              // 3. DROPDOWN SEARCH: PEMAIN
              DropdownSearch<dynamic>(
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  constraints: const BoxConstraints(maxHeight: 300),
                  searchFieldProps: const TextFieldProps(
                    decoration: InputDecoration(hintText: "Cari pemain..."),
                  ),
                ),
                items: (filter, loadProps) {
                  if (filter == null || filter.isEmpty) {
                    return _playerList;
                  }
                  return _playerList.where((element) => 
                    element['nama_pemain'].toString().toLowerCase().contains(filter.toLowerCase())
                  ).toList();
                },
                itemAsString: (item) => item['nama_pemain'],
                compareFn: (item, selectedItem) => item['id'] == selectedItem['id'],
                selectedItem: _playerList.isEmpty || _selectedPlayerId == null
                    ? null
                    : _playerList.firstWhere(
                        (item) => item['id'].toString() == _selectedPlayerId,
                        orElse: () => null),
                decoratorProps: const DropDownDecoratorProps(
                  decoration: InputDecoration(
                    labelText: "Pemain",
                    border: OutlineInputBorder(),
                  ),
                ),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedPlayerId = val['id'].toString());
                  }
                },
                validator: (val) => val == null ? "Pilih pemain" : null,
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

              // TOMBOL KIRIM
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
                      if (_selectedClubAsalId == null || _selectedClubTujuanId == null || _selectedPlayerId == null) {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mohon lengkapi semua data")));
                         return;
                      }

                      final response = await request.postJson(
                        "https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/rumors/create-flutter/",
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