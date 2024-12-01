import 'package:face_recognition_app/screens/home_page.dart';
import 'package:face_recognition_app/screens/login_screen.dart';
import 'package:face_recognition_app/screens/signup_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      initialRoute: '/', // Set the initial route to HomePage
      routes: {
        '/': (context) => HomePage(
              username: '',
            ),
        '/login': (context) => LoginScreen(),
        '/sign-up': (context) =>
            SignupScreen(), // SignUpScreen should be created
      },
    );
  }
}
