import 'package:flutter/material.dart';

class RallyCaptureScreen extends StatelessWidget {
  const RallyCaptureScreen({
    super.key,
    required this.matchId,
  });

  final String matchId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rally Capture'),
      ),
      body: Center(
        child: Text(
          'Rally capture coming soon\nmatchId: $matchId',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

