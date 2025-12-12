import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:premiere_trade/rumor/models/rumor_model.dart';
import 'package:premiere_trade/rumor/screens/edit_rumor_form.dart'; 

String getProxiedUrl(String? url) {
  if (url == null || url.isEmpty) return "";
  return "https://wsrv.nl/?url=$url&output=png";
}

class RumorDetailPage extends StatelessWidget {
  final Rumor rumor;

  const RumorDetailPage({super.key, required this.rumor});

  Future<void> _handleAction(BuildContext context, String url, String successMessage) async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.post(url, {});
      if (context.mounted) {
        if (response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
          Navigator.pop(context, true); 
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: ${response['message']}")));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String formatCurrency(int value) {
      return "Rp${(value / 1000000000).toStringAsFixed(1)}M";
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Detail Rumor")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- HEADER: STATUS & WAKTU ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(rumor.status),
                Text(
                  rumor.createdAt,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- SECTION 1: FOTO & NAMA PEMAIN ---
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(getProxiedUrl(rumor.pemainThumbnail)),
              backgroundColor: Colors.grey[200],
            ),
            const SizedBox(height: 12),
            Text(
              rumor.pemainNama,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              "${rumor.pemainPosisi} • ${rumor.pemainNegara}",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            
            const SizedBox(height: 24),

            // --- SECTION 2: TRANSFER FLOW ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildClubInfo(rumor.clubAsalLogo, rumor.clubAsalNama),
                  const Icon(Icons.arrow_forward, size: 30, color: Colors.grey),
                  _buildClubInfo(rumor.clubTujuanLogo, rumor.clubTujuanNama),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // --- SECTION 3: STATISTIK PEMAIN ---
            Row(
              children: [
                _buildStatCard("Market Value", formatCurrency(rumor.pemainValue)),
                const SizedBox(width: 12),
                _buildStatCard("Usia", "${rumor.pemainUmur} Tahun"),
              ],
            ),            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),

            // --- SECTION 4: KONTEN ---
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Berita Selengkapnya:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple[800]),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Text(
                rumor.content,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),
            
            const SizedBox(height: 15),

            // --- SECTION 5: TOMBOL AKSI ---
            if (rumor.isAdmin) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                   ElevatedButton.icon(
                     onPressed: () => _handleAction(
                       context, 
                       "http://localhost:8000/rumors/${rumor.id}/verify-flutter/", 
                       "Rumor berhasil diverifikasi!"
                     ),
                     icon: const Icon(Icons.check),
                     label: const Text("Verify"),
                     style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                   ),
                   ElevatedButton.icon(
                     onPressed: () => _handleAction(
                       context, 
                       "http://localhost:8000/rumors/${rumor.id}/deny-flutter/", 
                       "Rumor berhasil ditolak!"
                     ),
                     icon: const Icon(Icons.close),
                     label: const Text("Deny"),
                     style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                   ),
                ],
              )
            ] else if (rumor.isAuthor) ...[
               Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                   // [UPDATE] Tombol Edit
                   OutlinedButton.icon(
                     onPressed: () async {
                       // Navigasi ke Edit Page
                       final result = await Navigator.push(
                         context,
                         MaterialPageRoute(
                           builder: (context) => EditRumorFormPage(rumor: rumor),
                         ),
                       );

                       // Jika result true (berhasil edit), kita pop halaman detail ini juga
                       // agar halaman List me-refresh data dan menampilkan data terbaru
                       if (result == true && context.mounted) {
                         Navigator.pop(context, true);
                       }
                     },
                     icon: const Icon(Icons.edit),
                     label: const Text("Edit"),
                   ),
                   OutlinedButton.icon(
                     onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text("Hapus Rumor"),
                              content: const Text("Apakah Anda yakin ingin menghapus rumor ini?"),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _handleAction(
                                      context, 
                                      "http://localhost:8000/rumors/${rumor.id}/delete-flutter/", 
                                      "Rumor berhasil dihapus!"
                                    );
                                  },
                                  child: const Text("Hapus", style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            );
                          },
                        );
                     },
                     icon: const Icon(Icons.delete, color: Colors.red),
                     label: const Text("Delete", style: TextStyle(color: Colors.red)),
                     style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                   ),
                ],
              )
            ],
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER ---
  Widget _buildClubInfo(String url, String name) {
    return Column(
      children: [
        Image.network(getProxiedUrl(url), height: 50, width: 50, errorBuilder: (_,__,___) => const Icon(Icons.shield, size: 50)),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.purple[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    String text;
    
    if (status == 'verified') {
      color = Colors.green;
      icon = Icons.check_circle;
      text = "Verified";
    } else if (status == 'denied') {
      color = Colors.red;
      icon = Icons.cancel;
      text = "Denied";
    } else {
      color = Colors.orange;
      icon = Icons.access_time_filled;
      text = "Pending";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}