import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vpool/screens/User%20Pages/Miscellanous%20Pages/ride_details_page.dart';

class RidesPage extends StatefulWidget {
  const RidesPage({super.key});

  @override
  State<RidesPage> createState() => _RidesPageState();
}

class _RidesPageState extends State<RidesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseReference _ridesDatabase = FirebaseDatabase.instance.ref().child('Rides');
  final DatabaseReference _rideRequestDatabase = FirebaseDatabase.instance.ref().child('Ride_Request');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rides'),
        backgroundColor: Colors.blue.shade900,
        bottom: TabBar(
          controller: _tabController,
          unselectedLabelColor: Colors.white,
          labelColor: Colors.white,
          tabs: const [
            Tab(text: 'Available Rides'),
            Tab(text: 'My Rides'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAvailableRidesTab(),
          _buildMyRidesTab(),
        ],
      ),
    );
  }

  Widget _buildAvailableRidesTab() {
    return StreamBuilder<DatabaseEvent>(
      stream: _ridesDatabase.onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return const Center(child: Text('No available rides'));
        }

        final ridesMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
        final ridesList = ridesMap.entries.map((entry) {
          final ride = Map<String, dynamic>.from(entry.value);
          ride["id"] = entry.key;
          return ride;
        }).toList();

        return ListView.builder(
          itemCount: ridesList.length,
          itemBuilder: (context, index) {
            var ride = ridesList[index];
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                leading: Icon(Icons.directions_car, color: Colors.blue.shade900),
                title: Text('${ride["startLocation"]} to ${ride["endLocation"]}'),
                subtitle: Text(ride["carModel"]),
                trailing: const Icon(Icons.arrow_forward, color: Colors.blue),
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
    );
  }

  Widget _buildMyRidesTab() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return const Center(child: Text('Please sign in to view your rides'));
    }

    return StreamBuilder<DatabaseEvent>(
      stream: _rideRequestDatabase.onValue,
      builder: (context, requestsSnapshot) {
        if (requestsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!requestsSnapshot.hasData || requestsSnapshot.data?.snapshot.value == null) {
          return const Center(child: Text('No rides found'));
        }

        final requestsMap = Map<String, dynamic>.from(requestsSnapshot.data!.snapshot.value as Map);
        final myRideIds = <String>[];

        for (var requestEntry in requestsMap.entries) {
          final request = Map<String, dynamic>.from(requestEntry.value);
          if (request["userId"] == userId && request["status"] == "accepted") {
            myRideIds.add(request["rideID"]);
          }
        }

        if (myRideIds.isEmpty) {
          return const Center(child: Text('You have not joined any rides yet'));
        }

        return FutureBuilder<DataSnapshot>(
          future: _ridesDatabase.get(),
          builder: (context, ridesSnapshot) {
            if (ridesSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!ridesSnapshot.hasData || ridesSnapshot.data?.value == null) {
              return const Center(child: Text('No ride details found'));
            }

            final allRidesMap = Map<String, dynamic>.from(ridesSnapshot.data!.value as Map);
            final myRidesList = <Map<String, dynamic>>[];

            for (var rideId in myRideIds) {
              if (allRidesMap.containsKey(rideId)) {
                final ride = Map<String, dynamic>.from(allRidesMap[rideId]);
                ride["id"] = rideId;
                ride["requestId"] = requestsMap.entries
                    .firstWhere((entry) =>
                        entry.value["rideID"] == rideId &&
                        entry.value["userId"] == userId)
                    .key;
                myRidesList.add(ride);
              }
            }

            return ListView.builder(
              itemCount: myRidesList.length,
              itemBuilder: (context, index) {
                final ride = myRidesList[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: Icon(Icons.directions_car, color: Colors.blue.shade900),
                    title: Text('${ride["startLocation"]} to ${ride["endLocation"]}'),
                    subtitle: Text(ride["carModel"]),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.exit_to_app, color: Colors.red),
                          onPressed: () => _showLeaveRideDialog(context, ride["requestId"]),
                        ),
                        const Icon(Icons.arrow_forward, color: Colors.blue),
                      ],
                    ),
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
        );
      },
    );
  }

  void _showLeaveRideDialog(BuildContext context, String requestId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Ride'),
        content: const Text('Are you sure you want to leave this ride? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _leaveRide(requestId);
              Navigator.pop(context);
            },
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveRide(String requestId) async {
    try {
      await _rideRequestDatabase.child(requestId).remove();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have left the ride')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error leaving ride: $e')),
      );
      debugPrint('Error leaving ride: $e');
    }
  }
}