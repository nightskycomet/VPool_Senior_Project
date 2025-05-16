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
  bool _isChatCreated = false;
  Map<String, String> _userNames = {}; // Stores user IDs to names mapping

  @override
  void initState() {
    super.initState();
    _fetchReportDetails();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<String?> _fetchUserName(String userId) async {
    try {
      // Check Users node first
      final userSnapshot = await _database.child("Users/$userId").get();
      if (userSnapshot.exists) {
        return userSnapshot.child("name").value.toString();
      }

      // If not found in Users, check Employees node
      final employeeSnapshot = await _database.child("Employees/$userId").get();
      if (employeeSnapshot.exists) {
        return employeeSnapshot.child("name").value.toString();
      }

      return null;
    } catch (e) {
      debugPrint("Error fetching user name: $e");
      return null;
    }
  }

  Future<Map<String, String>> _fetchUserNames(List<String> userIds) async {
    final Map<String, String> names = {};

    for (final userId in userIds) {
      if (userId.isEmpty) continue;
      try {
        final name = await _fetchUserName(userId);
        if (name != null) {
          names[userId] = name;
        }
      } catch (e) {
        debugPrint("Error fetching name for $userId: $e");
      }
    }

    return names;
  }

  Future<void> _fetchReportDetails() async {
    final snapshot = await _database.child("Reports/${widget.reportId}").get();

    if (snapshot.exists) {
      if (mounted) {
        setState(() {
          _reportData = Map<String, dynamic>.from(snapshot.value as Map);
        });
      }

      // Fetch names for reporter and reported user
      final userIds = [
        _reportData["reporterId"]?.toString(),
        _reportData["reportedUserId"]?.toString(),
      ].whereType<String>().toList();

      final userNames = await _fetchUserNames(userIds);

      if (mounted) {
        setState(() {
          _userNames = userNames;
          _isLoading = false;

          if (_reportData["chatId"] != null) {
            _isChatCreated = true;
            _setupRealtimeListener();
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
            "senderName": message.child("senderName").value.toString(),
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
    await _showPunishmentModal();
  }

  Future<void> _showPunishmentModal() async {
    final reasonController = TextEditingController();
    final durationController = TextEditingController();
    String durationUnit = 's';

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

    await _database.child("Reports/${widget.reportId}").update({
      "status": "accepted",
      "punishmentReason": reason,
      "punishmentEndTime": endTime.millisecondsSinceEpoch,
    });

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
  final reporterId = _reportData["reporterId"]?.toString();
  final employeeId = await _fetchEmployeeId();

  if (reporterId == null || reporterId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error: Reporter ID is missing')),
    );
    return;
  }

  if (employeeId == null || employeeId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error: Could not identify employee')),
    );
    return;
  }

  // Get names for the chat participants
  final names = await _fetchUserNames([reporterId, employeeId]);
  final reporterName = names[reporterId] ?? "Reporter";
  final employeeName = names[employeeId] ?? "Employee";

  final chatData = {
    "participants": {
      reporterId: true,
      employeeId: true,
    },
    "participantNames": {
      reporterId: reporterName,
      employeeId: employeeName,
    },
    "label": "Report Chat - ${widget.reportId}",
    "timestamp": ServerValue.timestamp,
  };

  try {
    final chatRef = _database.child("ReportChats").push();
    final chatId = chatRef.key;

    if (chatId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Failed to create chat')),
      );
      return;
    }

    await chatRef.set(chatData);

    await _database.child("Reports/${widget.reportId}").update({
      "chatId": chatId,
    });

    if (mounted) {
      setState(() {
        _isChatCreated = true;
        _reportData["chatId"] = chatId;
      });
    }

    _setupRealtimeListener();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error creating chat: ${e.toString()}')),
    );
  }
}
  Future<String?> _fetchEmployeeId() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Employee not authenticated')),
      );
      return null;
    }

    try {
      // First check if the user exists in Employees node
      final employeeSnapshot =
          await _database.child("Employees/${currentUser.uid}").get();

      if (employeeSnapshot.exists) {
        return currentUser.uid;
      }

      // If not found in Employees, check Users node with employee role
      final userSnapshot =
          await _database.child("Users/${currentUser.uid}").get();
      if (userSnapshot.exists &&
          userSnapshot.child("role").value == "employee") {
        return currentUser.uid;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Employee not found in database')),
      );
      return null;
    } catch (e) {
      debugPrint("Error fetching employee ID: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error checking employee status')),
      );
      return null;
    }
  }

  Future<void> _sendMessage() async {
    final chatId = _reportData["chatId"];
    final employeeId = _auth.currentUser?.uid;
    final message = _messageController.text.trim();

    if (chatId == null || employeeId == null || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Missing chat ID or message')),
      );
      return;
    }

    // Get the sender's name
    final senderName = _userNames[employeeId] ?? "Employee";

    final messageData = {
      "senderId": employeeId,
      "senderName": senderName,
      "message": message,
      "timestamp": ServerValue.timestamp,
    };

    await _database
        .child("ReportChats/$chatId/messages")
        .push()
        .set(messageData);

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
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
                          'Reported User: ${_userNames[_reportData["reportedUserId"]] ?? _reportData["reportedUserId"]}',
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Reporter: ${_userNames[_reportData["reporterId"]] ?? _reportData["reporterId"]}',
                        ),
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
                                  final senderName = message["senderName"] ??
                                      _userNames[message["senderId"]] ??
                                      message["senderId"];

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
