import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _goToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _createAccount() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    if (password != confirmPassword) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        await user.sendEmailVerification();
        _showSuccess(
            'Account created! Please check your email for verification.');
        _goToLogin();
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists for this email.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        default:
          errorMessage = 'An error occurred: ${e.message}';
      }
      _showError(errorMessage);
    } catch (e) {
      _showError('An error occurred: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.danger, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: AppColors.success, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  Future<void> _signUpWithGoogle() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _goToHome();
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    bool? isObscured,
    VoidCallback? onToggle,
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscured ?? obscure,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        hintText: hint,
        suffixIcon: onToggle != null
            ? IconButton(
                icon: Icon(
                  (isObscured ?? false)
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.onMuted,
                  size: 20,
                ),
                onPressed: onToggle,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.primaryLight, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const LoginScreen()),
              );
            }
          },
        ),
      ),
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
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),

                // ── Logo ──
                Center(
                  child: Column(
                    children: [
                      Image.asset('assets/images/sleeplogo.png', height: 64),
                      const SizedBox(height: 12),
                      const Text(
                        'SleepGuard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'AI Sleep Apnea Monitoring',
                        style:
                            TextStyle(color: AppColors.onMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                const Text(
                  'Create Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Join SleepGuard to start monitoring your sleep.',
                  style: TextStyle(color: AppColors.onMuted, fontSize: 13),
                ),

                const SizedBox(height: 24),

                // ── Fields ──
                _buildField(
                  controller: _fullNameController,
                  hint: 'Full Name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _emailController,
                  hint: 'Email Address',
                  icon: Icons.email_outlined,
                  keyboard: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _passwordController,
                  hint: 'Password',
                  icon: Icons.lock_outline,
                  obscure: true,
                  isObscured: _obscurePassword,
                  onToggle: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _confirmPasswordController,
                  hint: 'Confirm Password',
                  icon: Icons.lock_outline,
                  obscure: true,
                  isObscured: _obscureConfirm,
                  onToggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),

                const SizedBox(height: 28),

                // ── Create account button ──
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createAccount,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Create Account'),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Divider ──
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                          color: AppColors.border.withValues(alpha: 0.6)),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'OR',
                        style: TextStyle(
                            color: AppColors.onMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                          color: AppColors.border.withValues(alpha: 0.6)),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Google signup ──
                SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: _signUpWithGoogle,
                    icon: const Icon(Icons.g_mobiledata_rounded, size: 22),
                    label: const Text('Sign up with Google'),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Already have account ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style:
                          TextStyle(color: AppColors.onMuted, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
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
