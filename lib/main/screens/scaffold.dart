import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/bottom_navbar.dart';
import 'homepage.dart';
import '../../account/screens/profile.dart';
import '../../community/screens/community_page.dart';
import '../../best_eleven/screens/best_eleven_builder_page.dart';
import '../../rumor/screens/rumors_page.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    const Homepage(),
    const BestElevenBuilderPage(hideScaffold: true),
    const Center(child: Text("Halaman Bursa Transfer (Market)")),
    const CommunityPage(),
    const RumorsPage(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Helper untuk mengubah Title AppBar sesuai Halaman
  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return "Premiere Trade";
      case 1:
        return "Best Eleven";
      case 2:
        return "Market";
      case 3:
        return "Community";
      case 4:
        return "Rumors";
      case 5:
        return "My Profile";
      default:
        return "Premiere Trade";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(_selectedIndex),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: AppColors.primary,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Icon(Icons.sports_soccer, size: 48, color: Colors.white),
                   SizedBox(height: 12),
                   Text(
                    'Premiere Trade',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              selected: _selectedIndex == 0,
              onTap: () {
                _onItemTapped(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sports_soccer),
              title: const Text('Best Eleven'),
              selected: _selectedIndex == 1,
              onTap: () {
                Navigator.pop(context); 
                _onItemTapped(1); 
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Bursa Transfer'),
              selected: _selectedIndex == 2,
              onTap: () {
                _onItemTapped(2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.forum),
              title: const Text('Community'),
              selected: _selectedIndex == 3,
              onTap: () {
                _onItemTapped(3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.record_voice_over),
              title: const Text('Rumors'),
              selected: _selectedIndex == 4,
              onTap: () {
                _onItemTapped(4);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              selected: _selectedIndex == 5,
              onTap: () {
                _onItemTapped(5);
                Navigator.pop(context);
              },
            ), 
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      floatingActionButton: _getFloatingActionButton(),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
  
  Widget? _getFloatingActionButton() {
    switch (_selectedIndex) {
      case 3: // Community
        // Community FAB functionality - to be implemented in CommunityPage itself
        return null;
      default:
        return null;
    }
  }
}