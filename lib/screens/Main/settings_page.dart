import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: Text('Notifications'),
              subtitle: Text('Enable or disable notifications'),
              value: true, // Replace with actual state
              onChanged: (value) {
                // Update notification settings
              },
              activeColor: Colors.blue.shade900,
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.lock, color: Colors.blue.shade900),
              title: Text('Change Password'),
              onTap: () {
                // Navigate to change password screen
              },
            ),
            ListTile(
              leading: Icon(Icons.help, color: Colors.blue.shade900),
              title: Text('Help & Support'),
              onTap: () {
                // Navigate to help & support screen
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Logout'),
              onTap: () {
                // Handle logout
              },
            ),
          ],
        ),
      ),
    );
  }
}