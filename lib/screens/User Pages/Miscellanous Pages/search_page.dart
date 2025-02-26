import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:vpool/screens/User%20Pages/Main%20Pages/profile_page.dart';

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key});

  @override
  _UserSearchPageState createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final DatabaseReference _database = FirebaseDatabase.instance.ref().child("Users");
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchRandomUsers(); // Load random users initially
  }

  // Fetch 15 random users if no search input
  Future<void> _fetchRandomUsers() async {
    setState(() => _isLoading = true);
    final snapshot = await _database.limitToFirst(15).get();
    if (snapshot.exists) {
      setState(() {
        _users = (snapshot.value as Map).entries.map((e) {
          return {
            "id": e.key,
            "name": e.value["name"],
            "email": e.value["email"],
            "role": e.value["role"],
          };
        }).toList();
      });
    }
    setState(() => _isLoading = false);
  }

  // Search users by name or email
  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      _fetchRandomUsers(); // Show random users if search is empty
      return;
    }

    setState(() => _isLoading = true);

    final snapshot = await _database.get();
    if (snapshot.exists) {
      List<Map<String, dynamic>> allUsers = (snapshot.value as Map).entries.map((e) {
        return {
          "id": e.key,
          "name": e.value["name"],
          "email": e.value["email"],
          "role": e.value["role"],
        };
      }).toList();

      // Filter users by name or email containing query
      setState(() {
        _users = allUsers
            .where((user) =>
                user["name"].toLowerCase().contains(query.toLowerCase()) ||
                user["email"].toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Users"),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search by name or email...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _searchUsers,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const Center(child: Text("No users found"))
                    : ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: const Icon(Icons.person),
                              title: Text(user["name"]),
                              subtitle: Text(user["email"]),
                              trailing: Text(user["role"].toUpperCase()),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProfilePage(userId: user["id"]),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
