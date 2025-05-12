// screens/ride_details_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/ride_map_view.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/ride_details_screen.dart';

class RideDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> ride;
  
  const RideDetailsScreen({
    Key? key,
    required this.ride,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extract ride details
    final LatLng startLocation = ride['startLocation'];
    final LatLng endLocation = ride['endLocation'];
    final String startAddress = ride['startAddress'] ?? 'Starting Point';
    final String endAddress = ride['endAddress'] ?? 'Destination';
    final String carModel = ride['carModel'] ?? 'Not specified';
    final String availableSeats = ride['availableSeats']?.toString() ?? '0';
    final String startTime = ride['startTime'] ?? 'Not specified';
    final String gasMoney = ride['gasMoney'] ?? 'Not specified';
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Ride Details'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map view at the top
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: RideMapView(
                startLocation: startLocation,
                endLocation: endLocation,
                startAddress: startAddress,
                endAddress: endAddress,
                height: 220.0,
                interactive: false, // Smaller view with expand option
              ),
            ),
            
            // Ride details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailsRow(Icons.directions_car, 'Car Model', carModel),
                      Divider(),
                      _buildDetailsRow(Icons.event_seat, 'Available Seats', availableSeats),
                      Divider(),
                      _buildDetailsRow(Icons.access_time, 'Departure Time', startTime),
                      Divider(),
                      _buildDetailsRow(Icons.attach_money, 'Gas Money', gasMoney),
                    ],
                  ),
                ),
              ),
            ),
            
            // Locations detail card
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Route',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildLocationRow(
                        Icons.trip_origin,
                        'Start',
                        startAddress,
                        Colors.green,
                      ),
                      Container(
                        margin: EdgeInsets.only(left: 12),
                        height: 30,
                        width: 1,
                        color: Colors.grey.shade300,
                      ),
                      _buildLocationRow(
                        Icons.location_on,
                        'Destination',
                        endAddress,
                        Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.message),
                      label: Text('Contact Driver'),
                      onPressed: () {
                        // Implement contact functionality
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade900,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.directions),
                      label: Text('Get Directions'),
                      onPressed: () {
                        // Open in maps app
                        _openInMapsApp(startLocation, endLocation);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
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

  Widget _buildDetailsRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade800, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String label, String address, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                address,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openInMapsApp(LatLng start, LatLng end) async {
  final url = 'https://www.google.com/maps/dir/?api=1&origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&travelmode=driving';
  
  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not launch $url';
  }
}
}