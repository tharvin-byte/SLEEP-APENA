import 'package:flutter/material.dart';

import '../widgets/animated_logo.dart';
import '../widgets/glow_button.dart';
import '../widgets/report_card.dart';
import '../widgets/star_background.dart';
import '../widgets/stat_card.dart';
import 'monitoring_screen.dart';
import 'report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? monitoringStartTime;
  DateTime? monitoringEndTime;

  int apneaEvents = 0;

  String get _sleepTimeText {
    if (monitoringStartTime == null || monitoringEndTime == null) {
      return '0h 0m';
    }
    final duration = monitoringEndTime!.difference(monitoringStartTime!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  Future<void> _startMonitoring() async {
    setState(() {
      monitoringStartTime = DateTime.now();
      monitoringEndTime = null;
    });

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MonitoringScreen(),
      ),
    );

    if (!mounted) return;

    setState(() {
      monitoringEndTime = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF020617),
                  Color(0xFF020617),
                  Color(0xFF0A1A2F),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          const StarBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // 1) Animated Moon Logo
                  const AnimatedLogo(
                    assetPath: 'assets/images/moonlogo.png',
                    size: 120,
                  ),

                  const SizedBox(height: 20),

                  // 2) Sleep Time card (no navigation)
                  StatCard(
                    title: 'SLEEP TIME',
                    value: _sleepTimeText,
                    icon: Icons.bedtime,
                  ),

                  const SizedBox(height: 14),

                  // 3) Apnea Events card (no navigation)
                  StatCard(
                    title: 'APNEA EVENTS',
                    value: '$apneaEvents',
                    icon: Icons.warning_amber_rounded,
                  ),

                  const SizedBox(height: 14),

                  // 4) Report card (navigates)
                  ReportCard(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReportScreen(),
                        ),
                      );
                    },
                  ),

                  const Spacer(),

                  // 5) Start Monitoring button
                  GlowButton(
                    text: 'Start Monitoring',
                    onPressed: _startMonitoring,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

