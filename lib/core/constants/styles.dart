import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTextStyles {
  // Heading 1: Untuk angka besar atau judul utama banget
  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  // Heading 2: Untuk judul Section (misal: "Overview", "Management")
  static const TextStyle h2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  // Heading 3: Untuk judul AppBar atau Card Title
  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Body: Untuk teks isi biasa / List Tile title
  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  // Caption: Untuk subtitle, keterangan kecil, atau teks pudar
  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  // Harga Pemain (Penting!)
  static TextStyle marketValue = GoogleFonts.poppins(
    fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary
  );
}

class AppBoxShadows {
  // Shadow lembut untuk Card agar terlihat "melayang" sedikit
  static final List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05), // Bayangan transparan
      blurRadius: 10,
      offset: const Offset(0, 4), // Arah bayangan ke bawah
    ),
  ];
  
  // Shadow yang lebih tajam (opsional, misal untuk tombol floating)
  static final List<BoxShadow> button = [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.3),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
}