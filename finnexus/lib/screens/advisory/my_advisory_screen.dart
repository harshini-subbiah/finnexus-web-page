import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../services/advisory_service.dart';
import '../../models/advisory_model.dart';
import 'advisor_sessions_screen.dart';

class MyAdvisoryScreen extends StatelessWidget {
  const MyAdvisoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16162A),
        title: const Text('My Advisory Sessions',
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Colors.white),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          TextButton.icon(
            onPressed: () =>
                context.go('/advisory-request'),
            icon: const Icon(Icons.add,
                color: Color(0xFF2196F3)),
            label: const Text('New Request',
                style: TextStyle(
                    color: Color(0xFF2196F3))),
          ),
        ],
      ),
      body: StreamBuilder<List<AdvisoryModel>>(
        stream:
            AdvisoryService().streamClientSessions(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF2196F3)));
          }
          final sessions = snapshot.data!;
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                const Icon(Icons.support_agent,
                    color: Colors.white24, size: 64),
                const SizedBox(height: 16),
                const Text(
                    'No advisory sessions yet',
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 16)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context
                      .go('/advisory-request'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF2196F3)),
                  child: const Text(
                      'Request a Session',
                      style: TextStyle(
                          color: Colors.white)),
                ),
              ]),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: sessions.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: 12),
            itemBuilder: (context, i) => SessionCard(
                session: sessions[i], isAdvisor: false),
          );
        },
      ),
    );
  }
}