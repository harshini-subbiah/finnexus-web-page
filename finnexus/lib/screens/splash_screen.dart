import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../services/firestore_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final List<String> _adminEmails = [
    'admin@finnexus.com',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigate();
    });
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    final user = FirebaseAuth.instance.currentUser;
    if (!mounted) return;

    if (user == null) {
      context.go('/login');
      return;
    }

    if (_adminEmails.contains(user.email)) {
      context.go('/admin/dashboard');
      return;
    }

    final userData = await FirestoreService().getUser(user.uid);
    if (!mounted) return;

    if (userData == null) {
      context.go('/role');
    } else if (userData.kycStatus == 'approved') {
      context.go('/dashboard');
    } else {
      context.go('/pending');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D0D1A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('FinNexus',
                style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6C63FF),
                    letterSpacing: 3)),
            SizedBox(height: 16),
            CircularProgressIndicator(color: Color(0xFF6C63FF)),
          ],
        ),
      ),
    );
  }
}