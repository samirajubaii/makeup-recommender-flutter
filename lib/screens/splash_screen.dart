import 'dart:async';
import 'package:flutter/material.dart';
import 'home/home_screen.dart'; // adjust if needed

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // match your pink background
      body: Center(
        child: Image.asset(
          "assets/images/blush_and_buy.jpeg",
          width: 260,
        ),
      ),
    );
  }
}
