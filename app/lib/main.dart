import 'package:flutter/material.dart';

import 'features/match_setup/match_setup_flow.dart';

void main() {
  runApp(const VolleyballStatsApp());
}

class VolleyballStatsApp extends StatelessWidget {
  const VolleyballStatsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Volleyball Stats',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const MatchSetupFlow(),
    );
  }
}
