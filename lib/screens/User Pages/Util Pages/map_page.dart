// import 'package:flutter/material.dart';

// class MapPage extends StatelessWidget {
//   const MapPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Map'),
//         backgroundColor: Colors.blue.shade900,
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.map,
//               size: 100,
//               color: Colors.blue.shade900,
//             ),
//             SizedBox(height: 16),
//             Text(
//               'Interactive Map',
//               style: TextStyle(fontSize: 24),
//             ),
//             SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: () {
//                 // Open a real map (e.g., using Google Maps API)
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue.shade900,
//                 padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//               ),
//               child: Text(
//                 'Open Map',
//                 style: TextStyle(fontSize: 18, color: Colors.white),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }