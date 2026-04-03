import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
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
      MaterialPageRoute(builder: (_) => const MonitoringScreen()),
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
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF020617), Color(0xFF0A1628)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          const StarBackground(),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // ── Header ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Good Night 🌙',
                            style: TextStyle(
                              color: AppColors.onMuted,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'SleepGuard',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              shadows: [
                                Shadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Animated moon icon
                      const AnimatedLogo(
                        assetPath: 'assets/images/moonlogo.png',
                        size: 52,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── Status indicator ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: AppColors.success, size: 8),
                        SizedBox(width: 8),
                        Text(
                          'AI Engine Ready — Awaiting Analysis',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Stats ──
                  StatCard(
                    title: 'SLEEP TIME',
                    value: _sleepTimeText,
                    icon: Icons.bedtime_outlined,
                  ),

                  const SizedBox(height: 14),

                  StatCard(
                    title: 'APNEA EVENTS',
                    value: '$apneaEvents',
                    icon: Icons.monitor_heart_outlined,
                    subtitle: apneaEvents == 0 ? 'No events detected' : 'Events detected',
                  ),

                  const SizedBox(height: 14),

                  ReportCard(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReportScreen()),
                      );
                    },
                  ),

                  const Spacer(),

                  // ── CTA ──
                  Column(
                    children: [
                      const Text(
                        'Upload a .wav recording to begin analysis',
                        style: TextStyle(
                          color: AppColors.onMuted,
                          fontSize: 12,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GlowButton(
                        text: 'START MONITORING',
                        icon: Icons.sensors_rounded,
                        onPressed: _startMonitoring,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
