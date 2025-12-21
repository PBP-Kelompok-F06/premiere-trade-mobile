import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/styles.dart';
import '../../core/widgets/primary_button.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});
  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  Future<List<dynamic>> fetchUsers(CookieRequest request) async {
    final response = await request.get(
        'https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/accounts/api/admin/users/');
    return response['data'];
  }

  void deleteUser(CookieRequest request, int id) async {
    await request.post(
        'https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/accounts/api/admin/users/$id/delete/',
        {});
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Manage Users",
            style: AppTextStyles.h3.copyWith(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.secondary,
        child: const Icon(Icons.add, color: AppColors.primary),
        onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const AddUserPage()))
            .then((_) => setState(() {})),
      ),
      body: FutureBuilder(
        future: fetchUsers(request),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final users = snapshot.data! as List<dynamic>;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (ctx, i) {
              final u = users[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppBoxShadows.card,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(u['username'][0].toUpperCase(),
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold)),
                  ),
                  title: Text(u['username'],
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      "${u['role']} ${u['managed_club'] != '-' ? '(${u['managed_club']})' : ''}",
                      style: AppTextStyles.caption),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.error),
                    onPressed: () => deleteUser(request, u['id']),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});
  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey = GlobalKey<FormState>();
  String username = "", password = "", role = "fan";
  String? selectedClubId;
  List<dynamic> clubs = [];

  @override
  void initState() {
    super.initState();
    fetchClubs();
  }

  void fetchClubs() async {
    final request = Provider.of<CookieRequest>(context, listen: false);
    final response = await request.get(
        'https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/accounts/api/admin/clubs/');
    setState(() {
      clubs = response['data'];
    });
  }

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Add User",
            style: AppTextStyles.h3.copyWith(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              decoration: _inputDecor("Username", Icons.person),
              onChanged: (v) => username = v,
              validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: _inputDecor("Password", Icons.lock),
              obscureText: true,
              onChanged: (v) => password = v,
              validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField(
              value: role,
              items: const [
                DropdownMenuItem(value: "fan", child: Text("Fan")),
                DropdownMenuItem(value: "admin", child: Text("Club Admin")),
              ],
              onChanged: (v) => setState(() => role = v.toString()),
              decoration: _inputDecor("Role", Icons.admin_panel_settings),
            ),
            if (role == "admin") ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedClubId,
                hint: const Text("Pilih Klub"),
                items: clubs.map<DropdownMenuItem<String>>((c) {
                  return DropdownMenuItem(
                      value: c['id'].toString(), child: Text(c['name']));
                }).toList(),
                onChanged: (v) => setState(() => selectedClubId = v!),
                decoration: _inputDecor("Managed Club", Icons.shield),
              ),
            ],
            const SizedBox(height: 30),
            PremiereButton(
              text: "SAVE USER",
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final response = await request.postJson(
                      "https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/accounts/api/admin/users/create/",
                      jsonEncode({
                        "username": username,
                        "password": password,
                        "role": role,
                        "club_id": selectedClubId
                      }));
                  if (context.mounted && response['status'])
                    Navigator.pop(context);
                }
              },
            )
          ],
        ),
      ),
    );
  }
}
