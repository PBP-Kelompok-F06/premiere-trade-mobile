import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../models/best_eleven_models.dart';
import '../services/best_eleven_service.dart';
import 'best_eleven_builder_page.dart';

class BestElevenListPage extends StatefulWidget {
  const BestElevenListPage({super.key});

  @override
  State<BestElevenListPage> createState() => BestElevenListPageState();
}

class BestElevenListPageState extends State<BestElevenListPage> {
  List<BestElevenFormation> _formations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchFormations();
    });
  }

  Future<void> _fetchFormations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final request = context.read<CookieRequest>();
      final service = BestElevenService(request);
      final formations = await service.fetchFormations();
      
      setState(() {
        _formations = formations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat formasi: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteFormation(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Formasi'),
        content: Text('Apakah Anda yakin ingin menghapus formasi "$name"?'),
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

    if (confirmed == true) {
      try {
        final request = context.read<CookieRequest>();
        final service = BestElevenService(request);
        final success = await service.deleteFormation(id);

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Formasi berhasil dihapus')),
            );
            _fetchFormations();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gagal menghapus formasi')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Removed Scaffold - using MainScaffold instead
    return _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchFormations,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : _formations.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sports_soccer, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Belum ada formasi yang dibuat.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchFormations,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _formations.length,
                        itemBuilder: (context, index) {
                          final formation = _formations[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.indigo,
                                child: Text(
                                  formation.layout,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                formation.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('Formasi: ${formation.layout}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteFormation(formation.id, formation.name),
                                tooltip: 'Hapus',
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BestElevenBuilderPage(formationId: formation.id),
                                  ),
                                ).then((_) => _fetchFormations());
                              },
                            ),
                          );
                        },
                      ),
                    );
  }
  
  // Public method to refresh data
  Future<void> refreshData() async {
    await _fetchFormations();
  }
}

