import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import 'otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController phoneController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // ── Header ──
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: AppDecorations.iconBadge(),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: AppColors.primaryLight,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Forgot Password',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                // ── Logo ──
                Center(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.12),
                            ),
                          ),
                          Image.asset('assets/images/sleeplogo.png',
                              height: 72),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'SleepGuard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 44),

                // ── Body label ──
                const Text(
                  'Reset Your Password',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter your phone number to receive a one-time code.',
                  style: TextStyle(color: AppColors.onMuted, fontSize: 13, height: 1.5),
                ),

                const SizedBox(height: 28),

                // ── Phone input ──
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: 'Phone number (e.g. 9876543210)',
                  ),
                ),

                const SizedBox(height: 28),

                // ── Send OTP button ──
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSending
                        ? null
                        : () async {
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

                            setState(() => _isSending = true);

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
                            } finally {
                              if (mounted) setState(() => _isSending = false);
                            }
                          },
                    child: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Send OTP'),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}