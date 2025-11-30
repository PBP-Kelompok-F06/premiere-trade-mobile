import 'package:flutter/material.dart';
import '../constants/colors.dart';

class PremiereButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool
      isSecondary; // Jika true, warnanya Neon Green (untuk tombol 'Buy' atau 'Bid')

  const PremiereButton(
      {super.key,
      required this.text,
      required this.onPressed,
      this.isSecondary = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSecondary ? AppColors.secondary : AppColors.primary,
          foregroundColor:
              isSecondary ? AppColors.primary : Colors.white, // Warna teks
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12), // Sudut tidak terlalu bulat (sporty)
          ),
          elevation: 0,
        ),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0, // Memberi kesan premium
          ),
        ),
      ),
    );
  }
}
