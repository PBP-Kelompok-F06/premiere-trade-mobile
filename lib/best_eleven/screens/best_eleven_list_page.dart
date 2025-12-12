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
  bool _hasNavigated = false;

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

      // Auto-navigate to builder if no formations and haven't navigated yet
      if (formations.isEmpty && !_hasNavigated && mounted) {
        _hasNavigated = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final navigatorContext = context;
          Navigator.push(
            navigatorContext,
            MaterialPageRoute(
              builder: (context) => const BestElevenBuilderPage(),
            ),
          ).then((_) {
            // Refresh after returning from builder
            if (mounted) {
              _fetchFormations();
            }
          });
        });
      }
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

    if (confirmed == true && mounted) {
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = MediaQuery.of(context).size.width < 600;
                      return Padding(
                        padding: EdgeInsets.all(isMobile ? 20 : 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: isMobile ? 48 : 64,
                              color: Colors.red,
                            ),
                            SizedBox(height: isMobile ? 12 : 16),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: isMobile ? 13 : 16,
                              ),
                            ),
                            SizedBox(height: isMobile ? 16 : 24),
                            ElevatedButton(
                              onPressed: _fetchFormations,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 24 : 32,
                                  vertical: isMobile ? 14 : 12,
                                ),
                                minimumSize: Size(0, isMobile ? 48 : 44),
                              ),
                              child: Text(
                                'Coba Lagi',
                                style: TextStyle(fontSize: isMobile ? 14 : 16),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                )
              : _formations.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchFormations,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isMobile = MediaQuery.of(context).size.width < 600;
                          return ListView.builder(
                            padding: EdgeInsets.all(isMobile ? 12 : 16),
                            itemCount: _formations.length,
                            itemBuilder: (context, index) {
                              final formation = _formations[index];
                              return Card(
                                margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 12 : 16,
                                    vertical: isMobile ? 8 : 12,
                                  ),
                                  leading: CircleAvatar(
                                    radius: isMobile ? 22 : 28,
                                    backgroundColor: Colors.indigo,
                                    child: Text(
                                      formation.layout,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isMobile ? 11 : 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    formation.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isMobile ? 15 : 16,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Formasi: ${formation.layout}',
                                    style: TextStyle(fontSize: isMobile ? 12 : 14),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: isMobile ? 22 : 24,
                                    ),
                                    onPressed: () => _deleteFormation(formation.id, formation.name),
                                    tooltip: 'Hapus',
                                    padding: EdgeInsets.all(isMobile ? 4 : 8),
                                    constraints: BoxConstraints(
                                      minWidth: isMobile ? 40 : 48,
                                      minHeight: isMobile ? 40 : 48,
                                    ),
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

