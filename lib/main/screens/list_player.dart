import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../models/club_model.dart';
import '../models/player_model.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/player_card.dart'; // Pakai Widget yang kita buat sebelumnya

class ListPlayerPage extends StatefulWidget {
  final Club club;

  const ListPlayerPage({super.key, required this.club});

  @override
  State<ListPlayerPage> createState() => _ListPlayerPageState();
}

class _ListPlayerPageState extends State<ListPlayerPage> {
  Future<List<Player>> fetchPlayers(CookieRequest request) async {
    // URL Endpoint API player by club
    // Pastikan ID club dikonversi ke String jika perlu
    final response = await request
        .get('http://localhost:8000/api/club/${widget.club.pk}/players/');

    var data = response;
    List<Player> listPlayer = [];
    for (var d in data) {
      if (d != null) {
        listPlayer.add(Player.fromJson(d));
      }
    }
    return listPlayer;
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
          } else {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("Belum ada pemain di klub ini."));
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
          }
        },
      ),
    );
  }
}
