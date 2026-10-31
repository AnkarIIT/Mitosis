import 'package:flutter/material.dart';

class ExamTimer extends StatelessWidget {
  final Duration duration;

  const ExamTimer({required this.duration, super.key});

  @override
  Widget build(BuildContext context) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    return Text(
      '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
      style: TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        fontFamily: 'monospace',
      ),
    );
  }
}
