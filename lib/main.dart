import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vpool/screens/home_page.dart';
import 'package:vpool/screens/login_page.dart';
import 'firebase_options.dart'; // Generated file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VPool',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        // Handle navigation to the HomePage with arguments
        if (settings.name == '/home') {
          final String role = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => HomePage(role: role),
          );
        }
        return null;
      },
      routes: {
        '/': (context) => LoginPage(), // LoginPage as the initial route
      },
    );
  }
}