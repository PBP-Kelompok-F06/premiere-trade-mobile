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
  Future<List<dynamic>> fetchPlayers(CookieRequest request) async {
    final response = await request.get(
        'https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/accounts/api/admin/players/');
    
    if (response['status'] == true) {
      return response['data'];
    } else {
      throw Exception("Gagal mengambil data");
    }
  }

  void deletePlayer(CookieRequest request, String id) async {
    final response = await request.post(
        'https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/accounts/api/admin/players/$id/delete/',
        {});

    if (mounted && response['status'] == true) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pemain berhasil dihapus")),
      );
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
        onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const PlayerFormPage())) // Mode Add
            .then((_) => setState(() {})),
      ),
      body: FutureBuilder(
        future: fetchPlayers(request),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
                    backgroundImage: (p['thumbnail'] != null &&
                            p['thumbnail'].toString().isNotEmpty)
                        ? NetworkImage(p['thumbnail'])
                        : null,
                    child: (p['thumbnail'] == null ||
                            p['thumbnail'].toString().isEmpty)
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(
                    p['nama_pemain'],
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("${p['position']} • ${p['club_name']}",
                      style: AppTextStyles.caption),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // TOMBOL EDIT
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            // Kirim data player ke form (perlu data lengkap)
                            builder: (_) => PlayerFormPage(playerToEdit: p),
                          ),
                        ).then((_) => setState(() {})),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                        onPressed: () => deletePlayer(request, p['id']),
                      ),
                    ],
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

// === FORM REUSABLE UNTUK PLAYER ===
class PlayerFormPage extends StatefulWidget {
  final Map<String, dynamic>? playerToEdit; // Jika ada, mode Edit

  const PlayerFormPage({super.key, this.playerToEdit});

  @override
  State<PlayerFormPage> createState() => _PlayerFormPageState();
}

class _PlayerFormPageState extends State<PlayerFormPage> {
  final _formKey = GlobalKey<FormState>();
  String nama = "", position = "", negara = "", thumbnail = "";
  int umur = 0, marketValue = 0, goal = 0, asis = 0, match = 0;
  String? selectedClubId;
  List<dynamic> clubs = [];
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    isEditing = widget.playerToEdit != null;
    _fetchClubs();

    if (isEditing) {
      // PERHATIAN: Pastikan data 'playerToEdit' dari list view memiliki semua field ini.
      // Jika list view hanya partial data, sebaiknya fetch detail player by ID dulu.
      // Asumsi: List view sudah mengirim data yang cukup atau kita mapping dari sana.
      final p = widget.playerToEdit!;
      nama = p['nama_pemain'] ?? "";
      position = p['position'] ?? "";
      negara = p['negara'] ?? ""; // Pastikan backend kirim ini di list
      thumbnail = p['thumbnail'] ?? "";
      umur = p['umur'] ?? 0; // Pastikan backend kirim ini
      marketValue = p['market_value'] ?? 0;
      // Club ID mungkin tidak dikirim di list view (hanya nama club).
      // Untuk UI sederhana, user pilih club ulang jika ingin edit, atau biarkan kosong.
    }
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
        title: Text(isEditing ? "Edit Player" : "Add Player",
            style: AppTextStyles.h3.copyWith(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            DropdownButtonFormField <String>(
              value: selectedClubId,
              hint: const Text("Pilih Klub"),
              items: clubs
                  .map<DropdownMenuItem<String>>((c) => DropdownMenuItem(
                      value: c['id'].toString(), child: Text(c['name'])))
                  .toList(),
              onChanged: (v) => setState(() => selectedClubId = v!),
              decoration: _inputDecor("Club"),
            ),
            const SizedBox(height: 12),
            TextFormField(
                initialValue: nama,
                decoration: _inputDecor("Nama Pemain"),
                onChanged: (v) => nama = v),
            const SizedBox(height: 12),
            TextFormField(
                initialValue: position,
                decoration: _inputDecor("Posisi"),
                onChanged: (v) => position = v),
            const SizedBox(height: 12),
            TextFormField(
                initialValue: negara,
                decoration: _inputDecor("Negara"),
                onChanged: (v) => negara = v),
            const SizedBox(height: 12),
            TextFormField(
                initialValue: umur > 0 ? umur.toString() : "",
                decoration: _inputDecor("Umur"),
                keyboardType: TextInputType.number,
                onChanged: (v) => umur = int.tryParse(v) ?? 0),
            const SizedBox(height: 12),
            TextFormField(
                initialValue: marketValue > 0 ? marketValue.toString() : "",
                decoration: _inputDecor("Market Value"),
                keyboardType: TextInputType.number,
                onChanged: (v) => marketValue = int.tryParse(v) ?? 0),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: TextFormField(
                      initialValue: goal.toString(),
                      decoration: _inputDecor("Goals"),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => goal = int.tryParse(v) ?? 0)),
              const SizedBox(width: 10),
              Expanded(
                  child: TextFormField(
                      initialValue: asis.toString(),
                      decoration: _inputDecor("Assists"),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => asis = int.tryParse(v) ?? 0)),
            ]),
            const SizedBox(height: 12),
            TextFormField(
                initialValue: match.toString(),
                decoration: _inputDecor("Matches"),
                keyboardType: TextInputType.number,
                onChanged: (v) => match = int.tryParse(v) ?? 0),
            const SizedBox(height: 12),
            TextFormField(
                initialValue: thumbnail,
                decoration: _inputDecor("Thumbnail URL"),
                onChanged: (v) => thumbnail = v),
            const SizedBox(height: 30),
            PremiereButton(
              text: isEditing ? "UPDATE PLAYER" : "SAVE PLAYER",
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  String url = isEditing
                      ? "https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/accounts/api/admin/players/${widget.playerToEdit!['id']}/edit/"
                      : "https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/accounts/api/admin/players/create/";

                  final response = await request.postJson(
                      url,
                      jsonEncode({
                        "club_id": selectedClubId, // Pastikan pilih club jika edit
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