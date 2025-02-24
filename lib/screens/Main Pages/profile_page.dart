import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  final String? userId; // userId can be null if we're showing the logged-in user's profile

  const ProfilePage({super.key, this.userId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic> _userData = {}; // Initialize as an empty map
  bool _isLoading = true;
  late String _userId; // Declare userId

  @override
  void initState() {
    super.initState();
    _userId = widget.userId ?? _auth.currentUser!.uid; // Use currentUser UID if userId is null
    _fetchUserProfile();
  }

  // Fetch user data from Firebase Realtime Database
  Future<void> _fetchUserProfile() async {
    final snapshot = await _database.child("Users/$_userId").get();
    
    if (snapshot.exists) {
      setState(() {
        _userData = Map<String, dynamic>.from(snapshot.value as Map);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User data not found')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Image (From Firebase or Placeholder)
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _userData["profilePicture"] != null
                          ? NetworkImage(_userData["profilePicture"])
                          : const AssetImage('assets/profile.png') as ImageProvider,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userData["name"] ?? "No Name",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _userData["email"] ?? "No Email",
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  // Phone Number
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: const Text('Phone Number'),
                    subtitle: Text(_userData["phoneNumber"] ?? 'No Phone Number'),
                  ),
                  // Rating
                  FutureBuilder<double>(
                    future: _getUserRating(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Text("Error loading rating");
                      }
                      final rating = snapshot.data ?? 0.0;
                      return ListTile(
                        leading: const Icon(Icons.star),
                        title: const Text('Average Rating'),
                        subtitle: Text(rating.toStringAsFixed(1)),
                      );
                    },
                  ),
                  // Ride History
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Ride History'),
                    onTap: () {
                      // Navigate to ride history page
                    },
                  ),
                ],
              ),
            ),
    );
  }

  // Fetch the user's average rating
  Future<double> _getUserRating() async {
    double totalRating = 0.0;
    int ratingCount = 0;

    final snapshot = await _database.child("Ratings/$_userId").get();
    if (snapshot.exists) {
      final ratings = Map<String, dynamic>.from(snapshot.value as Map);
      ratings.forEach((key, value) {
        totalRating += value["rating"];
        ratingCount++;
      });

      if (ratingCount > 0) {
        return totalRating / ratingCount; // Calculate average
      }
    }
    return 0.0; // If no ratings found, return 0
  }
}
