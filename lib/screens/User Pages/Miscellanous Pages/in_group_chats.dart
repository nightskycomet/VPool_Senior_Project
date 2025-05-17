import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class GroupChatPage extends StatefulWidget {
  final String chatId; // Changed from rideId to chatId to support both types
  final bool isReportChat; // Flag to determine if it's a report chat

  const GroupChatPage({
    super.key,
    required this.chatId,
    this.isReportChat = false, // Default to false (ride chat)
  });

  @override
  _GroupChatPageState createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  String _chatTitle = "Loading...";
  final Map<String, String> _userNames = {}; // Map of user IDs to names

  @override
  void initState() {
    super.initState();
    _fetchChatDetails();
    _fetchUserNames();
    _setupRealtimeListener();
  }

  Future<void> _fetchChatDetails() async {
    if (widget.isReportChat) {
      // Fetch report chat details
      final reportChatSnapshot =
          await _database.child("ReportChats/${widget.chatId}").get();
      if (reportChatSnapshot.exists) {
        final label = reportChatSnapshot.child("label").value.toString();
        setState(() {
          _chatTitle = label;
        });
      }
    } else {
      // Fetch ride chat details
      final rideSnapshot =
          await _database.child("Rides/${widget.chatId}").get();
      if (rideSnapshot.exists) {
        final startLocation =
            rideSnapshot.child("startLocation").value.toString();
        final endLocation = rideSnapshot.child("endLocation").value.toString();
        setState(() {
          _chatTitle = "$startLocation to $endLocation";
        });
      }
    }
  }

  Future<void> _fetchUserNames() async {
    if (widget.isReportChat) {
      // Fetch participants for report chat
      final reportChatSnapshot = await _database
          .child("ReportChats/${widget.chatId}/participantNames")
          .get();
      if (reportChatSnapshot.exists) {
        for (var participantId in reportChatSnapshot.children) {
          final userSnapshot = await _database
              .child("Users/${participantId.key}")
              .child("name")
              .get();
          if (userSnapshot.exists) {
            final userName = userSnapshot.value.toString();
            setState(() {
              _userNames[participantId.key.toString()] = userName;
            });
          }
        }
      }
    } else {
      // Fetch driver and riders for ride chat
      final rideSnapshot =
          await _database.child("Rides/${widget.chatId}").get();
      if (rideSnapshot.exists) {
        final driverId = rideSnapshot.child("driverId").value.toString();

        // Fetch driver's name
        final driverSnapshot =
            await _database.child("Users/$driverId").child("name").get();
        if (driverSnapshot.exists) {
          final driverName = driverSnapshot.value.toString();
          setState(() {
            _userNames[driverId] = driverName;
          });
        }

        // Fetch riders' names
        final ridersSnapshot =
            await _database.child("Rides/${widget.chatId}/riders").get();
        if (ridersSnapshot.exists) {
          for (var riderId in ridersSnapshot.children) {
            final userSnapshot = await _database
                .child("Users/${riderId.value}")
                .child("name")
                .get();
            if (userSnapshot.exists) {
              final riderName = userSnapshot.value.toString();
              setState(() {
                _userNames[riderId.value.toString()] = riderName;
              });
            }
          }
        }
      }
    }
  }

 void _setupRealtimeListener() {
  final messagesPath = widget.isReportChat
      ? "ReportChats/${widget.chatId}/messages"
      : "GroupChats/${widget.chatId}/messages";

  _database.child(messagesPath).onChildAdded.listen((event) {
    if (event.snapshot.value != null) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final message = {
        "senderId": data["senderId"].toString(),
        "message": data["message"].toString(),
        "timestamp": data["timestamp"].toString(),
      };

      setState(() {
        _messages.add(message);
      });
    }
  });
}


  Future<void> _sendMessage() async {
    final userId = _auth.currentUser!.uid;
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();

    // Check if the message is empty
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message cannot be empty!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Determine the path for the message
    String messagesPath;

    if (widget.isReportChat) {
      messagesPath = "ReportChats/${widget.chatId}/messages";
      await _database.child(messagesPath).push().set({
        "senderId": userId,
        "message": _messageController.text,
        "timestamp": ServerValue.timestamp,
      });
    } else {
      messagesPath = "GroupChats/${widget.chatId}/messages";

      // Send the message with the "message" key
      await _database.child(messagesPath).child(messageId).set({
        "senderId": userId,
        "message": _messageController.text,
        "timestamp": ServerValue.timestamp,
      });
    }

    // Clear the message input field
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_chatTitle),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final senderName =
                    _userNames[message["senderId"]] ?? 'Employee';
                return ListTile(
                  title: Text(message["message"]),
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
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
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
