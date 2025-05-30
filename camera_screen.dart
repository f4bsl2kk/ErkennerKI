import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  bool _isCameraReady = false;
  bool _isDetecting = false;
  List<dynamic>? _detections;
  AudioPlayer? _audioPlayer;
  bool _soundPlayed = false;
  double _lastDetectionTime = 0;
  final double _minDetectionInterval = 5.0; // Minimum 5 seconds between detections

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    _audioPlayer = AudioPlayer();
    try {
      // Copy sound file to local storage
      final ByteData soundData = await rootBundle.load('assets/sounds/detection_sound.mp3');
      final Directory tempDir = await getTemporaryDirectory();
      final File soundFile = File('${tempDir.path}/detection_sound.mp3');
      await soundFile.writeAsBytes(soundData.buffer.asUint8List());
    } catch (e) {
      print('Failed to initialize audio: $e');
    }
  }

  void _playDetectionSound() {
    if (_audioPlayer != null && !_soundPlayed) {
      final double currentTime = DateTime.now().millisecondsSinceEpoch / 1000;
      if (currentTime - _lastDetectionTime >= _minDetectionInterval) {
        _audioPlayer!.play(AssetSource('assets/sounds/detection_sound.mp3'));
        _lastDetectionTime = currentTime;
        _soundPlayed = true;
      }
    }
  }

  Future<void> _initializeCamera() async {
    // Request camera permission
    final status = await Permission.camera.request();
    if (status.isGranted) {
      final cameras = await availableCameras();
      _controller = CameraController(
        cameras[0], // Use first camera (back camera)
        ResolutionPreset.medium,
      );
      await _controller.initialize();
      setState(() {
        _isCameraReady = true;
      });
    } else {
      // Handle permission denied
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission is required')),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _detectVans() async {
    if (_isDetecting) return;
    
    try {
      setState(() {
        _isDetecting = true;
        _detections = null;
      });

      final image = await _controller.takePicture();
      
      final predictions = await Tflite.runModelOnImage(
        path: image.path,
        numResults: 1,
        threshold: 0.5,
      );

      setState(() {
        _detections = predictions;
        _soundPlayed = false; // Reset sound played flag for next detection
      });

      // Play sound if white van is detected
      if (predictions != null && predictions.isNotEmpty && predictions[0]['label'] == 'white_van') {
        _playDetectionSound();
      }
    } catch (e) {
      print('Detection error: $e');
    } finally {
      setState(() {
        _isDetecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraReady) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Initializing camera...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Van Detector'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        children: [
          Expanded(
            child: CameraPreview(_controller),
          ),
          if (_detections != null && _detections!.isNotEmpty)
            CustomPaint(
              painter: DetectionPainter(
                detections: _detections!,
                previewSize: _controller.value.previewSize!,
              ),
            ),
          if (_detections != null && _detections!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detected Van:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Confidence: ${(_detections![0]['confidence'] * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _detectVans,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

class DetectionPainter extends CustomPainter {
  final List<dynamic> detections;
  final Size previewSize;

  DetectionPainter({
    required this.detections,
    required this.previewSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    for (final detection in detections) {
      if (detection['label'] == 'white_van') {
        final double width = size.width;
        final double height = size.height;
        
        // Get bounding box coordinates
        final double x = detection['rect']['x'] * width;
        final double y = detection['rect']['y'] * height;
        final double w = detection['rect']['w'] * width;
        final double h = detection['rect']['h'] * height;

        // Draw green rectangle
        canvas.drawRect(
          Rect.fromLTWH(x, y, w, h),
          paint,
        );

        // Draw confidence text
        final TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: 'Van: ${detection['confidence'] * 100.0}%',
            style: const TextStyle(
              color: Colors.green,
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(x, y - textPainter.height - 5),
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
    );
  }
}
