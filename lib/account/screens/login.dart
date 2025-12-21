import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'register.dart';
import '../../main/screens/scaffold.dart';
import '../../core/constants/colors.dart';
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

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo atau Judul
              Image.asset('assets/images/logo.png', width: 250),
              const SizedBox(height: 16),
              // const Text(
              //   "PREMIERE TRADE",
              //   style: TextStyle(
              //     fontSize: 28,
              //     fontWeight: FontWeight.bold,
              //     color: AppColors.primary,
              //     letterSpacing: 1.5,
              //   ),
              // ),
              const SizedBox(height: 40),

              // Input Username
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Input Password
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock),
                  filled: true,
                  fillColor: Colors.white,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 32),

              // Tombol Login
              PremiereButton(
                text: "LOGIN",
                onPressed: () async {
                  setState(() => _isLoading = true);

                  String username = _usernameController.text;
                  String password = _passwordController.text;

                  // To connect Android emulator with Django on localhost, use URL http://10.0.2.2:8000
                  // If you using chrome, use URL http://localhost:8000
                  const String url =
                      "https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/auth/login/";

                  try {
                    final response = await request.login(url, {
                      'username': username,
                      'password': password,
                    });

                    if (request.loggedIn) {
                      String message = response['message'];
                      String uname = response['username'];

                      if (context.mounted) {
                        context.read<UserProvider>().setUsername(uname);

                        // Default navigasi ke MainScaffold (jika fetch gagal)
                        Widget nextPage = const MainScaffold();

                        try {
                          final profileResponse = await request.get(
                              'https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/accounts/api/profile/');

                          if (profileResponse != null) {
                            // Ambil role dari respon JSON backend
                            String role = profileResponse['role'] ?? "Fan";

                            bool isClubAdmin = (role == 'Club Admin');
                            if (context.mounted) {
                              context
                                  .read<UserProvider>()
                                  .setIsClubAdmin(isClubAdmin);
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
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => nextPage),
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("$message Selamat datang, $uname."),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(response['message'] ?? "Login gagal"),
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
                },
              ),

              const SizedBox(height: 16),

              // Link ke Register
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RegisterScreen()),
                  );
                },
                child: const Text("Don't have an account? Register here"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
