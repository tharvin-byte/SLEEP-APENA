import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🔹 Background gradient
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

          // 🔥 FIXED LAYERING
          SafeArea(
            child: Stack(
              children: [
                // Grid background (NON-CLICKABLE)
                IgnorePointer(
                  ignoring: true,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: GridPainter(),
                  ),
                ),

                // 🔹 MAIN UI (ON TOP → CLICKABLE)
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Forgot Password',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        Center(
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/images/sleeplogo.png',
                                height: 80,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'SLEEPGUARD',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  letterSpacing: 4,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'AI Sleep Apnea Monitoring',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        const Text(
                          'Reset Your Password',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),

                        const Text(
                          'Enter your phone number to receive an OTP',
                          style: TextStyle(color: Color(0xFF9CA3AF)),
                        ),

                        const SizedBox(height: 28),

                        // 📱 Phone input
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.phone, color: Colors.blueAccent),
                            hintText: 'Enter your phone number',
                            hintStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // 🔥 Send OTP Button
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: () async {
                              print("BUTTON CLICKED");

                              String phone = phoneController.text.trim();

                              if (!phone.startsWith('+91')) {
                                phone = '+91$phone';
                              }

                              if (phone.length != 13) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Enter valid 10-digit number'),
                                  ),
                                );
                                return;
                              }

                              print("PHONE: $phone");
                              print("SENDING OTP");

                              try {
                                await FirebaseAuth.instance.verifyPhoneNumber(
                                  phoneNumber: phone,

                                  verificationCompleted: (credential) async {
                                    print("AUTO VERIFIED");
                                    await FirebaseAuth.instance
                                        .signInWithCredential(credential);
                                  },

                                  verificationFailed: (e) {
                                    print("ERROR: ${e.code}");
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(e.message ?? 'Error'),
                                      ),
                                    );
                                  },

                                  codeSent: (verificationId, resendToken) {
                                    print("OTP SENT");

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => OtpScreen(
                                          verificationId: verificationId,
                                          phoneNumber: phone,
                                        ),
                                      ),
                                    );
                                  },

                                  codeAutoRetrievalTimeout: (_) {
                                    print("TIMEOUT");
                                  },
                                );
                              } catch (e) {
                                print("EXCEPTION: $e");
                              }
                            },
                            child: const Text("Send OTP"),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 🔹 Grid Painter
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.05)
      ..strokeWidth = 1;

    const spacing = 40.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}