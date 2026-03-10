import 'package:flutter/material.dart';

/// Home screen. Hosts the real-time audio capture UI.
/// Full implementation in Phase 3 (audio capture pipeline).
class RecordingPage extends StatelessWidget {
  const RecordingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SoundScore')),
      body: const Center(child: Text('Recording — Phase 3')),
    );
  }
}
