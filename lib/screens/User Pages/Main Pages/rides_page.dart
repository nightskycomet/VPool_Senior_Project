import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:vpool/screens/User%20Pages/Miscellanous%20Pages/ride_details_page.dart';

class RidesPage extends StatelessWidget {
  const RidesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseReference database = FirebaseDatabase.instance.ref().child('Rides');

    return Scaffold(
      appBar: AppBar(
        title: Text('Available Rides'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: database.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return Center(child: Text('No available rides'));
          }

          final ridesMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final ridesList = ridesMap.entries.map((entry) {
            final ride = Map<String, dynamic>.from(entry.value);
            ride["id"] = entry.key; // Add ride ID
            return ride;
          }).toList();

          return ListView.builder(
            itemCount: ridesList.length,
            itemBuilder: (context, index) {
              var ride = ridesList[index];
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  leading: Icon(Icons.directions_car, color: Colors.blue.shade900),
                  title: Text('${ride["startLocation"]} to ${ride["endLocation"]}'),
                  subtitle: Text(ride["carModel"]),
                  trailing: Icon(Icons.arrow_forward, color: Colors.blue.shade900),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RideDetailsPage(ride: ride), // ✅ Pass ride data
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
