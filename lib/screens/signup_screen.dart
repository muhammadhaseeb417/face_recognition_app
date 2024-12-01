import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  CameraController? _controller;
  late List<CameraDescription> _cameras;
  int _currentCameraIndex = 0;
  bool isTraining = false;
  List<File> trainingImages = [];
  bool isCapturing = false;
  String userName = '';
  final int MIN_TRAINING_IMAGES = 10; // Lowered minimum
  final int MAX_TRAINING_IMAGES = 50; // Matching original requirement
  Timer? _captureTimer;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _controller =
        CameraController(_cameras[_currentCameraIndex], ResolutionPreset.high);

    try {
      await _controller!.initialize();
      setState(() {});
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  void _switchCamera() async {
    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    await _controller?.dispose();

    _controller =
        CameraController(_cameras[_currentCameraIndex], ResolutionPreset.high);

    try {
      await _controller!.initialize();
      setState(() {});
    } catch (e) {
      print("Error switching camera: $e");
    }
  }

  Future<bool> detectFace(File imageFile) async {
    try {
      // Simple face detection using image package
      img.Image? image = img.decodeImage(imageFile.readAsBytesSync());

      // Basic checks to ensure a reasonable image
      return image != null && image.width > 100 && image.height > 100;
    } catch (e) {
      print('Face detection error: $e');
      return false;
    }
  }

  Future<void> startCapturing() async {
    if (userName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a name first!')),
      );
      return;
    }

    setState(() {
      isCapturing = true;
      trainingImages.clear();
    });

    // Take a picture every second
    _captureTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      try {
        // Capture an image
        final XFile? image = await _controller!.takePicture();

        if (image != null) {
          // Convert XFile to File
          File imageFile = File(image.path);

          // Detect if it looks like a face (very basic check)
          bool hasFace = await detectFace(imageFile);

          if (hasFace) {
            // Save the image
            final directory = await getApplicationDocumentsDirectory();
            final filePath =
                '${directory.path}/face_${DateTime.now().millisecondsSinceEpoch}.jpg';

            File newFile = await imageFile.copy(filePath);

            trainingImages.add(newFile);
            setState(() {});
          }

          // Stop if max images reached
          if (trainingImages.length >= MAX_TRAINING_IMAGES) {
            stopCapturing();
          }
        }
      } catch (e) {
        print('Error capturing image: $e');
      }
    });
  }

  void stopCapturing() {
    _captureTimer?.cancel();
    setState(() {
      isCapturing = false;
    });
  }

  Future<void> signupAndTrain() async {
    if (userName.isEmpty || trainingImages.length < MIN_TRAINING_IMAGES) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please capture at least $MIN_TRAINING_IMAGES images!'),
        ),
      );
      return;
    }

    setState(() {
      isTraining = true;
    });

    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('http://192.168.181.73:5000/train'));
      request.fields['name'] = userName;

      // Upload images
      for (var image in trainingImages) {
        request.files
            .add(await http.MultipartFile.fromPath('images', image.path));
      }

      var response = await request.send();

      setState(() {
        isTraining = false;
      });

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User trained successfully!')));
      } else {
        var responseBody = await response.stream.bytesToString();
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Training failed: $responseBody')));
      }
    } catch (e) {
      setState(() {
        isTraining = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error during training: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Signup & Train'),
        actions: [
          IconButton(
            icon: Icon(Icons.switch_camera),
            onPressed: _switchCamera,
          ),
        ],
      ),
      body: Column(
        children: [
          // Display the camera preview only if it's initialized
          if (_controller != null && _controller!.value.isInitialized)
            SizedBox(
              height: 300,
              child: CameraPreview(_controller!),
            ),
          SizedBox(height: 16),
          TextField(
            onChanged: (value) {
              userName = value;
            },
            decoration: InputDecoration(labelText: 'Enter Name'),
          ),
          SizedBox(height: 16),
          // Image count display
          Text(
            'Images Captured: ${trainingImages.length} / $MAX_TRAINING_IMAGES',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 8),
          // Progress bar
          LinearProgressIndicator(
            value: trainingImages.length / MAX_TRAINING_IMAGES,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: isCapturing ? stopCapturing : startCapturing,
            child: isCapturing
                ? Text('Stop Capturing')
                : Text('Start Capturing Faces'),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: isTraining ? null : signupAndTrain,
            child: isTraining
                ? CircularProgressIndicator()
                : Text('Signup & Train'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _captureTimer?.cancel();
    super.dispose();
  }
}
