import 'dart:async';
import "package:flutter/material.dart";
import "package:pbp_django_auth/pbp_django_auth.dart";
import 'package:provider/provider.dart';
import 'package:premiere_trade/rumor/models/rumor_model.dart';
import 'package:premiere_trade/rumor/screens/create_rumor_form.dart';
import 'package:premiere_trade/rumor/screens/rumor_detail_page.dart';

// Helper function untuk proxy gambar
String getProxiedUrl(String? url) {
  if (url == null || url.isEmpty) return "";
  return "https://wsrv.nl/?url=$url&output=png";
}

class RumorsPage extends StatefulWidget {
  const RumorsPage({super.key});

  @override
  State<RumorsPage> createState() => _RumorsPageState();
}

class _RumorsPageState extends State<RumorsPage> {
  // --- STATE ---
  String _searchName = "";
  String? _selectedClubAsal;
  String? _selectedClubTujuan;
  List<dynamic> _clubList = [];
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchClubs();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchClubs() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.get('http://localhost:8000/rumors/get-designated-clubs/');
      setState(() {
        _clubList = response;
      });
    } catch (e) {
      print("Error fetching clubs: $e");
    }
  }

  Future<List<Rumor>> fetchRumors(CookieRequest request) async {
    String url = 'http://localhost:8000/rumors/json/?';

    if (_searchName.isNotEmpty) {
      url += 'nama=$_searchName&';
    }
    if (_selectedClubAsal != null) {
      url += 'asal=$_selectedClubAsal&';
    }
    if (_selectedClubTujuan != null) {
      url += 'tujuan=$_selectedClubTujuan&';
    }

    final response = await request.get(url);
    
    List<Rumor> listRumor = [];
    for (var d in response) {
      if (d != null) {
        listRumor.add(Rumor.fromJson(d));
      }
    }
    return listRumor;
  }

  // Live Search Logic
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchName = query;
      });
    });
  }

  void _resetFilters() {
    setState(() {
      _searchName = "";
      _searchController.clear();
      _selectedClubAsal = null;
      _selectedClubTujuan = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      // Menggunakan CustomScrollView agar Filter dan List menyatu dalam satu scroll view
      body: CustomScrollView(
        slivers: [
          // 1. BAGIAN FILTER (SliverToBoxAdapter agar bisa discroll)
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 8), // Sedikit jarak dengan list
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Cari nama pemain...",
                      prefixIcon: const Icon(Icons.search, color: Colors.purple),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                    onChanged: _onSearchChanged, // Live Search trigger
                  ),
                  const SizedBox(height: 12),

                  // Dropdowns
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          hint: "Klub Asal",
                          value: _selectedClubAsal,
                          onChanged: (val) => setState(() => _selectedClubAsal = val),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDropdown(
                          hint: "Klub Tujuan",
                          value: _selectedClubTujuan,
                          onChanged: (val) => setState(() => _selectedClubTujuan = val),
                        ),
                      ),
                    ],
                  ),
                  
                  // Reset Button
                  if (_searchName.isNotEmpty || _selectedClubAsal != null || _selectedClubTujuan != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: GestureDetector(
                        onTap: _resetFilters,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.refresh, size: 16, color: Colors.red),
                            SizedBox(width: 4),
                            Text("Reset Filter", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 2. DAFTAR RUMOR (FutureBuilder + SliverList)
          FutureBuilder<List<Rumor>>(
            future: fetchRumors(request),
            builder: (context, AsyncSnapshot<List<Rumor>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Tampilan Loading
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                // Tampilan Error
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('Error: ${snapshot.error}')),
                );
              }

              final rumors = snapshot.data;
              if (rumors == null || rumors.isEmpty) {
                // Tampilan Kosong
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "Tidak ada rumor ditemukan",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Tampilan List Data
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final rumor = rumors[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: _buildRumorCard(rumor),
                    );
                  },
                  childCount: rumors.length,
                ),
              );
            },
          ),
          
          // Spacer bawah agar item terakhir tidak tertutup FAB
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RumorFormPage()),
          ).then((_) => setState(() {}));
        },
        backgroundColor: Colors.white,
        foregroundColor: Colors.purple[700],
        elevation: 4,
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- WIDGET HELPER ---

  Widget _buildDropdown({
    required String hint, 
    required String? value, 
    required Function(String?) onChanged
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.purple),
          items: _clubList.map<DropdownMenuItem<String>>((item) {
            return DropdownMenuItem<String>(
              value: item['id'].toString(),
              child: Text(
                item['name'], 
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildRumorCard(Rumor rumor) {
    Color statusColor;
    IconData statusIcon;
    if (rumor.status == 'verified') {
      statusColor = Colors.green;
      statusIcon = Icons.check;
    } else if (rumor.status == 'denied') {
      statusColor = Colors.red;
      statusIcon = Icons.close;
    } else {
      statusColor = Colors.amber;
      statusIcon = Icons.access_time_filled;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RumorDetailPage(rumor: rumor),
          ),
        ).then((_) => setState(() {})); 
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  Hero(
                    tag: 'player_img_${rumor.id}',
                    child: Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)
                        ],
                      ),
                      child: ClipOval(
                        child: (rumor.pemainThumbnail.isNotEmpty)
                            ? Image.network(
                                getProxiedUrl(rumor.pemainThumbnail),
                                width: 65,
                                height: 65,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.person, color: Colors.grey),
                                  );
                                },
                              )
                            : Container(
                                width: 65,
                                height: 65,
                                color: Colors.grey[200],
                                child: const Icon(Icons.person, color: Colors.grey),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 24,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(
                              rumor.pemainNama,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        
                        Row(
                          children: [
                            Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              rumor.createdAt,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Row(
                    children: [
                      _buildClubLogo(rumor.clubAsalLogo),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: Icon(Icons.arrow_right_alt, color: Colors.grey),
                      ),
                      _buildClubLogo(rumor.clubTujuanLogo),
                    ],
                  ),
                ],
              ),
            ),

            Positioned(
              left: -10,
              top: 35, 
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Icon(statusIcon, color: Colors.white, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClubLogo(String url) {
    if (url.isEmpty) return const SizedBox(width: 40);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade100),
      ),
      padding: const EdgeInsets.all(5),
      child: Image.network(
        getProxiedUrl(url),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.shield, color: Colors.grey, size: 20);
        },
      ),
    );
  }
}