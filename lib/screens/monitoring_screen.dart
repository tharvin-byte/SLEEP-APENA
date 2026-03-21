import 'package:flutter/material.dart';

class MonitoringScreen extends StatelessWidget {
  const MonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Monitoring'),
      ),
      body: const Center(
        child: Text(
          'Monitoring Screen',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
