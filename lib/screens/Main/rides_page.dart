import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:vpool/screens/Main/profile_page.dart';

class RidesPage extends StatelessWidget {
  const RidesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseReference _database = FirebaseDatabase.instance.ref().child('rides');

    return Scaffold(
      appBar: AppBar(
        title: Text('Available Rides'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _database.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return Center(child: Text('No available rides'));
          }

          final Map<dynamic, dynamic> ridesMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final ridesList = ridesMap.entries.map((entry) {
            final ride = entry.value as Map<dynamic, dynamic>;
            return {
              "id": entry.key,
              "availableSeats": ride["availableSeats"],
              "carModel": ride["carModel"],
              "driverId": ride["driverId"],
              "endLocation": ride["endLocation"],
              "startLocation": ride["startLocation"],
              "startTime": ride["startTime"],
            };
          }).toList();

          return ListView.builder(
            itemCount: ridesList.length,
            itemBuilder: (context, index) {
              var ride = ridesList[index];
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  leading: Icon(Icons.directions_car, color: Colors.blue.shade900),
                  title: Text(ride["carModel"] ?? 'Ride ${index + 1}'),
                  subtitle: Text('${ride["startLocation"]} to ${ride["endLocation"]}'),
                  trailing: Icon(Icons.arrow_forward, color: Colors.blue.shade900),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RideDetailsPage(ride: ride),
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

class RideDetailsPage extends StatelessWidget {
  final Map<dynamic, dynamic> ride;
  final DatabaseReference _userDatabase = FirebaseDatabase.instance.ref().child('Users');

  RideDetailsPage({super.key, required this.ride});

  Future<String> _fetchDriverName(String driverId) async {
    final snapshot = await _userDatabase.child(driverId).child("name").get();
    if (snapshot.exists) {
      return snapshot.value as String;
    }
    return "Unknown Driver";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ride["carModel"] ?? 'Ride Details'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From: ${ride["startLocation"]}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('To: ${ride["endLocation"]}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            FutureBuilder<String>(
              future: _fetchDriverName(ride["driverId"]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text('Driver: Loading...', style: TextStyle(fontSize: 18));
                }
                return GestureDetector(
                  onTap: () {
                    // Navigate to the driver's profile page when tapped
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(userId: ride["driverId"]),
                      ),
                    );
                  },
                  child: Text(
                    'Driver: ${snapshot.data}',
                    style: TextStyle(fontSize: 18, color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
            SizedBox(height: 8),
            Text('Seats Available: ${ride["availableSeats"]}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Start Time: ${ride["startTime"]}', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
