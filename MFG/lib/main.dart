import 'package:flutter/material.dart';
import 'package:manufacturing_dashboard/screens/dashboard_screen.dart';
 
void main() {
  runApp(const MyApp());
}
 
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF2E4057),
      ),
      home: const SettingsAwareDashboard(),
    );
  }
}
 