import 'package:flutter/material.dart';
import 'package:vpool/screens/Main/add_ride_page.dart';
import 'package:vpool/screens/Main/map_page.dart';
import 'package:vpool/screens/Main/profile_page.dart';
import 'package:vpool/screens/Main/rides_page.dart';
import 'package:vpool/screens/Main/settings_page.dart';

class HomePage extends StatefulWidget {
  final String userRole;

  const HomePage({super.key, required this.userRole});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Initialize pages based on the user's role
    _pages = [
      RidesPage(),
      if (widget.userRole == 'driver') AddRidePage(), // Only show for drivers
      MapPage(),
      ProfilePage(),
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
        title: Text('Home'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue.shade900,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Rides',
          ),
          if (widget.userRole == 'driver')
            BottomNavigationBarItem(
              icon: Icon(Icons.add),
              label: 'Add Ride',
            ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}