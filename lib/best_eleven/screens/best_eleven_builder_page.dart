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
  final BestElevenService _service = BestElevenService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _playerSearchController = TextEditingController();
  
  // Color theme
  static const Color _primaryPurple = Color(0xFF6B46C1);
  static const Color _accentPink = Color(0xFFD946A6);
  static const Color _cardBorder = Color(0xFF4A2C7C);
  static const Color _cardBg = Color(0xFFF5F8FC);
  static const Color _textLight = Color(0xFF4A2C7C);
  static const Color _textMuted = Color(0xFF2E0F32);
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _errorRed = Color(0xFFEF4444);
  
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
  
  // Formation layouts mapping
  static const Map<String, List<String>> _formationLayouts = {
    '4-3-3': ['GK', 'LB', 'LCB', 'RCB', 'RB', 'LCM', 'CM', 'RCM', 'LW', 'ST', 'RW'],
    '4-4-2': ['GK', 'LB', 'LCB', 'RCB', 'RB', 'LM', 'LCM', 'RCM', 'RM', 'LST', 'RST'],
    '3-5-2': ['GK', 'LCB', 'CB', 'RCB', 'LWB', 'LCM', 'RCM', 'RWB', 'CAM', 'LST', 'RST'],
    '4-2-3-1': ['GK', 'LB', 'LCB', 'RCB', 'RB', 'LDM', 'RDM', 'LAM', 'CAM', 'RAM', 'ST'],
  };
  
  // Slot to position mapping
  static const Map<String, String> _slotPositionMap = {
    'GK': 'Kiper',
    'LB': 'Bek-Kiri', 'LWB': 'Bek-Kiri',
    'LCB': 'Bek-Tengah', 'CB': 'Bek-Tengah', 'RCB': 'Bek-Tengah',
    'RB': 'Bek-Kanan', 'RWB': 'Bek-Kanan',
    'LDM': 'Gel. Bertahan', 'RDM': 'Gel. Bertahan',
    'LM': 'Sayap Kiri', 'LCM': 'Gel. Tengah', 'CM': 'Gel. Tengah', 'RCM': 'Gel. Tengah', 'RM': 'Sayap Kanan',
    'LAM': 'Sayap Kiri', 'CAM': 'Gel. Serang', 'RAM': 'Sayap Kanan',
    'LW': 'Sayap Kiri', 'RW': 'Sayap Kanan', 'LST': 'Penyerang', 'ST': 'Penyerang', 'RST': 'Penyerang'
  };
  
  // Position role mapping
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
  
  // Grid positions for 5x5 grid (row, col) - 0-indexed
  Map<String, (int, int)> _getGridPositions(String layout) {
    final Map<String, (int, int)> positions = {};
    
    if (layout == '4-3-3') {
      positions['GK'] = (4, 2);
      positions['LB'] = (3, 0);
      positions['LCB'] = (3, 1);
      positions['RCB'] = (3, 3);
      positions['RB'] = (3, 4);
      positions['LCM'] = (2, 1);
      positions['CM'] = (2, 2);
      positions['RCM'] = (2, 3);
      positions['LW'] = (1, 0);
      positions['ST'] = (1, 2);
      positions['RW'] = (1, 4);
    } else if (layout == '4-4-2') {
      positions['GK'] = (4, 2);
      positions['LB'] = (3, 0);
      positions['LCB'] = (3, 1);
      positions['RCB'] = (3, 3);
      positions['RB'] = (3, 4);
      positions['LM'] = (2, 0);
      positions['LCM'] = (2, 1);
      positions['RCM'] = (2, 3);
      positions['RM'] = (2, 4);
      positions['LST'] = (1, 1);
      positions['RST'] = (1, 3);
    } else if (layout == '3-5-2') {
      positions['GK'] = (4, 2);
      positions['LCB'] = (3, 1);
      positions['CB'] = (3, 2);
      positions['RCB'] = (3, 3);
      positions['LWB'] = (2, 0);
      positions['LCM'] = (2, 1);
      positions['CAM'] = (2, 2);
      positions['RCM'] = (2, 3);
      positions['RWB'] = (2, 4);
      positions['LST'] = (1, 1);
      positions['RST'] = (1, 3);
    } else if (layout == '4-2-3-1') {
      positions['GK'] = (4, 2);
      positions['LB'] = (3, 0);
      positions['LCB'] = (3, 1);
      positions['RCB'] = (3, 3);
      positions['RB'] = (3, 4);
      positions['LDM'] = (2, 1);
      positions['RDM'] = (2, 3);
      positions['LAM'] = (1, 0);
      positions['CAM'] = (1, 2);
      positions['RAM'] = (1, 4);
      positions['ST'] = (0, 2);
    }
    
    return positions;
  }

  @override
  void initState() {
    super.initState();
    _playerSearchController.addListener(_filterPlayers);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _playerSearchController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    final request = context.read<CookieRequest>();
    
    // Check if user is logged in first
    if (!request.loggedIn) {
      setState(() {
        _isLoading = false;
      });
      _showStatus('Anda belum login. Silakan login terlebih dahulu.', true, duration: 5000);
      // Navigate back after showing error
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
      return;
    }
    
    try {
      _showStatus('Memuat klub & riwayat...', false);
      
      final builderData = await _service.fetchBuilderData(request);
      
      setState(() {
        if (builderData['clubs'] != null) {
          final clubsList = builderData['clubs'] as List;
          _clubs = clubsList
              .map((c) => BestElevenClub.fromJson(c as Map<String, dynamic>))
              .whereType<BestElevenClub>()
              .toList();
        }
        
        if (builderData['history'] != null) {
          final historyList = builderData['history'] as List;
          _history = historyList.map((item) {
            return BestElevenFormation(
              id: item['id'],
              name: item['name'] ?? 'Unnamed',
              layout: item['layout'] ?? '4-3-3',
              players: null,
            );
          }).toList();
        }
      });

      await _fetchPlayers();
      
      if (widget.formationId != null) {
        await _loadFormation(widget.formationId!);
      }
      
      setState(() {
        _isLoading = false;
      });
      
      _showStatus('Siap! Pilih slot di lapangan.', false, duration: 3000);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showStatus('Error: $e', true, duration: 8000);
    }
  }

  Future<void> _fetchPlayers({int? clubId}) async {
    final request = context.read<CookieRequest>();
    try {
      _showStatus('Memuat daftar pemain...', false, duration: 2000);
      
      final players = await _service.fetchPlayers(request, clubId: clubId);
      
      setState(() {
        _allPlayers = players;
      });
      
      _filterPlayers();
      _showStatus('Daftar pemain diperbarui.', false, duration: 2000);
    } catch (e) {
      _showStatus('Error: $e', true, duration: 4000);
    }
  }

  void _filterPlayers() {
    final searchTerm = _playerSearchController.text.toLowerCase().trim();
    final requiredRole = _selectedSlotId != null ? _slotPositionMap[_selectedSlotId] : null;
    
    setState(() {
      _filteredPlayers = _allPlayers.where((player) {
        // Filter by search term
        if (searchTerm.isNotEmpty) {
          if (!player.name.toLowerCase().contains(searchTerm)) {
            return false;
          }
        }
        
        // Filter by position if slot is selected
        if (requiredRole != null) {
          final playerRoles = _positionRoleMap[player.position];
          if (playerRoles == null || !playerRoles.contains(requiredRole)) {
            return false;
          }
        }
        
        // Exclude already selected players
        if (_selectedPlayers.values.any((p) => p.id == player.id)) {
          return false;
        }
        
        return true;
      }).toList();
    });
  }

  Future<void> _loadFormation(int id) async {
    final request = context.read<CookieRequest>();
    try {
      _showStatus('Memuat formasi...', false, duration: 5000);
      
      final formation = await _service.fetchFormationDetails(request, id);
      
      setState(() {
        _currentFormationId = formation.id;
        _selectedLayout = formation.layout;
        _nameController.text = formation.name;
        _selectedPlayers.clear();
        
        if (formation.players != null) {
          for (var p in formation.players!) {
            if (p.slotId != null && p.slotId!.isNotEmpty) {
              _selectedPlayers[p.slotId!] = p;
            }
          }
        }
      });
      
      await _fetchPlayers();
      _showStatus('Formasi "${formation.name}" dimuat.', false, duration: 3000);
    } catch (e) {
      _showStatus('Error: $e', true, duration: 8000);
      _clearFormation(showMsg: false, isCreatingNew: true);
    }
  }

  Future<void> _saveFormation() async {
    if (_nameController.text.trim().isEmpty) {
      _showStatus('Nama formasi wajib diisi.', true, duration: 3000);
      return;
    }
    
    final slots = _formationLayouts[_selectedLayout] ?? [];
    if (_selectedPlayers.length != 11) {
      _showStatus('Harap lengkapi 11 pemain. Saat ini: ${_selectedPlayers.length}/11', true, duration: 3000);
      return;
    }
    
    for (var slot in slots) {
      if (!_selectedPlayers.containsKey(slot)) {
        _showStatus('Slot $slot belum diisi.', true, duration: 3000);
        return;
      }
    }

    final request = context.read<CookieRequest>();
    final playerIds = _selectedPlayers.entries.map((e) {
      return {'playerId': e.value.id, 'slotId': e.key};
    }).toList();

    _showStatus('Menyimpan formasi...', false, duration: 10000);
    
    try {
      final response = await _service.saveFormation(
        request,
        name: _nameController.text.trim(),
        layout: _selectedLayout,
        playerIds: playerIds,
        formationId: _currentFormationId,
      );

      if (response['success'] == true || response['formation'] != null) {
        final formationData = response['formation'] ?? {
          'id': _currentFormationId,
          'name': _nameController.text.trim(),
          'layout': _selectedLayout,
        };
        
        setState(() {
          _currentFormationId = formationData['id'];
          
          // Update history
          final idx = _history.indexWhere((h) => h.id == _currentFormationId);
          if (idx >= 0) {
            _history[idx] = BestElevenFormation(
              id: formationData['id'],
              name: formationData['name'],
              layout: formationData['layout'],
            );
          } else {
            _history.insert(0, BestElevenFormation(
              id: formationData['id'],
              name: formationData['name'],
              layout: formationData['layout'],
            ));
          }
        });
        
        _showStatus(response['message'] ?? 'Formasi disimpan!', false, duration: 3000);
      } else {
        _showStatus(response['error'] ?? 'Gagal menyimpan.', true, duration: 6000);
      }
    } catch (e) {
      _showStatus('Error: $e', true, duration: 6000);
    }
  }

  Future<void> _deleteFormation(int id, String name) async {
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final request = context.read<CookieRequest>();
    _showStatus('Menghapus "$name"...', false, duration: 5000);
    
    try {
      await _service.deleteFormation(request, id);
      
      setState(() {
        _history.removeWhere((h) => h.id == id);
        if (_currentFormationId == id) {
          _clearFormation(showMsg: false, isCreatingNew: true);
        }
      });
      
      _showStatus('Formasi "$name" dihapus.', false, duration: 3000);
    } catch (e) {
      _showStatus('Error: $e', true, duration: 6000);
    }
  }

  Future<void> _showFormationDetails(int id) async {
    final request = context.read<CookieRequest>();
    try {
      final formation = await _service.fetchFormationDetails(request, id);
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            formation.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _primaryPurple),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Formasi: ${formation.layout}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                if (formation.players == null || formation.players!.isEmpty)
                  const Text('Tidak ada pemain di formasi ini.', style: TextStyle(fontStyle: FontStyle.italic))
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: formation.players!.length,
                      itemBuilder: (context, index) {
                        final player = formation.players![index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: player.profileImageUrl.isNotEmpty
                                    ? NetworkImage(player.profileImageUrl)
                                    : null,
                                child: player.profileImageUrl.isEmpty
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      player.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      player.position,
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _primaryPurple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Slot: ${player.slotId ?? 'N/A'}',
                                  style: const TextStyle(fontSize: 12, color: _primaryPurple, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kembali'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        _showStatus('Error: $e', true, duration: 6000);
      }
    }
  }

  void _handleSlotClick(String slotId) {
    final playerInSlot = _selectedPlayers[slotId];
    
    if (playerInSlot != null) {
      // Remove player from slot
      setState(() {
        _selectedPlayers.remove(slotId);
        _selectedSlotId = null;
      });
      _filterPlayers();
      _showStatus('Pemain ${playerInSlot.name} dihapus.', false, duration: 3000);
    } else {
      // Select/deselect slot
      if (_selectedSlotId == slotId) {
        setState(() {
          _selectedSlotId = null;
        });
        _showStatus('Pemilihan slot $slotId dibatalkan.', false, duration: 2500);
      } else {
        setState(() {
          _selectedSlotId = slotId;
        });
        final requiredRole = _slotPositionMap[slotId];
        _showStatus('Memilih pemain untuk $slotId (${requiredRole ?? 'N/A'})', false, duration: 2000);
      }
      _filterPlayers();
    }
  }

  void _handlePlayerSelect(BestElevenPlayer player) {
    if (_selectedSlotId == null) {
      _showStatus('Harap pilih slot di lapangan terlebih dahulu!', true, duration: 3000);
      return;
    }
    
    if (_selectedPlayers.length >= 11) {
      _showStatus('Skuad penuh (11 pemain).', true, duration: 3000);
      return;
    }
    
    final requiredRole = _slotPositionMap[_selectedSlotId];
    final playerRoles = _positionRoleMap[player.position];
    
    if (playerRoles == null || !playerRoles.contains(requiredRole)) {
      _showStatus('Posisi tidak cocok! Slot $_selectedSlotId membutuhkan $requiredRole, tapi pemain ini adalah ${player.position}.', true, duration: 4000);
      return;
    }
    
    if (_selectedPlayers.values.any((p) => p.id == player.id)) {
      _showStatus('${player.name} sudah ada di skuad.', true, duration: 3000);
      return;
    }
    
    final slotId = _selectedSlotId!;
    setState(() {
      _selectedPlayers[slotId] = player;
      _selectedSlotId = null;
    });
    
    _filterPlayers();
    _showStatus('${player.name} ditambahkan ke slot $slotId.', false, duration: 3000);
  }

  void _handleLayoutChange(String? newLayout) {
    if (newLayout == null) return;
    
    setState(() {
      _selectedLayout = newLayout;
      final newSlots = _formationLayouts[newLayout] ?? [];
      _selectedPlayers.removeWhere((slotId, _) => !newSlots.contains(slotId));
      _selectedSlotId = null;
    });
    
    _filterPlayers();
  }

  void _handleClubChange(int? clubId) {
    setState(() {
      _selectedClubId = clubId;
      _selectedSlotId = null;
    });
    _fetchPlayers(clubId: clubId);
  }

  void _clearFormation({bool showMsg = true, bool isCreatingNew = false}) {
    setState(() {
      _selectedPlayers.clear();
      _selectedSlotId = null;
      if (isCreatingNew) {
        _currentFormationId = null;
        _nameController.clear();
        _selectedLayout = '4-3-3';
      }
    });
    _filterPlayers();
    if (showMsg) {
      _showStatus('Formasi dikosongkan.', false, duration: 3000);
    }
  }

  void _showStatus(String? message, bool isError, {int duration = 4000}) {
    if (!mounted) return;
    
    setState(() {
      _statusMessage = message;
      _isStatusError = isError;
    });
    
    if (message != null && duration > 0) {
      Future.delayed(Duration(milliseconds: duration), () {
        if (mounted && _statusMessage == message) {
          setState(() {
            _statusMessage = null;
          });
        }
      });
    }
  }

  String _formatMarketValue(int value) {
    if (value == 0) return 'N/A';
    try {
      return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(value);
    } catch (e) {
      return 'Rp ${value.toString()}';
    }
  }

  bool _isFormComplete() {
    return _selectedPlayers.length == 11 && _nameController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isLargeScreen = constraints.maxWidth > 1200;
                final isMediumScreen = constraints.maxWidth > 800;
                
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Title
                      const Text(
                        'Best XI Team Builder',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: _primaryPurple,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      
                      // Status message
                      if (_statusMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: _isStatusError
                                ? _errorRed.withOpacity(0.1)
                                : _successGreen.withOpacity(0.1),
                            border: Border.all(
                              color: _isStatusError ? _errorRed : _successGreen,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _statusMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _isStatusError ? _errorRed : _successGreen,
                            ),
                          ),
                        ),
                      
                      // Main grid layout
                      isLargeScreen
                          ? ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: constraints.maxWidth,
                                minHeight: 600,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // History Card
                                  Expanded(
                                    flex: 1,
                                    child: _buildHistoryCard(),
                                  ),
                                  const SizedBox(width: 24),
                                  // Pitch Card
                                  Expanded(
                                    flex: 2,
                                    child: _buildPitchCard(),
                                  ),
                                  const SizedBox(width: 24),
                                  // Player List Card
                                  Expanded(
                                    flex: 1,
                                    child: _buildPlayerListCard(),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                // History Card
                                _buildHistoryCard(),
                                const SizedBox(height: 16),
                                // Pitch Card
                                _buildPitchCard(),
                                const SizedBox(height: 16),
                                // Player List Card
                                _buildPlayerListCard(),
                              ],
                            ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildHistoryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBg,
        border: Border.all(color: _cardBorder, width: 2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryPurple.withOpacity(0.12),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Text(
                '💾 Formasi Tersimpan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textLight,
                ),
              ),
            ],
          ),
          const Divider(color: _cardBorder, thickness: 2, height: 32),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: _history.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'Belum ada formasi tersimpan.',
                        style: TextStyle(
                          color: _textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final formation = _history[index];
                      final isCurrent = _currentFormationId == formation.id;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFFE3DCEF)
                              : _cardBg,
                          border: Border.all(
                            color: isCurrent ? _accentPink : _cardBorder,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: _accentPink.withOpacity(0.08),
                                    blurRadius: 20,
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    formation.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _textLight,
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.visibility, size: 20),
                                      color: _textLight,
                                      onPressed: () => _showFormationDetails(formation.id),
                                      tooltip: 'Lihat Detail',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20),
                                      color: _errorRed,
                                      onPressed: () => _deleteFormation(formation.id, formation.name),
                                      tooltip: 'Hapus',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Formasi: ${formation.layout}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: _textMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => _loadFormation(formation.id),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Muat Formasi',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _clearFormation(showMsg: true, isCreatingNew: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryPurple,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '+ FORMASI BARU',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPitchCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBg,
        border: Border.all(color: _cardBorder, width: 2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryPurple.withOpacity(0.12),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Formation name and layout selector
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
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _cardBorder, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _primaryPurple, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedLayout,
                  items: _layouts.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                  onChanged: _handleLayoutChange,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _cardBorder, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _cardBorder, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _primaryPurple, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Pitch visualization
          SizedBox(
            height: 550,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green[800],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 40,
                  ),
                ],
              ),
              child: _buildPitch(),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          Row(
            children: [
              ElevatedButton(
                onPressed: () => _clearFormation(showMsg: true, isCreatingNew: false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Kosongkan Pemain',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isFormComplete() ? _saveFormation : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryPurple,
                    disabledBackgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _isFormComplete()
                        ? (_currentFormationId != null ? '💾 Perbarui' : '💾 Simpan Formasi')
                        : _selectedPlayers.length < 11
                            ? 'Pilih ${11 - _selectedPlayers.length} lagi'
                            : '✏️ Tambah Nama',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPitch() {
    final gridPositions = _getGridPositions(_selectedLayout);
    final slots = _formationLayouts[_selectedLayout] ?? [];
    
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
          return const SizedBox.shrink();
        }
        
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Field lines
            CustomPaint(
              painter: _FieldPainter(),
              size: Size(constraints.maxWidth, constraints.maxHeight),
            ),
            
            // Player slots using grid
            ...slots.map((slotId) {
              final pos = gridPositions[slotId] ?? (2, 2);
              final player = _selectedPlayers[slotId];
              final isSelected = _selectedSlotId == slotId;
              
              // Calculate position based on 5x5 grid
              final cellWidth = constraints.maxWidth / 5;
              final cellHeight = constraints.maxHeight / 5;
              final left = (pos.$2 * cellWidth + (cellWidth / 2) - 40).clamp(0.0, constraints.maxWidth - 80);
              final top = (pos.$1 * cellHeight + (cellHeight / 2) - 40).clamp(0.0, constraints.maxHeight - 80);
              
              return Positioned(
                left: left,
                top: top,
                child: GestureDetector(
                  onTap: () => _handleSlotClick(slotId),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? _accentPink : (player != null ? _primaryPurple : Colors.white.withOpacity(0.6)),
                              width: isSelected ? 4 : 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: player != null
                              ? ClipOval(
                                  child: player.profileImageUrl.isNotEmpty
                                      ? Image.network(
                                          player.profileImageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 40),
                                        )
                                      : const Icon(Icons.person, color: Colors.white, size: 40),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _primaryPurple.withOpacity(0.28),
                                  ),
                                  child: Center(
                                    child: Text(
                                      slotId,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: player != null
                                ? null
                                : const LinearGradient(
                                    colors: [Color.fromRGBO(107, 70, 193, 0.9), Color.fromRGBO(217, 70, 166, 0.9)],
                                  ),
                            color: player != null ? Colors.black87 : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          constraints: const BoxConstraints(maxWidth: 100),
                          child: Text(
                            player?.name ?? '(Kosong)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildPlayerListCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBg,
        border: Border.all(color: _cardBorder, width: 2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryPurple.withOpacity(0.12),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
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
          const Divider(color: _cardBorder, thickness: 2, height: 32),
          
          // Club filter
          const Text(
            'Filter berdasarkan Klub',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _textLight,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int?>(
            value: _selectedClubId,
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Semua Klub')),
              ..._clubs.map((club) => DropdownMenuItem<int?>(value: club.id, child: Text(club.name))),
            ],
            onChanged: _handleClubChange,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _cardBorder, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _cardBorder, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _primaryPurple, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          
          // Search input
          const Text(
            'Cari Nama Pemain',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _textLight,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _playerSearchController,
            decoration: InputDecoration(
              hintText: 'Ketik nama pemain....',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _cardBorder, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _cardBorder, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _primaryPurple, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          
          // Filter label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedSlotId != null
                    ? 'Filter: ${_slotPositionMap[_selectedSlotId]}'
                    : 'Pilih klub atau posisi',
                style: const TextStyle(
                  fontSize: 12,
                  color: _textLight,
                ),
              ),
              if (_selectedSlotId != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedSlotId = null;
                    });
                    _filterPlayers();
                  },
                  child: const Text(
                    '✕ Hapus Filter',
                    style: TextStyle(color: _errorRed, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Player list
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 600),
            child: _filteredPlayers.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'Tidak ada pemain yang cocok.',
                        style: TextStyle(
                          color: _textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredPlayers.length,
                    itemBuilder: (context, index) {
                      final player = _filteredPlayers[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _cardBg,
                          border: Border.all(color: _cardBorder, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () => _handlePlayerSelect(player),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundImage: player.profileImageUrl.isNotEmpty
                                    ? NetworkImage(player.profileImageUrl)
                                    : null,
                                child: player.profileImageUrl.isEmpty
                                    ? const Icon(Icons.person)
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
                                        color: _textLight,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          player.nationality,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: _textMuted,
                                          ),
                                        ),
                                        const Text(' • ', style: TextStyle(color: _textMuted)),
                                        Text(
                                          _formatMarketValue(player.marketValue),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: _successGreen,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _primaryPurple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  player.position,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _textLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
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

// Custom painter for field lines
class _FieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    // Center line
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
    
    // Center circle
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.15,
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
