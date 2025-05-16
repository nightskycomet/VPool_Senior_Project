import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vpool/widgets/ride_map_view.dart';
import 'package:vpool/widgets/ride_details_screen.dart';

class RideListItem extends StatelessWidget {
  final Map<String, dynamic> ride;
  
  const RideListItem({
    super.key,
    required this.ride,
  });





  @override
  Widget build(BuildContext context) {
    final startAddress = ride['startAddress'] ?? ride['startLocation'];
    final endAddress = ride['endAddress'] ?? ride['endLocation'];
    
    LatLng? startLocation;
    LatLng? endLocation;
    
    try {
      startLocation = LatLng(
        double.parse(ride['startLocation'].split(',')[0]),
        double.parse(ride['startLocation'].split(',')[1]),
      );
      endLocation = LatLng(
        double.parse(ride['endLocation'].split(',')[0]),
        double.parse(ride['endLocation'].split(',')[1]),
      );
    } catch (e) {
      debugPrint('Error parsing ride locations: $e');
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'To: $endAddress',
                          style: const TextStyle(
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
                        ride['startTime'] ?? '',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${ride['availableSeats']} seats available',
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
            
            // Small map preview (only if we have valid locations)
            if (startLocation != null && endLocation != null)
              SizedBox(
                height: 120,
                child: RideMapView(
                  startLocation: startLocation,
                  endLocation: endLocation,
                  startAddress: startAddress,
                  endAddress: endAddress,
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
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Details'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RideDetailsScreen(ride: ride),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.directions_car),
                    label: const Text('Join Ride'),
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