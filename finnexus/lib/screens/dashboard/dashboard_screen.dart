import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: FutureBuilder<UserModel?>(
        future: FirestoreService().getUser(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
          }
          final user = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text('FinNexus',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                          color: Color(0xFF6C63FF), letterSpacing: 2)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () async {
                      await AuthService().signOut();
                      if (context.mounted) context.go('/login');
                    },
                    icon: const Icon(Icons.logout, color: Colors.white38, size: 18),
                    label: const Text('Sign Out', style: TextStyle(color: Colors.white38)),
                  ),
                ]),
                const SizedBox(height: 32),

                // Welcome card
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF3A3580)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Welcome, ${user.businessName}',
                          style: const TextStyle(fontSize: 22,
                              fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 6),
                      Text('Role: ${user.role.toUpperCase()}',
                          style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text('Customer ID: ${user.customerId ?? "—"}',
                          style: const TextStyle(color: Colors.white,
                              fontFamily: 'monospace', fontSize: 15,
                              fontWeight: FontWeight.w600)),
                    ]),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.greenAccent),
                      ),
                      child: const Row(children: [
                        Icon(Icons.verified, color: Colors.greenAccent, size: 16),
                        SizedBox(width: 6),
                        Text('KYC Verified', style: TextStyle(color: Colors.greenAccent)),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 32),

                const Text('Financial Services',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white70)),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _ModuleCard(
                      title: 'Apply for Loan',
                      icon: '💳',
                      color: const Color(0xFFFF8C42),
                      onTap: () => context.go('/loan-apply'),
                    ),
                    _ModuleCard(
                      title: 'My Loans',
                      icon: '📋',
                      color: const Color(0xFFFF8C42),
                      onTap: () => context.go('/loans'),
                    ),
                    _ModuleCard(
                      title: 'Insurance',
                      icon: '🛡️',
                      color: const Color(0xFFE07B39),
                      onTap: () => context.go('/insurance'),
                    ),
                    _ModuleCard(
                      title: 'Apply Insurance',
                      icon: '📝',
                      color: const Color(0xFFE07B39),
                      onTap: () => context.go('/insurance-apply'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String title;
  final String icon;
  final Color color;
  final VoidCallback onTap;
  const _ModuleCard({required this.title, required this.icon,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF16162A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(icon, style: const TextStyle(fontSize: 30)),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: color,
              fontWeight: FontWeight.w600, fontSize: 14)),
        ]),
      ),
    );
  }
}