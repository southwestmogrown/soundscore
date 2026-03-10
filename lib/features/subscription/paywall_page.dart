import 'package:flutter/material.dart';

/// Full implementation in Phase 6 (monetization).
class PaywallPage extends StatelessWidget {
  const PaywallPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Go Pro')),
      body: const Center(child: Text('Paywall — Phase 6')),
    );
  }
}
