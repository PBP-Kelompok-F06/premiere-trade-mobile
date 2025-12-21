import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/primary_button.dart';
import 'edit_profile.dart';
import 'login.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<Map<String, dynamic>> fetchProfile(CookieRequest request) async {
    final response = await request.get(
        'https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/accounts/api/profile/');
    return response;
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Profil Saya", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: fetchProfile(request),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              (snapshot.data as Map<String, dynamic>)['status'] == false) {
            return const Center(child: Text("Gagal memuat profil."));
          }

          final data = snapshot.data! as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 16),

                // Username
                Text(
                  data['username'] ?? "User",
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),

                // Role
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    data['role'] ?? "Member",
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 30),

                if (data['managed_club'] != null && data['managed_club'] != "-")
                  _buildInfoTile(
                      Icons.shield, "Managed Club", data['managed_club']),

                if (data['managed_club'] == null || data['managed_club'] == "-")
                  const Text("Tidak ada klub yang dikelola.",
                      style: TextStyle(color: Colors.grey)),

                const SizedBox(height: 30),

                // Tombol Edit (Ke Halaman Edit yang Baru)
                PremiereButton(
                  text: "EDIT PROFIL",
                  onPressed: () async {
                    bool? result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(
                          currentUsername: data['username'] ?? "",
                        ),
                      ),
                    );
                    if (result == true) setState(() {});
                  },
                ),

                const SizedBox(height: 12),

                // Tombol Logout
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      final response = await request.logout(
                          "https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id//auth/logout/");
                      if (context.mounted && response['status']) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("LOGOUT",
                        style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
