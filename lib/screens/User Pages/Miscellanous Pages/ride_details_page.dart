import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:vpool/widgets/ride_map_view.dart';
import 'package:vpool/screens/User%20Pages/Main%20Pages/profile_page.dart';
import 'ride_request_page.dart';

class RideDetailsPage extends StatefulWidget {
  final Map<String, dynamic> ride;

  const RideDetailsPage({super.key, required this.ride});

  @override
  State<RideDetailsPage> createState() => _RideDetailsPageState();
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
  bool _groupChatExists = false;
  String _driverName = "";
  List<Map<String, String>> _riders = [];
  int _pendingRequestsCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeRideData();
    _fetchPendingRequestsCount();
  }

  LatLng _parseLocation(dynamic locationData) {
    if (locationData is String) {
      // Handle cases where location might be an address
      if (locationData.toLowerCase().contains('fiaa')) {
        return const LatLng(33.8076, 35.6774); // Fiaa coordinates
      }
      if (locationData.toLowerCase().contains('beirut')) {
        return const LatLng(33.8938, 35.5018); // Beirut coordinates
      }

      // Try to parse as coordinates
      if (locationData.contains(',')) {
        final parts = locationData.split(',');
        if (parts.length == 2) {
          return LatLng(
            double.parse(parts[0].trim()),
            double.parse(parts[1].trim()),
          );
        }
      }
    }

    // If we get here, the format is invalid
    throw FormatException('Invalid location format: $locationData');
  }

  Future<void> _initializeRideData() async {
    final userId = _auth.currentUser!.uid;
    final rideId = widget.ride["id"];
    final driverId = widget.ride["driverId"];

    setState(() => _isDriver = userId == driverId);

    final driverSnapshot =
        await _userDatabase.child(driverId).child("name").get();
    if (driverSnapshot.exists) {
      setState(() => _driverName = driverSnapshot.value.toString());
    }

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
            riders.add({"id": riderId, "name": riderSnapshot.value.toString()});
          }
        }
      }
      setState(() => _riders = riders);
    }

    final groupChatSnapshot = await _groupChatsDatabase.child(rideId).get();
    setState(() => _groupChatExists = groupChatSnapshot.exists);
  }

  Future<void> _openInMapsApp(String start, String end) async {
    final url = 'https://www.google.com/maps/dir/?api=1'
        '&origin=${Uri.encodeComponent(start)}'
        '&destination=${Uri.encodeComponent(end)}'
        '&travelmode=driving';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch maps';
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
      setState(() => _pendingRequestsCount = count);
    }
  }

  Future<void> _requestToJoinRide() async {
    if (_isDriver || _hasRequested || widget.ride["availableSeats"] <= 0) {
      return;
    }

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
      "riders": _riders.map((rider) => rider["id"]).toList(),
      "messages": {},
    });
    setState(() => _groupChatExists = true);
  }

  Future<void> _openGoogleMaps(String start, String end) async {
    try {
      final url = Uri.parse('https://www.google.com/maps/dir/?api=1'
          '&origin=${Uri.encodeComponent(start)}'
          '&destination=${Uri.encodeComponent(end)}'
          '&travelmode=driving');

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch Google Maps")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final startAddress =
        widget.ride['startAddress'] ?? widget.ride['startLocation'];
    final endAddress = widget.ride['endAddress'] ?? widget.ride['endLocation'];

    LatLng? startLocation;
    LatLng? endLocation;

    try {
      startLocation = _parseLocation(widget.ride['startLocation']);
      endLocation = _parseLocation(widget.ride['endLocation']);
    } catch (e) {
      debugPrint('Error parsing locations: $e');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ride["carModel"] ?? 'Ride Details'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (startLocation != null && endLocation != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: RideMapView(
                  startLocation: startLocation,
                  endLocation: endLocation,
                  startAddress: startAddress,
                  endAddress: endAddress,
                  height: 220,
                  interactive: true,
                ),
              ),

            // Location Display
            ListTile(
              leading: const Icon(Icons.location_pin, color: Colors.green),
              title: Text("From: $startAddress"),
              subtitle: startLocation != null
                  ? Text(
                      "Coordinates: ${startLocation.latitude.toStringAsFixed(4)}, "
                      "${startLocation.longitude.toStringAsFixed(4)}")
                  : null,
            ),
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.red),
              title: Text("To: $endAddress"),
              subtitle: endLocation != null
                  ? Text(
                      "Coordinates: ${endLocation.latitude.toStringAsFixed(4)}, "
                      "${endLocation.longitude.toStringAsFixed(4)}")
                  : null,
            ),

            // Ride Details Card
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailRow(Icons.person, "Driver", _driverName,
                        onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfilePage(
                                    userId: widget.ride["driverId"]),
                              ),
                            )),
                    const Divider(),
                    _buildDetailRow(Icons.directions_car, "Car",
                        widget.ride["carModel"] ?? ''),
                    const Divider(),
                    _buildDetailRow(Icons.event_seat, "Seats",
                        widget.ride["availableSeats"].toString()),
                    const Divider(),
                    _buildDetailRow(Icons.access_time, "Time",
                        widget.ride["startTime"] ?? ''),
                    const Divider(),
                    _buildDetailRow(Icons.attach_money, "Gas Money",
                        widget.ride["gasMoney"] ?? ''),
                  ],
                ),
              ),
            ),

            // Riders List
            if (_riders.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Riders:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      )),
                ),
              ),
              ..._riders.map((rider) => ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(rider["name"]!),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(userId: rider["id"]!),
                      ),
                    ),
                  )),
            ],

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (_isDriver) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _groupChatExists || _riders.isEmpty
                                ? null
                                : _createGroupChat,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade900,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: Text(_groupChatExists
                                ? "Chat Created"
                                : "Create Group Chat"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RideRequestPage(),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade900,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: Text(_pendingRequestsCount > 0
                                ? "Requests ($_pendingRequestsCount)"
                                : "View Requests"),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        const SizedBox(width: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.directions),
                          label: const Text("Directions"),
                          onPressed: () {
                            final start = widget.ride['startAddress'] ??
                                widget.ride['startLocation'];
                            final end = widget.ride['endAddress'] ??
                                widget.ride['endLocation'];
                            _openGoogleMaps(start, end);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.directions_car),
                        label:
                            Text(_hasRequested ? "Request Sent" : "Join Ride"),
                        onPressed: (_isLoading ||
                                _hasRequested ||
                                widget.ride["availableSeats"] <= 0)
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

  Widget _buildDetailRow(IconData icon, String label, String value,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue.shade800),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(
      IconData icon, String label, String address, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text(address,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}
