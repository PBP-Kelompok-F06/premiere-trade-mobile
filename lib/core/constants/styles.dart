import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTextStyles {
  // Headings (Poppins)
  static TextStyle h1 = GoogleFonts.poppins(
    fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary
  );
  
  static TextStyle h2 = GoogleFonts.poppins(
    fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary
  );

  // Body (Inter)
  static TextStyle body = GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.textPrimary
  );

  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12, color: AppColors.textSecondary
  );
  
  // Harga Pemain (Penting!)
  static TextStyle marketValue = GoogleFonts.poppins(
    fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary
  );
}