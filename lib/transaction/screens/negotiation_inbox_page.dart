import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../core/providers/user_provider.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

class NegotiationInboxPage extends StatefulWidget {
  const NegotiationInboxPage({super.key});

  @override
  State<NegotiationInboxPage> createState() => _NegotiationInboxPageState();
}

class _NegotiationInboxPageState extends State<NegotiationInboxPage> with SingleTickerProviderStateMixin {
  final TransactionService _service = TransactionService(
    CookieRequest(),
  );
  List<Negotiation> _receivedOffers = [];
  List<Negotiation> _sentOffers = [];
  bool _isLoading = true;
  String? _errorMessage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNegotiations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNegotiations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _service.fetchNegotiationInbox();
      setState(() {
        _receivedOffers = result['received'] ?? [];
        _sentOffers = result['sent'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'cancelled':
        return Colors.grey;
      default:
        return AppColors.warning;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return 'Diterima';
      case 'rejected':
        return 'Ditolak';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return 'Menunggu';
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
              onPressed: _loadNegotiations,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.secondary,
          tabs: const [
            Tab(text: 'Tawaran Masuk'),
            Tab(text: 'Tawaran Keluar'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildReceivedOffersList(service),
              _buildSentOffersList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReceivedOffersList(TransactionService service) {
    if (_receivedOffers.isEmpty) {
      return const Center(
        child: Text('Tidak ada tawaran masuk'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNegotiations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _receivedOffers.length,
        itemBuilder: (context, index) {
          final negotiation = _receivedOffers[index];
          final priceFormat = NumberFormat.currency(symbol: '€ ', decimalDigits: 0);
          final statusColor = _getStatusColor(negotiation.status);
          final statusText = _getStatusText(negotiation.status);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                            Text(
                              negotiation.player,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Dari: ${negotiation.fromClub}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Harga Tawaran: ${priceFormat.format(negotiation.offeredPrice)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tanggal: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(negotiation.createdAt))}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (negotiation.status == 'pending') ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _respondNegotiation(
                              context,
                              negotiation.id,
                              'reject',
                              service,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Tolak'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _respondNegotiation(
                              context,
                              negotiation.id,
                              'accept',
                              service,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Terima'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSentOffersList() {
    if (_sentOffers.isEmpty) {
      return const Center(
        child: Text('Tidak ada tawaran keluar'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNegotiations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sentOffers.length,
        itemBuilder: (context, index) {
          final negotiation = _sentOffers[index];
          final priceFormat = NumberFormat.currency(symbol: '€ ', decimalDigits: 0);
          final statusColor = _getStatusColor(negotiation.status);
          final statusText = _getStatusText(negotiation.status);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                            Text(
                              negotiation.player,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ke: ${negotiation.toClub}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Harga Tawaran: ${priceFormat.format(negotiation.offeredPrice)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tanggal: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(negotiation.createdAt))}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _respondNegotiation(
    BuildContext context,
    int negotiationId,
    String action,
    TransactionService service,
  ) async {
    final actionText = action == 'accept' ? 'menerima' : 'menolak';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(action == 'accept' ? 'Terima Tawaran' : 'Tolak Tawaran'),
        content: Text('Apakah Anda yakin ingin $actionText tawaran ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'accept' ? AppColors.success : AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(action == 'accept' ? 'Terima' : 'Tolak'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await service.respondNegotiation(negotiationId, action);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? ''),
          backgroundColor: result['success'] == true ? AppColors.success : AppColors.error,
        ),
      );

      if (result['success'] == true) {
        _loadNegotiations();
      }
    }
  }
}

