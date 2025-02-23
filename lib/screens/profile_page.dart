import 'package:flutter/material.dart';

class UserProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/profile.png'), // Add a profile image
              ),
            ),
            SizedBox(height: 16),
            Text(
              'John Doe',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'john.doe@example.com',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 16),
            Divider(),
            ListTile(
              leading: Icon(Icons.phone, color: Colors.blue.shade900),
              title: Text('Phone Number'),
              subtitle: Text('+1 234 567 890'),
            ),
            ListTile(
              leading: Icon(Icons.location_on, color: Colors.blue.shade900),
              title: Text('Address'),
              subtitle: Text('123 Main St, City, Country'),
            ),
            ListTile(
              leading: Icon(Icons.history, color: Colors.blue.shade900),
              title: Text('Ride History'),
              onTap: () {
                // Navigate to ride history
              },
            ),
          ],
        ),
      ),
    );
  }
}