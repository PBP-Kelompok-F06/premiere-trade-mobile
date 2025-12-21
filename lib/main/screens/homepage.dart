import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../models/club_model.dart';
import '../../core/constants/colors.dart';
import '../../account/screens/login.dart';
import 'list_player.dart';

String getProxiedUrl(String? url) {
  if (url == null || url.isEmpty) return "";
  return "https://wsrv.nl/?url=$url&output=png";
}

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  // Fungsi Fetch menggunakan CookieRequest
  Future<List<Club>> fetchClubs(CookieRequest request) async {
    // Sesuaikan URL
    try {
      final response = await request.get('https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/api/clubs/');

      if (response == null) {
        return [];
      }

      var data = response;

      List<Club> listClub = [];
      if (data is List) {
        for (var d in data) {
          if (d != null) {
            try {
              listClub.add(Club.fromJson(d));
            } catch (e) {
              print('Error parsing club: $e');
            }
          }
        }
      }
      return listClub;
    } catch (e) {
      print('Error fetching clubs: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return FutureBuilder(
        future: fetchClubs(request),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    "Error: ${snapshot.error}",
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Retry
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          } else if (snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          } else {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                              width: 50,
                              height: 50,
                              child: Image.network(
                                getProxiedUrl(club.logoUrl),
                                width: 60,
                                height: 60,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.shield,
                                      size: 60, color: Colors.grey);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                club.name,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
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
      );
  }
}
