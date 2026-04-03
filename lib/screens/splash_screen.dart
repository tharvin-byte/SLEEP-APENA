import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final AnimationController _pulseCtrl;

  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _slideAnim;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    // Main logo animation
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _fadeAnim = CurvedAnimation(
      parent: _logoCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _scaleAnim = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _slideAnim = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    // Subtle pulse on the outer glow ring
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Navigate after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFF0D1F3C),
              Color(0xFF0A1628),
              Color(0xFF020617),
            ],
          ),
        ),
        child: Stack(
          children: [
            // ── Ambient top-left blobs ──
            Positioned(
              top: -80,
              left: -60,
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Opacity(
                  opacity: _pulseAnim.value * 0.25,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              right: -50,
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Opacity(
                  opacity: (1.0 - _pulseAnim.value) * 0.2,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryLight.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ),

            // ── Main centered content ──
            Center(
              child: AnimatedBuilder(
                animation: _logoCtrl,
                builder: (_, __) {
                  return FadeTransition(
                    opacity: _fadeAnim,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnim.value),
                      child: ScaleTransition(
                        scale: _scaleAnim,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ── Glow rings + logo icon ──
                            AnimatedBuilder(
                              animation: _pulseAnim,
                              builder: (_, __) {
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Outermost pulse ring
                                    Opacity(
                                      opacity: _pulseAnim.value * 0.18,
                                      child: Container(
                                        width: 160,
                                        height: 160,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    // Middle ring
                                    Container(
                                      width: 124,
                                      height: 124,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.primary
                                            .withValues(alpha: 0.15),
                                        border: Border.all(
                                          color: AppColors.primaryLight
                                              .withValues(alpha: 0.25),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary
                                                .withValues(
                                                    alpha: _pulseAnim.value *
                                                        0.55),
                                            blurRadius: 48,
                                            spreadRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Inner filled circle
                                    Container(
                                      width: 86,
                                      height: 86,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.primary
                                                .withValues(alpha: 0.9),
                                            AppColors.primary
                                                .withValues(alpha: 0.5),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                    ),
                                    // Logo image
                                    SizedBox(
                                      width: 56,
                                      height: 56,
                                      child: Image.asset(
                                        'assets/images/sleeplogo.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 32),

                            // ── App name ──
                            Text(
                              'SleepGuard',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),

                            const SizedBox(height: 10),

                            // ── Tagline pill ──
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: AppColors.primaryLight
                                      .withValues(alpha: 0.35),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    color: AppColors.primaryLight,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'AI Sleep Apnea Monitoring',
                                    style: GoogleFonts.inter(
                                      color: AppColors.primaryLight,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Bottom loading indicator ──
            Positioned(
              bottom: 52,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryLight,
                        backgroundColor:
                            AppColors.primaryLight.withValues(alpha: 0.12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Initializing AI Engine...',
                      style: GoogleFonts.inter(
                        color: AppColors.onMuted,
                        fontSize: 12.5,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}