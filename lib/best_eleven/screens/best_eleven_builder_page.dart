import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/best_eleven_models.dart';
import '../services/best_eleven_service.dart';

String getProxiedUrl(String? url) {
  if (url == null || url.isEmpty) return "";
  // Jika URL sudah lengkap (http/https), gunakan langsung
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return "https://wsrv.nl/?url=$url&output=png";
  }
  // Jika URL relatif, tambahkan base URL dari Django
  return "https://wsrv.nl/?url=http://localhost:8000$url&output=png";
}

class BestElevenBuilderPage extends StatefulWidget {
  final int? formationId;
  final bool hideScaffold;

  const BestElevenBuilderPage({
    super.key, 
    this.formationId,
    this.hideScaffold = false,
  });

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
  bool _isSaving = false;
  String? _statusMessage;
  bool _isStatusError = false;
  
  // Modal state
  bool _showDetailModal = false;
  BestElevenFormation? _detailFormation;
  List<BestElevenPlayer> _detailPlayers = [];
  
  // Filter position state
  String? _currentFilterPositionCode;
  
  // Mobile UI state
  bool _isHistoryExpanded = false;
  
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
          // Tidak menampilkan pesan "X pemain dimuat"
          _statusMessage = null;
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
        
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error memuat formasi: $e')),
        );
      }
      print('Error loading formation: $e');
    }
  }

  Future<void> _saveFormation() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama formasi wajib diisi!')),
      );
      return;
    }
    
    if (_selectedPlayers.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus memiliki 11 pemain.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _statusMessage = null;
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
      
      print('Saving formation with:');
      print('  Name: ${_nameController.text.trim()}');
      print('  Layout: $_selectedLayout');
      print('  Formation ID: $_currentFormationId');
      print('  Player IDs: $playerIds');
      
      final response = await service.saveFormation(
        name: _nameController.text.trim(),
        layout: _selectedLayout,
        formationId: _currentFormationId,
        playerIds: playerIds,
      );

      print('Save response: $response');

      if (!mounted) return;

      if (response['error'] != null) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response['error']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      // Handle success response
      BestElevenFormation? savedFormation;
      if (response['formation'] != null) {
        try {
          savedFormation = BestElevenFormation.fromJson(response['formation']);
        } catch (e) {
          print('Error parsing formation from response: $e');
          print('Response formation data: ${response['formation']}');
        }
      }

      // Refresh history
      try {
        final builderData = await service.fetchBuilderData();
        if (builderData['history'] is List) {
          final updatedHistory = (builderData['history'] as List)
              .map((h) => BestElevenFormation.fromJson(h))
              .toList();
          
          setState(() {
            _history = updatedHistory;
            if (savedFormation != null) {
              _currentFormationId = savedFormation.id;
              // Update saved formation in history if exists
              final index = _history.indexWhere((h) => h.id == savedFormation!.id);
              if (index != -1) {
                _history[index] = savedFormation;
              } else {
                _history.insert(0, savedFormation);
              }
            }
            _isSaving = false;
          });
        }
      } catch (e) {
        print('Error refreshing history: $e');
        // Still update state even if refresh fails
        if (savedFormation != null) {
          setState(() {
            _currentFormationId = savedFormation!.id;
            final index = _history.indexWhere((h) => h.id == savedFormation!.id);
            if (index != -1) {
              _history[index] = savedFormation;
            } else {
              _history.insert(0, savedFormation);
            }
            _isSaving = false;
          });
        } else {
          setState(() {
            _isSaving = false;
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Formasi berhasil disimpan!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('Error in _saveFormation: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error menyimpan formasi: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
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
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gagal menghapus formasi.')),
            );
          }
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error memuat detail: $e')),
        );
      }
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
    } else {
      // Select slot - toggle selection
      setState(() {
        if (_selectedSlotId == slotId) {
          // Deselect jika slot yang sama diklik lagi
          _selectedSlotId = null;
          _currentFilterPositionCode = null;
        } else {
          // Select slot baru
          _selectedSlotId = slotId;
          _currentFilterPositionCode = _slotPositionMap[slotId];
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Skuad penuh (11 pemain).')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${player.name} sudah ada di skuad.')),
      );
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
    } else if (_selectedPlayers.isNotEmpty && _selectedPlayers.length < 11) {
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
        // Modal content - responsive
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width < 600 ? double.infinity : 500,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header - responsive
                Padding(
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 12 : 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _detailFormation?.name ?? 'Memuat...',
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width < 600 ? 18 : 24,
                                fontWeight: FontWeight.bold,
                                color: _primaryPurple,
                              ),
                            ),
                            if (_detailFormation != null)
                              Text(
                                'Formasi: ${_detailFormation!.layout}',
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 16,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          size: MediaQuery.of(context).size.width < 600 ? 20 : 24,
                        ),
                        onPressed: _hideDetailModal,
                        padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 4 : 8),
                        constraints: BoxConstraints(
                          minWidth: MediaQuery.of(context).size.width < 600 ? 36 : 48,
                          minHeight: MediaQuery.of(context).size.width < 600 ? 36 : 48,
                        ),
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
                              padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 12 : 16),
                              itemBuilder: (context, index) {
                                final player = _detailPlayers[index];
                                final isMobileModal = MediaQuery.of(context).size.width < 600;
                                return Container(
                                  margin: EdgeInsets.only(bottom: isMobileModal ? 8 : 12),
                                  padding: EdgeInsets.all(isMobileModal ? 10 : 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: isMobileModal ? 20 : 24,
                                        backgroundColor: _primaryPurple,
                                        backgroundImage: player.profileImageUrl != null && player.profileImageUrl!.isNotEmpty
                                            ? NetworkImage(getProxiedUrl(player.profileImageUrl))
                                            : null,
                                        onBackgroundImageError: (exception, stackTrace) {
                                          // Error loading image, will show child instead
                                        },
                                        child: player.profileImageUrl == null || player.profileImageUrl!.isEmpty
                                            ? Text(
                                                player.name.isNotEmpty 
                                                    ? player.name[0].toUpperCase() 
                                                    : '?',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: isMobileModal ? 14 : 16,
                                                ),
                                              )
                                            : null,
                                      ),
                                      SizedBox(width: isMobileModal ? 10 : 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              player.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: isMobileModal ? 14 : 16,
                                              ),
                                            ),
                                            Text(
                                              player.position.isNotEmpty ? player.position : 'N/A',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: isMobileModal ? 12 : 14,
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
                // Footer - responsive
                Padding(
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 12 : 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _hideDetailModal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryPurple,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.width < 600 ? 14 : 12,
                        ),
                        minimumSize: Size(0, MediaQuery.of(context).size.width < 600 ? 48 : 44),
                      ),
                      child: Text(
                        'Kembali',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = MediaQuery.of(context).size.width < 768;
                    return SingleChildScrollView(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      child: Column(
                        children: [
                          // Status message - sesuai template Django
                          if (_statusMessage != null)
                            Container(
                              margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
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
                            SizedBox(height: isMobile ? 8 : 40),
                          
                          // Main grid layout - responsive
                          LayoutBuilder(
                            builder: (context, innerConstraints) {
                              final isMobileInner = MediaQuery.of(context).size.width < 768;
                              final isTablet = MediaQuery.of(context).size.width >= 768 && MediaQuery.of(context).size.width <= 1200;
                          
                              if (innerConstraints.maxWidth > 1200) {
                                // Desktop layout: 3 columns
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildHistoryCard(isMobile: false)),
                                    const SizedBox(width: 16),
                                    Expanded(flex: 2, child: _buildPitchCard(isMobile: false)),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildPlayerListCard(isMobile: false)),
                                  ],
                                );
                              } else {
                                // Mobile/Tablet layout: optimized order for mobile
                                if (isMobileInner) {
                                  // Mobile: Pitch first (main focus), then Player List, then collapsible History
                                  return Column(
                                    children: [
                                      _buildPitchCard(isMobile: true),
                                      const SizedBox(height: 12),
                                      _buildPlayerListCard(isMobile: true),
                                      const SizedBox(height: 12),
                                      _buildHistoryCardMobile(),
                                    ],
                                  );
                                } else {
                                  // Tablet: Pitch on top, History and Player List side by side
                                  return Column(
                                    children: [
                                      _buildPitchCard(isMobile: false),
                                      const SizedBox(height: 16),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(child: _buildHistoryCard(isMobile: false)),
                                          const SizedBox(width: 16),
                                          Expanded(child: _buildPlayerListCard(isMobile: false)),
                                        ],
                                      ),
                                    ],
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
          // Detail Modal overlay
          if (_showDetailModal) _buildDetailModal(),
        ],
      );
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();
    
    // Jika hideScaffold true, return body saja (untuk diintegrasikan ke scaffold utama)
    if (widget.hideScaffold) {
      return Container(
        color: _cardBg,
        child: body,
      );
    }
    
    // Jika tidak, return Scaffold lengkap (untuk navigasi standalone)
    return Scaffold(
      backgroundColor: _cardBg,
      appBar: AppBar(
        title: Text(
          'Best XI Team Builder',
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width < 600 ? 18 : 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: _primaryPurple,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: body,
    );
  }

  Widget _buildHistoryCardMobile() {
    return Card(
      color: _cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _cardBorder, width: 2),
      ),
      elevation: 8,
      child: ExpansionTile(
        initiallyExpanded: _isHistoryExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isHistoryExpanded = expanded;
          });
        },
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.only(bottom: 12),
        title: Row(
          children: [
            const Text(
              '💾 Formasi Tersimpan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _textLight,
              ),
            ),
            if (_history.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _primaryPurple,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_history.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        children: [
          const Divider(color: _cardBorder, thickness: 2),
          SizedBox(
            height: 200,
            child: _history.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Belum ada formasi tersimpan.',
                        style: TextStyle(
                          color: _textMuted,
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final formation = _history[index];
                      final isSelected = _currentFormationId == formation.id;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? const Color(0xFFE3DCEF)
                              : _cardBg,
                          border: Border.all(
                            color: isSelected ? _accentPink : _cardBorder,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          title: Text(
                            formation.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _textLight,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            'Formasi: ${formation.layout}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.visibility,
                                  color: _primaryPurple,
                                  size: 20,
                                ),
                                onPressed: () => _showFormationDetails(formation.id),
                                tooltip: 'Lihat Detail',
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () => _deleteFormation(formation.id, formation.name),
                                tooltip: 'Hapus',
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _clearFormation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(0, 48),
                ),
                child: const Text(
                  '+ FORMASI BARU',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard({required bool isMobile}) {
    return Card(
      color: _cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        side: const BorderSide(color: _cardBorder, width: 2),
      ),
      elevation: 8,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💾 Formasi Tersimpan',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: _textLight,
              ),
            ),
            const Divider(color: _cardBorder, thickness: 2),
            SizedBox(
              height: isMobile ? 200 : 300,
              child: _history.isEmpty
                  ? Center(
                      child: Text(
                        'Belum ada formasi tersimpan.',
                        style: TextStyle(
                          color: _textMuted,
                          fontStyle: FontStyle.italic,
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final formation = _history[index];
                        final isSelected = _currentFormationId == formation.id;
                        return Container(
                          margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? const Color(0xFFE3DCEF)
                                : _cardBg,
                            border: Border.all(
                              color: isSelected ? _accentPink : _cardBorder,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 8 : 16,
                              vertical: isMobile ? 4 : 8,
                            ),
                            title: Text(
                              formation.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _textLight,
                                fontSize: isMobile ? 14 : 16,
                              ),
                            ),
                            subtitle: Text(
                              'Formasi: ${formation.layout}',
                              style: TextStyle(fontSize: isMobile ? 12 : 14),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.visibility,
                                    color: _primaryPurple,
                                    size: isMobile ? 20 : 24,
                                  ),
                                  onPressed: () => _showFormationDetails(formation.id),
                                  tooltip: 'Lihat Detail',
                                  padding: EdgeInsets.all(isMobile ? 4 : 8),
                                  constraints: BoxConstraints(
                                    minWidth: isMobile ? 36 : 48,
                                    minHeight: isMobile ? 36 : 48,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: isMobile ? 20 : 24,
                                  ),
                                  onPressed: () => _deleteFormation(formation.id, formation.name),
                                  tooltip: 'Hapus',
                                  padding: EdgeInsets.all(isMobile ? 4 : 8),
                                  constraints: BoxConstraints(
                                    minWidth: isMobile ? 36 : 48,
                                    minHeight: isMobile ? 36 : 48,
                                  ),
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
                  padding: EdgeInsets.symmetric(
                    vertical: isMobile ? 14 : 12,
                  ),
                  minimumSize: Size(0, isMobile ? 48 : 44),
                ),
                child: Text(
                  '+ FORMASI BARU',
                  style: TextStyle(fontSize: isMobile ? 13 : 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionSelector({required bool isMobile}) {
    final slots = _formationLayouts[_selectedLayout] ?? [];
    
    return Card(
      color: _cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
        side: BorderSide(
          color: _selectedSlotId != null ? _accentPink : _cardBorder,
          width: _selectedSlotId != null ? 3 : 2,
        ),
      ),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 10 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.touch_app,
                  size: isMobile ? 18 : 20,
                  color: _textLight,
                ),
                const SizedBox(width: 8),
                Text(
                  'Pilih Posisi',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: _textLight,
                  ),
                ),
                if (_selectedSlotId != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _accentPink,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _selectedSlotId!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: isMobile ? 6 : 8,
              runSpacing: isMobile ? 6 : 8,
              children: slots.map((slotId) {
                final isSelected = _selectedSlotId == slotId;
                final hasPlayer = _selectedPlayers.containsKey(slotId);
                final positionName = _slotPositionMap[slotId] ?? slotId;
                
                return InkWell(
                  onTap: () => _handleSlotClick(slotId),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 10 : 12,
                      vertical: isMobile ? 8 : 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _accentPink
                          : hasPlayer
                              ? _primaryPurple.withValues(alpha: 0.2)
                              : _cardBg,
                      border: Border.all(
                        color: isSelected
                            ? _accentPink
                            : hasPlayer
                                ? _primaryPurple
                                : _cardBorder,
                        width: isSelected ? 3 : 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasPlayer)
                          Icon(
                            Icons.check_circle,
                            size: isMobile ? 16 : 18,
                            color: isSelected ? Colors.white : _primaryPurple,
                          ),
                        if (hasPlayer) SizedBox(width: isMobile ? 4 : 6),
                        Text(
                          slotId,
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected || hasPlayer
                                ? Colors.white
                                : _textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_selectedSlotId != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accentPink.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _accentPink,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: isMobile ? 16 : 18,
                      color: _accentPink,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pilih pemain dari daftar di bawah untuk posisi ${_selectedSlotId} (${_slotPositionMap[_selectedSlotId] ?? "N/A"})',
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 12,
                          color: _textLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPitchCard({required bool isMobile}) {
    return Card(
      color: _cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        side: const BorderSide(color: _cardBorder, width: 2),
      ),
      elevation: 8,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name and layout inputs - stacked on mobile
            isMobile
                ? Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: '✏️ Nama Formasi',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _cardBorder, width: 2),
                          ),
                          filled: true,
                          fillColor: _cardBg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        style: const TextStyle(fontSize: 14),
                        onChanged: (_) => _checkFormCompletion(),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedLayout,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _cardBorder, width: 2),
                          ),
                          filled: true,
                          fillColor: _cardBg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        style: const TextStyle(fontSize: 14),
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
                            _reassignPlayersToPitch();
                          }
                        },
                      ),
                    ],
                  )
                : Row(
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
                              _reassignPlayersToPitch();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
            SizedBox(height: isMobile ? 12 : 16),
            
            // Pitch - responsive height
            LayoutBuilder(
              builder: (context, constraints) {
                final screenHeight = MediaQuery.of(context).size.height;
                final pitchHeight = isMobile 
                    ? (screenHeight * 0.35).clamp(280.0, 400.0)
                    : 550.0;
                
                return Container(
                  height: pitchHeight,
                  width: double.infinity,
                  constraints: BoxConstraints(
                    minHeight: isMobile ? 280 : 450,
                    maxHeight: isMobile ? 400 : 650,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade700,
                    borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                    border: Border.all(color: Colors.white, width: isMobile ? 1.5 : 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: isMobile ? 10 : 20,
                        spreadRadius: isMobile ? 2 : 5,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final pitchWidth = constraints.maxWidth;
                        final pitchHeight = constraints.maxHeight;
                        return Stack(
                          children: [
                            CustomPaint(
                              painter: PitchGridPainter(),
                              child: Container(),
                            ),
                            ..._buildPitchSlots(pitchWidth, pitchHeight, isMobile: isMobile),
                          ],
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            
            SizedBox(height: isMobile ? 12 : 16),
            
            // Quick Position Selector - untuk memudahkan pemilihan posisi
            _buildPositionSelector(isMobile: isMobile),
            
            SizedBox(height: isMobile ? 12 : 16),
            
            // Action buttons - stacked on mobile
            isMobile
                ? Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _clearFormation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            minimumSize: const Size(0, 48),
                          ),
                          child: const Text(
                            'Kosongkan Pemain',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_selectedPlayers.length == 11 && _nameController.text.trim().isNotEmpty && !_isSaving)
                              ? _saveFormation
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryPurple,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            minimumSize: const Size(0, 48),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  _selectedPlayers.length == 11 && _nameController.text.trim().isNotEmpty
                                      ? (_currentFormationId != null ? '💾 Perbarui' : '💾 Simpan')
                                      : _selectedPlayers.length < 11
                                          ? 'Pilih ${11 - _selectedPlayers.length} lagi'
                                          : '✏️ Tambah Nama',
                                  style: const TextStyle(fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ),
                    ],
                  )
                : Row(
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
                          onPressed: (_selectedPlayers.length == 11 && _nameController.text.trim().isNotEmpty && !_isSaving)
                              ? _saveFormation
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryPurple,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
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
  List<Widget> _buildPitchSlots(double containerWidth, double containerHeight, {required bool isMobile}) {
    final slots = _formationLayouts[_selectedLayout] ?? [];
    final List<Widget> widgets = [];
    
    // Mapping grid-area CSS ke Positioned Flutter
    // Format CSS: grid-area: row_start / col_start / row_end / col_end (1-indexed)
    // Flutter Positioned: left, top, width, height (dalam pixels)
    // Grid 6 kolom x 5 baris sesuai template Django
    final double colWidth = containerWidth / 6; // Pixels per kolom
    final double rowHeight = containerHeight / 5; // Pixels per baris
    
    // Sort slots: render GK and bottom slots last (so they're on top in stack)
    final sortedSlots = List<String>.from(slots);
    sortedSlots.sort((a, b) {
      // Get row position for sorting
      final posA = _getSlotRowPosition(a);
      final posB = _getSlotRowPosition(b);
      // Lower row number (higher on screen) first, but GK last
      if (a == 'GK') return 1; // GK always last
      if (b == 'GK') return -1;
      return posA.compareTo(posB);
    });
    
    for (String slotId in sortedSlots) {
      final position = _getSlotPosition(slotId, colWidth, rowHeight);
      if (position != null) {
        widgets.add(
          Positioned(
            left: position['left']!,
            top: position['top']!,
            width: position['width']!,
            height: position['height']!,
            child: ClipRect(
              child: _buildPitchSlot(slotId, position['width']!, position['height']!, isMobile: isMobile),
            ),
          ),
        );
      }
    }
    
    return widgets;
  }
  
  // Helper untuk mendapatkan row position untuk sorting
  int _getSlotRowPosition(String slotId) {
    // Common positions
    if (slotId == 'GK') return 6; // Bottom (rendered last)
    if (slotId == 'LB' || slotId == 'LCB' || slotId == 'RCB' || slotId == 'RB') return 4;
    
    // Layout-specific
    if (_selectedLayout == '4-3-3') {
      if (slotId == 'LCM' || slotId == 'CM' || slotId == 'RCM') return 3;
      if (slotId == 'LW' || slotId == 'ST' || slotId == 'RW') return 2;
    } else if (_selectedLayout == '4-4-2') {
      if (slotId == 'LM' || slotId == 'LCM' || slotId == 'RCM' || slotId == 'RM') return 3;
      if (slotId == 'LST' || slotId == 'RST') return 2;
    } else if (_selectedLayout == '3-5-2') {
      if (slotId == 'CB') return 4;
      if (slotId == 'LWB' || slotId == 'LCM' || slotId == 'CAM' || slotId == 'RCM' || slotId == 'RWB') return 3;
      if (slotId == 'LST' || slotId == 'RST') return 2;
    } else if (_selectedLayout == '4-2-3-1') {
      if (slotId == 'LDM' || slotId == 'RDM') return 3;
      if (slotId == 'LAM' || slotId == 'CAM' || slotId == 'RAM') return 2;
      if (slotId == 'ST') return 1;
    }
    
    return 5; // Default (will be sorted last with GK)
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

  Widget _buildPitchSlot(String slotId, double slotWidth, double slotHeight, {required bool isMobile}) {
    final player = _selectedPlayers[slotId];
    final isSelected = _selectedSlotId == slotId;
    
    // Hitung ukuran avatar dan text secara proporsional berdasarkan ukuran slot
    // Untuk mobile, gunakan ukuran yang lebih kecil tapi tetap mudah di-tap
    final double minDimension = slotWidth < slotHeight ? slotWidth : slotHeight;
    final double avatarRatio = isMobile ? 0.65 : 0.7;
    final double avatarSize = (minDimension * avatarRatio).clamp(isMobile ? 40.0 : 50.0, isMobile ? 60.0 : 80.0);
    final double fontSize = avatarSize * 0.4;
    final double labelRatio = isMobile ? 0.18 : 0.2;
    final double labelFontSize = (avatarSize * labelRatio).clamp(isMobile ? 8.0 : 10.0, isMobile ? 12.0 : 14.0);
    
    // Nonaktifkan tap pada lapangan - user hanya bisa pilih melalui "Pilih Posisi"
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.all(isMobile ? 2 : 3),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(top: isMobile ? 16 : 20),
          child: player != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? _accentPink
                              : _primaryPurple,
                          width: isSelected ? 5 : 4,
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
                                getProxiedUrl(player.profileImageUrl),
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: _primaryPurple,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                            : null,
                                        strokeWidth: 2,
                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                  );
                                },
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
                                          fontSize: fontSize.clamp(isMobile ? 16.0 : 20.0, isMobile ? 24.0 : 28.0),
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
                                      fontSize: fontSize.clamp(isMobile ? 16.0 : 20.0, isMobile ? 24.0 : 28.0),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: isMobile ? 6 : 8),
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 4 : 8,
                          vertical: isMobile ? 3 : 5,
                        ),
                        decoration: BoxDecoration(
                          color: _textLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          player.name.isNotEmpty ? player.name : 'Unknown',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: labelFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: isMobile ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        color: _primaryPurple.withValues(alpha: 0.28),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? _accentPink
                              : _primaryPurple.withValues(alpha: 0.6),
                          width: isSelected ? 5 : 3,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          slotId,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize.clamp(isMobile ? 14.0 : 16.0, isMobile ? 20.0 : 22.0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isMobile ? 6 : 8),
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 6 : 8,
                          vertical: isMobile ? 4 : 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _primaryPurple.withValues(alpha: 0.7),
                              _accentPink.withValues(alpha: 0.7),
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
                            fontSize: labelFontSize.clamp(isMobile ? 8.0 : 9.0, isMobile ? 11.0 : 12.0),
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPlayerListCard({required bool isMobile}) {
    return Card(
      color: _cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        side: const BorderSide(color: _cardBorder, width: 2),
      ),
      elevation: 8,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📋 Daftar Pemain',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
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
                labelStyle: TextStyle(fontSize: isMobile ? 13 : 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _cardBorder, width: 2),
                ),
                filled: true,
                fillColor: _cardBg,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: isMobile ? 16 : 12,
                ),
              ),
              style: TextStyle(fontSize: isMobile ? 14 : 16),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Semua Klub', style: TextStyle(fontSize: isMobile ? 14 : 16)),
                ),
                ..._clubs.map((club) {
                  return DropdownMenuItem<int?>(
                    value: club.id,
                    child: Text(
                      club.name,
                      style: TextStyle(fontSize: isMobile ? 14 : 16),
                      overflow: TextOverflow.ellipsis,
                    ),
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
            
            SizedBox(height: isMobile ? 12 : 16),
            
            // Player search
            TextField(
              controller: _playerSearchController,
              decoration: InputDecoration(
                hintText: 'Ketik nama pemain....',
                hintStyle: TextStyle(fontSize: isMobile ? 14 : 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _cardBorder, width: 2),
                ),
                filled: true,
                fillColor: _cardBg,
                prefixIcon: const Icon(Icons.search),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: isMobile ? 16 : 12,
                ),
              ),
              style: TextStyle(fontSize: isMobile ? 14 : 16),
              onChanged: (_) => _filterPlayers(),
            ),
            
            SizedBox(height: isMobile ? 12 : 16),
            
            // Filter position label and clear button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    _currentFilterPositionCode != null 
                        ? 'Filter: $_currentFilterPositionCode'
                        : 'Pilih klub atau posisi',
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 14,
                      color: _textLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_currentFilterPositionCode != null)
                  TextButton(
                    onPressed: _handleClearFilter,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 12,
                        vertical: isMobile ? 4 : 8,
                      ),
                      minimumSize: Size(isMobile ? 80 : 100, isMobile ? 32 : 36),
                    ),
                    child: Text(
                      '✕ Hapus',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: isMobile ? 11 : 12,
                      ),
                    ),
                  ),
              ],
            ),
            
            SizedBox(height: isMobile ? 12 : 16),
            
            // Player list - responsive height
            LayoutBuilder(
              builder: (context, constraints) {
                final screenHeight = MediaQuery.of(context).size.height;
                final listHeight = isMobile 
                    ? (screenHeight * 0.25).clamp(200.0, 350.0)
                    : 400.0;
                
                return SizedBox(
                  height: listHeight,
                  child: _filteredPlayers.isEmpty
                      ? Center(
                          child: Text(
                            'Tidak ada pemain yang cocok.',
                            style: TextStyle(
                              color: _textMuted,
                              fontStyle: FontStyle.italic,
                              fontSize: isMobile ? 12 : 14,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredPlayers.length,
                          itemBuilder: (context, index) {
                            final player = _filteredPlayers[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: isMobile ? 6 : 8),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 12 : 16,
                                  vertical: isMobile ? 4 : 8,
                                ),
                                leading: CircleAvatar(
                                  radius: isMobile ? 20 : 24,
                                  backgroundColor: _primaryPurple,
                                  backgroundImage: player.profileImageUrl != null && player.profileImageUrl!.isNotEmpty
                                      ? NetworkImage(getProxiedUrl(player.profileImageUrl))
                                      : null,
                                  onBackgroundImageError: (exception, stackTrace) {
                                    // Error loading image, will show child instead
                                  },
                                  child: player.profileImageUrl == null || player.profileImageUrl!.isEmpty
                                      ? Text(
                                          player.name.isNotEmpty 
                                              ? player.name[0].toUpperCase() 
                                              : '?',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: isMobile ? 14 : 16,
                                          ),
                                        )
                                      : null,
                                ),
                                title: Text(
                                  player.name,
                                  style: TextStyle(fontSize: isMobile ? 14 : 16),
                                ),
                                subtitle: Text(
                                  '${player.nationality ?? '-'} • ${_formatCurrency(player.marketValue)}',
                                  style: TextStyle(fontSize: isMobile ? 11 : 13),
                                ),
                                trailing: Chip(
                                  label: Text(
                                    player.position,
                                    style: TextStyle(fontSize: isMobile ? 10 : 12),
                                  ),
                                  backgroundColor: _primaryPurple.withValues(alpha: 0.2),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 6 : 8,
                                    vertical: isMobile ? 0 : 4,
                                  ),
                                ),
                                onTap: () => _handlePlayerSelect(player),
                              ),
                            );
                          },
                        ),
                );
              },
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


