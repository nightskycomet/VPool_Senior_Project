import 'package:flutter/material.dart';

class HelpFaqPage extends StatelessWidget {
  const HelpFaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help & FAQ'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text('Frequently Asked Questions', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          _buildFaqItem('How do I join a ride?', 'Go to the ride details page and click on "Join Ride".'),
          _buildFaqItem('How do I leave a ride?', 'On the ride details page, click "Leave Ride".'),
          _buildFaqItem('How do I reset my password?', 'Go to Settings > Change Password and enter your email to receive a reset link.'),
          _buildFaqItem('How do I contact support?', 'You can contact support at support@vpool.com.'),
          _buildFaqItem('How do I delete my account?', 'Please contact support to delete your account permanently.'),
          SizedBox(height: 20),
          Text('Need More Help?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          Text('If you have any other questions, feel free to reach out to us at support@vpool.com.', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      children: [
        Padding(
          padding: EdgeInsets.all(10),
          child: Text(answer, style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}
