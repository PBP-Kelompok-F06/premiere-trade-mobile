import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/bottom_navbar.dart';
import 'homepage.dart';
import '../../account/screens/profile.dart'; 

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  // Daftar Halaman untuk setiap Tab
  final List<Widget> _pages = [
    const Homepage(), // Index 0: Home (File lama kamu, tapi hapus drawernya nanti)
    const Center(child: Text("Halaman Bursa Transfer (Market)")), // Index 1: Placeholder
    const Center(child: Text("Halaman Community")), // Index 2: Placeholder
    const ProfileScreen(), // Index 3: Profile
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body akan berubah sesuai index yang dipilih
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      // Bottom Navigation Bar Custom
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}