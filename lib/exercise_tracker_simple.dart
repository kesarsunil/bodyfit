import 'package:flutter/material.dart';

class ExerciseTracker extends StatefulWidget {
  final String exerciseType;
  
  const ExerciseTracker({Key? key, required this.exerciseType}) : super(key: key);

  @override
  State<ExerciseTracker> createState() => _ExerciseTrackerState();
}

class _ExerciseTrackerState extends State<ExerciseTracker> with TickerProviderStateMixin {
  int _repCount = 0;
  String _feedback = 'Position yourself and start exercising!';
  bool _isTracking = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(_pulseController);
  }

  void _startTracking() {
    setState(() {
      _isTracking = true;
      _feedback = 'Tracking started! Begin your ${widget.exerciseType}';
    });
    
    // Simulate rep counting for demo
    _simulateRepCounting();
  }

  void _simulateRepCounting() {
    Future.delayed(const Duration(seconds: 3), () {
      if (_isTracking) {
        setState(() {
          _repCount++;
          _feedback = 'Great form! Rep $_repCount completed';
        });
        _simulateRepCounting();
      }
    });
  }

  void _stopTracking() {
    setState(() {
      _isTracking = false;
      _feedback = 'Workout completed! Total reps: $_repCount';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.exerciseType} Tracker'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
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
            // Camera/Tracking Area Placeholder
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 2),
                  color: Colors.black.withOpacity(0.3),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _isTracking ? _pulseAnimation.value : 1.0,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: _isTracking ? Colors.red : Colors.white.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                  ),
                                  child: Icon(
                                    _isTracking ? Icons.visibility : Icons.videocam_off,
                                    size: 60,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _isTracking ? 'AI Tracking Active' : 'Camera Ready',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Pose tracking overlay simulation
                    if (_isTracking)
                      CustomPaint(
                        painter: PoseOverlayPainter(),
                        size: Size.infinite,
                      ),
                  ],
                ),
              ),
            ),
            
            // Stats and Feedback Panel
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
                        _buildStatCard('Form', _isTracking ? 'Good' : 'Ready', Icons.check_circle),
                        _buildStatCard('Time', _isTracking ? '${(_repCount * 3)}s' : '0:00', Icons.timer),
                      ],
                    ),
                    const SizedBox(height: 20),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isTracking ? _stopTracking : _startTracking,
                            icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
                            label: Text(_isTracking ? 'Stop Tracking' : 'Start Tracking'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isTracking ? Colors.red : Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}

class PoseOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 8.0
      ..style = PaintingStyle.fill;

    // Simulate pose detection points (like in your image)
    final points = [
      Offset(size.width * 0.3, size.height * 0.2), // Head
      Offset(size.width * 0.25, size.height * 0.35), // Left shoulder
      Offset(size.width * 0.35, size.height * 0.35), // Right shoulder
      Offset(size.width * 0.2, size.height * 0.5), // Left elbow
      Offset(size.width * 0.4, size.height * 0.5), // Right elbow
      Offset(size.width * 0.15, size.height * 0.65), // Left wrist
      Offset(size.width * 0.45, size.height * 0.65), // Right wrist
      Offset(size.width * 0.28, size.height * 0.7), // Left hip
      Offset(size.width * 0.32, size.height * 0.7), // Right hip
      Offset(size.width * 0.26, size.height * 0.85), // Left knee
      Offset(size.width * 0.34, size.height * 0.85), // Right knee
      Offset(size.width * 0.24, size.height * 0.95), // Left ankle
      Offset(size.width * 0.36, size.height * 0.95), // Right ankle
    ];

    // Draw skeleton connections
    final connections = [
      [0, 1], [0, 2], [1, 2], [1, 3], [2, 4], [3, 5], [4, 6],
      [1, 7], [2, 8], [7, 8], [7, 9], [8, 10], [9, 11], [10, 12]
    ];

    for (final connection in connections) {
      if (connection[0] < points.length && connection[1] < points.length) {
        canvas.drawLine(points[connection[0]], points[connection[1]], paint);
      }
    }

    // Draw points
    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
