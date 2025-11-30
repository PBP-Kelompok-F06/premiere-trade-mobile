import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../models/club_model.dart'; // Pastikan path model benar
import '../../core/constants/colors.dart';
import '../../account/screens/login.dart';
import 'list_player.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  // Fungsi Fetch menggunakan CookieRequest
  Future<List<Club>> fetchClubs(CookieRequest request) async {
    // Sesuaikan URL
    final response = await request.get('http://localhost:8000/api/clubs/');

    // Karena request.get sudah mengembalikan List Dynamic / Map Dynamic,
    // kita perlu mapping manual sedikit berbeda dari http.get biasa
    // atau kita pastikan data yang masuk valid
    var data = response;

    List<Club> listClub = [];
    for (var d in data) {
      if (d != null) {
        listClub.add(Club.fromJson(d));
      }
    }
    return listClub;
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Premiere Trade", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        actions: [
          // Tombol Logout di AppBar
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              final response = await request.logout(
                  "http://localhost:8000/auth/logout/"); // Endpoint logout Django
              String message = response["message"];
              if (context.mounted) {
                if (response['status']) {
                  String uname = response["username"];
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("$message Sampai jumpa, $uname."),
                  ));
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Logout gagal"),
                  ));
                }
              }
            },
          ),
        ],
      ),
      // Drawer (Menu Samping) - Sesuai Tutorial PBP
      drawer: Drawer(
        child: ListView(
          children: [
            const UserAccountsDrawerHeader(
              accountName: Text("User Premiere Trade"), 
              accountEmail: Text("user@ui.ac.id"),
              decoration: BoxDecoration(color: AppColors.primary),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Halaman Utama'),
              onTap: () => Navigator.pop(context),
            ),
            // Tambahkan menu lain di sini (Community, Rumors, dll)
          ],
        ),
      ),
      body: FutureBuilder(
        future: fetchClubs(request),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          } else {
            if (!snapshot.hasData) {
              return const Column(
                children: [
                  Text(
                    "Tidak ada data klub.",
                    style: TextStyle(color: Color(0xff59A5D8), fontSize: 20),
                  ),
                  SizedBox(height: 8),
                ],
              );
            } else {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.length,
                itemBuilder: (_, index) {
                  Club club = snapshot.data![index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ListPlayerPage(club: club),
                        ),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            // Gambar logo jika ada, kalau null pakai icon
                             SizedBox(
                                width: 50, height: 50,
                                child: (club.logoUrl != null && club.logoUrl!.isNotEmpty)
                                    ? Image.network(club.logoUrl!, errorBuilder: (_,__,___) => const Icon(Icons.shield))
                                    : const Icon(Icons.shield, color: AppColors.primary, size: 40),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                club.name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          }
        },
      ),
    );
  }
}