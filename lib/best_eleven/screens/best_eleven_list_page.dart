import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../models/best_eleven_models.dart';
import '../services/best_eleven_service.dart';
import 'best_eleven_builder_page.dart';

class BestElevenListPage extends StatefulWidget {
  const BestElevenListPage({super.key});

  @override
  State<BestElevenListPage> createState() => _BestElevenListPageState();
}

class _BestElevenListPageState extends State<BestElevenListPage> {
  final BestElevenService _service = BestElevenService();
  List<BestElevenFormation> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Fetch data after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    final request = context.read<CookieRequest>();
    
    // Check if user is logged in first
    if (!request.loggedIn) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda belum login. Silakan login terlebih dahulu.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        // Navigate back or to login page
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
      return;
    }
    
    try {
      print('Fetching best eleven list data...');
      final response = await _service.fetchBuilderData(request);
      print('List data received: ${response.keys}');
      
      if (response['history'] != null) {
        try {
          final historyList = response['history'] as List;
          print('Found ${historyList.length} formations in history');
          
          setState(() {
            _history = historyList.map((item) {
              try {
                // Mapping formatted response to BEFormation (lighter version for list)
                return BestElevenFormation(
                  id: item['id'],
                  name: item['name'] ?? 'Unnamed',
                  layout: item['layout'] ?? '4-3-3',
                  players: null, // Detail not loaded yet
                );
              } catch (e) {
                print('Error parsing formation item: $item, Error: $e');
                return null;
              }
            }).whereType<BestElevenFormation>().toList();
            _isLoading = false;
          });
          
          print('Loaded ${_history.length} formations');
        } catch (e) {
          print('Error parsing history: $e');
          setState(() {
            _history = [];
            _isLoading = false;
          });
        }
      } else {
        print('No history in response');
        setState(() {
          _history = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error in _fetchData: $e');
      print('Stack trace: ${StackTrace.current}');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        String errorMessage = 'Error loading history: $e';
        if (e.toString().contains('User belum login') || e.toString().contains('login')) {
          errorMessage = 'Sesi telah berakhir. Silakan login ulang.';
          // Navigate back after showing error
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _deleteFormation(int id, String name) async {
    final request = context.read<CookieRequest>();
    
    // Show confirmation dialog
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteFormation(request, id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Formasi berhasil dihapus')),
        );
        _fetchData(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus formasi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Best Elevens'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
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
                  onRefresh: _fetchData,
                  child: ListView.builder(
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final formation = _history[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteFormation(formation.id, formation.name),
                                tooltip: 'Hapus',
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                          onTap: () {
                            // Navigate to detail or builder with ID
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BestElevenBuilderPage(formationId: formation.id),
                              ),
                            ).then((_) => _fetchData()); // Refresh on return
                          },
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BestElevenBuilderPage(),
            ),
          ).then((_) => _fetchData());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
