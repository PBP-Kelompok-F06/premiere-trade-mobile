import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../../main/screens/scaffold.dart';
import '../../account/screens/login.dart';
import '../../core/providers/user_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _checkSession();
    });
  }

  Future<void> _checkSession() async {
    final request = context.read<CookieRequest>();
    // URL Backend Validasi User
    // To connect Android emulator with Django on localhost, use URL http://10.0.2.2:8000
    // If you using chrome, use URL http://localhost:8000
    const String profileUrl = "http://localhost:8000/accounts/api/profile/";
    
    try {
      final response = await request.get(profileUrl);
      
      if (mounted) {
        if (response != null && response['username'] != null) {
            // Sukses Login & Dapat User Data
            String username = response['username'];
            bool isClubAdmin = response['is_club_admin'] ?? false;
            context.read<UserProvider>().setUsername(username);
            context.read<UserProvider>().setIsClubAdmin(isClubAdmin);
            
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MainScaffold()),
            );
        } else {
           Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
           );
        }
      }
    } catch (e) {
      if (mounted) {
         Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
       ),
    );
  }
}

