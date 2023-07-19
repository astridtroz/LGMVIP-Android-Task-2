import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

void main() {
  runApp(FaceDetectionApp());
}

class FaceDetectionApp extends StatefulWidget {
  @override
  _FaceDetectionAppState createState() => _FaceDetectionAppState();
}

class _FaceDetectionAppState extends State<FaceDetectionApp> {
  late FaceDetector _faceDetector;
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    _faceDetector = GoogleMlKit.vision.faceDetector();
  }

  @override
  void dispose() {
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _detectFaces() async {
    setState(() {
      _isDetecting = true;
    });

    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.camera);

    if (pickedImage != null) {
      final imageFile = File(pickedImage.path);
      final image = InputImage.fromFile(imageFile);
      final faces = await _faceDetector.processImage(image);

      for (final face in faces) {
        // Access face information
        print('Bounding box: ${face.boundingBox}');
        print('Tracking ID: ${face.trackingId}');
        print('Landmarks: ${face.landmarks}');
        print('Smiling probability: ${face.smilingProbability}');
        print('Left eye open probability: ${face.leftEyeOpenProbability}');
        print('Right eye open probability: ${face.rightEyeOpenProbability}');
      }
    }

    setState(() {
      _isDetecting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Face Detection App'),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: _isDetecting ? null : _detectFaces,
            child: Text(_isDetecting ? 'Detecting...' : 'Detect Faces'),
          ),
        ),
      ),
    );
  }
}
