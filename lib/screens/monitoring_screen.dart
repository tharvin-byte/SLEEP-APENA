import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'package:flutter_application_1/services/sleep_analysis.dart';
import 'result_screen.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  bool _isLoading = false;
  String? _selectedFileName;
  String? _errorMessage;

  final _service = SleepAnalysisService();

  Future<void> _pickAndAnalyze() async {
    setState(() {
      _errorMessage = null;
      _selectedFileName = null;
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['wav'],
      withData: true, // 🔥 REQUIRED FOR WEB
    );

    if (result == null) return;

    Uint8List fileBytes = result.files.single.bytes!;
    String fileName = result.files.single.name;

    setState(() {
      _selectedFileName = fileName;
      _isLoading = true;
    });

    try {
      final analysisResult = await _service.analyze(
        bytes: fileBytes,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(result: analysisResult),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Sleep Apnea Monitor",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 20),

              if (_selectedFileName != null)
                Text(
                  _selectedFileName!,
                  style: const TextStyle(color: Colors.blueAccent),
                ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _isLoading ? null : _pickAndAnalyze,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Upload Audio (.wav)"),
              ),

              const SizedBox(height: 20),

              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
      ),
    );
  }
}