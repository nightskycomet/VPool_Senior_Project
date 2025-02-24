import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Future<void> _addRide() async {
    if (_formKey.currentState!.validate()) {
      final uuid = Uuid();
      final rideId = uuid.v4(); // Generate a unique ride ID
      final driverId = _auth.currentUser!.uid; // Get the current driver's ID

      final rideData = {
        "availableSeats": _availableSeatsController.text,
        "carModel": _carModelController.text,
        "createdAt": DateTime.now().toIso8601String(),
        "driverId": driverId,
        "endLocation": _endLocationController.text,
        "startLocation": _startLocationController.text,
        "startTime": _startTimeController.text,
      };

      // Save the ride to Firebase Realtime Database
      await _database.child("rides/$rideId").set(rideData);

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride added successfully!')),
      );

      // Clear the form
      _availableSeatsController.clear();
      _carModelController.clear();
      _startLocationController.clear();
      _endLocationController.clear();
      _startTimeController.clear();
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
              TextFormField(
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
              ),
              SizedBox(height: 16),
              TextFormField(
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
            ],
          ),
        ),
      ),
    );
  }
}