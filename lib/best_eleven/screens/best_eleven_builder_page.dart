import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/best_eleven_models.dart';
import '../services/best_eleven_service.dart';

class BestElevenBuilderPage extends StatefulWidget {
  final int? formationId;

  const BestElevenBuilderPage({super.key, this.formationId});

  @override
  State<BestElevenBuilderPage> createState() => _BestElevenBuilderPageState();
}

class _BestElevenBuilderPageState extends State<BestElevenBuilderPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _playerSearchController = TextEditingController();
  
  // Color theme
  static const Color _primaryPurple = Color(0xFF6B46C1);
  static const Color _accentPink = Color(0xFFD946A6);
  static const Color _cardBorder = Color(0xFF4A2C7C);
  static const Color _cardBg = Color(0xFFF5F8FC);
  static const Color _textLight = Color(0xFF4A2C7C);
  static const Color _textMuted = Color(0xFF2E0F32);
  
  List<BestElevenClub> _clubs = [];
  List<BestElevenFormation> _history = [];
  List<BestElevenPlayer> _allPlayers = [];
  List<BestElevenPlayer> _filteredPlayers = [];
  
  String _selectedLayout = '4-3-3';
  final List<String> _layouts = ['4-3-3', '4-4-2', '3-5-2', '4-2-3-1'];
  int? _selectedClubId;
  String? _selectedSlotId;
  int? _currentFormationId;
  
  // Map slotId to Player
  final Map<String, BestElevenPlayer> _selectedPlayers = {};
  bool _isLoading = true;
  String? _statusMessage;
  bool _isStatusError = false;
  
  // Modal state
  bool _showDetailModal = false;
  BestElevenFormation? _detailFormation;
  List<BestElevenPlayer> _detailPlayers = [];
  
  // Filter position state
  String? _currentFilterPositionCode;
  
  // Formation layouts mapping
  static const Map<String, List<String>> _formationLayouts = {
    '4-3-3': ['GK', 'LB', 'LCB', 'RCB', 'RB', 'LCM', 'CM', 'RCM', 'LW', 'ST', 'RW'],
    '4-4-2': ['GK', 'LB', 'LCB', 'RCB', 'RB', 'LM', 'LCM', 'RCM', 'RM', 'LST', 'RST'],
    '3-5-2': ['GK', 'LCB', 'CB', 'RCB', 'LWB', 'LCM', 'RCM', 'RWB', 'CAM', 'LST', 'RST'],
    '4-2-3-1': ['GK', 'LB', 'LCB', 'RCB', 'RB', 'LDM', 'RDM', 'LAM', 'CAM', 'RAM', 'ST'],
  };
  
  // Slot position mapping
  static const Map<String, String> _slotPositionMap = {
    'GK': 'Kiper',
    'LB': 'Bek-Kiri', 'LWB': 'Bek-Kiri',
    'LCB': 'Bek-Tengah', 'CB': 'Bek-Tengah', 'RCB': 'Bek-Tengah',
    'RB': 'Bek-Kanan', 'RWB': 'Bek-Kanan',
    'LDM': 'Gel. Bertahan', 'RDM': 'Gel. Bertahan',
    'LM': 'Sayap Kiri', 'LCM': 'Gel. Tengah', 'CM': 'Gel. Tengah', 
    'RCM': 'Gel. Tengah', 'RM': 'Sayap Kanan',
    'LAM': 'Sayap Kiri', 'CAM': 'Gel. Serang', 'RAM': 'Sayap Kanan',
    'LW': 'Sayap Kiri', 'RW': 'Sayap Kanan', 
    'LST': 'Penyerang', 'ST': 'Penyerang', 'RST': 'Penyerang',
  };
  
  // Indonesian position to compatible roles mapping (sesuai template Django)
  static const Map<String, List<String>> _indonesianToRoleMap = {
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
    'Depan-Tengah': ['Penyerang'],
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
    });
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Memuat klub & riwayat...';
      _isStatusError = false;
    });

    try {
      final request = context.read<CookieRequest>();
      final service = BestElevenService(request);
      final data = await service.fetchBuilderData();
      
      setState(() {
        // Handle casting dengan lebih aman
        if (data['clubs'] is List) {
          _clubs = (data['clubs'] as List).cast<BestElevenClub>();
        } else {
          _clubs = [];
        }
        if (data['history'] is List) {
          _history = (data['history'] as List).cast<BestElevenFormation>();
        } else {
          _history = [];
        }
        _isLoading = false;
        _statusMessage = 'Siap! Pilih slot di lapangan. (${_clubs.length} klub, ${_history.length} formasi)';
        _isStatusError = false;
      });
      
      print('Loaded ${_clubs.length} clubs and ${_history.length} formations');
      
      await _fetchPlayers();
      
      if (widget.formationId != null) {
        await _loadFormation(widget.formationId!);
      }
    } catch (e) {
      print('Error in _fetchInitialData: $e');
      setState(() {
        _statusMessage = 'Error memuat data: $e';
        _isStatusError = true;
        _isLoading = false;
      });
      
      // Tetap coba fetch players meskipun builder data gagal
      try {
        await _fetchPlayers();
      } catch (playerError) {
        print('Error fetching players after builder data error: $playerError');
      }
    }
  }

  Future<void> _fetchPlayers({int? clubId}) async {
    try {
      setState(() {
        _statusMessage = 'Memuat daftar pemain...';
        _isStatusError = false;
      });
      
      final request = context.read<CookieRequest>();
      final service = BestElevenService(request);
      final players = await service.fetchPlayers(clubId: clubId);
      
      setState(() {
        _allPlayers = players;
        _filterPlayers();
        if (players.isEmpty) {
          _statusMessage = 'Tidak ada pemain ditemukan.';
          _isStatusError = false;
        } else {
          _statusMessage = '${players.length} pemain dimuat.';
          _isStatusError = false;
        }
      });
      
      print('Fetched ${players.length} players');
    } catch (e) {
      print('Error fetching players: $e');
      setState(() {
        _statusMessage = 'Error memuat pemain: $e';
        _isStatusError = true;
      });
    }
  }

  void _filterPlayers() {
    String searchTerm = _playerSearchController.text.toLowerCase();
    List<BestElevenPlayer> filtered = _allPlayers.where((player) {
      bool matchesSearch = player.name.toLowerCase().contains(searchTerm);
      bool matchesClub = _selectedClubId == null || player.clubId == _selectedClubId;
      bool notInSquad = !_selectedPlayers.values.any((p) => p.id.toString() == player.id.toString());
      
      // Filter berdasarkan posisi jika slot dipilih
      bool matchesPosition = true;
      if (_selectedSlotId != null) {
        final requiredRole = _slotPositionMap[_selectedSlotId];
        if (requiredRole != null) {
          // Cek apakah posisi player cocok dengan role yang dibutuhkan
          matchesPosition = player.position == requiredRole || 
                           _isPositionCompatible(player.position, requiredRole);
        }
      }
      
      return matchesSearch && matchesClub && notInSquad && matchesPosition;
    }).toList();
    
    setState(() {
      _filteredPlayers = filtered;
    });
  }

  Future<void> _loadFormation(int formationId) async {
    try {
      _showStatus('Memuat formasi...', false);
      
      final request = context.read<CookieRequest>();
      final service = BestElevenService(request);
      final formation = await service.fetchFormationById(formationId);
      
      if (formation != null) {
        setState(() {
          _currentFormationId = formation.id;
          _selectedLayout = formation.layout;
          _nameController.text = formation.name;
          _selectedPlayers.clear();
          
          // Sesuai template Django: currentSquad = (data.players || []).map(p => ({ player: p, originalSlotId: p.slotId }))
          for (var slot in formation.players) {
            if (slot.player != null) {
              // Gunakan slotId jika ada, jika tidak gunakan position
              String slotKey = slot.slotId ?? slot.position;
              _selectedPlayers[slotKey] = slot.player!;
            }
          }
        });
        
        // Reassign players ke layout baru (sesuai template Django)
        _reassignPlayersToPitch();
        
        await _fetchPlayers();
        _filterPlayers();
        _checkFormCompletion();
        
        _showStatus('Formasi "${formation.name}" dimuat.', false);
      }
    } catch (e) {
      _showStatus('Error memuat formasi: $e', true);
      print('Error loading formation: $e');
    }
  }

  Future<void> _saveFormation() async {
    if (_nameController.text.trim().isEmpty) {
      _showStatus('Nama formasi wajib diisi!', true);
      return;
    }
    
    if (_selectedPlayers.length != 11) {
      _showStatus('Anda harus memiliki 11 pemain.', true);
      return;
    }

    setState(() {
      _statusMessage = 'Menyimpan formasi...';
      _isStatusError = false;
    });

    try {
      final request = context.read<CookieRequest>();
      final service = BestElevenService(request);
      
      // Sesuai template Django: player_ids: currentSquad.map(s => ({ slotId: s.originalSlotId, playerId: s.player.id }))
      // Di Flutter, _selectedPlayers adalah Map<String, BestElevenPlayer> dimana key adalah slotId
      // Django mengharapkan playerId sebagai string (UUID)
      List<Map<String, dynamic>> playerIds = _selectedPlayers.entries
          .map((e) => {'slotId': e.key, 'playerId': e.value.id.toString()})
          .toList();
      
      final response = await service.saveFormation(
        name: _nameController.text.trim(),
        layout: _selectedLayout,
        formationId: _currentFormationId,
        playerIds: playerIds,
      );

      if (response['error'] != null) {
        _showStatus('Error: ${response['error']}', true);
        return;
      }

      if (response['formation'] != null) {
        final formation = BestElevenFormation.fromJson(response['formation']);
        setState(() {
          _currentFormationId = formation.id;
          if (!_history.any((h) => h.id == formation.id)) {
            _history.insert(0, formation);
          } else {
            int index = _history.indexWhere((h) => h.id == formation.id);
            if (index != -1) {
              _history[index] = formation;
            }
          }
        });
      }

      _showStatus(response['message'] ?? 'Formasi disimpan!', false);
    } catch (e) {
      _showStatus('Error: $e', true);
    }
  }

  Future<void> _deleteFormation(int formationId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Formasi'),
        content: Text('Apakah Anda yakin ingin menghapus "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final request = context.read<CookieRequest>();
        final service = BestElevenService(request);
        final success = await service.deleteFormation(formationId);

        if (!mounted) return;
        if (success) {
          setState(() {
            _history.removeWhere((h) => h.id == formationId);
            if (_currentFormationId == formationId) {
              _clearFormation();
            }
          });
          _showStatus('Formasi "$name" dihapus.', false);
        } else {
          _showStatus('Gagal menghapus formasi.', true);
        }
      } catch (e) {
        if (!mounted) return;
        _showStatus('Error: $e', true);
      }
    }
  }

  void _clearFormation() {
    setState(() {
      _selectedPlayers.clear();
      _selectedSlotId = null;
      _currentFormationId = null;
      _nameController.clear();
      _selectedLayout = '4-3-3';
      _currentFilterPositionCode = null;
    });
    _filterPlayers();
    _showStatus('Formasi dikosongkan.', false);
  }
  
  void _handleClearFilter() {
    setState(() {
      _selectedSlotId = null;
      _currentFilterPositionCode = null;
    });
    _filterPlayers();
  }
  
  Future<void> _showFormationDetails(int formationId) async {
    try {
      setState(() {
        _showDetailModal = true;
        _detailFormation = null;
        _detailPlayers = [];
      });
      
      final request = context.read<CookieRequest>();
      final service = BestElevenService(request);
      final formation = await service.fetchFormationById(formationId);
      
      if (formation != null) {
        setState(() {
          _detailFormation = formation;
          // Extract players from formation - players are stored in slots
          _detailPlayers = formation.players
              .where((slot) => slot.player != null)
              .map((slot) => slot.player!)
              .toList();
        });
      }
    } catch (e) {
      _showStatus('Error memuat detail: $e', true);
      setState(() {
        _showDetailModal = false;
      });
    }
  }
  
  void _hideDetailModal() {
    setState(() {
      _showDetailModal = false;
      _detailFormation = null;
      _detailPlayers = [];
    });
  }

  void _handleSlotClick(String slotId) {
    if (_selectedPlayers.containsKey(slotId)) {
      // Remove player from slot
      setState(() {
        _selectedPlayers.remove(slotId);
        _selectedSlotId = null;
        _currentFilterPositionCode = null;
      });
      _filterPlayers();
      _showStatus('Pemain dihapus dari slot $slotId.', false);
    } else {
      // Select slot - toggle selection
      setState(() {
        if (_selectedSlotId == slotId) {
          // Deselect jika slot yang sama diklik lagi
          _selectedSlotId = null;
          _currentFilterPositionCode = null;
          _showStatus('Pemilihan slot $slotId dibatalkan.', false);
        } else {
          // Select slot baru
          _selectedSlotId = slotId;
          _currentFilterPositionCode = _slotPositionMap[slotId];
          final requiredRole = _slotPositionMap[slotId] ?? 'N/A';
          _showStatus('Memilih pemain untuk $slotId ($requiredRole)', false);
        }
      });
      // Filter players berdasarkan posisi yang dibutuhkan
      _filterPlayers();
    }
  }

  void _handlePlayerSelect(BestElevenPlayer player) {
    if (_selectedSlotId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih slot di lapangan terlebih dahulu!')),
      );
      return;
    }

    if (_selectedPlayers.length >= 11) {
      _showStatus('Skuad penuh (11 pemain).', true);
      return;
    }

    String requiredRole = _slotPositionMap[_selectedSlotId] ?? '';
    if (player.position != requiredRole && !_isPositionCompatible(player.position, requiredRole)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Posisi tidak cocok! Slot $_selectedSlotId membutuhkan $requiredRole, tapi pemain ini adalah ${player.position}.'),
        ),
      );
      return;
    }

    if (_selectedPlayers.values.any((p) => p.id.toString() == player.id.toString())) {
      _showStatus('${player.name} sudah ada di skuad.', true);
      return;
    }

    final slotId = _selectedSlotId!; // Simpan sebelum di-set ke null
    setState(() {
      _selectedPlayers[slotId] = player;
      _selectedSlotId = null;
      _currentFilterPositionCode = null;
    });
    
    _filterPlayers();
    _checkFormCompletion();
    _showStatus('${player.name} ditambahkan ke slot $slotId.', false);
  }

  bool _isPositionCompatible(String playerPosition, String requiredRole) {
    // Menggunakan mapping yang sama dengan template Django
    final playerRoles = _indonesianToRoleMap[playerPosition];
    if (playerRoles == null) return false;
    return playerRoles.contains(requiredRole);
  }
  
  // Reassign players to pitch saat layout berubah (sesuai template Django)
  void _reassignPlayersToPitch() {
    final newSlots = _formationLayouts[_selectedLayout] ?? [];
    final oldPlayers = Map<String, BestElevenPlayer>.from(_selectedPlayers);
    final newSelectedPlayers = <String, BestElevenPlayer>{};
    final unplacedPlayers = <BestElevenPlayer>[];
    
    // Track players yang sudah ditempatkan
    final placedPlayerIds = <String>{};
    
    for (final slotId in newSlots) {
      final requiredRole = _slotPositionMap[slotId] ?? '';
      
      // 1. Cari player yang exact match (slotId sama dan posisi cocok)
      BestElevenPlayer? matchedPlayer;
      String? matchedSlot;
      
      for (var entry in oldPlayers.entries) {
        if (placedPlayerIds.contains(entry.value.id.toString())) continue;
        
        final playerRoles = _indonesianToRoleMap[entry.value.position];
        if (playerRoles != null && playerRoles.contains(requiredRole)) {
          // Exact match jika slotId sama
          if (entry.key == slotId) {
            matchedPlayer = entry.value;
            matchedSlot = entry.key;
            break;
          }
        }
      }
      
      // 2. Jika tidak ada exact match, cari player dengan primary role yang cocok
      if (matchedPlayer == null) {
        for (var entry in oldPlayers.entries) {
          if (placedPlayerIds.contains(entry.value.id.toString())) continue;
          
          final playerRoles = _indonesianToRoleMap[entry.value.position];
          if (playerRoles != null && playerRoles.isNotEmpty && playerRoles[0] == requiredRole) {
            matchedPlayer = entry.value;
            matchedSlot = entry.key;
            break;
          }
        }
      }
      
      // 3. Jika masih tidak ada, cari player dengan role yang kompatibel
      if (matchedPlayer == null) {
        for (var entry in oldPlayers.entries) {
          if (placedPlayerIds.contains(entry.value.id.toString())) continue;
          
          final playerRoles = _indonesianToRoleMap[entry.value.position];
          if (playerRoles != null && playerRoles.contains(requiredRole)) {
            matchedPlayer = entry.value;
            matchedSlot = entry.key;
            break;
          }
        }
      }
      
      if (matchedPlayer != null && matchedSlot != null) {
        newSelectedPlayers[slotId] = matchedPlayer;
        placedPlayerIds.add(matchedPlayer.id.toString());
      }
    }
    
    // Collect unplaced players
    for (var entry in oldPlayers.entries) {
      if (!placedPlayerIds.contains(entry.value.id.toString())) {
        unplacedPlayers.add(entry.value);
      }
    }
    
    setState(() {
      _selectedPlayers.clear();
      _selectedPlayers.addAll(newSelectedPlayers);
      _selectedSlotId = null;
    });
    
    _filterPlayers();
    _checkFormCompletion();
    
    // Show status message
    if (unplacedPlayers.isNotEmpty) {
      final names = unplacedPlayers.map((p) => p.name).join(', ');
      _showStatus('Pemain dihapus (posisi tidak tersedia): $names', true);
    } else if (_selectedPlayers.isNotEmpty && _selectedPlayers.length < 11) {
      _showStatus('Formasi berubah. Harap isi ${11 - _selectedPlayers.length} slot yang kosong.', false);
    }
  }

  void _checkFormCompletion() {
    // Update UI based on completion status
    setState(() {});
  }

  void _showStatus(String message, bool isError) {
    setState(() {
      _statusMessage = message;
      _isStatusError = isError;
    });
    
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _statusMessage == message) {
        setState(() {
          _statusMessage = null;
        });
      }
    });
  }

  String _formatCurrency(double? value) {
    if (value == null || value == 0) return 'N/A';
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(value);
  }
  
  Widget _buildDetailModal() {
    if (!_showDetailModal) return const SizedBox.shrink();
    
    return Stack(
      children: [
        // Backdrop
        GestureDetector(
          onTap: _hideDetailModal,
          child: Container(
            color: Colors.black.withValues(alpha: 0.6),
          ),
        ),
        // Modal content
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _detailFormation?.name ?? 'Memuat...',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _primaryPurple,
                              ),
                            ),
                            if (_detailFormation != null)
                              Text(
                                'Formasi: ${_detailFormation!.layout}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _hideDetailModal,
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Player list
                Flexible(
                  child: _detailFormation == null
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _detailPlayers.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                child: Text(
                                  'Tidak ada pemain di formasi ini.',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _detailPlayers.length,
                              padding: const EdgeInsets.all(16),
                              itemBuilder: (context, index) {
                                final player = _detailPlayers[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundImage: player.profileImageUrl != null
                                            ? NetworkImage(player.profileImageUrl!)
                                            : null,
                                        child: player.profileImageUrl == null
                                            ? Text(
                                                player.name.isNotEmpty 
                                                    ? player.name[0].toUpperCase() 
                                                    : '?',
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              player.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              player.position.isNotEmpty ? player.position : 'N/A',
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
                // Footer
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: _hideDetailModal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryPurple,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Kembali'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cardBg,
      appBar: AppBar(
        title: const Text(
          'Best XI Team Builder',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        backgroundColor: _primaryPurple,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Status message - sesuai template Django
                      if (_statusMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isStatusError 
                                ? const Color(0xFFF25022).withValues(alpha: 0.06)
                                : const Color(0xFF7FBA00).withValues(alpha: 0.06),
                            border: Border.all(
                              color: _isStatusError 
                                  ? const Color(0xFFF25022)
                                  : const Color(0xFF7FBA00),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _statusMessage!,
                            style: TextStyle(
                              color: _isStatusError 
                                  ? const Color(0xFFF25022)
                                  : const Color(0xFF7FBA00),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      // Placeholder untuk spacing jika tidak ada status
                      if (_statusMessage == null)
                        const SizedBox(height: 40),
                      
                      // Main grid layout
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 1200) {
                            // Desktop layout: 3 columns
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildHistoryCard()),
                                const SizedBox(width: 16),
                                Expanded(flex: 2, child: _buildPitchCard()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildPlayerListCard()),
                              ],
                            );
                          } else {
                            // Mobile layout: stacked
                            return Column(
                              children: [
                                _buildHistoryCard(),
                                const SizedBox(height: 16),
                                _buildPitchCard(),
                                const SizedBox(height: 16),
                                _buildPlayerListCard(),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
          // Detail Modal overlay
          if (_showDetailModal) _buildDetailModal(),
        ],
      ),
    );
  }

  Widget _buildHistoryCard() {
    return Card(
      color: _cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _cardBorder, width: 2),
      ),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💾 Formasi Tersimpan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textLight,
              ),
            ),
            const Divider(color: _cardBorder, thickness: 2),
            SizedBox(
              height: 300,
              child: _history.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada formasi tersimpan.',
                        style: TextStyle(color: _textMuted, fontStyle: FontStyle.italic),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final formation = _history[index];
                        final isSelected = _currentFormationId == formation.id;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? const Color(0xFFE3DCEF)
                                : _cardBg,
                            border: Border.all(
                              color: isSelected ? _accentPink : _cardBorder,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(
                              formation.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _textLight,
                              ),
                            ),
                            subtitle: Text('Formasi: ${formation.layout}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility, color: _primaryPurple),
                                  onPressed: () => _showFormationDetails(formation.id),
                                  tooltip: 'Lihat Detail',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteFormation(formation.id, formation.name),
                                  tooltip: 'Hapus',
                                ),
                              ],
                            ),
                            onTap: () => _loadFormation(formation.id),
                          ),
                        );
                      },
                    ),
            ),
            const Divider(color: _cardBorder),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _clearFormation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('+ FORMASI BARU'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPitchCard() {
    return Card(
      color: _cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _cardBorder, width: 2),
      ),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name and layout inputs
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: '✏️ Nama Formasi (cth: Tim Impian)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _cardBorder, width: 2),
                      ),
                      filled: true,
                      fillColor: _cardBg,
                    ),
                    onChanged: (_) => _checkFormCompletion(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedLayout,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _cardBorder, width: 2),
                      ),
                      filled: true,
                      fillColor: _cardBg,
                    ),
                    items: _layouts.map((layout) {
                      return DropdownMenuItem(
                        value: layout,
                        child: Text(layout),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedLayout = value;
                          _selectedSlotId = null;
                        });
                        // Reassign players ke layout baru (sesuai template Django)
                        _reassignPlayersToPitch();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Pitch - menggunakan Stack dengan Positioned sesuai grid-area CSS Django (6 kolom x 5 baris)
            Container(
              height: 550,
              width: double.infinity,
              constraints: const BoxConstraints(
                minHeight: 450,
                maxHeight: 650,
              ),
              decoration: BoxDecoration(
                // Background hijau lapangan (bisa diganti dengan image jika ada)
                color: Colors.green.shade700,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final pitchWidth = constraints.maxWidth;
                    final pitchHeight = constraints.maxHeight;
                    return Stack(
                      children: [
                        // Background grid lines untuk visualisasi (6 kolom x 5 baris)
                        CustomPaint(
                          painter: PitchGridPainter(),
                          child: Container(),
                        ),
                        // Player slots dengan ukuran container yang tepat
                        ..._buildPitchSlots(pitchWidth, pitchHeight),
                      ],
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                ElevatedButton(
                  onPressed: _clearFormation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Kosongkan Pemain'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedPlayers.length == 11 && _nameController.text.trim().isNotEmpty
                        ? _saveFormation
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryPurple,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: Text(
                      _selectedPlayers.length == 11 && _nameController.text.trim().isNotEmpty
                          ? (_currentFormationId != null ? '💾 Perbarui' : '💾 Simpan Formasi')
                          : _selectedPlayers.length < 11
                              ? 'Pilih ${11 - _selectedPlayers.length} lagi'
                              : '✏️ Tambah Nama',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build pitch slots sesuai grid-area CSS Django (6 kolom x 5 baris)
  List<Widget> _buildPitchSlots(double containerWidth, double containerHeight) {
    final slots = _formationLayouts[_selectedLayout] ?? [];
    final List<Widget> widgets = [];
    
    // Mapping grid-area CSS ke Positioned Flutter
    // Format CSS: grid-area: row_start / col_start / row_end / col_end (1-indexed)
    // Flutter Positioned: left, top, width, height (dalam pixels)
    // Grid 6 kolom x 5 baris sesuai template Django
    final double colWidth = containerWidth / 6; // Pixels per kolom
    final double rowHeight = containerHeight / 5; // Pixels per baris
    
    for (String slotId in slots) {
      final position = _getSlotPosition(slotId, colWidth, rowHeight);
      if (position != null) {
        widgets.add(
          Positioned(
            left: position['left']!,
            top: position['top']!,
            width: position['width']!,
            height: position['height']!,
            child: _buildPitchSlot(slotId, position['width']!, position['height']!),
          ),
        );
      }
    }
    
    return widgets;
  }
  
  // Get position untuk slot berdasarkan grid-area CSS Django
  Map<String, double>? _getSlotPosition(String slotId, double colWidth, double rowHeight) {
    // Mapping sesuai CSS grid-area dari template Django
    // Format: row_start / col_start / row_end / col_end (1-indexed)
    List<int>? gridArea;
    
    // Common positions (semua layout)
    if (slotId == 'GK') gridArea = [5, 3, 6, 4]; // grid-area: 5 / 3 / 6 / 4
    if (slotId == 'LB') gridArea = [4, 1, 5, 2]; // grid-area: 4 / 1 / 5 / 2
    if (slotId == 'LCB') gridArea = [4, 2, 5, 3]; // grid-area: 4 / 2 / 5 / 3
    if (slotId == 'RCB') gridArea = [4, 4, 5, 5]; // grid-area: 4 / 4 / 5 / 5
    if (slotId == 'RB') gridArea = [4, 5, 5, 6]; // grid-area: 4 / 5 / 5 / 6
    
    // Layout-specific positions
    if (_selectedLayout == '4-3-3') {
      if (slotId == 'LCM') gridArea = [3, 2, 4, 3]; // grid-area: 3/2/4/3
      if (slotId == 'CM') gridArea = [3, 3, 4, 4]; // grid-area: 3/3/4/4
      if (slotId == 'RCM') gridArea = [3, 4, 4, 5]; // grid-area: 3/4/4/5
      if (slotId == 'LW') gridArea = [2, 1, 3, 2]; // grid-area: 2/1/3/2
      if (slotId == 'ST') gridArea = [2, 3, 3, 4]; // grid-area: 2/3/3/4
      if (slotId == 'RW') gridArea = [2, 5, 3, 6]; // grid-area: 2/5/3/6
    } else if (_selectedLayout == '4-4-2') {
      if (slotId == 'LM') gridArea = [3, 1, 4, 2]; // grid-area: 3/1/4/2
      if (slotId == 'LCM') gridArea = [3, 2, 4, 3]; // grid-area: 3/2/4/3
      if (slotId == 'RCM') gridArea = [3, 4, 4, 5]; // grid-area: 3/4/4/5
      if (slotId == 'RM') gridArea = [3, 5, 4, 6]; // grid-area: 3/5/4/6
      if (slotId == 'LST') gridArea = [2, 2, 3, 3]; // grid-area: 2/2/3/3
      if (slotId == 'RST') gridArea = [2, 4, 3, 5]; // grid-area: 2/4/3/5
    } else if (_selectedLayout == '3-5-2') {
      if (slotId == 'CB') gridArea = [4, 3, 5, 4]; // grid-area: 4/3/5/4
      if (slotId == 'LWB') gridArea = [3, 1, 4, 2]; // grid-area: 3/1/4/2
      if (slotId == 'LCM') gridArea = [3, 2, 4, 3]; // grid-area: 3/2/4/3
      if (slotId == 'CAM') gridArea = [3, 3, 4, 4]; // grid-area: 3/3/4/4
      if (slotId == 'RCM') gridArea = [3, 4, 4, 5]; // grid-area: 3/4/4/5
      if (slotId == 'RWB') gridArea = [3, 5, 4, 6]; // grid-area: 3/5/4/6
      if (slotId == 'LST') gridArea = [2, 2, 3, 3]; // grid-area: 2/2/3/3
      if (slotId == 'RST') gridArea = [2, 4, 3, 5]; // grid-area: 2/4/3/5
    } else if (_selectedLayout == '4-2-3-1') {
      if (slotId == 'LDM') gridArea = [3, 2, 4, 3]; // grid-area: 3/2/4/3
      if (slotId == 'RDM') gridArea = [3, 4, 4, 5]; // grid-area: 3/4/4/5
      if (slotId == 'LAM') gridArea = [2, 1, 3, 2]; // grid-area: 2/1/3/2
      if (slotId == 'CAM') gridArea = [2, 3, 3, 4]; // grid-area: 2/3/3/4
      if (slotId == 'RAM') gridArea = [2, 5, 3, 6]; // grid-area: 2/5/3/6
      if (slotId == 'ST') gridArea = [1, 3, 2, 4]; // grid-area: 1/3/2/4
    }
    
    if (gridArea == null || gridArea.length != 4) return null;
    
    // Convert CSS grid-area (1-indexed) ke Flutter Positioned (0-indexed, pixels)
    // grid-area: row_start / col_start / row_end / col_end
    // CSS grid menggunakan 1-indexed, Flutter menggunakan 0-indexed
    // row_end dan col_end adalah exclusive (tidak termasuk dalam area)
    // Contoh: grid-area: 5/3/6/4 berarti baris 5 kolom 3, ukuran 1x1
    int rowStart = gridArea[0] - 1; // Convert to 0-indexed (baris mulai)
    int colStart = gridArea[1] - 1; // Convert to 0-indexed (kolom mulai)
    int rowEnd = gridArea[2]; // row_end (1-indexed, exclusive)
    int colEnd = gridArea[3]; // col_end (1-indexed, exclusive)
    
    // Hitung posisi dan ukuran dengan tepat
    // width = (colEnd - colStart) karena colEnd adalah exclusive
    // height = (rowEnd - rowStart) karena rowEnd adalah exclusive
    final left = colStart * colWidth;
    final top = rowStart * rowHeight;
    final width = (colEnd - colStart) * colWidth;
    final height = (rowEnd - rowStart) * rowHeight;
    
    return {
      'left': left,
      'top': top,
      'width': width,
      'height': height,
    };
  }

  Widget _buildPitchSlot(String slotId, double slotWidth, double slotHeight) {
    final player = _selectedPlayers[slotId];
    final isSelected = _selectedSlotId == slotId;
    
    // Hitung ukuran avatar dan text secara proporsional berdasarkan ukuran slot
    // Sesuai template Django: avatar lebih besar (60-80px) dan proporsional
    final double minDimension = slotWidth < slotHeight ? slotWidth : slotHeight;
    final double avatarSize = minDimension * 0.7; // Lebih besar dari sebelumnya
    final double fontSize = avatarSize * 0.4; // Font untuk inisial
    final double labelFontSize = avatarSize * 0.2; // Font untuk nama
    
    return GestureDetector(
      onTap: () => _handleSlotClick(slotId),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(2),
        decoration: isSelected
            ? BoxDecoration(
                border: Border.all(
                  color: _accentPink,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Center(
          child: player != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: avatarSize.clamp(50.0, 80.0),
                      height: avatarSize.clamp(50.0, 80.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _primaryPurple,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: player.profileImageUrl != null && player.profileImageUrl!.isNotEmpty
                            ? Image.network(
                                player.profileImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: _primaryPurple,
                                    child: Center(
                                      child: Text(
                                        player.name.isNotEmpty 
                                            ? player.name[0].toUpperCase() 
                                            : '?',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: fontSize.clamp(20.0, 28.0),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: _primaryPurple,
                                child: Center(
                                  child: Text(
                                    player.name.isNotEmpty 
                                        ? player.name[0].toUpperCase() 
                                        : '?',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: fontSize.clamp(20.0, 28.0),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _textLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          player.name.isNotEmpty ? player.name : 'Unknown',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: labelFontSize.clamp(10.0, 14.0),
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: avatarSize.clamp(50.0, 80.0),
                      height: avatarSize.clamp(50.0, 80.0),
                      decoration: BoxDecoration(
                        color: _primaryPurple.withValues(alpha: 0.28),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _primaryPurple.withValues(alpha: 0.6),
                          width: 3,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          slotId,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize.clamp(14.0, 18.0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _primaryPurple.withValues(alpha: 0.9),
                              _accentPink.withValues(alpha: 0.9),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '(Kosong)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: labelFontSize.clamp(10.0, 14.0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPlayerListCard() {
    return Card(
      color: _cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _cardBorder, width: 2),
      ),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 Daftar Pemain',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textLight,
              ),
            ),
            const Divider(color: _cardBorder, thickness: 2),
            
            // Club filter
            DropdownButtonFormField<int?>(
              value: _selectedClubId,
              decoration: InputDecoration(
                labelText: 'Filter berdasarkan Klub',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _cardBorder, width: 2),
                ),
                filled: true,
                fillColor: _cardBg,
              ),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Semua Klub')),
                ..._clubs.map((club) {
                  return DropdownMenuItem<int?>(
                    value: club.id,
                    child: Text(club.name),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedClubId = value;
                });
                _fetchPlayers(clubId: value);
              },
            ),
            
            const SizedBox(height: 16),
            
            // Player search
            TextField(
              controller: _playerSearchController,
              decoration: InputDecoration(
                hintText: 'Ketik nama pemain....',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _cardBorder, width: 2),
                ),
                filled: true,
                fillColor: _cardBg,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (_) => _filterPlayers(),
            ),
            
            const SizedBox(height: 16),
            
            // Filter position label and clear button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _currentFilterPositionCode != null 
                      ? 'Filter: $_currentFilterPositionCode'
                      : 'Pilih klub atau posisi',
                  style: const TextStyle(
                    fontSize: 14,
                    color: _textLight,
                  ),
                ),
                if (_currentFilterPositionCode != null)
                  TextButton(
                    onPressed: _handleClearFilter,
                    child: const Text(
                      '✕ Hapus Filter',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Player list
            SizedBox(
              height: 400,
              child: _filteredPlayers.isEmpty
                  ? const Center(
                      child: Text(
                        'Tidak ada pemain yang cocok.',
                        style: TextStyle(color: _textMuted, fontStyle: FontStyle.italic),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredPlayers.length,
                      itemBuilder: (context, index) {
                        final player = _filteredPlayers[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: player.profileImageUrl != null
                                  ? NetworkImage(player.profileImageUrl!)
                                  : null,
                              child: player.profileImageUrl == null
                                  ? Text(
                                      player.name.isNotEmpty 
                                          ? player.name[0].toUpperCase() 
                                          : '?',
                                    )
                                  : null,
                            ),
                            title: Text(player.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${player.nationality ?? '-'} • ${_formatCurrency(player.marketValue)}'),
                              ],
                            ),
                            trailing: Chip(
                              label: Text(player.position),
                              backgroundColor: _primaryPurple.withValues(alpha: 0.2),
                            ),
                            onTap: () => _handlePlayerSelect(player),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _playerSearchController.dispose();
    super.dispose();
  }
}

// Custom painter untuk grid lines lapangan (opsional, untuk visualisasi)
class PitchGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw vertical lines (6 kolom)
    for (int i = 0; i <= 6; i++) {
      final x = (size.width / 6) * i;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines (5 baris)
    for (int i = 0; i <= 5; i++) {
      final y = (size.height / 5) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
    
    // Draw center circle (opsional, untuk estetika)
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width * 0.12;
    final centerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(centerX, centerY), radius, centerPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

