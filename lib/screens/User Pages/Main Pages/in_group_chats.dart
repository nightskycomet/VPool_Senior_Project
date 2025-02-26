import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class GroupChatPage extends StatefulWidget {
  final String rideId;

  const GroupChatPage({super.key, required this.rideId});

  @override
  _GroupChatPageState createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _groupChatsDatabase = FirebaseDatabase.instance.ref().child('GroupChats');
  final DatabaseReference _ridesDatabase = FirebaseDatabase.instance.ref().child('Rides');
  final DatabaseReference _usersDatabase = FirebaseDatabase.instance.ref().child('Users');
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  String _rideTitle = "Loading...";
  Map<String, String> _userNames = {}; // Map of user IDs to names

  @override
  void initState() {
    super.initState();
    _fetchRideDetails();
    _fetchUserNames();
    _setupRealtimeListener();
  }

  Future<void> _fetchRideDetails() async {
    final rideSnapshot = await _ridesDatabase.child(widget.rideId).get();
    if (rideSnapshot.exists) {
      final startLocation = rideSnapshot.child("startLocation").value.toString();
      final endLocation = rideSnapshot.child("endLocation").value.toString();
      setState(() {
        _rideTitle = "$startLocation to $endLocation";
      });
    }
  }

  Future<void> _fetchUserNames() async {
    // Fetch the driver's ID from the ride details
    final rideSnapshot = await _ridesDatabase.child(widget.rideId).get();
    if (rideSnapshot.exists) {
      final driverId = rideSnapshot.child("driverId").value.toString();

      // Fetch the driver's name
      final driverSnapshot = await _usersDatabase.child(driverId).child("name").get();
      if (driverSnapshot.exists) {
        final driverName = driverSnapshot.value.toString();
        setState(() {
          _userNames[driverId] = driverName;
        });
      }
    }

    // Fetch the riders' names
    final ridersSnapshot = await _groupChatsDatabase.child(widget.rideId).child("riders").get();
    if (ridersSnapshot.exists) {
      for (var riderId in ridersSnapshot.value as List) {
        final userSnapshot = await _usersDatabase.child(riderId.toString()).child("name").get();
        if (userSnapshot.exists) {
          final riderName = userSnapshot.value.toString();
          setState(() {
            _userNames[riderId.toString()] = riderName;
          });
        } else {
        }
      }
    } 
  }

  void _setupRealtimeListener() {
    _groupChatsDatabase.child(widget.rideId).child("messages").onValue.listen((event) {
      if (event.snapshot.exists) {
        final messages = <Map<String, dynamic>>[];
        for (var message in event.snapshot.children) {
          messages.add({
            "senderId": message.child("senderId").value.toString(),
            "text": message.child("text").value.toString(),
            "timestamp": message.child("timestamp").value.toString(),
          });
        }
        setState(() {
          _messages = messages;
        });
      }
    });
  }

  Future<void> _sendMessage() async {
  final userId = _auth.currentUser!.uid;
  final messageId = DateTime.now().millisecondsSinceEpoch.toString();

  // Check if the message is empty
  if (_messageController.text.trim().isEmpty) {
    // Show a SnackBar to inform the user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Message cannot be empty!'),
        backgroundColor: Colors.red, // Red color for error messages
      ),
    );
    return; // Exit the function without sending the message
  }

  // Send the message if it's not empty
  await _groupChatsDatabase.child(widget.rideId).child("messages").child(messageId).set({
    "senderId": userId,
    "text": _messageController.text,
    "timestamp": DateTime.now().toIso8601String(),
  });

  // Clear the message input field
  _messageController.clear();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_rideTitle),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final senderName = _userNames[message["senderId"]] ?? "Unknown User";
                return ListTile(
                  title: Text(message["text"]),
                  subtitle: Text('Sent by: $senderName'),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}