import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ReportDetailsPage extends StatefulWidget {
  final String reportId;

  const ReportDetailsPage({super.key, required this.reportId});

  @override
  _ReportDetailsPageState createState() => _ReportDetailsPageState();
}

class _ReportDetailsPageState extends State<ReportDetailsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  Map<String, dynamic> _reportData = {};
  bool _isLoading = true;
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _isChatCreated = false; // Track if the chat has been created

  @override
  void initState() {
    super.initState();
    _fetchReportDetails();
  }

  @override
  void dispose() {
    _messageController.dispose(); // Dispose the controller
    super.dispose();
  }

  Future<void> _fetchReportDetails() async {
    final snapshot = await _database.child("Reports/${widget.reportId}").get();

    if (snapshot.exists) {
      if (mounted) {
        setState(() {
          _reportData = Map<String, dynamic>.from(snapshot.value as Map);
          _isLoading = false;

          // Check if a chat already exists
          if (_reportData["chatId"] != null) {
            _isChatCreated = true;
            _setupRealtimeListener(); // Set up real-time listener for messages
          }
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report not found')),
      );
    }
  }

  void _setupRealtimeListener() {
    final chatId = _reportData["chatId"];
    if (chatId == null) return;

    _database.child("ReportChats/$chatId/messages").onValue.listen((event) {
      if (event.snapshot.exists) {
        final messages = <Map<String, dynamic>>[];
        for (var message in event.snapshot.children) {
          messages.add({
            "id": message.key,
            "senderId": message.child("senderId").value.toString(),
            "message": message.child("message").value.toString(),
            "timestamp": message.child("timestamp").value.toString(),
          });
        }
        if (mounted) {
          setState(() {
            _messages = messages;
          });
        }
      }
    });
  }

  Future<void> _rejectReport(String reason) async {
    await _database.child("Reports/${widget.reportId}").update({
      "status": "rejected",
      "rejectionReason": reason,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report rejected')),
    );
    Navigator.pop(context);
  }

  Future<void> _acceptReport() async {
    // Show the punishment modal
    await _showPunishmentModal();
  }

  Future<void> _showPunishmentModal() async {
    final reasonController = TextEditingController();
    final durationController = TextEditingController();
    String durationUnit = 's'; // Default unit: seconds

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Punish User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  hintText: 'Enter the reason for punishment',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: durationController,
                      decoration: const InputDecoration(
                        hintText: 'Duration (e.g., 10)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: durationUnit,
                    items: const [
                      DropdownMenuItem(value: 's', child: Text('s')),
                      DropdownMenuItem(value: 'm', child: Text('m')),
                      DropdownMenuItem(value: 'h', child: Text('h')),
                      DropdownMenuItem(value: 'd', child: Text('d')),
                      DropdownMenuItem(value: 'w', child: Text('w')),
                      DropdownMenuItem(value: 'mo', child: Text('mo')),
                      DropdownMenuItem(value: 'yr', child: Text('yr')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        durationUnit = value!;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (reasonController.text.isNotEmpty &&
                    durationController.text.isNotEmpty) {
                  final duration = int.tryParse(durationController.text);
                  if (duration != null) {
                    await _punishUser(
                      reasonController.text,
                      duration,
                      durationUnit,
                    );
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _punishUser(String reason, int duration, String unit) async {
    // Calculate the punishment end time
    final now = DateTime.now();
    DateTime endTime;

    switch (unit) {
      case 's':
        endTime = now.add(Duration(seconds: duration));
        break;
      case 'm':
        endTime = now.add(Duration(minutes: duration));
        break;
      case 'h':
        endTime = now.add(Duration(hours: duration));
        break;
      case 'd':
        endTime = now.add(Duration(days: duration));
        break;
      case 'w':
        endTime = now.add(Duration(days: duration * 7));
        break;
      case 'mo':
        endTime = now.add(Duration(days: duration * 30));
        break;
      case 'yr':
        endTime = now.add(Duration(days: duration * 365));
        break;
      default:
        endTime = now;
    }

    // Update the report status
    await _database.child("Reports/${widget.reportId}").update({
      "status": "accepted",
      "punishmentReason": reason,
      "punishmentEndTime": endTime.millisecondsSinceEpoch,
    });

    // Update the user's status (e.g., disable account)
    await _database.child("Users/${_reportData["reportedUserId"]}").update({
      "isDisabled": true,
      "disabledUntil": endTime.millisecondsSinceEpoch,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User punished. Report accepted.')),
    );
    Navigator.pop(context);
  }

  Future<void> _createChat() async {
    final reporterId = _reportData["reporterId"];
    final employeeId = await _fetchEmployeeId(); // Fetch employee UID

    if (reporterId == null || employeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Missing user IDs')),
      );
      return;
    }

    // Create a new chat for employee and reporter
    final chatData = {
      "participants": {
        reporterId: true,
        employeeId: true,
      },
      "label": "Report Chat - ${widget.reportId}",
      "timestamp": ServerValue.timestamp,
    };

    final chatRef = _database.child("ReportChats").push();
    final chatId = chatRef.key;

    if (chatId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Failed to create chat')),
      );
      return;
    }

    await chatRef.set(chatData);

    // Update the report with the chat ID
    await _database.child("Reports/${widget.reportId}").update({
      "chatId": chatId,
    });

    // Set chat as created and fetch messages
    if (mounted) {
      setState(() {
        _isChatCreated = true;
        _reportData["chatId"] = chatId;
      });
    }

    // Set up real-time listener for messages
    _setupRealtimeListener();
  }

  Future<String?> _fetchEmployeeId() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Employee not authenticated')),
      );
      Navigator.pushReplacementNamed(context, '/login');
      return null;
    }

    // Fetch the employee's data from the Employees node
    final employeeSnapshot = await _database.child("Employees/${currentUser.uid}").get();

    if (employeeSnapshot.exists) {
      // Return the employee's UID
      return currentUser.uid;
    } else {
      // If no employee is found, show an error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Employee not found in database')),
      );
      return null;
    }
  }

  Future<void> _sendMessage() async {
    final chatId = _reportData["chatId"];
    final employeeId = _auth.currentUser!.uid;
    final message = _messageController.text.trim();

    if (chatId == null || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Missing chat ID or message')),
      );
      return;
    }

    final messageData = {
      "senderId": employeeId,
      "message": message,
      "timestamp": ServerValue.timestamp,
    };

    await _database
        .child("ReportChats/$chatId/messages")
        .push()
        .set(messageData);

    // Clear the message input
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Report Details'),
          backgroundColor: Colors.blue.shade900,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Details'),
              Tab(text: 'Chat'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // Details Tab
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Report ID: ${widget.reportId}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Text('Reason: ${_reportData["reason"]}'),
                        const SizedBox(height: 16),
                        Text(
                            'Reported User ID: ${_reportData["reportedUserId"]}'),
                        const SizedBox(height: 16),
                        Text('Reporter ID: ${_reportData["reporterId"]}'),
                        const SizedBox(height: 16),
                        Text(
                            'Timestamp: ${DateTime.fromMillisecondsSinceEpoch(_reportData["timestamp"]).toString()}'),
                        const SizedBox(height: 32),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    final reasonController =
                                        TextEditingController();
                                    return AlertDialog(
                                      title: const Text('Reject Report'),
                                      content: TextField(
                                        controller: reasonController,
                                        decoration: const InputDecoration(
                                          hintText:
                                              'Enter the reason for rejection',
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            if (reasonController
                                                .text.isNotEmpty) {
                                              _rejectReport(
                                                  reasonController.text);
                                              Navigator.pop(context);
                                            }
                                          },
                                          child: const Text('Submit'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Reject'),
                            ),
                            ElevatedButton(
                              onPressed: _acceptReport,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text('Accept'),
                            ),
                            if (!_isChatCreated)
                              ElevatedButton(
                                onPressed: _createChat,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                                child: const Text('Start Chat'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Chat Tab
                  _isChatCreated
                      ? Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  final message = _messages[index];
                                  return ListTile(
                                    title: Text(message["message"]),
                                    subtitle:
                                        Text('Sent by: ${message["senderId"]}'),
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
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _sendMessage,
                                    icon: const Icon(Icons.send),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : const Center(
                          child: Text('Start a chat to view messages.'),
                        ),
                ],
              ),
      ),
    );
  }
}