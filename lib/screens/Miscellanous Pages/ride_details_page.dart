import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart'; // Add this import
import 'package:vpool/screens/Main%20Pages/profile_page.dart';
import 'ride_request_page.dart'; // Import the RideRequestPage

class RideDetailsPage extends StatefulWidget {
  final Map<String, dynamic> ride;

  const RideDetailsPage({super.key, required this.ride});

  @override
  _RideDetailsPageState createState() => _RideDetailsPageState();
}

class _RideDetailsPageState extends State<RideDetailsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _rideRequestDatabase =
      FirebaseDatabase.instance.ref().child('Ride_Request');
  final DatabaseReference _userDatabase =
      FirebaseDatabase.instance.ref().child('Users');
  final DatabaseReference _groupChatsDatabase =
      FirebaseDatabase.instance.ref().child('GroupChats');

  bool _isLoading = false;
  bool _isDriver = false;
  bool _hasRequested = false;
  bool _groupChatExists = false; // Track if a group chat already exists
  String _driverName = "Loading...";
  List<Map<String, String>> _riders =
      []; // List of riders with their IDs and names
  int _pendingRequestsCount = 0; // Track the number of pending requests

  @override
  void initState() {
    super.initState();
    _initializeRideData();
    _fetchPendingRequestsCount(); // Fetch the number of pending requests
  }

  Future<void> _initializeRideData() async {
    final userId = _auth.currentUser!.uid;
    final rideId = widget.ride["id"];
    final driverId = widget.ride["driverId"];

    if (mounted) {
      setState(() {
        _isDriver = userId == driverId;
      });
    }

    // Fetch driver name
    final driverSnapshot =
        await _userDatabase.child(driverId).child("name").get();
    if (driverSnapshot.exists) {
      if (mounted) {
        setState(() {
          _driverName = driverSnapshot.value.toString();
        });
      }
    }

    // Fetch riders in the ride
    final ridersSnapshot =
        await _rideRequestDatabase.orderByChild("rideID").equalTo(rideId).get();
    if (ridersSnapshot.exists) {
      final riders = <Map<String, String>>[];
      for (var request in ridersSnapshot.children) {
        if (request.child("status").value == "accepted") {
          final riderId = request.child("userId").value.toString();
          final riderSnapshot =
              await _userDatabase.child(riderId).child("name").get();
          if (riderSnapshot.exists) {
            riders.add({
              "id": riderId,
              "name": riderSnapshot.value.toString(),
            });
          }
        }
      }
      if (mounted) {
        setState(() {
          _riders = riders;
        });
      }
    }

    // Check if a group chat already exists
    final groupChatSnapshot = await _groupChatsDatabase.child(rideId).get();
    if (groupChatSnapshot.exists) {
      if (mounted) {
        setState(() {
          _groupChatExists = true;
        });
      }
    }
  }

  Future<void> _fetchPendingRequestsCount() async {
    final driverId = _auth.currentUser!.uid;
    final rideId = widget.ride["id"];

    final requestSnapshot = await _rideRequestDatabase
        .orderByChild('driverId')
        .equalTo(driverId)
        .get();

    if (requestSnapshot.exists) {
      int count = 0;
      for (var request in requestSnapshot.children) {
        if (request.child("status").value == "pending" &&
            request.child("rideID").value == rideId) {
          count++;
        }
      }
      if (mounted) {
        setState(() {
          _pendingRequestsCount = count;
        });
      }
    }
  }

  Future<void> _requestToJoinRide() async {
    if (_isDriver || _hasRequested || widget.ride["availableSeats"] <= 0)
      return;

    if (mounted) {
      setState(() => _isLoading = true);
    }

    final userId = _auth.currentUser!.uid;
    final rideId = widget.ride["id"];
    final driverId = widget.ride["driverId"];

    try {
      await _rideRequestDatabase.push().set({
        "rideID": rideId,
        "userId": userId,
        "driverId": driverId,
        "status": "pending",
      });

      if (mounted) {
        setState(() {
          _hasRequested = true;
        });
      }

      // Show a toast notification
      Fluttertoast.showToast(
        msg: "Ride request sent!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createGroupChat() async {
    final rideId = widget.ride["id"];
    final driverId = widget.ride["driverId"];

    if (_riders.isEmpty) {
      Fluttertoast.showToast(
        msg: "No riders to create a group chat!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    await _groupChatsDatabase.child(rideId).set({
      "rideId": rideId,
      "driverId": driverId,
      "riders": _riders.map((rider) => rider["id"]).toList(),
      "messages": {},
    });

    // Show a toast notification
    Fluttertoast.showToast(
      msg: "Group chat created!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );

    if (mounted) {
      setState(() {
        _groupChatExists = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ride["carModel"] ?? 'Ride Details'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRideInfoCard(),
            SizedBox(height: 20),
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildRideInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(Icons.person, "Driver", _driverName, isClickable: true,
                onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ProfilePage(userId: widget.ride["driverId"])));
            }),
            _infoRow(Icons.location_on, "From", widget.ride["startLocation"]),
            _infoRow(Icons.flag, "To", widget.ride["endLocation"]),
            _infoRow(Icons.event_seat, "Seats Available",
                widget.ride["availableSeats"].toString()),
            _infoRow(Icons.access_time, "Start Time", widget.ride["startTime"]),
            _infoRow(Icons.local_gas_station, "Gas Money",
                widget.ride["gasMoney"] ?? "Not specified"),
            if (_riders.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Riders:",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    ..._riders.map((rider) {
                      return ListTile(
                        leading:
                            Icon(Icons.person, color: Colors.blue.shade900),
                        title: Text(rider["name"]!),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProfilePage(userId: rider["id"]!),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
            if (_isDriver)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly, // Space buttons evenly
                  children: [
                    // Create Group Chat Button
                    ElevatedButton(
                      onPressed: _groupChatExists || _riders.isEmpty
                          ? null
                          : _createGroupChat,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _groupChatExists || _riders.isEmpty
                            ? Colors.grey
                            : Colors.blue.shade900,
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _groupChatExists
                            ? "Group Chat Created"
                            : "Create Group Chat",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),

                    // Ride Requests Button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RideRequestPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade900,
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _pendingRequestsCount > 0
                            ? "View Requests ($_pendingRequestsCount)"
                            : "View Requests",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {bool isClickable = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: isClickable ? onTap : null,
        child: Row(
          children: [
            Icon(icon, color: Colors.blue.shade900),
            SizedBox(width: 12),
            Text("$label:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(width: 8),
            Expanded(
                child: Text(value,
                    style: TextStyle(
                        fontSize: 16,
                        color: isClickable
                            ? Colors.blue.shade900
                            : Colors.black))),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    final bool isDisabled = _isLoading ||
        _hasRequested ||
        _isDriver ||
        widget.ride["availableSeats"] <= 0;

    return Center(
      child: ElevatedButton(
        onPressed: isDisabled ? null : _requestToJoinRide,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled ? Colors.grey : Colors.blue.shade900,
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Text(
                _hasRequested ? "Request Sent" : "Request to Join",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
      ),
    );
  }
}
