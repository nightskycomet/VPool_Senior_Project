import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class EmployeeHomePage extends StatefulWidget {
  final String role;

  const EmployeeHomePage({Key? key, required this.role}) : super(key: key);

  @override
  _EmployeeHomePageState createState() => _EmployeeHomePageState();
}

class _EmployeeHomePageState extends State<EmployeeHomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  int _selectedIndex = 0; // For sidebar navigation

  // Placeholder for different pages
  static final List<Widget> _pages = [
    ReportsPage(), // Replace with your ReportsPage widget
    UserVerificationPage(), // Replace with your UserVerificationPage widget
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250, // Fixed width for the sidebar
            decoration: BoxDecoration(
              color: Colors.blue.shade800,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                SizedBox(height: 40),
                Text(
                  'Employee Dashboard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 40),
                // Sidebar Navigation
                ListTile(
                  leading: Icon(Icons.bar_chart, color: Colors.white),
                  title: Text(
                    'Reports',
                    style: TextStyle(color: Colors.white),
                  ),
                  selected: _selectedIndex == 0,
                  onTap: () => _onItemTapped(0),
                ),
                ListTile(
                  leading: Icon(Icons.verified_user, color: Colors.white),
                  title: Text(
                    'User Verification',
                    style: TextStyle(color: Colors.white),
                  ),
                  selected: _selectedIndex == 1,
                  onTap: () => _onItemTapped(1),
                ),
                Spacer(),
                // Logout Button
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.white),
                  title: Text(
                    'Logout',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: _signOut,
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
          // Main Content Area
          Expanded(
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: _pages[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}

// Placeholder for Reports Page
class ReportsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Reports Page',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    );
  }
}

// Placeholder for User Verification Page
class UserVerificationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'User Verification Page',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    );
  }
}