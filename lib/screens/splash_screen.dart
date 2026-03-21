import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  double waveSize = 120;

  @override
  void initState() {
    super.initState();

    // Wave animation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      setState(() {
        waveSize = 260;
      });
    });

    // Navigate to Login Screen safely
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // Wave Animation + Logo
              Stack(
                alignment: Alignment.center,
                children: [

                  AnimatedContainer(
                    duration: const Duration(seconds: 2),
                    width: waveSize,
                    height: waveSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withOpacity(0.2),
                    ),
                  ),

                  AnimatedContainer(
                    duration: const Duration(seconds: 3),
                    width: waveSize - 60,
                    height: waveSize - 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withOpacity(0.15),
                    ),
                  ),

                  // Logo
                  Image.asset(
                    "assets/images/sleeplogo.png",
                    height: 160,
                  ),
                ],
              ),

              const SizedBox(height: 40),

              const Text(
                "SleepGuard",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "AI Sleep Apnea Monitoring",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),

              const SizedBox(height: 40),

              const CircularProgressIndicator(
                color: Colors.white,
              ),

              const SizedBox(height: 15),

              const Text(
                "Initializing AI Monitoring...",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}