// widgets/ride_list_item.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/ride_map_view.dart';
import './ride_details_screen.dart';
import '../screens/User Pages/Miscellanous Pages/ride_details_page.dart'
class RideListItem extends StatelessWidget {
  final Map<String, dynamic> ride;
  
  const RideListItem({
    Key? key,
    required this.ride,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final LatLng startLocation = ride['startLocation'];
    final LatLng endLocation = ride['endLocation'];
    final String startAddress = ride['startAddress'] ?? 'Starting Point';
    final String endAddress = ride['endAddress'] ?? 'Destination';
    final String startTime = ride['startTime'] ?? 'Not specified';
    final String availableSeats = ride['availableSeats']?.toString() ?? '0';
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RideDetailsScreen(ride: ride),
            ),
          );
        },
        child: Column(
          children: [
            // Route info
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From: $startAddress',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'To: $endAddress',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        startTime,
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$availableSeats seats available',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Small map preview
            Container(
              height: 120,
              child: RideMapView(
                startLocation: startLocation,
                endLocation: endLocation,
                height: 120,
                interactive: false,
              ),
            ),
            
            // Action buttons
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: Icon(Icons.info_outline),
                    label: Text('Details'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RideDetailsScreen(ride: ride),
                        ),
                      );
                    },
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: Icon(Icons.directions_car),
                    label: Text('Join Ride'),
                    onPressed: () {
                      // Implement join ride functionality
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade900,
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
}