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
  dynamic fetchProfile(CookieRequest request) async {
    final response =
        await request.get('http://localhost:8000/accounts/api/profile/');
    return response;
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Container(
      color: AppColors.background,
      child: FutureBuilder(
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
                // Icon User Sederhana (Karena tidak ada field foto)
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 16),
 
                // Username & Role
                Text(
                  data['username'] ?? "User",
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    data['role'] ?? "Fan Account",
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 30),
 
                // Info Tile (Hanya data yang ada di Model)
                _buildInfoTile(Icons.email, "Email", data['email']),
                _buildInfoTile(
                    Icons.person_outline, "First Name", data['first_name']),
                _buildInfoTile(
                    Icons.person_outline, "Last Name", data['last_name']),
 
                const SizedBox(height: 30),
 
                PremiereButton(
                  text: "EDIT PROFILE",
                  onPressed: () async {
                    bool? result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(
                          currentEmail: data['email'] ?? "",
                          currentFirstName: data['first_name'] ?? "",
                          currentLastName: data['last_name'] ?? "",
                        ),
                      ),
                    );
                    if (result == true) setState(() {});
                  },
                ),
 
                const SizedBox(height: 12),
 
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      final response = await request
                          .logout("http://localhost:8000/auth/logout/");
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
                        style: TextStyle(color: AppColors.error)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String? value) {
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
                Text(
                  (value == null || value.isEmpty) ? "-" : value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
