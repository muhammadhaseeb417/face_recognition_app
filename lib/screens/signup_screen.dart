import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  List<File> trainingImages = [];
  bool isTraining = false;

  Future<void> pickTrainingImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        trainingImages = pickedFiles.map((file) => File(file.path)).toList();
      });
    }
  }

  Future<void> signupAndTrain() async {
    if (_nameController.text.isEmpty || trainingImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please enter a name and select training images!')),
      );
      return;
    }

    setState(() {
      isTraining = true;
    });

    var request = http.MultipartRequest(
        'POST', Uri.parse('http://192.168.181.73:5000/train'));
    request.fields['name'] = _nameController.text;
    for (var image in trainingImages) {
      request.files
          .add(await http.MultipartFile.fromPath('images', image.path));
    }
    var response = await request.send();

    setState(() {
      isTraining = false;
    });

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('User trained successfully!')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Training failed.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Signup & Train')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
                onPressed: pickTrainingImages,
                child: Text('Pick Training Images')),
            SizedBox(height: 16),
            trainingImages.isNotEmpty
                ? Text('${trainingImages.length} images selected')
                : Text('No training images selected'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: isTraining ? null : signupAndTrain,
              child: isTraining
                  ? CircularProgressIndicator()
                  : Text('Signup & Train'),
            ),
          ],
        ),
      ),
    );
  }
}
