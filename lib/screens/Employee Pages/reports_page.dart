import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:vpool/screens/Employee%20Pages/reports_detail_page.dart'; // Import the ReportDetailsPage

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  _ReportsPageState createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> _pendingReports = [];
  List<Map<String, dynamic>> _handledReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    final snapshot = await _database.child("Reports").get();

    if (snapshot.exists) {
      final reports = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        _pendingReports = reports.entries.where((entry) => entry.value["status"] == null).map<Map<String, dynamic>>((entry) {
          return {
            "id": entry.key,
            ...entry.value,
          };
        }).toList();

        _handledReports = reports.entries.where((entry) => entry.value["status"] != null).map<Map<String, dynamic>>((entry) {
          return {
            "id": entry.key,
            ...entry.value,
          };
        }).toList();

        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reports'),
          backgroundColor: Colors.blue.shade900,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Handled'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // Pending Reports Tab
                  _pendingReports.isEmpty
                      ? const Center(child: Text('No pending reports'))
                      : ListView.builder(
                          itemCount: _pendingReports.length,
                          itemBuilder: (context, index) {
                            final report = _pendingReports[index];
                            return Card(
                              margin: const EdgeInsets.all(8),
                              child: ListTile(
                                title: Text('Report ID: ${report["id"]}'),
                                subtitle: Text('Reason: ${report["reason"]}'),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ReportDetailsPage(reportId: report["id"]),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),

                  // Handled Reports Tab
                  _handledReports.isEmpty
                      ? const Center(child: Text('No handled reports'))
                      : ListView.builder(
                          itemCount: _handledReports.length,
                          itemBuilder: (context, index) {
                            final report = _handledReports[index];
                            return Card(
                              margin: const EdgeInsets.all(8),
                              child: ListTile(
                                title: Text('Report ID: ${report["id"]}'),
                                subtitle: Text('Status: ${report["status"]}'),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ReportDetailsPage(reportId: report["id"]),
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
    );
  }
}