import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/bottom_navbar.dart';
import 'homepage.dart';
import '../../account/screens/profile.dart';
import '../../community/screens/community_page.dart';
import '../../best_eleven/screens/best_eleven_list_page.dart';
import '../../best_eleven/screens/best_eleven_builder_page.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  final GlobalKey<BestElevenListPageState> _bestElevenKey = GlobalKey();

  late final List<Widget> _pages = [
    const Homepage(),
    BestElevenListPage(key: _bestElevenKey),
    const Center(child: Text("Halaman Bursa Transfer (Market)")),
    const CommunityPage(),
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
                _onItemTapped(1);
                Navigator.pop(context);
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
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              selected: _selectedIndex == 4,
              onTap: () {
                _onItemTapped(4);
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
      case 1: // Best Eleven
        return FloatingActionButton(
          onPressed: () async {
            if (!mounted) return;
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BestElevenBuilderPage(),
              ),
            );
            if (mounted) {
              (_bestElevenKey.currentState as BestElevenListPageState?)?.refreshData();
            }
          },
          child: const Icon(Icons.add),
        );
      case 3: // Community
        // Community FAB functionality - to be implemented in CommunityPage itself
        return null;
      default:
        return null;
    }
  }
}