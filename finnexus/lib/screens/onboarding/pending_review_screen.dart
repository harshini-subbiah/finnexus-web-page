import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../widgets/workflow_stepper.dart';

class PendingReviewScreen extends StatelessWidget {
  const PendingReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: StreamBuilder<UserModel?>(
        stream: FirestoreService().streamUser(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF6C63FF)));
          }

          final user = snapshot.data;
          final status = user?.kycStatus ?? 'pending';

          // Approved
          if (status == 'approved') {
            return Center(
              child: Container(
                width: 520,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: const Color(0xFF16162A),
                  borderRadius:
                      BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.greenAccent
                          .withOpacity(0.4)),
                ),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  const WorkflowStepper(
                    steps: Workflows.onboarding,
                    currentStep: 5,
                    color: Colors.greenAccent,
                  ),
                  const SizedBox(height: 24),
                  const Icon(
                      Icons.check_circle_outline,
                      color: Colors.greenAccent,
                      size: 64),
                  const SizedBox(height: 20),
                  const Text('Account Approved!',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 12),
                  Text(
                      'Welcome to FinNexus, ${user?.businessName ?? ''}!\nYour Customer ID is ${user?.customerId ?? ''}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white60,
                          height: 1.6)),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          context.go('/dashboard'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.greenAccent.shade700,
                        padding:
                            const EdgeInsets.symmetric(
                                vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    10)),
                      ),
                      child: const Text(
                          'Go to Dashboard',
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.white)),
                    ),
                  ),
                ]),
              ),
            );
          }

          // Rejected
          if (status == 'rejected') {
            return Center(
              child: Container(
                width: 520,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: const Color(0xFF16162A),
                  borderRadius:
                      BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.redAccent
                          .withOpacity(0.4)),
                ),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  const WorkflowStepper(
                    steps: Workflows.onboarding,
                    currentStep: 3,
                    color: Color(0xFF6C63FF),
                  ),
                  const SizedBox(height: 24),
                  const Icon(Icons.cancel_outlined,
                      color: Colors.redAccent, size: 64),
                  const SizedBox(height: 20),
                  const Text('Application Rejected',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 12),
                  if (user?.rejectionReason != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent
                            .withOpacity(0.08),
                        borderRadius:
                            BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.redAccent
                                .withOpacity(0.3)),
                      ),
                      child: Text(
                          'Reason: ${user!.rejectionReason}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white70,
                              height: 1.4)),
                    )
                  else
                    const Text(
                        'Your documents were rejected. Please resubmit with corrected documents.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white60,
                            height: 1.5)),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          context.go('/kyc'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF6C63FF),
                        padding:
                            const EdgeInsets.symmetric(
                                vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    10)),
                      ),
                      icon: const Icon(
                          Icons.upload_file,
                          color: Colors.white),
                      label: const Text(
                          'Resubmit Documents',
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () async {
                      await AuthService().signOut();
                      if (context.mounted)
                        context.go('/login');
                    },
                    child: const Text('Sign Out',
                        style: TextStyle(
                            color: Colors.white38)),
                  ),
                ]),
              ),
            );
          }

          // Pending
          return Center(
            child: Container(
              width: 520,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: const Color(0xFF16162A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF6C63FF)
                        .withOpacity(0.3)),
              ),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                const WorkflowStepper(
                  steps: Workflows.onboarding,
                  currentStep: 4,
                  color: Color(0xFF6C63FF),
                ),
                const SizedBox(height: 24),
                const Icon(
                    Icons.hourglass_top_rounded,
                    size: 64,
                    color: Color(0xFF6C63FF)),
                const SizedBox(height: 20),
                Text(
                    user?.isResubmission == true
                        ? 'Documents Resubmitted'
                        : 'Under Review',
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 12),
                Text(
                    user?.isResubmission == true
                        ? 'Your updated documents are in the admin\'s review queue.'
                        : 'Your KYC documents are being reviewed by our team. You will be notified once approved.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white60,
                        height: 1.5)),
                const SizedBox(height: 28),
                const LinearProgressIndicator(
                  backgroundColor: Color(0xFF2D2D4E),
                  color: Color(0xFF6C63FF),
                ),
                const SizedBox(height: 28),
                TextButton(
                  onPressed: () async {
                    await AuthService().signOut();
                    if (context.mounted)
                      context.go('/login');
                  },
                  child: const Text('Sign Out',
                      style: TextStyle(
                          color: Colors.white38)),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}