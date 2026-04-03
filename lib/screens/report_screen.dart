import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
                        'Sleep Reports',
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),

                      // ── Last Night summary card ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: AppDecorations.glassCard(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: AppDecorations.iconBadge(),
                                  child: const Icon(
                                    Icons.nights_stay_rounded,
                                    color: AppColors.primaryLight,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Last Night',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            const _SummaryRow(
                              icon: Icons.bedtime_outlined,
                              label: 'Sleep Time',
                              value: '6h 42m',
                            ),
                            const SizedBox(height: 12),
                            const _SummaryRow(
                              icon: Icons.monitor_heart_outlined,
                              label: 'Apnea Events',
                              value: '2',
                            ),
                            const SizedBox(height: 12),
                            const _SummaryRow(
                              icon: Icons.thumb_up_alt_outlined,
                              label: 'Sleep Quality',
                              value: 'Good',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Section label ──
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'HISTORY',
                          style: TextStyle(
                            color: AppColors.onMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── History list ──
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reports.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final r = reports[index];
                          final status = _statusForApnea(r.apneaEvents);
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: AppDecorations.glassCard(),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: status.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          status.color.withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Icon(
                                    status.icon,
                                    color: status.color,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.date,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '🛏  ${r.sleepTime}   •   ⚠ ${r.apneaEvents} events',
                                        style: const TextStyle(
                                          color: AppColors.onSurface,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: AppColors.primaryLight.withValues(alpha: 0.7),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),
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
        Icon(icon, color: AppColors.primaryLight, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w500,
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
  if (apnea == 0) return const _Status(Icons.check_circle_outline, AppColors.riskNormal);
  if (apnea <= 1) return const _Status(Icons.info_outline, AppColors.primaryLight);
  if (apnea <= 2) return const _Status(Icons.warning_amber_rounded, AppColors.riskMild);
  return const _Status(Icons.error_outline, AppColors.riskSevere);
}
