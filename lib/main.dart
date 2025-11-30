import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

// Import Halaman Login (Halaman pertama yang muncul)
import 'account/screens/login.dart';

// Import Design System (Warna)
import 'core/constants/colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) {
        // Inisialisasi CookieRequest untuk menangani otentikasi (Login/Logout)
        // Objek ini akan dibagikan ke seluruh aplikasi via Provider
        CookieRequest request = CookieRequest();
        return request;
      },
      child: MaterialApp(
        title: 'Premiere Trade',
        debugShowCheckedModeBanner:
            false, // Menghilangkan banner 'Debug' di pojok kanan atas

        // --- KONFIGURASI TEMA (DESIGN SYSTEM) ---
        theme: ThemeData(
          useMaterial3: true,

          // Mengatur Warna Utama
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,

          // Skema Warna Material 3
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            surface: AppColors.surface,
          ),

          // Mengatur Font Default (Inter untuk body, Poppins biasanya manual di Styles)
          textTheme: GoogleFonts.interTextTheme(
            Theme.of(context).textTheme,
          ),

          // Mengatur Style AppBar secara Global
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white, // Warna Teks/Icon di AppBar
            elevation: 0,
            centerTitle: true,
          ),

          // Mengatur Style Tombol Global (Opsional, jika tidak pakai widget custom)
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),

        // --- HALAMAN AWAL ---
        // Kita arahkan ke LoginScreen terlebih dahulu
        home: const LoginScreen(),
      ),
    );
  }
}
