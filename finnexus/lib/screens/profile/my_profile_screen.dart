import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/audit_service.dart';
import 'dart:async';

class MyProfileScreen extends StatefulWidget {
  final UserModel user;
  const MyProfileScreen({super.key, required this.user});
  @override
  State<MyProfileScreen> createState() =>
      _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  bool _checkingDeletion = false;
  Timer? _countdownTimer;
  Duration? _remaining;

  @override
  void initState() {
    super.initState();
    if (widget.user.deletionRequested &&
        widget.user.deletionScheduledAt != null) {
      _startCountdown();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    final scheduledAt = DateTime.parse(
        widget.user.deletionScheduledAt!);
    _updateRemaining(scheduledAt);
    _countdownTimer = Timer.periodic(
        const Duration(seconds: 1), (_) {
      _updateRemaining(scheduledAt);
    });
  }

  void _updateRemaining(DateTime scheduledAt) {
    final remaining = scheduledAt.difference(DateTime.now());
    if (remaining.isNegative) {
      _countdownTimer?.cancel();
      _performActualDeletion();
      return;
    }
    if (mounted) {
      setState(() => _remaining = remaining);
    }
  }

  Future<void> _performActualDeletion() async {
    await AuditService().log(
        'account_deleted',
        'Self-deletion timer expired, account permanently removed',
        targetUid: widget.user.uid);
    await FirestoreService()
        .adminDeleteUser(widget.user.uid);
    try {
      await FirebaseAuth.instance.currentUser
          ?.delete();
    } catch (_) {}
    if (mounted) context.go('/login');
  }

  Future<void> _requestDeletion() async {
    setState(() => _checkingDeletion = true);
    final hasPending = await FirestoreService()
        .hasPendingPayments(widget.user.uid);
    setState(() => _checkingDeletion = false);

    if (hasPending) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF16162A),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Row(children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.redAccent),
              SizedBox(width: 10),
              Text('Cannot Delete Account',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ]),
            content: const Text(
                'You have pending loans, active insurance policies, or undelivered orders. Please resolve these before deleting your account.',
                style: TextStyle(
                    color: Colors.white70, height: 1.4)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK',
                    style:
                        TextStyle(color: Color(0xFF6C63FF))),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16162A),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account?',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        content: const Text(
            'Your account will be permanently deleted in 5 minutes. You can cancel this anytime before then. This action cannot be undone after the timer expires.',
            style: TextStyle(
                color: Colors.white70, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirestoreService()
                  .requestSelfDeletion(widget.user.uid);
              await AuditService().log(
                  'account_deletion_requested',
                  'User initiated self-deletion, scheduled in 5 minutes',
                  targetUid: widget.user.uid);
              if (mounted) {
                setState(() => _startCountdown());
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            child: const Text('Yes, Delete My Account',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelDeletion() async {
    _countdownTimer?.cancel();
    await FirestoreService()
        .cancelSelfDeletion(widget.user.uid);
    await AuditService().log(
        'account_deletion_cancelled',
        'User cancelled scheduled self-deletion',
        targetUid: widget.user.uid);
    setState(() => _remaining = null);
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: SingleChildScrollView(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          const Text('My Profile',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 4),
          const Text(
              'View and manage your account details',
              style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 24),

          // Deletion countdown banner
          if (_remaining != null) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color:
                        Colors.redAccent.withOpacity(0.5)),
              ),
              child: Row(children: [
                const Icon(Icons.timer_outlined,
                    color: Colors.redAccent),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                    Text(
                        'Your account will be deleted in ${_remaining!.inMinutes}:${(_remaining!.inSeconds % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold)),
                    const Text(
                        'You can cancel this anytime before the timer ends.',
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12)),
                  ]),
                ),
                OutlinedButton(
                  onPressed: _cancelDeletion,
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Colors.greenAccent)),
                  child: const Text('Cancel Deletion',
                      style: TextStyle(
                          color: Colors.greenAccent)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
          ],

          // Ban banner
          if (u.isBanned) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color:
                        Colors.redAccent.withOpacity(0.5)),
              ),
              child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                const Row(children: [
                  Icon(Icons.block,
                      color: Colors.redAccent),
                  SizedBox(width: 10),
                  Text('Account Suspended',
                      style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold)),
                ]),
                if (u.banReason != null) ...[
                  const SizedBox(height: 8),
                  Text('Reason: ${u.banReason}',
                      style: const TextStyle(
                          color: Colors.white70)),
                ],
              ]),
            ),
            const SizedBox(height: 20),
          ],

          // Profile card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF16162A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFF2D2D4E)),
            ),
            child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
              Row(children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor:
                      const Color(0xFF6C63FF)
                          .withOpacity(0.15),
                  child: Text(
                      u.businessName.isNotEmpty
                          ? u.businessName[0]
                              .toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Color(0xFF6C63FF),
                          fontSize: 28,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                    Text(u.businessName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20)),
                    Text(u.email,
                        style: const TextStyle(
                            color: Colors.white54)),
                    if (u.customerId != null)
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 4),
                        child: Text(
                            'ID: ${u.customerId}',
                            style: const TextStyle(
                                color: Color(0xFF6C63FF),
                                fontFamily: 'monospace',
                                fontSize: 12)),
                      ),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF)
                        .withOpacity(0.15),
                    borderRadius:
                        BorderRadius.circular(6),
                  ),
                  child: Text(u.role.toUpperCase(),
                      style: const TextStyle(
                          color: Color(0xFF6C63FF),
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ]),
              const SizedBox(height: 24),
              const Divider(color: Color(0xFF2D2D4E)),
              const SizedBox(height: 16),
              _row('Business Address', u.address),
              _row('GSTIN', u.gstin),
              _row('PAN', u.pan),
              _row('Bank Account', u.bankAccount),
              _row('KYC Status',
                  u.kycStatus.toUpperCase()),
              _row(
                  'Member Since',
                  u.createdAt
                      .toLocal()
                      .toString()
                      .split(' ')[0]),
            ]),
          ),

          const SizedBox(height: 24),

          // Danger zone
          if (!u.deletionRequested) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF16162A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color:
                        Colors.redAccent.withOpacity(0.3)),
              ),
              child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                const Text('Danger Zone',
                    style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 8),
                const Text(
                    'Deleting your account is permanent. If you have any pending loans, active insurance, or undelivered orders, deletion will be blocked until they are resolved. You will have 5 minutes to cancel after requesting.',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        height: 1.4)),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _checkingDeletion
                      ? null
                      : _requestDeletion,
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Colors.redAccent)),
                  icon: _checkingDeletion
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child:
                              CircularProgressIndicator(
                                  color: Colors.redAccent,
                                  strokeWidth: 2))
                      : const Icon(Icons.delete_outline,
                          color: Colors.redAccent,
                          size: 18),
                  label: Text(
                      _checkingDeletion
                          ? 'Checking pending payments...'
                          : 'Delete My Account',
                      style: const TextStyle(
                          color: Colors.redAccent)),
                ),
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        SizedBox(
            width: 160,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 13))),
        Expanded(
            child: Text(value.isEmpty ? '—' : value,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13))),
      ]),
    );
  }
}