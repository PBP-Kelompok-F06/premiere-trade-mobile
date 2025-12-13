import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../core/providers/user_provider.dart';
import '../../core/widgets/player_card.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

class TransferMarketPage extends StatefulWidget {
  const TransferMarketPage({super.key});

  @override
  State<TransferMarketPage> createState() => _TransferMarketPageState();
}

class _TransferMarketPageState extends State<TransferMarketPage> {
  final TransactionService _service = TransactionService(
    CookieRequest(),
  );
  List<PlayerForSale> _players = [];
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
      final players = await _service.fetchPlayersForSale();
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
    final isClubAdmin = context.watch<UserProvider>().isClubAdmin;
    final request = context.watch<CookieRequest>();
    final service = TransactionService(request);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $_errorMessage',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
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
        child: Text('Tidak ada pemain yang sedang dijual'),
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  player.namaPemain,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (player.isMyClub)
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
                                    'Pemain Anda',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            player.posisi,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            player.namaKlub,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
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
                    if (isClubAdmin && !player.isMyClub) ...[
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              _sendNegotiation(context, player, service);
                            },
                            icon: const Icon(Icons.handshake, size: 18),
                            label: const Text('Negosiasi'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          ElevatedButton.icon(
                            onPressed: () {
                              _buyPlayer(context, player, service);
                            },
                            icon: const Icon(Icons.shopping_cart, size: 18),
                            label: const Text('Beli'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPlayerDetail(BuildContext context, PlayerForSale player, TransactionService service) {
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
                    child: Text(
                      player.posisi,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ),
                  const Divider(height: 32),
                  _buildDetailRow('Klub', player.namaKlub),
                  _buildDetailRow('Umur', '${player.umur} tahun'),
                  _buildDetailRow('Negara', player.negara),
                  _buildDetailRow('Match', '${player.match}'),
                  _buildDetailRow('Goal', '${player.goal}'),
                  _buildDetailRow('Assist', '${player.assist}'),
                  _buildDetailRow('Market Value', priceFormat.format(player.marketValue)),
                  const SizedBox(height: 24),
                  // Tombol hanya muncul untuk admin club dan bukan pemain sendiri
                  Builder(
                    builder: (context) {
                      final isClubAdmin = context.watch<UserProvider>().isClubAdmin;
                      if (!isClubAdmin) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Hanya Admin Club yang dapat membeli atau menegosiasi pemain.',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      // Jika pemain dari klub sendiri, tampilkan pesan
                      if (player.isMyClub) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Ini adalah pemain dari klub Anda. Anda tidak dapat membeli atau menegosiasi pemain sendiri.',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _sendNegotiation(context, player, service);
                              },
                              icon: const Icon(Icons.handshake),
                              label: const Text('Negosiasi'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _buyPlayer(context, player, service);
                              },
                              icon: const Icon(Icons.shopping_cart),
                              label: const Text('Beli Langsung'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
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

  Future<void> _buyPlayer(BuildContext context, PlayerForSale player, TransactionService service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Beli Pemain'),
        content: Text('Apakah Anda yakin ingin membeli ${player.namaPemain} dengan harga ${NumberFormat.currency(symbol: '€ ', decimalDigits: 0).format(player.marketValue)}?'),
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
            child: const Text('Beli'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await service.buyPlayer(player.id);

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

  Future<void> _sendNegotiation(BuildContext context, PlayerForSale player, TransactionService service) async {
    final priceController = TextEditingController(
      text: player.marketValue.toStringAsFixed(0),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kirim Tawaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Masukkan harga tawaran untuk ${player.namaPemain}:'),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Harga Tawaran',
                prefixText: '€ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final offeredPrice = double.tryParse(priceController.text);
    if (offeredPrice == null || offeredPrice <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Harga tidak valid'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final result = await service.sendNegotiation(player.id, offeredPrice);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? ''),
          backgroundColor: result['success'] == true ? AppColors.success : AppColors.error,
        ),
      );
    }
  }
}

