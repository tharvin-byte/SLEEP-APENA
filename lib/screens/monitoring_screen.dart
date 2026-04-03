import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'package:flutter_application_1/services/sleep_analysis.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
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

    // Web needs bytes; mobile can use file path
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['wav'],
      withData: kIsWeb,   // bytes only on web
    );

    if (result == null) return;

    final pickedFile = result.files.single;
    final String fileName = pickedFile.name;

    setState(() {
      _selectedFileName = fileName;
      _isLoading = true;
    });

    try {
      AnalysisResult analysisResult;

      if (kIsWeb) {
        // ✅ Web — use bytes
        final Uint8List bytes = pickedFile.bytes!;
        analysisResult = await _service.analyze(bytes: bytes);
      } else {
        // ✅ Mobile — use file path
        final String filePath = pickedFile.path!;
        analysisResult = await _service.analyze(file: File(filePath));
      }

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF020617), Color(0xFF0A1628)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── AppBar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.primaryLight, size: 20),
                    ),
                    const Expanded(
                      child: Text(
                        'Sleep Analysis',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),

                      // ── Title block ──
                      const Icon(
                        Icons.mic_none_rounded,
                        color: AppColors.primaryLight,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Upload Sleep Audio',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Select a .wav audio recording from your device\nto begin AI-powered apnea analysis.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.onMuted,
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ── Upload zone ──
                      GestureDetector(
                        onTap: _isLoading ? null : _pickAndAnalyze,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          decoration: BoxDecoration(
                            color: _selectedFileName != null
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : AppColors.bgMid,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _selectedFileName != null
                                  ? AppColors.primaryLight.withValues(alpha: 0.6)
                                  : AppColors.border,
                              width: 1.5,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: _isLoading
                              ? Column(
                                  children: [
                                    SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: AppColors.primaryLight,
                                        backgroundColor: AppColors.primaryLight
                                            .withValues(alpha: 0.15),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Analyzing audio...',
                                      style: TextStyle(
                                        color: AppColors.onSurface,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'This may take a moment',
                                      style: TextStyle(
                                        color: AppColors.onMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: AppDecorations.iconBadge(),
                                      child: const Icon(
                                        Icons.upload_file_rounded,
                                        color: AppColors.primaryLight,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _selectedFileName != null
                                          ? 'File Selected'
                                          : 'Tap to Select Audio File',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    if (_selectedFileName != null) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: AppColors.primaryLight
                                                .withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: Text(
                                          '🎵  $_selectedFileName',
                                          style: const TextStyle(
                                            color: AppColors.primaryLight,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ] else ...[
                                      const Text(
                                        'Only .wav files are supported',
                                        style: TextStyle(
                                          color: AppColors.onMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Error banner ──
                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppColors.danger, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: AppColors.danger,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const Spacer(),

                      // ── CTA ──
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _pickAndAnalyze,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.upload_rounded, size: 20),
                          label: Text(
                              _isLoading ? 'Analyzing...' : 'Select & Analyze'),
                        ),
                      ),

                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}