import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  // =========================
  // WARNA TEMA SURVEY
  // =========================
  static const Color primary = Color(0xFF8FA28A);
  static const Color primaryDark = Color(0xFF687864);
  static const Color primaryLight = Color(0xFFB7C3B2);
  // static const Color background = Color(0xFFF3F5F0);
  // static const Color textPrimary = Color(0xFF283127);

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();

    _startSplash();
  }

  // =========================
  // SPLASH TIMER
  // =========================
  Future<void> _startSplash() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');

    if (token != null && token.isNotEmpty) {
      context.go('/dashboard');
    } else {
      context.go('/');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        // =========================
        // BACKGROUND GRADIENT
        // =========================
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryDark,
              primary,
              primaryLight,
            ],
          ),
        ),

        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: child,
                ),
              );
            },

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // =========================
                // LOGO SURVEY
                // =========================
                Container(
                  width: 145,
                  height: 145,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EEE5),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(
                        Icons.assignment_rounded,
                        size: 62,
                        color: primaryDark,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // =========================
                // JUDUL
                // =========================
                const Text(
                  'SURVEY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 5,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Aplikasi Survey Lapangan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Data survey lebih mudah dan terorganisir',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 60),

                // =========================
                // LOADING
                // =========================
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Memuat aplikasi...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
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