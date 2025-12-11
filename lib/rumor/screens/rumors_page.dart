import "package:flutter/material.dart";
import "package:pbp_django_auth/pbp_django_auth.dart";
import 'package:provider/provider.dart';
import 'package:premiere_trade/rumor/models/rumor_model.dart';

class RumorsPage extends StatefulWidget {
  const RumorsPage({super.key});

  @override
  State<RumorsPage> createState() => _RumorsPageState();
}

class _RumorsPageState extends State<RumorsPage> {
  Future<List<Rumor>> fetchRumors(CookieRequest request) async {
    final response = await request.get('http://localhost:8000/rumors/json/');
    
    List<Rumor> listRumor = [];
    for (var d in response) {
      if (d != null) {
        listRumor.add(Rumor.fromJson(d));
      }
    }
    return listRumor;
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      body: FutureBuilder<List<Rumor>>(
        future: fetchRumors(request),
        builder: (context, AsyncSnapshot<List<Rumor>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final rumors = snapshot.data;
          if (rumors == null || rumors.isEmpty) {
            return const Center(
              child: Text(
                "Belum ada rumor transfer",
                style: TextStyle(fontSize: 20, color: Color(0xff59A5D8)),
              ),
            );
          }

          return ListView.builder(
            itemCount: rumors.length,
            itemBuilder: (context, index) {
              final rumor = rumors[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: rumor.status == 'verified'
                              ? Colors.green
                              : rumor.status == 'denied'
                                  ? Colors.red
                                  : Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          rumor.status.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        rumor.title,
                        style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      Text("By: ${rumor.author} | ${rumor.createdAt}"),
                      const Divider(),
                      Text(rumor.content),
                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("${rumor.views} views"),
                          if (rumor.isAuthor)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                // TODO: implement delete
                              },
                            )
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      // Tombol melayang di pojok kanan bawah untuk menambah rumor
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigasi ke halaman form (masih dikomentar karena belum di-import)
          // Navigator.push(context, MaterialPageRoute(builder: (context) => const RumorFormPage()));
        },
        tooltip: 'Buat Rumor',
        child: const Icon(Icons.add), // Ikon tambah (+)
      ),
    );
  }
}