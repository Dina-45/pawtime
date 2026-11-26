import 'package:flutter/material.dart';

import '../widgets/paw_bottom_nav.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'my_walks_screen.dart';
import 'profile_screen.dart';

// Favorites and bookings now live in BLoCs, so MainScreen only switches tabs.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  static const _pages = [
    HomeScreen(),
    MyWalksScreen(),
    FavoritesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: PawBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
