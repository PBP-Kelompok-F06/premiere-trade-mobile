import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'register.dart';
import '../../main/screens/scaffold.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/styles.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/providers/user_provider.dart';
import 'admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // Helper Style Input
  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: AppColors.primary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 1. BACKGROUND IMAGE
          Positioned.fill(
            child: Image.asset(
              'assets/images/login-background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // 2. OVERLAY GELAP
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),

          // 3. KONTEN TENGAH
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // (Logo dipindah ke dalam Card)

                  // CARD CONTAINER MODERN
                  Container(
                    width: size.width > 600 ? 500 : double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 40, horizontal: 30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                            spreadRadius: 5),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- LOGO DI DALAM CARD ---
                        Center(
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 80,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.sports_soccer,
                                size: 80,
                                color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          "Welcome Back",
                          textAlign: TextAlign.center,
                          style: AppTextStyles.h2.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 28),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Sign in to continue to Premiere Trade",
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(fontSize: 14),
                        ),
                        const SizedBox(height: 40),

                        // INPUT USERNAME
                        TextField(
                          controller: _usernameController,
                          decoration:
                              _inputDecor('Username', Icons.person_outline),
                        ),
                        const SizedBox(height: 20),

                        // INPUT PASSWORD
                        TextField(
                          controller: _passwordController,
                          decoration:
                              _inputDecor('Password', Icons.lock_outline),
                          obscureText: true,
                        ),
                        const SizedBox(height: 40),

                        // TOMBOL LOGIN
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : SizedBox(
                                height: 55,
                                child: PremiereButton(
                                  text: "LOGIN",
                                  onPressed: () async {
                                    setState(() => _isLoading = true);
                                    String username = _usernameController.text;
                                    String password = _passwordController.text;
                                    const String url =
                                        "https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/auth/login/";

                                    try {
                                      final response =
                                          await request.login(url, {
                                        'username': username,
                                        'password': password,
                                      });

                                      if (request.loggedIn) {
                                        String message = response['message'];
                                        String uname = response['username'];

                                        if (context.mounted) {
                                          context
                                              .read<UserProvider>()
                                              .setUsername(uname);
                                          Widget nextPage =
                                              const MainScaffold();

                                          try {
                                            final profileResponse =
                                                await request.get(
                                                    'https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/accounts/api/profile/');

                                            if (profileResponse != null) {
                                              String role =
                                                  profileResponse['role'] ??
                                                      "Fan";
                                              bool isClubAdmin =
                                                  (role == 'Club Admin');
                                              if (context.mounted) {
                                                context
                                                    .read<UserProvider>()
                                                    .setIsClubAdmin(
                                                        isClubAdmin);
                                              }
                                              if (role == 'Super Admin') {
                                                nextPage =
                                                    const AdminDashboardPage();
                                              }
                                            }
                                          } catch (e) {
                                            print('Error fetching profile: $e');
                                          }

                                          if (context.mounted) {
                                            // PENGGUNAAN pushReplacement (Aman dari Back Button)
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      nextPage),
                                            );
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      "$message Selamat datang, $uname."),
                                                  backgroundColor:
                                                      AppColors.success),
                                            );
                                          }
                                        }
                                      } else {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    response['message'] ??
                                                        "Login gagal"),
                                                backgroundColor:
                                                    AppColors.error),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      // Error handling
                                    } finally {
                                      if (mounted)
                                        setState(() => _isLoading = false);
                                    }
                                  },
                                ),
                              ),

                        const SizedBox(height: 24),

                        // LINK REGISTER (PushReplacement agar tidak numpuk)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("New user? ",
                                style: AppTextStyles.body
                                    .copyWith(color: Colors.grey[600])),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const RegisterScreen()),
                                );
                              },
                              child: Text("Create an account",
                                  style: AppTextStyles.body.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
