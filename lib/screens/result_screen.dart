import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Results'),
      ),
      body: const Center(
        child: Text(
          'Result Screen',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
