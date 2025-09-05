import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

class CameraExerciseTracker extends StatefulWidget {
  final String exerciseType;
  
  const CameraExerciseTracker({Key? key, required this.exerciseType}) : super(key: key);

  @override
  State<CameraExerciseTracker> createState() => _CameraExerciseTrackerState();
}

class _CameraExerciseTrackerState extends State<CameraExerciseTracker> with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isDetecting = false;
  bool _isCameraInitialized = false;
  bool _isCameraActive = false;
  PoseDetector? _poseDetector;
  List<Pose> _poses = [];
  int _repCount = 0;
  String _feedback = 'Click camera button to start tracking!';
  bool _isInExercisePosition = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializePoseDetector();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(_pulseController);
  }

  void _initializePoseDetector() {
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.accurate,
    );
    _poseDetector = PoseDetector(options: options);
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      _initializeCamera();
    } else {
      setState(() {
        _feedback = 'Camera permission denied. Please enable it in settings.';
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0], // Use front camera for pose detection
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.yuv420,
        );
        
        await _cameraController!.initialize();
        
        setState(() {
          _isCameraInitialized = true;
          _feedback = 'Camera ready! Tap start to begin tracking.';
        });
      }
    } catch (e) {
      setState(() {
        _feedback = 'Error initializing camera: $e';
      });
    }
  }

  void _startCameraTracking() {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      setState(() {
        _isCameraActive = true;
        _feedback = 'Tracking started! Position yourself in frame.';
      });
      
      _cameraController!.startImageStream(_processCameraImage);
    }
  }

  void _stopCameraTracking() {
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      _cameraController!.stopImageStream();
    }
    
    setState(() {
      _isCameraActive = false;
      _poses = [];
      _feedback = 'Tracking stopped. Total reps: $_repCount';
    });
  }

  void _processCameraImage(CameraImage image) async {
    if (_isDetecting) return;
    _isDetecting = true;

    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage != null) {
        final poses = await _poseDetector!.processImage(inputImage);
        if (mounted) {
          setState(() {
            _poses = poses;
            _analyzeExerciseForm(poses);
          });
        }
      }
    } catch (e) {
      print('Error processing image: $e');
    } finally {
      _isDetecting = false;
    }
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final inputImageRotation = InputImageRotation.rotation90deg;
      const inputImageFormat = InputImageFormat.yuv420;

      final planeData = image.planes.map(
        (Plane plane) {
          return InputImagePlaneMetadata(
            bytesPerRow: plane.bytesPerRow,
            height: plane.height,
            width: plane.width,
          );
        },
      ).toList();

      final inputImageData = InputImageData(
        size: imageSize,
        imageRotation: inputImageRotation,
        inputImageFormat: inputImageFormat,
        planeData: planeData,
      );

      return InputImage.fromBytes(
        bytes: bytes,
        inputImageData: inputImageData,
      );
    } catch (e) {
      print('Error converting camera image: $e');
      return null;
    }
  }

  void _analyzeExerciseForm(List<Pose> poses) {
    if (poses.isEmpty) return;

    final pose = poses.first;
    final landmarks = pose.landmarks;

    // Get key body landmarks for exercise analysis
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];

    if (leftShoulder != null && rightShoulder != null && 
        leftHip != null && rightHip != null && 
        leftKnee != null && rightKnee != null) {
      
      // Calculate body positions for different exercises
      final shoulderHeight = (leftShoulder.y + rightShoulder.y) / 2;
      final hipHeight = (leftHip.y + rightHip.y) / 2;
      final kneeHeight = (leftKnee.y + rightKnee.y) / 2;

      // Exercise-specific analysis
      if (widget.exerciseType.toLowerCase().contains('squat')) {
        _analyzeSquat(shoulderHeight, hipHeight, kneeHeight);
      } else if (widget.exerciseType.toLowerCase().contains('deadlift')) {
        _analyzeDeadlift(shoulderHeight, hipHeight, kneeHeight);
      } else {
        _analyzeGenericExercise(shoulderHeight, hipHeight, kneeHeight);
      }
    }
  }

  void _analyzeSquat(double shoulderHeight, double hipHeight, double kneeHeight) {
    // Squat analysis: hip should go below knee level
    final isSquatPosition = hipHeight > kneeHeight + 30; // Deep squat
    final isStandingPosition = hipHeight < kneeHeight + 10; // Standing

    if (isSquatPosition && !_isInExercisePosition) {
      _isInExercisePosition = true;
      setState(() {
        _feedback = 'Good squat depth! Now stand up.';
      });
    } else if (isStandingPosition && _isInExercisePosition) {
      _isInExercisePosition = false;
      setState(() {
        _repCount++;
        _feedback = 'Squat rep completed! Count: $_repCount';
      });
    }
  }

  void _analyzeDeadlift(double shoulderHeight, double hipHeight, double kneeHeight) {
    // Deadlift analysis: bending forward and standing up
    final isBentPosition = shoulderHeight > hipHeight + 20; // Bent over
    final isStandingPosition = shoulderHeight < hipHeight + 10; // Standing

    if (isBentPosition && !_isInExercisePosition) {
      _isInExercisePosition = true;
      setState(() {
        _feedback = 'Good starting position! Lift up straight.';
      });
    } else if (isStandingPosition && _isInExercisePosition) {
      _isInExercisePosition = false;
      setState(() {
        _repCount++;
        _feedback = 'Deadlift rep completed! Count: $_repCount';
      });
    }
  }

  void _analyzeGenericExercise(double shoulderHeight, double hipHeight, double kneeHeight) {
    // Generic exercise movement detection
    final hasMovement = (shoulderHeight - hipHeight).abs() > 15;
    
    if (hasMovement && !_isInExercisePosition) {
      _isInExercisePosition = true;
      setState(() {
        _feedback = 'Movement detected! Good form.';
      });
    } else if (!hasMovement && _isInExercisePosition) {
      _isInExercisePosition = false;
      setState(() {
        _repCount++;
        _feedback = 'Rep completed! Count: $_repCount';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.exerciseType} Tracker'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isCameraActive ? Icons.videocam_off : Icons.videocam),
            onPressed: () {
              if (!_isCameraInitialized) {
                _requestCameraPermission();
              } else if (_isCameraActive) {
                _stopCameraTracking();
              } else {
                _startCameraTracking();
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: Column(
          children: [
            // Camera Preview with Pose Overlay
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 2),
                  color: Colors.black.withOpacity(0.3),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _buildCameraPreview(),
                ),
              ),
            ),
            
            // Stats and Control Panel
            Expanded(
              flex: 1,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard('Reps', _repCount.toString(), Icons.fitness_center),
                        _buildStatCard('Form', _isCameraActive ? 'Tracking' : 'Ready', Icons.visibility),
                        _buildStatCard('Status', _isCameraActive ? 'Active' : 'Stopped', Icons.play_circle),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _feedback,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Tap camera icon to start',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Camera Preview
        CameraPreview(_cameraController!),
        
        // Pose Detection Overlay
        if (_isCameraActive && _poses.isNotEmpty)
          CustomPaint(
            painter: PoseOverlayPainter(_poses),
            size: Size.infinite,
          ),
        
        // Center guide circle
        if (_isCameraActive)
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _poses.isNotEmpty ? Colors.green : Colors.white.withOpacity(0.5),
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  _poses.isNotEmpty ? 'TRACKING' : 'POSITION\nYOURSELF',
                  style: TextStyle(
                    color: _poses.isNotEmpty ? Colors.green : Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector?.close();
    _pulseController.dispose();
    super.dispose();
  }
}

class PoseOverlayPainter extends CustomPainter {
  final List<Pose> poses;

  PoseOverlayPainter(this.poses);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 6.0
      ..style = PaintingStyle.fill;

    for (final pose in poses) {
      // Draw skeleton connections
      _drawLine(canvas, paint, pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, size);
      _drawLine(canvas, paint, pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, size);
      _drawLine(canvas, paint, pose, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip, size);
      _drawLine(canvas, paint, pose, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip, size);
      _drawLine(canvas, paint, pose, PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, size);
      _drawLine(canvas, paint, pose, PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, size);
      _drawLine(canvas, paint, pose, PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle, size);
      _drawLine(canvas, paint, pose, PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle, size);
      _drawLine(canvas, paint, pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, size);
      _drawLine(canvas, paint, pose, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow, size);
      _drawLine(canvas, paint, pose, PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, size);
      _drawLine(canvas, paint, pose, PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, size);

      // Draw key points
      for (final landmark in pose.landmarks.values) {
        if (landmark.likelihood > 0.5) { // Only draw confident detections
          canvas.drawCircle(
            Offset(landmark.x * size.width, landmark.y * size.height),
            3,
            pointPaint,
          );
        }
      }
    }
  }

  void _drawLine(Canvas canvas, Paint paint, Pose pose, PoseLandmarkType from, PoseLandmarkType to, Size size) {
    final fromLandmark = pose.landmarks[from];
    final toLandmark = pose.landmarks[to];

    if (fromLandmark != null && toLandmark != null && 
        fromLandmark.likelihood > 0.5 && toLandmark.likelihood > 0.5) {
      canvas.drawLine(
        Offset(fromLandmark.x * size.width, fromLandmark.y * size.height),
        Offset(toLandmark.x * size.width, toLandmark.y * size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
