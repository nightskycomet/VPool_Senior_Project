import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vpool/screens/User%20Pages/Main%20Pages/profile_page.dart';
import 'package:vpool/screens/User%20Pages/Util%20Pages/help_and_faq_page.dart';
import 'package:vpool/screens/Shared%20Pages/login_page.dart';
import 'change_password_page.dart';

class SettingsPage extends StatelessWidget {
  SettingsPage({super.key});

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
                (route) => false,
              );
            },
            child: Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid; // Get the current user's ID

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Divider(),
            SwitchListTile(
              title: Text('Notifications'),
              subtitle: Text('Enable or disable notifications'),
              value: true,
              onChanged: (value) {
                // Update notification settings
              },
              activeColor: Colors.blue.shade900,
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.person, color: Colors.blue.shade900),
              title: Text('Your Profile'),
              onTap: () {
                if (userId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(userId: userId),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Unable to fetch profile. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.lock, color: Colors.blue.shade900),
              title: Text('Change Password'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChangePasswordPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.help, color: Colors.blue.shade900),
              title: Text('Help & Support'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HelpFaqPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Logout'),
              onTap: () => _confirmLogout(context),
            ),
          ],
        ),
      ),
    );
  }
}
