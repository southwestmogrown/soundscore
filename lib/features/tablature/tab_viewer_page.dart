import 'package:flutter/material.dart';

/// Full implementation in Phase 4 (tablature generator).
class TabViewerPage extends StatelessWidget {
  const TabViewerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tablature')),
      body: const Center(child: Text('Tab Viewer — Phase 4')),
    );
  }
}
