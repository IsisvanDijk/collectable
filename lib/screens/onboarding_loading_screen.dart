import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingLoadingScreen extends StatefulWidget {
  const OnboardingLoadingScreen({super.key});

  @override
  State<OnboardingLoadingScreen> createState() => _OnboardingLoadingScreenState();
}

class _OnboardingLoadingScreenState extends State<OnboardingLoadingScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) context.go('/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          SvgPicture.asset(
            'assets/images/Background.svg',
            fit: BoxFit.cover,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Image.asset(
                'assets/images/Filled-shelf.png',
                width: MediaQuery.of(context).size.width * 0.55,
              ),
              SizedBox(height: screenHeight * 0.04),
              const Text(
                'COLLECTABLE',
                style: TextStyle(
                  color: Color(0xFF2C3E50),
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              SizedBox(height: screenHeight * 0.06),
              const SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  backgroundColor: Color(0xFFF7E7CE),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFFC3D4D7),
                  ),
                  strokeWidth: 6,
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ],
      ),
    );
  }
}