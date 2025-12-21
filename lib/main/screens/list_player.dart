import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../models/club_model.dart';
import '../models/player_model.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/player_card.dart'; 

class ListPlayerPage extends StatefulWidget {
  final Club club;

  const ListPlayerPage({super.key, required this.club});

  @override
  State<ListPlayerPage> createState() => _ListPlayerPageState();
}

class _ListPlayerPageState extends State<ListPlayerPage> {
  Future<List<Player>> fetchPlayers(CookieRequest request) async {
    // URL Endpoint API player by club
    // To connect Android emulator with Django on localhost, use URL http://10.0.2.2:8000
    // If you using chrome, use URL http://localhost:8000
    try {
      final response = await request.get(
        'https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/api/club/${widget.club.pk}/players/',
      );

      if (response == null) {
        print('Response is null');
        return [];
      }

      List<Player> listPlayer = [];
      
      // Handle jika response adalah List
      if (response is List) {
        for (var d in response) {
          if (d != null) {
            try {
              listPlayer.add(Player.fromJson(d));
            } catch (e) {
              print('Error parsing player: $e');
            }
          }
        }
      } else {
        print('Unexpected response type: ${response.runtimeType}');
      }
      
      return listPlayer;
    } catch (e) {
      print('Error fetching players: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.club.name, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder(
        future: fetchPlayers(request),
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
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "Belum ada pemain di klub ini.",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          } else {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.length,
              itemBuilder: (_, index) {
                Player player = snapshot.data![index];
                // Menggunakan PlayerCard dari Design System
                return PlayerCard(
                  playerName: player.name,
                  clubName: widget.club.name,
                  position: player.position,
                  price:
                      "€ ${player.marketValue}", // Format mata uang sederhana
                  imageUrl:
                      player.thumbnail ?? "https://via.placeholder.com/150",
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("Kamu memilih ${player.name}")));
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
