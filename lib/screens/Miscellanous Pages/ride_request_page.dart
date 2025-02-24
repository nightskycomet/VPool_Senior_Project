import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:vpool/screens/Main%20Pages/profile_page.dart';

class RideRequestPage extends StatefulWidget {
  const RideRequestPage({super.key});

  @override
  _RideRequestPageState createState() => _RideRequestPageState();
}

class _RideRequestPageState extends State<RideRequestPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _rideRequestDatabase =
      FirebaseDatabase.instance.ref().child('Ride_Request');
  final DatabaseReference _ridesDatabase =
      FirebaseDatabase.instance.ref().child('Rides');
  final DatabaseReference _userDatabase =
      FirebaseDatabase.instance.ref().child('Users');
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingRequests();
  }

  Future<void> _fetchPendingRequests() async {
    final driverId = _auth.currentUser!.uid; // Current user's ID (driverId)
    print('Driver ID: $driverId');

    try {
      // Step 1: Fetch all pending requests that have the current driver's ID
      final requestSnapshot = await _rideRequestDatabase
          .orderByChild('driverId')
          .equalTo(driverId)
          .get();

      if (!requestSnapshot.exists) {
        print('No pending requests found for driver: $driverId');
        setState(() => _isLoading = false);
        return;
      }

      final requests = <Map<String, dynamic>>[];
      for (var request in requestSnapshot.children) {
        final status = request.child('status').value.toString();
        if (status == 'pending') {
          final userId = request.child('userId').value.toString();
          final userSnapshot = await _userDatabase.child(userId).get();
          if (userSnapshot.exists) {
            requests.add({
              'requestId': request.key,
              'userId': userId,
              'userName': userSnapshot.child('name').value.toString(),
              'rideID': request.child('rideID').value.toString(),
            });
          }
        }
      }

      print('Total pending requests: ${requests.length}');
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching pending requests: $e');
      setState(() => _isLoading = false);
    }
  }

Future<void> _updateRequestStatus(String requestId, String status) async {
  try {
    // Get request details
    final requestSnapshot = await _rideRequestDatabase.child(requestId).get();
    final rideId = requestSnapshot.child('rideID').value.toString();
    final userId = requestSnapshot.child('userId').value.toString();

    if (status == 'accepted') {
      // Fetch the ride info
      final rideSnapshot = await _ridesDatabase.child(rideId).get();

      // Check if the ride exists
      if (!rideSnapshot.exists) {
        print('Ride not found: $rideId');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ride not found!')),
        );
        return;
      }

      // Get availableSeats as a number
      final availableSeats = rideSnapshot.child('availableSeats').value;

      // Handle missing or invalid availableSeats
      if (availableSeats == null || availableSeats is! int) {
        print('Invalid available seats value for ride: $rideId');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid available seats value!')),
        );
        return;
      }

      print('Available Seats: $availableSeats');

      if (availableSeats > 0) {
        // Add the rider to the ride (add to riders list)
        final ridersList = rideSnapshot.child('riders').exists
            ? List<String>.from(rideSnapshot.child('riders').value as List)
            : <String>[];

        // Add the rider's ID to the list
        ridersList.add(userId);

        // Decrease available seats by 1
        await _ridesDatabase.child(rideId).update({
          'availableSeats': availableSeats - 1, // Save as a number
          'riders': ridersList,
        });

        // Update the request status to accepted
        await _rideRequestDatabase.child(requestId).update({"status": status});

        setState(() {
          // Remove the accepted request from the list
          _requests.removeWhere((request) => request["requestId"] == requestId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request accepted and rider added to the ride!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No available seats!')),
        );
      }
    } else if (status == 'rejected') {
      // Update the request status to rejected
      await _rideRequestDatabase.child(requestId).update({"status": status});

      setState(() {
        // Remove the rejected request from the list
        _requests.removeWhere((request) => request["requestId"] == requestId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request rejected!')),
      );
    }
  } catch (e) {
    print('Error updating request status: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('An error occurred. Please try again.')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Requests'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text('No pending requests'))
              : ListView.builder(
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final request = _requests[index];
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(request["userName"]),
                      subtitle: Text("Requested to join your ride"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _updateRequestStatus(
                                request["requestId"], "accepted"),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _updateRequestStatus(
                                request["requestId"], "rejected"),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    ProfilePage(userId: request["userId"])));
                      },
                    );
                  },
                ),
    );
  }
}