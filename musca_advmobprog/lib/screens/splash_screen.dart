import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/user_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  late final AnimationController _animationController;
  late final Animation<double> _logoFloat;
  late final Animation<double> _logoScale;
  late final Animation<double> _textOpacity;
  late final Animation<double> _ringScale;

  @override
  void initState() {
    super.initState();
    // ENHANCEMENT 1: Animate splash branding while persistent auth check runs.
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);

    _logoFloat = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _logoScale = Tween<double>(begin: 0.96, end: 1.03).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _textOpacity = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _ringScale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final loggedIn = await _userService.isLoggedIn();

    if (!mounted) {
      return;
    }

    if (loggedIn) {
      final userData = await _userService.getUserData();

      if (!mounted) {
        return;
      }

      Navigator.pushReplacementNamed(context, '/home', arguments: userData);
    } else {
      Navigator.pushReplacementNamed(context, '/signin');
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
      // ENHANCEMENT 1: Custom animated splash UI using NUBD Exchange image.
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF9FAFF), Color(0xFFF1F3FF), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, _) {
              return Column(
                children: [
                  const Spacer(flex: 4),
                  Transform.translate(
                    offset: Offset(0, _logoFloat.value),
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.scale(
                            scale: _ringScale.value,
                            child: Container(
                              width: 126.w,
                              height: 126.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(
                                    0xFFF2B92E,
                                  ).withValues(alpha: 0.35),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          Image.asset(
                            'assets/images/nubdexchange_logo (1).png',
                            width: 108.w,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 22.h),
                  Opacity(
                    opacity: _textOpacity.value,
                    child: Text(
                      'NUBD Exchange',
                      style: TextStyle(
                        color: const Color(0xFF222533),
                        fontSize: 34.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Opacity(
                    opacity: _textOpacity.value,
                    child: Text(
                      'Preparing your personalized storefront...',
                      style: TextStyle(
                        color: const Color(0xFF60657A),
                        fontSize: 13.sp,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  const Spacer(flex: 5),
                  SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.6,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFFDBE2D),
                      ),
                    ),
                  ),
                  SizedBox(height: 34.h),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
