// widgets/ride_map_view.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:async';
import '../const.dart'; // For your API keys

class RideMapView extends StatefulWidget {
  final LatLng startLocation;
  final LatLng endLocation;
  final String startAddress;
  final String endAddress;
  final double height;
  final bool interactive;

  const RideMapView({
    Key? key,
    required this.startLocation,
    required this.endLocation,
    this.startAddress = 'Start',
    this.endAddress = 'Destination',
    this.height = 250.0,
    this.interactive = true,
  }) : super(key: key);

  @override
  _RideMapViewState createState() => _RideMapViewState();
}

class _RideMapViewState extends State<RideMapView> {
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();
  Map<PolylineId, Polyline> _polylines = {};
  Set<Marker> _markers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }
  
  @override
  void didUpdateWidget(RideMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If locations changed, update the map
    if (oldWidget.startLocation != widget.startLocation || 
        oldWidget.endLocation != widget.endLocation) {
      _initializeMap();
    }
  }

  Future<void> _initializeMap() async {
    setState(() {
      _isLoading = true;
      _markers = {};
      _polylines = {};
    });

    // Add start and destination markers
    _markers.add(
      Marker(
        markerId: MarkerId('start_location'),
        position: widget.startLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: widget.startAddress),
      ),
    );

    _markers.add(
      Marker(
        markerId: MarkerId('end_location'),
        position: widget.endLocation,
        icon: BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(title: widget.endAddress),
      ),
    );

    // Get polyline points
    List<LatLng> polylineCoordinates = await _getPolylinePoints();
    _generatePolyline(polylineCoordinates);

    // Move camera after map is initialized
    if (_mapController.isCompleted) {
      _fitBoundsToPoints();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<List<LatLng>> _getPolylinePoints() async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    
    try {
      // Create a PolylineRequest object
      PolylineRequest request = PolylineRequest(
        origin: PointLatLng(widget.startLocation.latitude, widget.startLocation.longitude),
        destination: PointLatLng(widget.endLocation.latitude, widget.endLocation.longitude),
        mode: TravelMode.driving,
      );
      
      // Get route
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        request: request,
        googleApiKey: GOOGLE_MAPS_API_KEY,
      );
      
      if (result.points.isNotEmpty) {
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
      } else {
        print("Polyline points are empty: ${result.errorMessage}");
        // Return a fallback direct line
        polylineCoordinates = [widget.startLocation, widget.endLocation];
      }
    } catch (e) {
      print("Exception in getPolylinePoints: $e");
      // Return a fallback route
      polylineCoordinates = [widget.startLocation, widget.endLocation];
    }
    
    return polylineCoordinates;
  }

  void _generatePolyline(List<LatLng> polylineCoordinates) {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.blue,
      points: polylineCoordinates,
      width: 3,
    );
    setState(() {
      _polylines[id] = polyline;
    });
  }

  Future<void> _fitBoundsToPoints() async {
    if (!_mapController.isCompleted) return;
    
    final GoogleMapController controller = await _mapController.future;
    
    double minLat = widget.startLocation.latitude;
    double maxLat = widget.startLocation.latitude;
    double minLng = widget.startLocation.longitude;
    double maxLng = widget.startLocation.longitude;
    
    // Compare with end location
    if (widget.endLocation.latitude < minLat) minLat = widget.endLocation.latitude;
    if (widget.endLocation.latitude > maxLat) maxLat = widget.endLocation.latitude;
    if (widget.endLocation.longitude < minLng) minLng = widget.endLocation.longitude;
    if (widget.endLocation.longitude > maxLng) maxLng = widget.endLocation.longitude;
    
    // Add some padding
    double padding = 0.01; // Roughly 1km
    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat - padding, minLng - padding),
      northeast: LatLng(maxLat + padding, maxLng + padding),
    );
    
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50.0));
  }

  @override
  Widget build(BuildContext context) {
    // Calculate center point between start and end for initial camera position
    final initialCameraPosition = CameraPosition(
      target: LatLng(
        (widget.startLocation.latitude + widget.endLocation.latitude) / 2,
        (widget.startLocation.longitude + widget.endLocation.longitude) / 2,
      ),
      zoom: 12.0,
    );

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: initialCameraPosition,
              markers: _markers,
              polylines: Set<Polyline>.of(_polylines.values),
              mapType: MapType.normal,
              myLocationEnabled: false,
              compassEnabled: widget.interactive,
              zoomControlsEnabled: widget.interactive,
              zoomGesturesEnabled: widget.interactive,
              scrollGesturesEnabled: widget.interactive,
              rotateGesturesEnabled: widget.interactive,
              tiltGesturesEnabled: widget.interactive,
              onMapCreated: (GoogleMapController controller) {
                _mapController.complete(controller);
                _fitBoundsToPoints();
              },
            ),
            if (_isLoading)
              Container(
                color: Colors.white70,
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!widget.interactive)
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenMap(
                          startLocation: widget.startLocation,
                          endLocation: widget.endLocation,
                          startAddress: widget.startAddress,
                          endAddress: widget.endAddress,
                        ),
                      ),
                    );
                  },
                  child: Icon(Icons.fullscreen, color: Colors.blue.shade900),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Full screen map for when the user taps the expand button
class FullScreenMap extends StatelessWidget {
  final LatLng startLocation;
  final LatLng endLocation;
  final String startAddress;
  final String endAddress;

  const FullScreenMap({
    Key? key,
    required this.startLocation,
    required this.endLocation,
    required this.startAddress,
    required this.endAddress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trip Map'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: RideMapView(
        startLocation: startLocation,
        endLocation: endLocation,
        startAddress: startAddress,
        endAddress: endAddress,
        height: double.infinity,
      ),
    );
  }
}