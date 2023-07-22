import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:async';

void main() {
  runApp(FaceDetectionApp());
}

class FaceDetectionApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FaceDetectionScreen(),
    );
  }
}

class FaceDetectionScreen extends StatefulWidget {
  @override
  _FaceDetectionScreenState createState() => _FaceDetectionScreenState();
}

class _FaceDetectionScreenState extends State<FaceDetectionScreen> {
  final FaceDetector _faceDetector = GoogleMlKit.vision.faceDetector();
  File? _imageFile;
  List<Face> _detectedFaces = [];

  @override
  void dispose() {
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _getImageAndDetectFaces(ImageSource source) async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: source);

    if (pickedImage != null) {
      final imageFile = File(pickedImage.path);
      final inputImage = InputImage.fromFile(imageFile);

      try {
        final faces = await _faceDetector.processImage(inputImage);
        setState(() {
          _imageFile = imageFile;
          _detectedFaces = faces;
        });
      } catch (e) {
        print("Error during face detection: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Face Detection App'),
      ),
      body: Center(
        child: _imageFile == null
            ? Text('No image selected')
            : ImageWithFaceBoxes(
          imageFile: _imageFile!,
          detectedFaces: _detectedFaces,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _getImageAndDetectFaces(ImageSource.camera),
        child: Icon(Icons.camera),
      ),
    );
  }
}

class ImageWithFaceBoxes extends StatelessWidget {
  final File imageFile;
  final List<Face> detectedFaces;

  ImageWithFaceBoxes({required this.imageFile, required this.detectedFaces});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Size>(
      future: _getImageSize(imageFile),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }

        final Size imageSize = snapshot.data!;
        final double aspectRatio = imageSize.width / imageSize.height;

        return AspectRatio(
          aspectRatio: aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(imageFile, fit: BoxFit.cover),
              CustomPaint(
                painter: FacePainter(imageSize: imageSize, detectedFaces: detectedFaces),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Size> _getImageSize(File imageFile) async {
    Completer<Size> completer = Completer<Size>();
    Image image = Image.file(imageFile);
    image.image.resolve(ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(Size(
          info.image!.width.toDouble(),
          info.image!.height.toDouble(),
        ));
      }),
    );
    return completer.future;
  }
}

class FacePainter extends CustomPainter {
  final Size imageSize;
  final List<Face> detectedFaces;

  FacePainter({required this.imageSize, required this.detectedFaces});

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / imageSize.width;
    final double scaleY = size.height / imageSize.height;

    final Paint paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final face in detectedFaces) {
      final Rect rect = Rect.fromLTRB(
        face.boundingBox.left * scaleX,
        face.boundingBox.top * scaleY,
        face.boundingBox.right * scaleX,
        face.boundingBox.bottom * scaleY,
      );

      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return imageSize != oldDelegate.imageSize || detectedFaces != oldDelegate.detectedFaces;
  }
}
