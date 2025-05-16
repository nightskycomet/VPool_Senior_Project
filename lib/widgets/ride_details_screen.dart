import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/ride_map_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class RideDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> ride;

  const RideDetailsScreen({
    super.key,
    required this.ride,
  });

  @override
  State<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends State<RideDetailsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _rideRequestDatabase =
      FirebaseDatabase.instance.ref().child('Ride_Request');
  final DatabaseReference _groupChatsDatabase =
      FirebaseDatabase.instance.ref().child('GroupChats');

  bool _isLoading = false;
  bool _hasRequested = false;
  bool _isDriver = false;
  bool _groupChatExists = false;
  int _pendingRequestsCount = 0;

  @override
  void initState() {
    super.initState();
    _checkIfDriver();
    _checkIfRequested();
    _checkGroupChat();
    _fetchPendingRequests();
  }

  Future<void> _checkIfDriver() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      setState(() {
        _isDriver = widget.ride["driverId"] == currentUser.uid;
      });
    }
  }

  Future<void> _checkIfRequested() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final snapshot = await _rideRequestDatabase
          .orderByChild('userId')
          .equalTo(currentUser.uid)
          .get();

      if (snapshot.exists) {
        for (var request in snapshot.children) {
          if (request.child("rideID").value == widget.ride["id"]) {
            setState(() {
              _hasRequested = true;
            });
            break;
          }
        }
      }
    }
  }

  Future<void> _checkGroupChat() async {
    final snapshot = await _groupChatsDatabase.child(widget.ride["id"]).get();
    setState(() => _groupChatExists = snapshot.exists);
  }

  Future<void> _fetchPendingRequests() async {
    if (!_isDriver) return;
    
    final snapshot = await _rideRequestDatabase
        .orderByChild('rideID')
        .equalTo(widget.ride["id"])
        .get();

    if (snapshot.exists) {
      int count = 0;
      for (var request in snapshot.children) {
        if (request.child("status").value == "pending") {
          count++;
        }
      }
      setState(() => _pendingRequestsCount = count);
    }
  }

  Future<void> _requestToJoinRide() async {
    if (_isDriver || _hasRequested || widget.ride["availableSeats"] <= 0) return;

    setState(() => _isLoading = true);
    try {
      await _rideRequestDatabase.push().set({
        "rideID": widget.ride["id"],
        "userId": _auth.currentUser!.uid,
        "driverId": widget.ride["driverId"],
        "status": "pending",
      });
      setState(() => _hasRequested = true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createGroupChat() async {
    await _groupChatsDatabase.child(widget.ride["id"]).set({
      "rideId": widget.ride["id"],
      "driverId": widget.ride["driverId"],
      "createdAt": DateTime.now().toString(),
    });
    setState(() => _groupChatExists = true);
  }

  Future<void> _openMaps(LatLng start, LatLng end) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final startLocation = LatLng(
      double.parse(widget.ride['startLocation'].split(',')[0]),
      double.parse(widget.ride['startLocation'].split(',')[1]),
    );
    final endLocation = LatLng(
      double.parse(widget.ride['endLocation'].split(',')[0]),
      double.parse(widget.ride['endLocation'].split(',')[1]),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Details'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Map Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: RideMapView(
                startLocation: startLocation,
                endLocation: endLocation,
                startAddress: widget.ride['startAddress'],
                endAddress: widget.ride['endAddress'],
                height: 220,
                interactive: true,
              ),
            ),

            // Ride Details Card
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailRow(Icons.directions_car, 'Car Model', widget.ride['carModel']),
                    const Divider(),
                    _buildDetailRow(Icons.event_seat, 'Available Seats', widget.ride['availableSeats'].toString()),
                    const Divider(),
                    _buildDetailRow(Icons.access_time, 'Departure Time', widget.ride['startTime']),
                    const Divider(),
                    _buildDetailRow(Icons.attach_money, 'Gas Money', widget.ride['gasMoney']),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Directions Button (always visible)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.directions),
                      label: const Text('Get Directions'),
                      onPressed: () => _openMaps(startLocation, endLocation),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Driver-specific buttons
                  if (_isDriver) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.group_add),
                        label: Text(_groupChatExists ? 'Chat Created' : 'Create Group Chat'),
                        onPressed: _groupChatExists ? null : _createGroupChat,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade900,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.list_alt),
                        label: Text(_pendingRequestsCount > 0 
                            ? 'Requests ($_pendingRequestsCount)' 
                            : 'View Requests'),
                        onPressed: () {
                          // Navigate to requests page
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ] 
                  // Passenger button
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white),
                              )
                            : const Icon(Icons.directions_car),
                        label: Text(_hasRequested ? 'Request Sent' : 'Join Ride'),
                        onPressed: (_isLoading || _hasRequested || widget.ride["availableSeats"] <= 0)
                            ? null
                            : _requestToJoinRide,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasRequested 
                              ? Colors.grey 
                              : Colors.blue.shade900,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}