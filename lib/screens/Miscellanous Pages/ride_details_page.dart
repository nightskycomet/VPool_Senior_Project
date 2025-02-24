import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:vpool/screens/Main%20Pages/profile_page.dart';

class RideDetailsPage extends StatefulWidget {
  final Map<String, dynamic> ride;

  const RideDetailsPage({super.key, required this.ride});

  @override
  _RideDetailsPageState createState() => _RideDetailsPageState();
}

class _RideDetailsPageState extends State<RideDetailsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _rideRequestDatabase = FirebaseDatabase.instance.ref().child('Ride_Request');
  final DatabaseReference _userDatabase = FirebaseDatabase.instance.ref().child('Users');

  bool _isLoading = false;
  bool _isDriver = false;
  bool _hasRequested = false;
  String _driverName = "Loading...";

  @override
  void initState() {
    super.initState();
    _initializeRideData();
  }

  Future<void> _initializeRideData() async {
    final userId = _auth.currentUser!.uid;
    final rideId = widget.ride["id"];
    final driverId = widget.ride["driverId"];

    setState(() {
      _isDriver = userId == driverId;
    });

    // Check if user has already requested to join
    final requestSnapshot = await _rideRequestDatabase.orderByChild("userId").equalTo(userId).get();
    if (requestSnapshot.exists) {
      for (var request in requestSnapshot.children) {
        if (request.child("rideID").value == rideId && request.child("status").value == "pending") {
          setState(() {
            _hasRequested = true;
          });
        }
      }
    }

    // Fetch driver name
    final driverSnapshot = await _userDatabase.child(driverId).child("name").get();
    if (driverSnapshot.exists) {
      setState(() {
        _driverName = driverSnapshot.value.toString();
      });
    }
  }

  Future<void> _requestToJoinRide() async {
    if (_isDriver || _hasRequested || widget.ride["availableSeats"] <= 0) return;

    setState(() => _isLoading = true);
    final userId = _auth.currentUser!.uid;
    final rideId = widget.ride["id"];
    final driverId = widget.ride["driverId"]; // Get driverId from ride

    try {
      await _rideRequestDatabase.push().set({
        "rideID": rideId,
        "userId": userId,
        "driverId": driverId, // Include the driver ID in the request
        "status": "pending",
      });
      setState(() {
        _hasRequested = true;
      });

      await _sendNotificationToDriver();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ride request sent!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendNotificationToDriver() async {
    final driverId = widget.ride["driverId"];
    final driverTokenSnapshot = await _userDatabase.child(driverId).child("fcmToken").get();
    if (!driverTokenSnapshot.exists) return;

    final driverToken = driverTokenSnapshot.value.toString();
    await FirebaseMessaging.instance.sendMessage(
      to: driverToken,
      data: {"title": "New Ride Request", "body": "Someone has requested to join your ride."},
    );
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
            _infoRow(Icons.person, "Driver", _driverName, isClickable: true, onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(userId: widget.ride["driverId"])));
            }),
            _infoRow(Icons.location_on, "From", widget.ride["startLocation"]),
            _infoRow(Icons.flag, "To", widget.ride["endLocation"]),
            _infoRow(Icons.event_seat, "Seats Available", widget.ride["availableSeats"].toString()),
            _infoRow(Icons.access_time, "Start Time", widget.ride["startTime"]),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool isClickable = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: isClickable ? onTap : null,
        child: Row(
          children: [
            Icon(icon, color: Colors.blue.shade900),
            SizedBox(width: 12),
            Text("$label:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(width: 8),
            Expanded(child: Text(value, style: TextStyle(fontSize: 16, color: isClickable ? Colors.blue.shade900 : Colors.black))),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    final bool isDisabled = _isLoading || _hasRequested || _isDriver || widget.ride["availableSeats"] <= 0;

    return Center(
      child: ElevatedButton(
        onPressed: isDisabled ? null : _requestToJoinRide,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled ? Colors.grey : Colors.blue.shade900, // Grey out if disabled
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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