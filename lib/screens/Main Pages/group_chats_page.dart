import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:vpool/screens/Main%20Pages/in_group_chats.dart';

class GroupChatsPage extends StatefulWidget {
  const GroupChatsPage({super.key});

  @override
  _GroupChatsPageState createState() => _GroupChatsPageState();
}

class _GroupChatsPageState extends State<GroupChatsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _groupChatsDatabase = FirebaseDatabase.instance.ref().child('GroupChats');
  final DatabaseReference _ridesDatabase = FirebaseDatabase.instance.ref().child('Rides');
  final DatabaseReference _rideRequestDatabase = FirebaseDatabase.instance.ref().child('Ride_Request');

  List<Map<String, dynamic>> _groupChats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGroupChats();
  }

  Future<void> _fetchGroupChats() async {
  final userId = _auth.currentUser!.uid;
  final groupChats = <Map<String, dynamic>>[];

  // Fetch group chats where the user is a rider
  final rideRequestsSnapshot = await _rideRequestDatabase.orderByChild("userId").equalTo(userId).get();
  if (rideRequestsSnapshot.exists) {
    for (var request in rideRequestsSnapshot.children) {
      if (request.child("status").value == "accepted") {
        final rideId = request.child("rideID").value.toString();
        final groupChatSnapshot = await _groupChatsDatabase.child(rideId).get();
        if (groupChatSnapshot.exists) {
          final rideSnapshot = await _ridesDatabase.child(rideId).get();
          if (rideSnapshot.exists) {
            groupChats.add({
              "rideId": rideId,
              "startLocation": rideSnapshot.child("startLocation").value.toString(),
              "endLocation": rideSnapshot.child("endLocation").value.toString(),
              "startTime": rideSnapshot.child("startTime").value.toString(),
            });
          }
        }
      }
    }
  }

  // Fetch group chats where the user is a driver
  final ridesSnapshot = await _ridesDatabase.orderByChild("driverId").equalTo(userId).get();
  if (ridesSnapshot.exists) {
    for (var ride in ridesSnapshot.children) {
      final rideId = ride.key;
      final groupChatSnapshot = await _groupChatsDatabase.child(rideId!).get();
      if (groupChatSnapshot.exists) {
        groupChats.add({
          "rideId": rideId,
          "startLocation": ride.child("startLocation").value.toString(),
          "endLocation": ride.child("endLocation").value.toString(),
          "startTime": ride.child("startTime").value.toString(),
        });
      }
    }
  }

  setState(() {
    _groupChats = groupChats;
    _isLoading = false;
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Group Chats'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _groupChats.isEmpty
              ? Center(child: Text('No group chats available'))
              : ListView.builder(
                  itemCount: _groupChats.length,
                  itemBuilder: (context, index) {
                    final chat = _groupChats[index];
                    return ListTile(
                      title: Text('${chat["startLocation"]} to ${chat["endLocation"]}'),
                      subtitle: Text('Time: ${chat["startTime"]}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GroupChatPage(rideId: chat["rideId"]),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}