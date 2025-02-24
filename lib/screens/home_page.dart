import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vpool/screens/Main/add_ride_page.dart';
import 'package:vpool/screens/Main/map_page.dart';
import 'package:vpool/screens/Main/profile_page.dart';
import 'package:vpool/screens/Main/rides_page.dart';
import 'package:vpool/screens/Main/search_page.dart';
import 'package:vpool/screens/Main/settings_page.dart';

class HomePage extends StatefulWidget {
  final String role;

  const HomePage({super.key, required this.role});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Initialize pages based on the user's role
    _pages = [
      if (widget.role == 'rider' || widget.role == 'both') RidesPage(),
      if (widget.role == 'driver' || widget.role == 'both') AddRidePage(),
      MapPage(),
      UserSearchPage(),
      ProfilePage(userId: _auth.currentUser?.uid), // Pass actual userId here
      SettingsPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue.shade900,
        unselectedItemColor: Colors.grey,
        items: [
          if (widget.role == 'rider' || widget.role == 'both')
            BottomNavigationBarItem(
              icon: const Icon(Icons.directions_car),
              label: 'Rides',
            ),
          if (widget.role == 'driver' || widget.role == 'both')
            BottomNavigationBarItem(
              icon: const Icon(Icons.add),
              label: 'Add Ride',
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Person',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
