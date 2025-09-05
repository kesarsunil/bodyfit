import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class SimpleCameraExerciseTracker extends StatefulWidget {
  final String exerciseType;
  
  const SimpleCameraExerciseTracker({Key? key, required this.exerciseType}) : super(key: key);

  @override
  State<SimpleCameraExerciseTracker> createState() => _SimpleCameraExerciseTrackerState();
}

class _SimpleCameraExerciseTrackerState extends State<SimpleCameraExerciseTracker> with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCameraActive = false;
  bool _isTracking = false;
  int _repCount = 0;
  String _feedback = 'Click camera button to start tracking!';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _trackingController;
  late Animation<Color?> _trackingAnimation;
  Timer? _exerciseTimer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(_pulseController);

    _trackingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _trackingAnimation = ColorTween(
      begin: Colors.blue,
      end: Colors.green,
    ).animate(_trackingController);
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
        // Use front camera if available, otherwise use first available camera
        final cameraIndex = _cameras!.length > 1 ? 1 : 0;
        _cameraController = CameraController(
          _cameras![cameraIndex],
          ResolutionPreset.medium,
          enableAudio: false,
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
        _isTracking = true;
        _feedback = 'Tracking started! Perform your ${widget.exerciseType} exercises.';
        _seconds = 0;
      });
      
      // Start exercise timer
      _exerciseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _seconds++;
        });
      });

      // Simulate rep detection every 3-5 seconds
      _simulateRepDetection();
    }
  }

  void _simulateRepDetection() {
    Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_isTracking) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _repCount++;
        _feedback = _getExerciseFeedback();
      });
    });
  }

  String _getExerciseFeedback() {
    final exerciseType = widget.exerciseType.toLowerCase();
    final feedbacks = <String>[];
    
    if (exerciseType.contains('squat')) {
      feedbacks.addAll([
        'Great squat form! Keep your back straight.',
        'Good depth! Make sure knees track over toes.',
        'Excellent! Keep your core engaged.',
        'Perfect squat! Control the movement.',
      ]);
    } else if (exerciseType.contains('deadlift')) {
      feedbacks.addAll([
        'Strong deadlift! Keep the bar close to your body.',
        'Good form! Engage your lats and core.',
        'Excellent! Drive through your heels.',
        'Perfect lift! Maintain neutral spine.',
      ]);
    } else if (exerciseType.contains('push')) {
      feedbacks.addAll([
        'Great push-up! Keep your body in a straight line.',
        'Good form! Lower slowly and push up strong.',
        'Excellent! Engage your core throughout.',
        'Perfect form! Keep those elbows close.',
      ]);
    } else {
      feedbacks.addAll([
        'Great rep! Maintain good form.',
        'Excellent technique! Keep it up.',
        'Perfect! Stay focused on your breathing.',
        'Outstanding form! You\'re doing great.',
      ]);
    }
    
    return feedbacks[_repCount % feedbacks.length] + ' Rep $_repCount completed!';
  }

  void _stopCameraTracking() {
    setState(() {
      _isCameraActive = false;
      _isTracking = false;
      _feedback = 'Workout complete! Total reps: $_repCount in ${_formatTime(_seconds)}';
    });
    
    _exerciseTimer?.cancel();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
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
            // Camera Preview
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
                        _buildStatCard('Time', _formatTime(_seconds), Icons.timer),
                        _buildStatCard('Status', _isTracking ? 'Active' : 'Ready', Icons.play_circle),
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
        
        // Tracking Overlay
        if (_isTracking) ...[
          // Animated border
          AnimatedBuilder(
            animation: _trackingAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _trackingAnimation.value ?? Colors.blue,
                    width: 4,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              );
            },
          ),
          
          // Center tracking circle
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.green.withOpacity(0.8),
                  width: 3,
                ),
                color: Colors.green.withOpacity(0.1),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.visibility,
                      color: Colors.green,
                      size: 40,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'TRACKING',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        
        // Exercise instruction overlay
        if (_isCameraActive && !_isTracking)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Position yourself in the frame and start your exercise!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
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
    _pulseController.dispose();
    _trackingController.dispose();
    _exerciseTimer?.cancel();
    super.dispose();
  }
}
