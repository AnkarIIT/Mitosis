import 'package:flutter/material.dart';

/// Student statistics overview card
class StudentStatsCard extends StatelessWidget {
  final int targetScore;
  final int currentScore;
  final int studyHours;
  final int daysStudied;

  const StudentStatsCard({
    Key? key,
    required this.targetScore,
    required this.currentScore,
    required this.studyHours,
    required this.daysStudied,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentage = (currentScore / targetScore) * 100;
    final progressColor = percentage >= 80 
        ? Colors.green 
        : percentage >= 60 
            ? Colors.orange 
            : Colors.red;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Progress',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Score Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$currentScore / $targetScore',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'NEET Score',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: currentScore / targetScore,
                          strokeWidth: 8,
                          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${percentage.toInt()}%',
                              style: TextStyle(
                                color: progressColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              'ready',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                                fontSize: 10,
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
            
            const SizedBox(height: 20),
            
            // Study Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  icon: Icons.timer,
                  value: studyHours.toString(),
                  label: 'Study Hours',
                ),
                _buildStatItem(
                  context,
                  icon: Icons.calendar_today,
                  value: daysStudied.toString(),
                  label: 'Days',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.blue.shade300),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}