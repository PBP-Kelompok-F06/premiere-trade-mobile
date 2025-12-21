import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/styles.dart';
import '../../core/widgets/primary_button.dart';

class ManagePlayersPage extends StatefulWidget {
  const ManagePlayersPage({super.key});

  @override
  State<ManagePlayersPage> createState() => _ManagePlayersPageState();
}

class _ManagePlayersPageState extends State<ManagePlayersPage> {
  // Fungsi Fetch Data Pemain
  Future<List<dynamic>> fetchPlayers(CookieRequest request) async {
    final response = await request.get(
        'https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/accounts/api/admin/players/');

    if (response['status'] == true) {
      return response['data'];
    } else {
      throw Exception("Gagal mengambil data");
    }
  }

  // Fungsi Hapus Pemain
  void deletePlayer(CookieRequest request, String id) async {
    // Player ID menggunakan UUID (String)
    final response = await request.post(
        'https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/accounts/api/admin/players/$id/delete/',
        {});

    if (mounted) {
      if (response['status'] == true) {
        setState(() {}); // Refresh halaman
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pemain berhasil dihapus")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? "Gagal menghapus")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Manage Players",
            style: AppTextStyles.h3.copyWith(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.secondary,
        child: const Icon(Icons.add, color: AppColors.primary),
        onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AddPlayerPage()))
            .then((_) => setState(() {})), // Refresh setelah tambah
      ),
      body: FutureBuilder(
        future: fetchPlayers(request),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || (snapshot.data! as List<dynamic>).isEmpty) {
            return const Center(child: Text("Belum ada data pemain."));
          }

          final players = snapshot.data! as List<dynamic>;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: players.length,
            itemBuilder: (ctx, i) {
              final p = players[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppBoxShadows.card,
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    backgroundImage: (p['thumbnail'] != null &&
                            p['thumbnail'].toString().isNotEmpty)
                        ? NetworkImage(p['thumbnail'])
                        : null,
                    child: (p['thumbnail'] == null ||
                            p['thumbnail'].toString().isEmpty)
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                  title: Text(
                    p['nama_pemain'],
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${p['position']} • ${p['club_name']}",
                          style: AppTextStyles.caption),
                      Text("Value: €${p['market_value']}",
                          style: AppTextStyles.caption
                              .copyWith(color: Colors.green)),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.error),
                    onPressed: () => deletePlayer(request, p['id']),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- FORM TAMBAH PLAYER (Sudah benar, hanya penyesuaian Style) ---
class AddPlayerPage extends StatefulWidget {
  const AddPlayerPage({super.key});
  @override
  State<AddPlayerPage> createState() => _AddPlayerPageState();
}

class _AddPlayerPageState extends State<AddPlayerPage> {
  final _formKey = GlobalKey<FormState>();
  String nama = "", position = "", negara = "", thumbnail = "";
  int umur = 0, marketValue = 0, goal = 0, asis = 0, match = 0;
  String? selectedClubId;
  List<dynamic> clubs = [];

  @override
  void initState() {
    super.initState();
    _fetchClubs();
  }

  void _fetchClubs() async {
    final request = Provider.of<CookieRequest>(context, listen: false);
    final response = await request.get(
        'https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/accounts/api/admin/clubs/');
    setState(() => clubs = response['data']);
  }

  InputDecoration _inputDecor(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Add Player",
            style: AppTextStyles.h3.copyWith(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            DropdownButtonFormField<String>(
              value: selectedClubId,
              hint: const Text("Pilih Klub"),
              items: clubs
                  .map<DropdownMenuItem<String>>((c) => DropdownMenuItem(
                      value: c['id'].toString(), child: Text(c['name'])))
                  .toList(),
              onChanged: (v) => setState(() => selectedClubId = v!),
              validator: (v) => v == null ? "Wajib pilih klub" : null,
              decoration: _inputDecor("Club"),
            ),
            const SizedBox(height: 12),
            TextFormField(
                decoration: _inputDecor("Nama Pemain"),
                onChanged: (v) => nama = v),
            const SizedBox(height: 12),
            TextFormField(
                decoration: _inputDecor("Posisi"),
                onChanged: (v) => position = v),
            const SizedBox(height: 12),
            TextFormField(
                decoration: _inputDecor("Negara"),
                onChanged: (v) => negara = v),
            const SizedBox(height: 12),
            TextFormField(
                decoration: _inputDecor("Umur"),
                keyboardType: TextInputType.number,
                onChanged: (v) => umur = int.tryParse(v) ?? 0),
            const SizedBox(height: 12),
            TextFormField(
                decoration: _inputDecor("Market Value"),
                keyboardType: TextInputType.number,
                onChanged: (v) => marketValue = int.tryParse(v) ?? 0),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: TextFormField(
                      decoration: _inputDecor("Goals"),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => goal = int.tryParse(v) ?? 0)),
              const SizedBox(width: 10),
              Expanded(
                  child: TextFormField(
                      decoration: _inputDecor("Assists"),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => asis = int.tryParse(v) ?? 0)),
            ]),
            const SizedBox(height: 12),
            TextFormField(
                decoration: _inputDecor("Matches"),
                keyboardType: TextInputType.number,
                onChanged: (v) => match = int.tryParse(v) ?? 0),
            const SizedBox(height: 12),
            TextFormField(
                decoration: _inputDecor("Thumbnail URL"),
                onChanged: (v) => thumbnail = v),
            const SizedBox(height: 30),
            PremiereButton(
              text: "SAVE PLAYER",
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final response = await request.postJson(
                      "https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/accounts/api/admin/players/create/",
                      jsonEncode({
                        "club_id": selectedClubId,
                        "nama_pemain": nama,
                        "position": position,
                        "umur": umur,
                        "market_value": marketValue,
                        "negara": negara,
                        "jumlah_goal": goal,
                        "jumlah_asis": asis,
                        "jumlah_match": match,
                        "thumbnail": thumbnail
                      }));
                  if (context.mounted && response['status'] == true) {
                    Navigator.pop(context);
                  }
                }
              },
            )
          ],
        ),
      ),
    );
  }
}
