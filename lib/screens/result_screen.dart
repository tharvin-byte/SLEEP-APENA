import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/sleep_analysis.dart';
import 'package:flutter_application_1/theme/app_theme.dart';

class ResultScreen extends StatefulWidget {
  final AnalysisResult result;

  const ResultScreen({super.key, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeAnim = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Color _riskColor(String risk) {
    switch (risk) {
      case 'Mild':
        return AppColors.riskMild;
      case 'Moderate':
        return AppColors.riskModerate;
      case 'Severe':
        return AppColors.riskSevere;
      default:
        return AppColors.riskNormal;
    }
  }

  IconData _riskIcon(String risk) {
    switch (risk) {
      case 'Mild':
        return Icons.warning_amber_rounded;
      case 'Moderate':
        return Icons.warning_rounded;
      case 'Severe':
        return Icons.dangerous_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final riskColor = _riskColor(r.risk);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF020617), Color(0xFF0A1628), Color(0xFF0D1F3C)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                children: [
                  _buildAppBar(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          _buildRiskBanner(r, riskColor),
                          const SizedBox(height: 20),
                          _buildStatsRow(r),
                          const SizedBox(height: 20),
                          _buildAdviceCard(r, riskColor),
                          if (r.eventsDetail.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildEventsList(r),
                          ],
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
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
              'Analysis Result',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildRiskBanner(AnalysisResult r, Color riskColor) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            riskColor.withValues(alpha: 0.18),
            riskColor.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: riskColor.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(_riskIcon(r.risk), color: riskColor, size: 48),
          const SizedBox(height: 14),
          Text(
            r.risk.toUpperCase(),
            style: TextStyle(
              color: riskColor,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            r.apnea
                ? 'Sleep apnea indicators detected'
                : 'No significant apnea detected',
            style: const TextStyle(
              color: AppColors.onSurface,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(AnalysisResult r) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            label: 'Total Events',
            value: '${r.events}',
            icon: Icons.format_list_numbered_rounded,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _statCard(
            label: 'Events / Hour',
            value: r.eventsPerHour.toStringAsFixed(1),
            icon: Icons.timer_outlined,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryLight, size: 24),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.onMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceCard(AnalysisResult r, Color riskColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgMid,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.medical_information_rounded,
                color: riskColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recommendation',
                  style: TextStyle(
                    color: AppColors.onMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  r.advice,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(AnalysisResult r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'DETECTED EVENTS',
            style: TextStyle(
              color: AppColors.onMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgMid,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: r.eventsDetail.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: AppColors.border.withValues(alpha: 0.4),
            ),
            itemBuilder: (context, index) {
              final ev = r.eventsDetail[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        '${_formatTime(ev.start)}  →  ${_formatTime(ev.end)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        '${ev.duration.toStringAsFixed(1)}s',
                        style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatTime(double seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toInt().toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}