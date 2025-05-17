import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vpool/screens/User%20Pages/user_home_page.dart';
import 'package:vpool/screens/Shared%20Pages/login_page.dart';
import 'package:vpool/screens/Employee%20Pages/employee_home_page.dart'; 
import 'firebase_options.dart'; 

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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        // Handle navigation to the HomePage with arguments
        if (settings.name == '/home') {
          final String role = settings.arguments as String;
          if (role == 'employee') {
            return MaterialPageRoute(
              builder: (context) => EmployeeHomePage(role: role),
            );
          } else {
            return MaterialPageRoute(
              builder: (context) => HomePage(role: role),
            );
          }
        }
        // Handle other routes here if needed
        return null;
      },
      routes: {
        '/': (context) => LoginPage(), // LoginPage as the initial route
        '/login': (context) => LoginPage(), // Define the login route
        // Add other routes here
      },
      onUnknownRoute: (settings) {
        // Handle unknown routes (e.g., show a 404 page)
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Text('Page not found: ${settings.name}'),
            ),
          ),
        );
      },
    );
  }
}