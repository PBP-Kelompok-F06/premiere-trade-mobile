import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';

class PlayerCard extends StatelessWidget {
  final String playerName;
  final String clubName;
  final String position;
  final String price;
  final String imageUrl;
  final VoidCallback onTap;

  const PlayerCard({
    super.key,
    required this.playerName,
    required this.clubName,
    required this.position,
    required this.price,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Bagian Foto (Kiri)
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            // Bagian Info (Tengah & Kanan)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Posisi (Badge Kecil)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        position,
                        style: TextStyle(
                          color: AppColors.primary, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 10
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Nama Pemain
                    Text(playerName, style: AppTextStyles.h2.copyWith(fontSize: 16)),
                    Text(clubName, style: AppTextStyles.caption),
                    
                    const SizedBox(height: 8),
                    
                    // Harga (Market Value)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Market Value", style: AppTextStyles.caption),
                        Text(price, style: AppTextStyles.marketValue),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}