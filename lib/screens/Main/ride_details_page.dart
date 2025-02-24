import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:vpool/screens/Main/profile_page.dart';

class RideDetailsPage extends StatefulWidget {
  final Map<String, dynamic> ride;

  RideDetailsPage({super.key, required this.ride});

  @override
  _RideDetailsPageState createState() => _RideDetailsPageState();
}

class _RideDetailsPageState extends State<RideDetailsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _rideDatabase = FirebaseDatabase.instance.ref().child('rides');
  final DatabaseReference _userDatabase = FirebaseDatabase.instance.ref().child('Users');
  bool _isLoading = false;
  bool _isUserInRide = false;

  @override
  void initState() {
    super.initState();
    _checkIfUserInRide();
  }

  Future<void> _checkIfUserInRide() async {
    final userId = _auth.currentUser!.uid;
    final snapshot = await _rideDatabase.child(widget.ride["id"]).child("riders").get();

    if (snapshot.exists) {
      final riders = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        _isUserInRide = riders.containsKey(userId);
      });
    }
  }

  Future<String> _fetchDriverName(String driverId) async {
    final snapshot = await _userDatabase.child(driverId).child("name").get();
    return snapshot.exists ? snapshot.value as String : "Unknown Driver";
  }

  Future<void> _joinRide() async {
    setState(() => _isLoading = true);

    final rideId = widget.ride["id"];
    final userId = _auth.currentUser!.uid;

    try {
      final rideSnapshot = await _rideDatabase.child(rideId).get();
      if (!rideSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ride not found')));
        return;
      }

      final rideData = Map<String, dynamic>.from(rideSnapshot.value as Map);
      final availableSeats = int.tryParse(rideData["availableSeats"].toString()) ?? 0;

      if (availableSeats <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No available seats')));
        return;
      }

      final userSnapshot = await _userDatabase.child(userId).child("name").get();
      final userName = userSnapshot.exists ? userSnapshot.value as String : "Unknown User";

      final updatedRideData = {
        ...rideData,
        "availableSeats": (availableSeats - 1).toString(),
        "riders": {
          ...(rideData["riders"] ?? {}), // Preserve existing riders
          userId: userName, // Add new rider
        },
      };

      await _rideDatabase.child(rideId).set(updatedRideData);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You have joined the ride!')));
      setState(() {
        _isUserInRide = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error joining ride: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _leaveRide() async {
    setState(() => _isLoading = true);

    final rideId = widget.ride["id"];
    final userId = _auth.currentUser!.uid;

    try {
      final rideSnapshot = await _rideDatabase.child(rideId).get();
      if (!rideSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ride not found')));
        return;
      }

      final rideData = Map<String, dynamic>.from(rideSnapshot.value as Map);
      final riders = Map<String, dynamic>.from(rideData["riders"] ?? {});

      if (!riders.containsKey(userId)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You are not in this ride')));
        return;
      }

      riders.remove(userId); // Remove user from riders

      final updatedRideData = {
        ...rideData,
        "availableSeats": (int.parse(rideData["availableSeats"]) + 1).toString(),
        "riders": riders,
      };

      await _rideDatabase.child(rideId).set(updatedRideData);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You have left the ride!')));
      setState(() {
        _isUserInRide = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error leaving ride: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _fetchRiders() async {
    final snapshot = await _rideDatabase.child(widget.ride["id"]).child("riders").get();
    return snapshot.exists ? Map<String, dynamic>.from(snapshot.value as Map) : {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ride["carModel"] ?? 'Ride Details'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From: ${widget.ride["startLocation"]}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('To: ${widget.ride["endLocation"]}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            FutureBuilder<String>(
              future: _fetchDriverName(widget.ride["driverId"]),
              builder: (context, snapshot) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfilePage(userId: widget.ride["driverId"])),
                    );
                  },
                  child: Text(
                    'Driver: ${snapshot.data ?? "Loading..."}',
                    style: TextStyle(fontSize: 18, color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
            SizedBox(height: 8),
            Text('Seats Available: ${widget.ride["availableSeats"]}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Start Time: ${widget.ride["startTime"]}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 16),

            // Conditionally render "Join Ride" or "Leave Ride" button
            _isUserInRide
                ? ElevatedButton(
                    onPressed: _isLoading ? null : _leaveRide,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Leave Ride', style: TextStyle(fontSize: 18, color: Colors.white)),
                  )
                : ElevatedButton(
                    onPressed: _isLoading ? null : _joinRide,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade900,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Join Ride', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),

            SizedBox(height: 16),
            Text('Riders:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _fetchRiders(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No riders yet'));
                  }

                  final riders = snapshot.data!;
                  return ListView.builder(
                    itemCount: riders.length,
                    itemBuilder: (context, index) {
                      final riderId = riders.keys.elementAt(index);
                      final riderName = riders[riderId];

                      return ListTile(
                        leading: Icon(Icons.person, color: Colors.blue.shade900),
                        title: Text(riderName),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ProfilePage(userId: riderId)),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
