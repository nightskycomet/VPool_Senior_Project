import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:vpool/screens/Employee%20Pages/reports_page.dart'; // Import the ReportsPage

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

  // List of pages for the employee dashboard
  final List<Widget> _pages = [
    const ReportsPage(), // Reports Page
    const Center( // Placeholder for User Verification Page
      child: Text(
        'User Verification Page',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    ),
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

  // Function to show the "Add Employee" modal
  Future<void> _showAddEmployeeModal() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Employee'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter the employee\'s name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter the employee\'s email',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter a password',
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final email = emailController.text.trim();
                final password = passwordController.text.trim();

                if (name.isNotEmpty && email.isNotEmpty && password.isNotEmpty) {
                  await _addEmployee(name, email, password);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Function to add an employee to Firebase
  Future<void> _addEmployee(String name, String email, String password) async {
    try {
      // Create a new user in Firebase Authentication
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get the UID of the newly created user
      final String uid = userCredential.user!.uid;

      // Save employee details to Firebase Realtime Database
      await _database.child("Employees/$uid").set({
        "name": name,
        "email": email,
        "role": "employee", // Automatically set role to "employee"
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
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
              decoration: BoxDecoration(),
              child: _pages[_selectedIndex], // Display the selected page
            ),
          ),
        ],
      ),
      // Floating Action Button to add an employee
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEmployeeModal,
        child: Icon(Icons.add),
        backgroundColor: Colors.blue.shade800,
      ),
    );
  }
}