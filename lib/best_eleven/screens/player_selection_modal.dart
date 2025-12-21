import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../models/best_eleven_models.dart';
import '../services/best_eleven_service.dart';

String getProxiedUrl(String? url) {
  if (url == null || url.isEmpty) return "";
  // Jika URL sudah lengkap (http/https), gunakan langsung
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return "https://wsrv.nl/?url=$url&output=png";
  }
  // Jika URL relatif, tambahkan base URL dari Django
  return "https://wsrv.nl/?url=https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id$url&output=png";
}

class PlayerSelectionModal extends StatefulWidget {
  final List<BestElevenClub> clubs;
  final String? requiredPosition; // Posisi yang dibutuhkan untuk slot
  final String? slotId; // ID slot yang dipilih

  const PlayerSelectionModal({
    super.key,
    required this.clubs,
    this.requiredPosition,
    this.slotId,
  });

  @override
  State<PlayerSelectionModal> createState() => _PlayerSelectionModalState();
}

class _PlayerSelectionModalState extends State<PlayerSelectionModal> {
  BestElevenClub? _selectedClub;
  List<BestElevenPlayer> _players = [];
  bool _isLoadingPlayers = false;

  void _onClubChanged(BestElevenClub? club) {
    setState(() {
      _selectedClub = club;
      _isLoadingPlayers = true;
      _players = []; // Clear previous
    });
    
    if (club != null) {
      _fetchPlayers(club.id);
    } else {
      // If no club selected, fetch all players
      _fetchPlayers(null);
    }
  }

  // Mapping posisi Indonesia ke role yang valid (sesuai Django)
  static const Map<String, List<String>> _positionRoleMap = {
    'Kiper': ['Kiper'],
    'Bek-Tengah': ['Bek-Tengah'],
    'Bek-Kanan': ['Bek-Kanan'],
    'Bek-Kiri': ['Bek-Kiri'],
    'Gel. Bertahan': ['Gel. Bertahan', 'Gel. Tengah'],
    'Gel. Serang': ['Gel. Serang', 'Gel. Tengah', 'Sayap Kiri', 'Sayap Kanan'],
    'Gel. Tengah': ['Gel. Tengah', 'Gel. Bertahan', 'Gel. Serang'],
    'Sayap Kiri': ['Sayap Kiri', 'Gel. Serang', 'Bek-Kiri'],
    'Sayap Kanan': ['Sayap Kanan', 'Gel. Serang', 'Bek-Kanan'],
    'Penyerang': ['Penyerang'],
    'Depan-Tengah': ['Penyerang']
  };

  bool _isValidPositionForSlot(String playerPosition, String? requiredRole) {
    if (requiredRole == null) return true;
    
    final playerRoles = _positionRoleMap[playerPosition];
    if (playerRoles == null) return false;
    
    return playerRoles.contains(requiredRole);
  }

  Future<void> _fetchPlayers(int? clubId) async {
    final request = context.read<CookieRequest>();
    try {
      print('Fetching players for club: $clubId');
      final service = BestElevenService(request);
      final allPlayers = await service.fetchPlayers(clubId: clubId);
      print('Received ${allPlayers.length} players');
      
      // Filter berdasarkan posisi jika diperlukan
      List<BestElevenPlayer> filteredPlayers = allPlayers;
      if (widget.requiredPosition != null) {
        filteredPlayers = allPlayers.where((p) => 
          _isValidPositionForSlot(p.position, widget.requiredPosition)
        ).toList();
        print('Filtered to ${filteredPlayers.length} players for position ${widget.requiredPosition}');
      }
      
      if (mounted) {
        setState(() {
          _players = filteredPlayers;
          _isLoadingPlayers = false;
        });
        
        if (filteredPlayers.isEmpty) {
          final message = widget.requiredPosition != null
              ? 'Tidak ada pemain dengan posisi ${widget.requiredPosition} ditemukan.'
              : 'Tidak ada pemain ditemukan untuk klub ini.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error fetching players: $e');
      if (mounted) {
        setState(() {
          _isLoadingPlayers = false;
          _players = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading players: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _formatMarketValue(double? value) {
    if (value == null || value == 0) {
      return '€0';
    }
    final intValue = value.toInt();
    if (intValue >= 1000) {
      return '€${(intValue / 1000).toStringAsFixed(1)}B';
    }
    return '€${intValue}M';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilih Pemain',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (widget.requiredPosition != null && widget.slotId != null)
                      Text(
                        'Slot: ${widget.slotId} - Posisi: ${widget.requiredPosition}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Pilih Klub', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<BestElevenClub?>(
            value: _selectedClub,
            items: [
              const DropdownMenuItem<BestElevenClub?>(
                value: null,
                child: Text('Semua Klub'),
              ),
              ...widget.clubs.map((club) {
                return DropdownMenuItem<BestElevenClub?>(
                  value: club,
                  child: Text(club.name),
                );
              }),
            ],
            onChanged: _onClubChanged,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            hint: const Text('Pilih Klub Asal'),
          ),
          const SizedBox(height: 16),
          const Text('Daftar Pemain', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoadingPlayers
                ? const Center(child: CircularProgressIndicator())
                : _players.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_off, size: 48, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Tidak ada pemain ditemukan.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _players.length,
                            itemBuilder: (context, index) {
                              final player = _players[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.indigo,
                                    backgroundImage: (player.profileImageUrl != null && player.profileImageUrl!.isNotEmpty)
                                        ? NetworkImage(getProxiedUrl(player.profileImageUrl))
                                        : null,
                                    onBackgroundImageError: (exception, stackTrace) {
                                      // Error loading image, will show child instead
                                    },
                                    child: (player.profileImageUrl == null || player.profileImageUrl!.isEmpty)
                                        ? const Icon(Icons.person, color: Colors.white)
                                        : null,
                                  ),
                                  title: Text(
                                    player.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text('${player.position} • ${player.nationality ?? "-"}'),
                                      if (player.clubName != null && player.clubName!.isNotEmpty)
                                        Text(
                                          player.clubName!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _formatMarketValue(player.marketValue),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.pop(context, player);
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
