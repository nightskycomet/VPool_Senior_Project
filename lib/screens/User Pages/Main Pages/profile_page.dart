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

  // Show a dialog to input the report reason
  Future<void> _showReportDialog() async {
    final reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Report User'),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              hintText: 'Enter the reason for reporting this user',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (reasonController.text.isNotEmpty) {
                  await _submitReport(reasonController.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  // Submit the report to Firebase
  Future<void> _submitReport(String reason) async {
    final reportData = {
      "reportedUserId": _userId,
      "reporterId": _auth.currentUser!.uid,
      "reason": reason,
      "timestamp": ServerValue.timestamp,
    };

    // Generate a unique report ID using Firebase's push() method
    final reportRef = _database.child("Reports").push();
    await reportRef.set(reportData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report submitted successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = _userId == _auth.currentUser!.uid;

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

                  // Report Button (only show if not viewing your own profile)
                  if (!isCurrentUser)
                    Center(
                      child: ElevatedButton(
                        onPressed: _showReportDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: const Text('Report User'),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}