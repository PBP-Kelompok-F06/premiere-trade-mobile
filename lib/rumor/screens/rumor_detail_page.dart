import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:premiere_trade/rumor/models/rumor_model.dart';
import 'package:premiere_trade/rumor/screens/edit_rumor_form.dart';

String getProxiedUrl(String? url) {
  if (url == null || url.isEmpty) return "";
  return "https://wsrv.nl/?url=$url&output=png";
}

// UBAH JADI STATEFUL WIDGET
class RumorDetailPage extends StatefulWidget {
  final Rumor rumor;

  const RumorDetailPage({super.key, required this.rumor});

  @override
  State<RumorDetailPage> createState() => _RumorDetailPageState();
}

class _RumorDetailPageState extends State<RumorDetailPage> {
  
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _incrementView();
    });
  }

  Future<void> _incrementView() async {
    final request = context.read<CookieRequest>();
    try {
      await request.post(
        "https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/rumors/${widget.rumor.id}/increment-view-flutter/", 
        {}
      );
    } catch (e) {
      print("Gagal update views: $e");
    }
  }

  // LOGIC TIME SINCE 
  String getTimeSince(String createdAt) {
    try {
      DateTime created = DateTime.parse(createdAt).toLocal();
      DateTime now = DateTime.now();
      Duration difference = now.difference(created);

      if (difference.inSeconds < 60) {
        return '0 menit lalu';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} menit lalu';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} jam lalu';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} hari lalu';
      } else if (difference.inDays < 30) {
        int weeks = difference.inDays ~/ 7;
        return '$weeks minggu lalu';
      } else if (difference.inDays < 365) {
        int months = difference.inDays ~/ 30;
        int remainingWeeks = (difference.inDays % 30) ~/ 7;
        if (remainingWeeks > 0) {
          return '$months bulan, $remainingWeeks minggu lalu';
        }
        return '$months bulan lalu';
      } else {
        int years = difference.inDays ~/ 365;
        int remainingMonths = (difference.inDays % 365) ~/ 30;
        if (remainingMonths > 0) {
          return '$years tahun, $remainingMonths bulan lalu';
        }
        return '$years tahun lalu';
      }
    } catch (e) {
      return createdAt;
    }
  }

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
            // HEADER: STATUS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(widget.rumor.status),
              ],
            ),
            const SizedBox(height: 20),

            // --- SECTION 1: FOTO & NAMA PEMAIN ---
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(getProxiedUrl(widget.rumor.pemainThumbnail)),
              backgroundColor: Colors.grey[200],
            ),
            const SizedBox(height: 12),
            Text(
              widget.rumor.pemainNama,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            Text(
              "${widget.rumor.pemainPosisi} • ${widget.rumor.pemainNegara}",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            
            const SizedBox(height: 24),

            // SECTION 2: TRANSFER FLOW 
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
                  _buildClubInfo(widget.rumor.clubAsalLogo, widget.rumor.clubAsalNama),
                  const Icon(Icons.arrow_forward, size: 30, color: Colors.grey),
                  _buildClubInfo(widget.rumor.clubTujuanLogo, widget.rumor.clubTujuanNama),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // SECTION 3: PROFIL PEMAIN 
            Row(
              children: [
                _buildStatCard("Market Value", formatCurrency(widget.rumor.pemainValue)),
                const SizedBox(width: 12),
                _buildStatCard("Usia", "${widget.rumor.pemainUmur} Tahun"),
              ],
            ),            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),

            //  SECTION 4: KONTEN
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Deskripsi Rumor",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.purple[800]),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "${widget.rumor.pemainNama} transfer dari ${widget.rumor.clubAsalNama} ke ${widget.rumor.clubTujuanNama}",
                style: TextStyle(fontSize: 13,fontStyle: FontStyle.italic, color: Colors.grey[600]),
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
                widget.rumor.content,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),
            
            const SizedBox(height: 12),

            // SECTION: AUTHOR, VIEWS & TIME SINCE 
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // KIRI: Author & Views
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.account_circle_rounded, color: Colors.purple, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.rumor.author,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('•', style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(width: 6),
                      Text(
                        // Kita tampilkan views yang lama dulu karena update terjadi async
                        '${widget.rumor.views} views',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),

                // KANAN: Time Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 12, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        getTimeSince(widget.rumor.createdAt),
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // SECTION 5: TOMBOL AKSI
            if (widget.rumor.isAdmin) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0, 
                runSpacing: 8.0, 
                alignment: WrapAlignment.spaceEvenly,
                children: [
                   // TOMBOL VERIFY
                   ElevatedButton.icon(
                     onPressed: () => _handleAction(
                       context, 
                       "https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/rumors/${widget.rumor.id}/verify-flutter/", 
                       "Rumor berhasil diverifikasi!"
                     ),
                     icon: const Icon(Icons.check),
                     label: const Text("Verify"),
                     style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                   ),
                   
                   // TOMBOL DENY
                   ElevatedButton.icon(
                     onPressed: () => _handleAction(
                       context, 
                       "https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/rumors/${widget.rumor.id}/deny-flutter/", 
                       "Rumor berhasil ditolak!"
                     ),
                     icon: const Icon(Icons.close),
                     label: const Text("Deny"),
                     style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                   ),

                   // TOMBOL REVERT
                   if (widget.rumor.status != 'pending')
                   ElevatedButton.icon(
                     onPressed: () => _handleAction(
                       context, 
                       "https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/rumors/${widget.rumor.id}/revert-flutter/", 
                       "Status dikembalikan ke Menunggu Verifikasi!"
                     ),
                     icon: const Icon(Icons.undo),
                     label: const Text("Revert"),
                     style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                   ),
                ],
              )
            ] else if (widget.rumor.isAuthor) ...[
               Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                   OutlinedButton.icon(
                     onPressed: () async {
                       final result = await Navigator.push(
                         context,
                         MaterialPageRoute(
                           builder: (context) => EditRumorFormPage(rumor: widget.rumor),
                         ),
                       );

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
                                      "https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/rumors/${widget.rumor.id}/delete-flutter/", 
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

  // WIDGET HELPER 
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
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
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
      text = "Menunggu Verifikasi";
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