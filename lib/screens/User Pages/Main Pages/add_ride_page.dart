import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vpool/screens/User%20Pages/Miscellanous%20Pages/ride_details_page.dart';
import 'package:vpool/pages/map_page.dart'; // Fixed import with lowercase 'm'

class AddRidePage extends StatefulWidget {
  const AddRidePage({super.key});

  @override
  _AddRidePageState createState() => _AddRidePageState();
}

class _AddRidePageState extends State<AddRidePage> {
  final _formKey = GlobalKey<FormState>();
  final _availableSeatsController = TextEditingController();
  final _carModelController = TextEditingController();
  final _startLocationController = TextEditingController();
  final _endLocationController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _gasMoneyController = TextEditingController();
  final _dateController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  List<Map<String, dynamic>> _driverRides = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDriverRides();
  }

  Future<void> _fetchDriverRides() async {
    final driverId = _auth.currentUser!.uid;
    final ridesSnapshot = await _database.child("Rides").orderByChild("driverId").equalTo(driverId).get();
    if (ridesSnapshot.exists) {
      final rides = <Map<String, dynamic>>[];
      for (var ride in ridesSnapshot.children) {
        rides.add({
          "id": ride.key,
          "startLocation": ride.child("startLocation").value.toString(),
          "endLocation": ride.child("endLocation").value.toString(),
          "startTime": ride.child("startTime").value.toString(),
          "availableSeats": ride.child("availableSeats").value.toString(),
          "gasMoney": ride.child("gasMoney").value.toString(),
          "date": ride.child("date").value.toString(),
          "driverId": ride.child("driverId").value.toString(),
        });
      }
      setState(() {
        _driverRides = rides;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addRide() async {
    if (_formKey.currentState!.validate()) {
      final uuid = Uuid();
      final rideId = uuid.v4();
      final driverId = _auth.currentUser!.uid;

      final availableSeats = int.tryParse(_availableSeatsController.text) ?? 0;

      final rideData = {
        "availableSeats": availableSeats,
        "carModel": _carModelController.text,
        "createdAt": DateTime.now().toIso8601String(),
        "driverId": driverId,
        "endLocation": _endLocationController.text,
        "startLocation": _startLocationController.text,
        "startTime": _startTimeController.text,
        "gasMoney": _gasMoneyController.text,
        "date": _dateController.text,
      };

      await _database.child("Rides/$rideId").set(rideData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride added successfully!')),
      );

      _availableSeatsController.clear();
      _carModelController.clear();
      _startLocationController.clear();
      _endLocationController.clear();
      _startTimeController.clear();
      _gasMoneyController.clear();
      _dateController.clear();

      await _fetchDriverRides();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add a Ride'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _availableSeatsController,
                decoration: InputDecoration(
                  labelText: 'Available Seats',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the number of available seats';
                  }
                  final seats = int.tryParse(value);
                  if (seats == null || seats <= 0) {
                    return 'Please enter a valid number of seats';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _carModelController,
                decoration: InputDecoration(
                  labelText: 'Car Model',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the car model';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startLocationController,
                      decoration: InputDecoration(
                        labelText: 'Start Location',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the start location';
                        }
                        return null;
                      },
                      readOnly: true,
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MapPage()),
                      );
                      if (result != null && result is String) {
                        setState(() {
                          _startLocationController.text = result;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade900,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Icon(Icons.map, color: Colors.white),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _endLocationController,
                      decoration: InputDecoration(
                        labelText: 'End Location',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the end location';
                        }
                        return null;
                      },
                      readOnly: true,
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MapPage()),
                      );
                      if (result != null && result is String) {
                        setState(() {
                          _endLocationController.text = result;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade900,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Icon(Icons.map, color: Colors.white),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _startTimeController,
                decoration: InputDecoration(
                  labelText: 'Start Time (e.g., 10:00 AM)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the start time';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _gasMoneyController,
                decoration: InputDecoration(
                  labelText: 'Gas Money (e.g., \$ or LBP)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the gas money amount';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  );
                  if (pickedDate != null) {
                    final formattedDate = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                    setState(() {
                      _dateController.text = formattedDate;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a date';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _addRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade900,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Add Ride',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              SizedBox(height: 32),
              Text(
                'Your Current Open Rides',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _driverRides.isEmpty
                      ? Text('No open rides found.')
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _driverRides.length,
                          itemBuilder: (context, index) {
                            final ride = _driverRides[index];
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                title: Text('${ride["startLocation"]} to ${ride["endLocation"]}'),
                                subtitle: Text(
                                    'Time: ${ride["startTime"]}\nSeats: ${ride["availableSeats"]}\nGas Money: ${ride["gasMoney"]}'),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RideDetailsPage(ride: ride),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
            ],
          ),
        ),
      ),
    );
  }
}
