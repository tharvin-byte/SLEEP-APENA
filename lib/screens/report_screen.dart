import 'dart:ui';

import 'package:flutter/material.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const reports = [
      _ReportItem(date: 'March 10', sleepTime: '7h 12m', apneaEvents: 0),
      _ReportItem(date: 'March 9', sleepTime: '6h 35m', apneaEvents: 1),
      _ReportItem(date: 'March 8', sleepTime: '5h 55m', apneaEvents: 3),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Reports'),
        backgroundColor: const Color(0xFF020617),
        foregroundColor: Colors.white,
      ),
      body: Container(
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Night',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 12),
                      _SummaryRow(
                        icon: Icons.bedtime,
                        label: 'Sleep Time',
                        value: '6h 42m',
                      ),
                      SizedBox(height: 8),
                      _SummaryRow(
                        icon: Icons.warning_amber_rounded,
                        label: 'Apnea Events',
                        value: '2',
                      ),
                      SizedBox(height: 8),
                      _SummaryRow(
                        icon: Icons.thumb_up_alt_outlined,
                        label: 'Sleep Quality',
                        value: 'Good',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: reports.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final r = reports[index];
                      final status = _statusForApnea(r.apneaEvents);
                      return _GlassCard(
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB)
                                    .withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF60A5FA)
                                      .withValues(alpha: 0.22),
                                ),
                              ),
                              child: Icon(
                                status.icon,
                                color: status.color,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.date,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Sleep Time: ${r.sleepTime}',
                                    style: const TextStyle(
                                      color: Color(0xFFCBD5E1),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Apnea Events: ${r.apneaEvents}',
                                    style: const TextStyle(
                                      color: Color(0xFFCBD5E1),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: const Color(0xFF93C5FD)
                                  .withValues(alpha: 0.9),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF93C5FD)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ReportItem {
  const _ReportItem({
    required this.date,
    required this.sleepTime,
    required this.apneaEvents,
  });

  final String date;
  final String sleepTime;
  final int apneaEvents;
}

class _Status {
  const _Status(this.icon, this.color);

  final IconData icon;
  final Color color;
}

_Status _statusForApnea(int apnea) {
  if (apnea == 0) {
    return const _Status(Icons.check_circle_outline, Color(0xFF22C55E));
  }
  if (apnea <= 1) {
    return const _Status(Icons.info_outline, Color(0xFF60A5FA));
  }
  if (apnea <= 2) {
    return const _Status(Icons.warning_amber_rounded, Color(0xFFF59E0B));
  }
  return const _Status(Icons.error_outline, Color(0xFFEF4444));
}

