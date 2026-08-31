import 'package:flutter/material.dart';

/// Topic progress bar widget
class TopicProgressBar extends StatelessWidget {
  final String topic;
  final double progress;
  final int questions;
  final int mastered;

  const TopicProgressBar({
    Key? key,
    required this.topic,
    required this.progress,
    required this.questions,
    required this.mastered,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = progress >= 0.8 
        ? Colors.green 
        : progress >= 0.6 
            ? Colors.blue 
            : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                topic,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                '$mastered/$questions',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}