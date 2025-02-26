import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:vpool/screens/User%20Pages/Main%20Pages/profile_page.dart';

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
  final DatabaseReference _groupChatsDatabase =
      FirebaseDatabase.instance.ref().child('GroupChats');
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingRequests();
  }

  Future<void> _fetchPendingRequests() async {
    final driverId = _auth.currentUser!.uid; // Current user's ID (driverId)
    try {
      // Step 1: Fetch all pending requests that have the current driver's ID
      final requestSnapshot = await _rideRequestDatabase
          .orderByChild('driverId')
          .equalTo(driverId)
          .get();

      if (!requestSnapshot.exists) {
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

      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
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

        final availableSeats =
            rideSnapshot.child('availableSeats').value as int? ?? 0;

        if (availableSeats > 0) {
          // Add the rider to the ride (add to riders list)
          final ridersList = rideSnapshot.child('riders').exists
              ? List<String>.from(
                  (rideSnapshot.child('riders').value as List<dynamic>)
                      .map((e) => e.toString())
                      .toList())
              : <String>[];

          // Add the rider's ID to the list
          ridersList.add(userId);

          // Decrease available seats by 1
          await _ridesDatabase.child(rideId).update({
            'availableSeats': availableSeats - 1, // Update as a number
            'riders': ridersList,
          });

          // Add the rider to the group chat
          final groupChatSnapshot =
              await _groupChatsDatabase.child(rideId).get();
          if (groupChatSnapshot.exists) {
            final groupChatRiders = groupChatSnapshot.child('riders').exists
                ? List<String>.from(
                    (groupChatSnapshot.child('riders').value as List<dynamic>)
                        .map((e) => e.toString())
                        .toList())
                : <String>[];
            groupChatRiders.add(userId);
            await _groupChatsDatabase.child(rideId).update({
              'riders': groupChatRiders,
            });
          }

          // Update the request status to accepted
          await _rideRequestDatabase
              .child(requestId)
              .update({'status': status});

          setState(() {
            _requests
                .removeWhere((request) => request['requestId'] == requestId);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Request accepted and rider added to the ride!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No available seats!')),
          );
        }
      } else if (status == 'rejected') {
        // Update the request status to rejected
        await _rideRequestDatabase.child(requestId).update({'status': status});

        setState(() {
          _requests.removeWhere((request) => request['requestId'] == requestId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request rejected!')),
        );
      }
    } catch (e) {
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
                      title: Text(request['userName']),
                      subtitle: Text('Requested to join your ride'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _updateRequestStatus(
                                request['requestId'], 'accepted'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _updateRequestStatus(
                                request['requestId'], 'rejected'),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProfilePage(userId: request['userId']),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
