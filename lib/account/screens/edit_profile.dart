import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/primary_button.dart';
import 'login.dart'; // Untuk redirect setelah hapus akun

class EditProfileScreen extends StatefulWidget {
  final String currentUsername;

  const EditProfileScreen({
    super.key,
    required this.currentUsername,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _usernameController;
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.currentUsername);
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profil", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // === BAGIAN 1: EDIT USERNAME ===
            const Text("Informasi Akun",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: "Username",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.person),
              ),
              validator: (value) =>
                  value!.isEmpty ? "Username tidak boleh kosong" : null,
            ),

            const SizedBox(height: 30),

            // === BAGIAN 2: GANTI PASSWORD ===
            const Text("Ganti Password (Opsional)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("Kosongkan jika tidak ingin mengganti password.",
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),

            // Password Lama
            TextFormField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password Lama",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 12),

            // Password Baru
            TextFormField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password Baru",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 12),

            // Konfirmasi Password Baru
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Konfirmasi Password Baru",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.lock_reset),
              ),
              validator: (value) {
                if (_newPasswordController.text.isNotEmpty &&
                    value != _newPasswordController.text) {
                  return "Password baru tidak cocok";
                }
                return null;
              },
            ),

            const SizedBox(height: 30),

            // TOMBOL SIMPAN
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : PremiereButton(
                    text: "SIMPAN PERUBAHAN",
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() => _isLoading = true);
                        try {
                          final response = await request.postJson(
                            "https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/accounts/api/profile/edit/",
                            jsonEncode({
                              "username": _usernameController.text,
                              "old_password": _oldPasswordController.text,
                              "new_password": _newPasswordController.text,
                              "confirm_password":
                                  _confirmPasswordController.text,
                            }),
                          );

                          if (context.mounted) {
                            if (response['status'] == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(response['message'])),
                              );
                              Navigator.pop(context, true); // Refresh profile
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(response['message'] ?? "Gagal"),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          // Error handling
                        } finally {
                          if (mounted) setState(() => _isLoading = false);
                        }
                      }
                    },
                  ),

            const SizedBox(height: 50),

            // === BAGIAN 3: ZONA BERBAHAYA (HAPUS AKUN) ===
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.red, width: 2), // BORDER MERAH
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.red.withOpacity(0.1), blurRadius: 10)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Zona Berbahaya",
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Tindakan ini tidak dapat diurungkan. Ini akan menghapus akun Anda secara permanen.",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () =>
                          _showDeleteConfirmation(context, request),
                      child: const Text("HAPUS AKUN SAYA"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog Konfirmasi Hapus Akun
  void _showDeleteConfirmation(BuildContext context, CookieRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Akun?"),
        content: const Text(
            "Apakah Anda benar-benar yakin? Semua data Anda akan hilang."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
              setState(() => _isLoading = true);

              final response = await request.post(
                  "https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/accounts/api/profile/delete/",
                  {});

              if (context.mounted) {
                if (response['status'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Akun berhasil dihapus. Sampai jumpa.")),
                  );
                  // Redirect ke Login dan hapus semua route sebelumnya
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            response['message'] ?? "Gagal menghapus akun")),
                  );
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text("Ya, Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
