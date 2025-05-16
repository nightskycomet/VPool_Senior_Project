import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RideMapView extends StatelessWidget {
  final LatLng startLocation;
  final LatLng endLocation;
  final String startAddress;
  final String endAddress;
  final double height;
  final bool interactive;

  const RideMapView({
    super.key,
    required this.startLocation,
    required this.endLocation,
    required this.startAddress,
    required this.endAddress,
    this.height = 250.0,
    this.interactive = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(
            (startLocation.latitude + endLocation.latitude) / 2,
            (startLocation.longitude + endLocation.longitude) / 2,
          ),
          zoom: 12.0,
        ),
        markers: {
          Marker(
            markerId: const MarkerId('start'),
            position: startLocation,
            infoWindow: InfoWindow(title: startAddress),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
          Marker(
            markerId: const MarkerId('end'),
            position: endLocation,
            infoWindow: InfoWindow(title: endAddress),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        },
        polylines: {
          Polyline(
            polylineId: const PolylineId('route'),
            points: [startLocation, endLocation],
            color: Colors.blue,
            width: 3,
          ),
        },
        mapType: MapType.normal,
        myLocationEnabled: false,
        zoomControlsEnabled: interactive,
        zoomGesturesEnabled: interactive,
        scrollGesturesEnabled: interactive,
        rotateGesturesEnabled: interactive,
        tiltGesturesEnabled: interactive,
      ),
    );
  }
}