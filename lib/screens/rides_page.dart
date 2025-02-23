import 'package:flutter/material.dart';

class RidesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Available Rides'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: ListView.builder(
        itemCount: 10, // Replace with actual ride count
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              leading: Icon(Icons.directions_car, color: Colors.blue.shade900),
              title: Text('Ride ${index + 1}'),
              subtitle: Text('From Location A to Location B'),
              trailing: Icon(Icons.arrow_forward, color: Colors.blue.shade900),
              onTap: () {
                // Navigate to ride details
              },
            ),
          );
        },
      ),
    );
  }
}