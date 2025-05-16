import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:vpool/const.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Location _locationController = Location();
  
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
      final TextEditingController _searchController = TextEditingController();
 bool _isSearching = false;
 LatLng? _startLocation;
LatLng? _endLocation;
bool _justSelectedPlace = false;
List<PlacePrediction> _placePredictions = [];
bool _showPredictions = false;
bool _selectingStartLocation = true;
  final String googlePlacesApiKey = GOOGLE_MAPS_API_KEY; // Use your existing key
  late String tokenForSession;

static const LatLng _pGooglePlex = LatLng(33.8938, 35.5018); // Beirut
static const LatLng _pApplePark = LatLng(34.4367, 35.8950);  // Different location (e.g., Tripoli)


  LatLng? _currentP;
  LatLng? _selectedLocation;
  String _selectedAddress = "";
  String? _sessionToken; // For Place Autocomplete API

  final Map<PolylineId, Polyline> _polylines = {};
  Set<Marker> _markers = {};

    bool _initialCameraMoved = false;
     StreamSubscription<LocationData>? _locationSubscription;

  @override
  void initState() {
  super.initState();
  tokenForSession = Uuid().v4(); // Generate a session token
  _searchController.addListener(() {
    if (_searchController.text.length > 1) {
      _getPlacePredictions(_searchController.text);
    }
  });
  
  getLocationUpdates().then((_) {
    getPolylinePoints().then((coordinates) {
      generatePolyLineFromPoints(coordinates);
    });
  });
}


@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      titleSpacing: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Container(
        height: 40,
        margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search for a location...',
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
            suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey.shade600),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _showPredictions = false;  // Hide predictions when clearing the search
                    });
                  },
                )
              : null,
          ),
          style: TextStyle(color: Colors.black87, fontSize: 16.0),
          // onTap: () {
          //   // Show predictions again when user taps on search field if there's text
          //   if (!_justSelectedPlace && _searchController.text.length > 1) {
          //     setState(() {
          //       _showPredictions = true;
          //     });
          //   }
          //   // Reset the flag in case it was set
          //   _justSelectedPlace = false;
          // },
          onChanged: (value) {
            // Show predictions when typing if text length > 1
            if (value.length > 1) {
              _getPlacePredictions(value);
            } else {
              setState(() {
                _showPredictions = false;
                _placePredictions = [];
              });
            }
          },

    onSubmitted: (query) {
            if (query.isNotEmpty) {
              _searchLocation(query);
              setState(() {
                _showPredictions = false;
              });
            }
            },

        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _selectingStartLocation ? Icons.play_circle_filled : Icons.location_on,
            color: _selectingStartLocation ? Colors.green : Colors.red,
          ),
          tooltip: _selectingStartLocation 
              ? 'Selecting start location' 
              : 'Selecting destination',
          onPressed: () {
            setState(() {
              _selectingStartLocation = !_selectingStartLocation;
              _showPredictions = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _selectingStartLocation 
                      ? 'Now selecting start location' 
                      : 'Now selecting destination'
                ),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
      ],
      backgroundColor: Colors.blue.shade900,
    ),
    body: Stack(
      children: [
        _currentP == null
            ? const Center(child: Text("Loading..."))
            : GoogleMap(
                onMapCreated: ((GoogleMapController controller) =>
                    _mapController.complete(controller)),
                initialCameraPosition: CameraPosition(
                  target: _currentP ?? _pGooglePlex,
                  zoom: 13,
                ),
                markers: _markers,
                polylines: Set<Polyline>.of(_polylines.values),
                onTap: _handleMapTap,
              ),
        
        // Predictions list
        if (_showPredictions)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _placePredictions.length > 5 ? 5 : _placePredictions.length,
                separatorBuilder: (context, index) => Divider(height: 1),
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(Icons.location_on, color: Colors.grey),
                    title: Text(_placePredictions[index].mainText),
                    subtitle: Text(
                      _placePredictions[index].secondaryText,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      _searchPlace(_placePredictions[index]);
                    },
                  );
                },
              ),
            ),
          ),
        
        // Your existing bottom panel for selected location
        if (_selectedLocation != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                          context,
                          _selectedAddress.isNotEmpty
                              ? _selectedAddress
                              : '${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade900,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 32),
                    ),
                    child: const Text(
                      'Confirm Location',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}


void _handleMapTap(LatLng position) {
  // Determine if user is setting start or end location based on UI state
  // (you could have a toggle button or some other UI element)
  if (_selectingStartLocation) {
    setState(() {
      _startLocation = position;
      
      _markers = {
        ..._markers.where((m) => m.markerId != MarkerId("_startLocation")),
        Marker(
          markerId: const MarkerId("_startLocation"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          position: position,
        ),
      };
    });
  } else {
    setState(() {
      _endLocation = position;
      
      _markers = {
        ..._markers.where((m) => m.markerId != MarkerId("_endLocation")),
        Marker(
          markerId: const MarkerId("_endLocation"),
          icon: BitmapDescriptor.defaultMarker, // Red marker
          position: position,
        ),
      };
    });
  }
  
  // If both locations are selected, draw the polyline
  if (_startLocation != null && _endLocation != null) {
    getPolylinePoints().then((coordinates) {
      generatePolyLineFromPoints(coordinates);
    });
  }
}


  Future<void> _cameraToPosition(LatLng pos) async {
  final GoogleMapController controller = await _mapController.future;
  
  // Set searching flag to prevent location updates from interfering
  setState(() {
    _isSearching = true;
  });
  
  final CameraPosition newCameraPosition = CameraPosition(
    target: pos,
    zoom: 15,
  );
  
  await controller.animateCamera(
    CameraUpdate.newCameraPosition(newCameraPosition)
  );
  
  // Reset searching flag after animation completes
  Future.delayed(Duration(milliseconds: 500), () {
    if (mounted) {
      setState(() {
        _isSearching = false;
      });
    }
  });
}

  Future<void> getLocationUpdates() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await _locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
    

     _locationSubscription = _locationController.onLocationChanged.listen((LocationData currentLocation) {
  if (currentLocation.latitude != null && currentLocation.longitude != null) {
    if (mounted) {
      setState(() {
        _currentP = LatLng(currentLocation.latitude!, currentLocation.longitude!);

        _markers = {
          ..._markers.where((m) => m.markerId != MarkerId("_currentLocation")),
          Marker(
            markerId: const MarkerId("_currentLocation"),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            position: _currentP!,
          ),
        };

        // Only move camera for initial position, not during searching
        if (!_initialCameraMoved && !_isSearching) {
          _cameraToPosition(_currentP!);
          _initialCameraMoved = true;
        }
      });
    }
  }
});
  }
  @override
void dispose() {
   _locationSubscription?.cancel(); // Important: Cancel the stream subscription
  _searchController.dispose();
  super.dispose();
}


// Replace your current _getPlacePredictions method
Future<void> _getPlacePredictions(String input) async {
  String groundURL = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  String request = '$groundURL?input=$input&key=$googlePlacesApiKey&sessiontoken=$tokenForSession';
  
  try {
    final response = await http.get(
      Uri.parse(request),
      headers: {
        'Referer': 'com.example.vpool'
      }
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['status'] == 'OK') {
        setState(() {
          _placePredictions = (data['predictions'] as List)
              .map((prediction) => PlacePrediction.fromJson(prediction))
              .toList();
          _showPredictions = _placePredictions.isNotEmpty;
        });
      } else {
        setState(() {
          _placePredictions = [];
          _showPredictions = false;
        });
        print('Place predictions error: ${data['status']}');
      }
    }
  } catch (e) {
    print('Exception getting predictions: $e');
  }
}
 
 
  Future<void> _goToPlace(String placeId) async {
    final String apiKey = GOOGLE_MAPS_API_KEY;
    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey&fields=geometry';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK' && data['result'] != null) {
        final lat = data['result']['geometry']['location']['lat'];
        final lng = data['result']['geometry']['location']['lng'];
        final selectedLocation = LatLng(lat, lng);
        _cameraToPosition(selectedLocation);
        _handleMapTap(selectedLocation); // Optionally add a marker
      } else {
        print('Places Details API error: ${data['status']}');
      }
    } else {
      print('Places Details API error: ${response.statusCode}');
    }
  }

Future<List<LatLng>> getPolylinePoints() async {
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();
  
  try {
    // Check if both start and end locations are selected
    if (_startLocation != null && _endLocation != null) {
      // Create a PolylineRequest object
      PolylineRequest request = PolylineRequest(
        origin: PointLatLng(_startLocation!.latitude, _startLocation!.longitude),
        destination: PointLatLng(_endLocation!.latitude, _endLocation!.longitude),
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
        polylineCoordinates = [_startLocation!, _endLocation!];
      }
    } else {
      // If either location is missing, return empty list
      return [];
    }
  } catch (e) {
    print("Exception in getPolylinePoints: $e");
    // Return a fallback route if both locations exist
    if (_startLocation != null && _endLocation != null) {
      polylineCoordinates = [_startLocation!, _endLocation!];
    }
  }
  
  return polylineCoordinates;
}

  void generatePolyLineFromPoints(List<LatLng> polylinecoordinates) {
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.blue,
      points: polylinecoordinates,
      width: 8,
    );
    setState(() {
      _polylines[id] = polyline;
    });
  }

Future<void> _searchLocation(String query) async {
  final String apiKey = GOOGLE_MAPS_API_KEY;
  final String url = 'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(query)}&key=$apiKey';
  
  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Referer': 'com.example.vpool' // Using your package name as referer
      }
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        final lat = data['results'][0]['geometry']['location']['lat'];
        final lng = data['results'][0]['geometry']['location']['lng'];
        final searchedLocation = LatLng(lat, lng);
        
        // Clean up the formatted address to remove Plus Codes
        String formattedAddress = data['results'][0]['formatted_address'] ?? "";
        formattedAddress = _removePlusCode(formattedAddress);
        
        // Alternatively, use address components for more control
        if (data['results'][0]['address_components'] != null) {
          String componentAddress = _formatAddressFromComponents(data['results'][0]['address_components']);
          if (componentAddress.isNotEmpty) {
            formattedAddress = componentAddress;
          }
        }
        
        setState(() {
          _selectedLocation = searchedLocation;
          _selectedAddress = formattedAddress;
          
          _markers = {
            if (_currentP != null)
              Marker(
                markerId: const MarkerId("_currentLocation"),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                position: _currentP!,
              ),
            Marker(
              markerId: const MarkerId("_selectedLocation"),
              icon: BitmapDescriptor.defaultMarker,
              position: searchedLocation,
              infoWindow: InfoWindow(title: formattedAddress),
            ),
          };
        });
        
        await _cameraToPosition(searchedLocation);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No results found for: $query')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.statusCode}')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}

// Helper method to clean up addresses with Plus Codes
String _removePlusCode(String address) {
  // Pattern to match Plus Codes (like "VGHR+V74, ")
  RegExp plusCodePattern = RegExp(r'[A-Z0-9]{4}\+[A-Z0-9]{2,3},\s*');
  
  // Replace the Plus Code with an empty string
  return address.replaceAll(plusCodePattern, '');
}

// Helper method to format address from components
String _formatAddressFromComponents(List<dynamic> addressComponents) {
  // Extract the relevant components you want to show
  String? street = _findAddressComponent(addressComponents, 'route');
  String? neighborhood = _findAddressComponent(addressComponents, 'neighborhood') ?? 
                       _findAddressComponent(addressComponents, 'sublocality_level_1');
  String? locality = _findAddressComponent(addressComponents, 'locality');
  String? country = _findAddressComponent(addressComponents, 'country');
  
  // Build a formatted address string
  List<String> addressParts = [];
  if (street != null) addressParts.add(street);
  if (neighborhood != null) addressParts.add(neighborhood);
  if (locality != null) addressParts.add(locality);
  if (country != null) addressParts.add(country);
  
  return addressParts.join(', ');
}

String? _findAddressComponent(List<dynamic> components, String type) {
  for (var component in components) {
    if (component['types'].contains(type)) {
      return component['long_name'];
    }
  }
  return null;
}

Future<void> _searchPlace(PlacePrediction prediction) async {
  setState(() {
    _showPredictions = false;
     _justSelectedPlace = true;
    _searchController.text = prediction.description;
  });
  
  String detailsUrl = 'https://maps.googleapis.com/maps/api/place/details/json';
  String request = '$detailsUrl?place_id=${prediction.placeId}&key=$googlePlacesApiKey&sessiontoken=$tokenForSession';
  
  try {
    final response = await http.get(
      Uri.parse(request),
      headers: {
        'Referer': 'com.example.vpool'
      }
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['status'] == 'OK') {
        final result = data['result'];
        final lat = result['geometry']['location']['lat'];
        final lng = result['geometry']['location']['lng'];
        final searchedLocation = LatLng(lat, lng);
        
        if (_selectingStartLocation) {
          setState(() {
            _startLocation = searchedLocation;
            
            _markers = {
              ..._markers.where((m) => m.markerId.value != "_startLocation"),
              Marker(
                markerId: const MarkerId("_startLocation"),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                position: searchedLocation,
                infoWindow: InfoWindow(title: "Start: ${prediction.mainText}"),
              ),
            };
          });
        } else {
          setState(() {
            _endLocation = searchedLocation;
            
            _markers = {
              ..._markers.where((m) => m.markerId.value != "_endLocation"),
              Marker(
                markerId: const MarkerId("_endLocation"),
                icon: BitmapDescriptor.defaultMarker,
                position: searchedLocation,
                infoWindow: InfoWindow(title: "Destination: ${prediction.mainText}"),
              ),
            };
          });
        }
        
        await _cameraToPosition(searchedLocation);
        
        if (_startLocation != null && _endLocation != null) {
          getPolylinePoints().then((coordinates) {
            generatePolyLineFromPoints(coordinates);
          });
        }
        
        tokenForSession = Uuid().v4(); // Generate new token for next search
      }
    }
  } catch (e) {
    print('Exception getting place details: $e');
  }
}



Future<void> _saveRecentSearch(String query, LatLng location) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final recentSearches = prefs.getStringList('recentSearches') ?? [];
    
    // Store as JSON
    final searchData = jsonEncode({
      'query': query,
      'lat': location.latitude,
      'lng': location.longitude
    });
    
    // Add to list and limit size
    if (!recentSearches.contains(searchData)) {
      recentSearches.insert(0, searchData);
      if (recentSearches.length > 5) {
        recentSearches.removeLast();
      }
      await prefs.setStringList('recentSearches', recentSearches);
    }
  } catch (e) {
    // Silently handle errors with recent searches since it's not critical
    print('Error saving recent search: $e');
  }
}


}

class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      placeId: json['place_id'],
      description: json['description'],
      mainText: json['structured_formatting']['main_text'] ?? '',
      secondaryText: json['structured_formatting']['secondary_text'] ?? '',
    );
  }
}