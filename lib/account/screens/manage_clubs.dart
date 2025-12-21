import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/styles.dart';
import '../../core/widgets/primary_button.dart';

class ManageClubsPage extends StatefulWidget {
  const ManageClubsPage({super.key});
  @override
  State<ManageClubsPage> createState() => _ManageClubsPageState();
}

class _ManageClubsPageState extends State<ManageClubsPage> {
  Future<List<dynamic>> fetchClubs(CookieRequest request) async {
    final response = await request.get('https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/accounts/api/admin/clubs/');
    return response['data'];
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Manage Clubs", style: AppTextStyles.h3.copyWith(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.secondary,
        child: const Icon(Icons.add, color: AppColors.primary),
        onPressed: () => _showAddClubDialog(context, request),
      ),
      body: FutureBuilder(
        future: fetchClubs(request),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final clubs = snapshot.data! as List<dynamic>;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: clubs.length,
            itemBuilder: (ctx, i) {
              final c = clubs[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppBoxShadows.card,
                ),
                child: ListTile(
                  leading: Container(
                    width: 40, height: 40,
                    padding: const EdgeInsets.all(4),
                    child: Image.network(c['logo_url'], 
                      errorBuilder: (_,__,___)=> Icon(Icons.shield, color: AppColors.secondary),
                    ),
                  ),
                  title: Text(c['name'], style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Text(c['country'], style: AppTextStyles.caption),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: () async {
                      await request.post('https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/accounts/api/admin/clubs/${c['id']}/delete/', {});
                      setState((){});
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddClubDialog(BuildContext context, CookieRequest request) {
    String name="", country="", logoUrl="";
    
    InputDecoration inputDecor(String label) {
      return InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Add Club", style: AppTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: inputDecor("Name"), onChanged: (v)=>name=v),
            const SizedBox(height: 12),
            TextField(decoration: inputDecor("Country"), onChanged: (v)=>country=v),
            const SizedBox(height: 12),
            TextField(decoration: inputDecor("Logo URL"), onChanged: (v)=>logoUrl=v),
          ],
        ),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text("Save"),
            onPressed: () async {
              await request.postJson("https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/accounts/api/admin/clubs/create/", 
                jsonEncode({"name":name, "country":country, "logo_url":logoUrl}));
              if(context.mounted) {
                Navigator.pop(ctx);
                setState((){});
              }
            }, 
          ),
        ],
      ),
    );
  }
}