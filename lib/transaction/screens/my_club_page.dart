import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../core/providers/user_provider.dart';
import '../../core/widgets/player_card.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

class MyClubPage extends StatefulWidget {
  const MyClubPage({super.key});

  @override
  State<MyClubPage> createState() => _MyClubPageState();
}

class _MyClubPageState extends State<MyClubPage> {
  final TransactionService _service = TransactionService(
    CookieRequest(),
  );
  List<MyPlayer> _players = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final players = await _service.fetchMyPlayers();
      setState(() {
        _players = players;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final service = TransactionService(request);
    final isClubAdmin = context.watch<UserProvider>().isClubAdmin;

    // Hanya admin club yang bisa akses
    if (!isClubAdmin) {
      return const Center(
        child: Text('Hanya Admin Club yang dapat mengakses halaman ini.'),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error: $_errorMessage',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
            ElevatedButton(
              onPressed: _loadPlayers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_players.isEmpty) {
      return const Center(
        child: Text('Tidak ada pemain di klub Anda'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPlayers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _players.length,
        itemBuilder: (context, index) {
          final player = _players[index];
          final priceFormat = NumberFormat.currency(symbol: '€ ', decimalDigits: 0);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => _showPlayerDetail(context, player, service),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        getProxiedUrl(player.thumbnail),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: const Icon(Icons.person, size: 40),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.namaPemain,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            player.posisi,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            priceFormat.format(player.marketValue),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        if (player.sedangDijual)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Dijual',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        if (player.sedangDijual)
                          ElevatedButton(
                            onPressed: () => _cancelSellPlayer(context, player, service),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            child: const Text('Batal Jual'),
                          )
                        else
                          ElevatedButton(
                            onPressed: () => _sellPlayer(context, player, service),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            child: const Text('Jual'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPlayerDetail(BuildContext context, MyPlayer player, TransactionService service) {
    final priceFormat = NumberFormat.currency(symbol: '€ ', decimalDigits: 0);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40), // Spacer untuk balance
                      const Text(
                        'Detail Pemain',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Image.network(
                      getProxiedUrl(player.thumbnail),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[300],
                          child: const Icon(Icons.person, size: 50),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      player.namaPemain,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          player.posisi,
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        if (player.sedangDijual) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Dijual',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Divider(height: 32),
                  _buildDetailRow('Umur', '${player.umur} tahun'),
                  _buildDetailRow('Negara', player.negara),
                  _buildDetailRow('Match', '${player.match}'),
                  _buildDetailRow('Goal', '${player.goal}'),
                  _buildDetailRow('Assist', '${player.assist}'),
                  _buildDetailRow('Market Value', priceFormat.format(player.marketValue)),
                  _buildDetailRow(
                    'Status',
                    player.sedangDijual ? 'Sedang Dijual' : 'Tidak Dijual',
                  ),
                  const SizedBox(height: 24),
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: player.sedangDijual
                            ? ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _cancelSellPlayer(context, player, service);
                                },
                                icon: const Icon(Icons.cancel),
                                label: const Text('Batalkan Penjualan'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              )
                            : ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _sellPlayer(context, player, service);
                                },
                                icon: const Icon(Icons.sell),
                                label: const Text('Jual Pemain'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  foregroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Future<void> _sellPlayer(BuildContext context, MyPlayer player, TransactionService service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Jual Pemain'),
        content: Text('Apakah Anda yakin ingin menjual ${player.namaPemain} ke Transfer Market?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.primary,
            ),
            child: const Text('Jual'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await service.sellPlayer(player.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? ''),
          backgroundColor: result['success'] == true ? AppColors.success : AppColors.error,
        ),
      );

      if (result['success'] == true) {
        _loadPlayers();
      }
    }
  }

  Future<void> _cancelSellPlayer(BuildContext context, MyPlayer player, TransactionService service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Penjualan'),
        content: Text('Apakah Anda yakin ingin membatalkan penjualan ${player.namaPemain}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Batalkan Penjualan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await service.cancelSellPlayer(player.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? ''),
          backgroundColor: result['success'] == true ? AppColors.success : AppColors.error,
        ),
      );

      if (result['success'] == true) {
        _loadPlayers();
      }
    }
  }
}
