import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../../account/screens/login.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/styles.dart';
import 'manage_users.dart';
import 'manage_clubs.dart';
import 'manage_players.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  Future<Map<String, dynamic>> fetchStats(CookieRequest request) async {
    final response = await request.get(
        'https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/accounts/api/admin/stats/');
    return response;
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Super Admin Dashboard", style: AppTextStyles.h3.copyWith(color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await request.logout(
                  "https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/auth/logout/");
              if (context.mounted) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Overview", style: AppTextStyles.h2),
            const SizedBox(height: 16),
            FutureBuilder(
              future: fetchStats(request),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError || !snapshot.hasData) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text("Gagal memuat data. Pastikan Anda Super Admin.", style: AppTextStyles.body.copyWith(color: AppColors.error)),
                  );
                }

                final data = snapshot.data! as Map<String, dynamic>;

                return Row(
                  children: [
                    _statCard("Users", data['user_count'] ?? 0, Icons.people, AppColors.primary),
                    const SizedBox(width: 12),
                    _statCard("Clubs", data['club_count'] ?? 0, Icons.shield, AppColors.primary),
                    const SizedBox(width: 12),
                    _statCard("Players", data['player_count'] ?? 0, Icons.sports_soccer, AppColors.primary),
                  ],
                );
              },
            ),
            const SizedBox(height: 30),
            Text("Management", style: AppTextStyles.h2),
            const SizedBox(height: 16),
            
            _menuItem(context, "Manage Users", Icons.people_outline, const ManageUsersPage()),
            _menuItem(context, "Manage Clubs", Icons.shield_outlined, const ManageClubsPage()),
            _menuItem(context, "Manage Players", Icons.sports_soccer_outlined, const ManagePlayersPage()),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, int count, IconData icon, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppBoxShadows.card,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: accentColor, size: 30),
            const SizedBox(height: 8),
            Text(count.toString(),
                style: AppTextStyles.h1.copyWith(color: AppColors.textPrimary)),
            Text(title, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
      BuildContext context, String title, IconData icon, Widget page) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppBoxShadows.card,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      ),
    );
  }
}