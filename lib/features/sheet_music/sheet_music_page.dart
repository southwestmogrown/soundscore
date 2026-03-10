import 'package:flutter/material.dart';

/// Full implementation in Phase 5 (sheet music renderer).
class SheetMusicPage extends StatelessWidget {
  const SheetMusicPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sheet Music')),
      body: const Center(child: Text('Sheet Music — Phase 5')),
    );
  }
}
