import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'transfer_market_page.dart';
import 'my_club_page.dart';
import 'negotiation_inbox_page.dart';
import '../../core/constants/colors.dart';
import '../../core/providers/user_provider.dart';

class TransactionMainPage extends StatefulWidget {
  const TransactionMainPage({super.key});

  @override
  State<TransactionMainPage> createState() => _TransactionMainPageState();
}

class _TransactionMainPageState extends State<TransactionMainPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Always create 3 tabs, but we'll conditionally show them
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isClubAdmin = context.watch<UserProvider>().isClubAdmin;

    // If not club admin, only show Transfer Market
    if (!isClubAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Transfer Market', style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.primary,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const TransferMarketPage(),
      );
    }

    // If club admin, show all tabs
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppColors.secondary,
          tabs: const [
            Tab(icon: Icon(Icons.shopping_cart), text: 'Transfer Market'),
            Tab(icon: Icon(Icons.group), text: 'Klub Saya'),
            Tab(icon: Icon(Icons.inbox), text: 'Negotiation'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          TransferMarketPage(),
          MyClubPage(),
          NegotiationInboxPage(),
        ],
      ),
    );
  }
}
