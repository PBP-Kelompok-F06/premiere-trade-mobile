import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'login.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/styles.dart';
import '../../core/widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controller
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

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
                  // (Logo dipindah ke dalam Card di bawah)

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
                                Icons.person_add,
                                size: 80,
                                color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          "Create Account",
                          textAlign: TextAlign.center,
                          style: AppTextStyles.h2.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 28),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Join us today!",
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(fontSize: 14),
                        ),
                        const SizedBox(height: 40),

                        // INPUT FIELDS
                        TextField(
                          controller: _usernameController,
                          decoration:
                              _inputDecor('Username', Icons.person_outline),
                        ),
                        const SizedBox(height: 20),

                        TextField(
                          controller: _passwordController,
                          decoration:
                              _inputDecor('Password', Icons.lock_outline),
                          obscureText: true,
                        ),
                        const SizedBox(height: 20),

                        TextField(
                          controller: _confirmPasswordController,
                          decoration:
                              _inputDecor('Confirm Password', Icons.lock_reset),
                          obscureText: true,
                        ),
                        const SizedBox(height: 40),

                        // === TOMBOL REGISTER ===
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : SizedBox(
                                height: 55,
                                child: PremiereButton(
                                  text: "REGISTER",
                                  onPressed: () async {
                                    // 1. Ambil Data
                                    String username = _usernameController.text;
                                    String password = _passwordController.text;
                                    String confirmPassword =
                                        _confirmPasswordController.text;

                                    // 2. Validasi Lokal
                                    if (password != confirmPassword) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text("Password tidak cocok!")),
                                      );
                                      return;
                                    }

                                    setState(() => _isLoading = true);

                                    // 3. URL & Request
                                    const String url =
                                        "https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/auth/register/";

                                    try {
                                      final response = await request.post(url, {
                                        'username': username,
                                        'password': password,
                                        'password_confirm': confirmPassword,
                                      });

                                      if (mounted) {
                                        if (response['status'] == true) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    "Akun berhasil dibuat! Silakan login.")),
                                          );
                                          // Pake pushReplacement agar user tidak bisa back ke register
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const LoginScreen()),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  response['message'] ??
                                                      "Register gagal"),
                                              backgroundColor: AppColors.error,
                                            ),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  "Terjadi kesalahan koneksi.")),
                                        );
                                      }
                                    } finally {
                                      if (mounted)
                                        setState(() => _isLoading = false);
                                    }
                                  },
                                ),
                              ),

                        const SizedBox(height: 24),

                        // LINK LOGIN (PushReplacement)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Already have an account? ",
                                style: AppTextStyles.body
                                    .copyWith(color: Colors.grey[600])),
                            GestureDetector(
                              onTap: () {
                                // Pake pushReplacement agar ga numpuk di stack
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const LoginScreen()),
                                );
                              },
                              child: Text("Login here",
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
