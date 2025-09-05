import 'package:flutter/material.dart';
import 'simple_camera_exercise_tracker.dart';

class ExerciseSelectionPage extends StatelessWidget {
  const ExerciseSelectionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Exercise'),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildExerciseCard(
                context,
                'Deadlift',
                Icons.fitness_center,
                'Track your deadlift form with AI pose detection',
                Colors.red.shade400,
              ),
              _buildExerciseCard(
                context,
                'Squat',
                Icons.sports_gymnastics,
                'Perfect your squat technique with real-time feedback',
                Colors.blue.shade400,
              ),
              _buildExerciseCard(
                context,
                'Push-up',
                Icons.sports_handball,
                'Count push-ups and analyze your form',
                Colors.green.shade400,
              ),
              _buildExerciseCard(
                context,
                'Plank',
                Icons.timer,
                'Hold perfect plank position with AI guidance',
                Colors.orange.shade400,
              ),
              _buildExerciseCard(
                context,
                'Bicep Curl',
                Icons.sports_martial_arts,
                'Track bicep curl reps and form quality',
                Colors.purple.shade400,
              ),
              _buildExerciseCard(
                context,
                'Lunges',
                Icons.directions_walk,
                'Monitor lunge depth and balance',
                Colors.teal.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, String title, IconData icon, String description, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SimpleCameraExerciseTracker(exerciseType: title),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
