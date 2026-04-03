import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Color Tokens ────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  static const bgDeep    = Color(0xFF020617);   // darkest bg
  static const bgMid     = Color(0xFF0A1628);   // surface / card bg
  static const bgCard    = Color(0xFF0D1F3C);   // secondary card
  static const bgInput   = Color(0xFF0F172A);   // input fill

  static const primary      = Color(0xFF2563EB); // brand blue
  static const primaryLight = Color(0xFF60A5FA); // accent / icons
  static const primaryGlow  = Color(0xFF93C5FD); // soft glow

  static const onPrimary  = Colors.white;
  static const onSurface  = Color(0xFFCBD5E1);  // body text
  static const onMuted    = Color(0xFF64748B);   // hint / placeholder
  static const border     = Color(0xFF1E3A5F);   // card border

  static const danger  = Color(0xFFEF4444);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);

  // Risk colours (result screen)
  static const riskNormal   = Color(0xFF22C55E);
  static const riskMild     = Color(0xFFFFB300);
  static const riskModerate = Color(0xFFFF6D00);
  static const riskSevere   = Color(0xFFD50000);
}

// ─── Theme ───────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark();
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppColors.onSurface,
      displayColor: Colors.white,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bgDeep,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: AppColors.bgMid,
        error: AppColors.danger,
      ),
      textTheme: textTheme,

      // ── Input fields ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgInput,
        hintStyle: GoogleFonts.inter(
          color: AppColors.onMuted,
          fontSize: 14,
        ),
        prefixIconColor: AppColors.primaryLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryLight),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),

      // ── Elevated buttons ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
          elevation: 0,
        ),
      ),

      // ── Outlined buttons ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          minimumSize: const Size(double.infinity, 54),
          side: const BorderSide(color: AppColors.primaryLight, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgDeep,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.primaryLight),
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),

      // ── SnackBar ──
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.bgCard,
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Divider ──
      dividerTheme: DividerThemeData(
        color: AppColors.border.withValues(alpha: 0.5),
        thickness: 1,
      ),
    );
  }
}

// ─── Shared Decorations ──────────────────────────────────────────────────────
class AppDecorations {
  AppDecorations._();

  static BoxDecoration get pageGradient => const BoxDecoration(
    gradient: LinearGradient(
      colors: [AppColors.bgDeep, Color(0xFF0A1628)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  static BoxDecoration glassCard({double radius = 18}) => BoxDecoration(
    color: AppColors.bgMid,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.08),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static BoxDecoration iconBadge({Color? color}) => BoxDecoration(
    color: (color ?? AppColors.primary).withValues(alpha: 0.15),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: (color ?? AppColors.primaryLight).withValues(alpha: 0.25),
    ),
  );
}
