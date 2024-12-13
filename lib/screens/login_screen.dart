import 'package:face_recognition_app/screens/home_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';

import '../env_variables.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _isLoggingIn = false;

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> login(BuildContext context) async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please take a picture for login!')),
      );
      return;
    }

    setState(() {
      _isLoggingIn = true;
    });

    // Get the file extension to determine content type
    String extension = _image!.path.split('.').last.toLowerCase();
    String contentType = 'image/jpeg'; // Default to JPEG

    if (extension == 'png') {
      contentType = 'image/png';
    }

    // Prepare the image file to send
    var request =
        http.MultipartRequest('POST', Uri.parse('${requestUrl}/login'));
    request.files.add(await http.MultipartFile.fromPath(
      'image',
      _image!.path,
      contentType: MediaType('image', extension),
    ));

    // Send the image to the backend for recognition
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    setState(() {
      _isLoggingIn = false;
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final allMatches = data["all_matches"];
      final username = data['best_match']['user']; // Accessing the username

      print("Matching percentages with usernames:");
      for (var match in allMatches) {
        print(
            "Username: ${match['user']}, Match Percentage: ${match['match_percentage']}%");
      }

      if (username == null || username.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: username not found!')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Welcome $username!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(username: username),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed. Face not recognized.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _image == null
                ? Text('No image selected.')
                : Image.file(_image!, height: 200),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: pickImage,
              child: Text('Take a Picture'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoggingIn ? null : () => login(context),
              child: _isLoggingIn ? CircularProgressIndicator() : Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
