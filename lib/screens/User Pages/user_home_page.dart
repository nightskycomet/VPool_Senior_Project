import 'package:flutter/material.dart';
import 'package:vpool/screens/User%20Pages/Main%20Pages/add_ride_page.dart';
import 'package:vpool/screens/User%20Pages/Main%20Pages/group_chats_page.dart';
import 'package:vpool/screens/User%20Pages/Main%20Pages/rides_page.dart';
import 'package:vpool/screens/User%20Pages/Miscellanous%20Pages/search_page.dart';
import 'package:vpool/screens/User%20Pages/Util%20Pages/settings_page.dart';

class HomePage extends StatefulWidget {
  final String role;

  const HomePage({super.key, required this.role});

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
      if (widget.role == 'rider' || widget.role == 'both') RidesPage(),
      if (widget.role == 'driver' || widget.role == 'both') AddRidePage(),
      GroupChatsPage(),
      UserSearchPage(),
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
            const BottomNavigationBarItem(
              icon: Icon(Icons.directions_car),
              label: 'Rides',
            ),
          if (widget.role == 'driver' || widget.role == 'both')
            const BottomNavigationBarItem(
              icon: Icon(Icons.add),
              label: 'Add Ride',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.group),
              label: 'Group Chats',
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
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