import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../account/screens/login.dart';
import '../../best_eleven/screens/best_eleven_list_page.dart';
import 'list_player.dart';
import '../models/club_model.dart';

String getProxiedUrl(String? url) {
  if (url == null || url.isEmpty) return "";
  return "https://wsrv.nl/?url=$url&output=png";
}

class ItemHomepage {
  final String name;
  final IconData icon;
  final Color? color;

  ItemHomepage(this.name, this.icon, {this.color});
}

class ItemCard extends StatelessWidget {
  final ItemHomepage item;
  final CookieRequest request;

  const ItemCard(this.item, {super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.color ?? Theme.of(context).colorScheme.secondary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () async {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text("Kamu telah menekan tombol ${item.name}!"),
              ),
            );

          // Navigate ke route yang sesuai
          if (item.name == "Best Eleven") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BestElevenListPage()),
            );
          } else if (item.name == "Daftar Klub") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ClubListPage()),
            );
          } else if (item.name == "Logout") {
            final response = await request.logout(
              "http://localhost:8000/auth/logout/",
            );
            String message = response["message"];
            if (context.mounted) {
              if (response['status']) {
                String uname = response["username"];
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("$message See you again, $uname.")),
                );
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              }
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: Colors.white, size: 30.0),
                const Padding(padding: EdgeInsets.all(3)),
                Text(
                  item.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    
    final List<ItemHomepage> items = [
      ItemHomepage("Best Eleven", Icons.sports_soccer, color: AppColors.primary),
      ItemHomepage("Daftar Klub", Icons.shield, color: Colors.blue),
      ItemHomepage("Logout", Icons.logout, color: Colors.red),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Premiere Trade", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return ItemCard(items[index], request: request);
          },
        ),
      ),
    );
  }
}

// Halaman untuk menampilkan daftar klub
class ClubListPage extends StatefulWidget {
  const ClubListPage({super.key});

  @override
  State<ClubListPage> createState() => _ClubListPageState();
}

class _ClubListPageState extends State<ClubListPage> {
  Future<List<Club>> fetchClubs(CookieRequest request) async {
    try {
      final response = await request.get('http://localhost:8000/api/clubs/');
      
      if (response == null) {
        return [];
      }
      
      List<Club> listClub = [];
      if (response is List) {
        for (var d in response) {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Klub", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
      ),
      body: FutureBuilder(
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
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "Tidak ada data klub.",
                    style: TextStyle(color: Colors.grey, fontSize: 20),
                  ),
                ],
              ),
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
        },
      ),
    );
  }
}
