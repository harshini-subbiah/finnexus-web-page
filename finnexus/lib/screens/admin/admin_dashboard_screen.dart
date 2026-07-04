import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/loan_service.dart';
import '../../services/insurance_service.dart';
import '../../models/user_model.dart';
import '../../models/loan_model.dart';
import '../../models/insurance_model.dart';
import '../../widgets/document_viewer.dart';
import '../../models/shipment_model.dart';
import '../../services/order_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/audit_service.dart';
import '../../models/audit_log_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen> {
  int _selectedNav = 0;

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Overview'),
    _NavItem(icon: Icons.hourglass_top_rounded, label: 'KYC Review'),
    _NavItem(icon: Icons.people_rounded, label: 'All Users'),
    _NavItem(icon: Icons.account_balance_wallet, label: 'Loans'),
    _NavItem(icon: Icons.shield_outlined, label: 'Insurance'),
    _NavItem(icon: Icons.local_shipping_outlined, label: 'Shipments'),
    _NavItem(icon: Icons.history_rounded, label: 'Audit Log'),
    _NavItem(icon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 220,
            color: const Color(0xFF12121E),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text('FinNexus',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight:
                                  FontWeight.bold,
                              color: Color(0xFFFF6B35),
                              letterSpacing: 2)),
                      Container(
                        margin: const EdgeInsets.only(
                            top: 4),
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35)
                              .withOpacity(0.15),
                          borderRadius:
                              BorderRadius.circular(4),
                        ),
                        child: const Text('ADMIN PANEL',
                            style: TextStyle(
                                color:
                                    Color(0xFFFF6B35),
                                fontSize: 9,
                                fontWeight:
                                    FontWeight.bold,
                                letterSpacing: 2)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                ...List.generate(_navItems.length, (i) {
                  final item = _navItems[i];
                  final isSelected = _selectedNav == i;
                  return GestureDetector(
                    onTap: () => setState(
                        () => _selectedNav = i),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFF6B35)
                                .withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius:
                            BorderRadius.circular(10),
                        border: isSelected
                            ? Border.all(
                                color: const Color(
                                        0xFFFF6B35)
                                    .withOpacity(0.4))
                            : null,
                      ),
                      child: Row(children: [
                        Icon(item.icon,
                            color: isSelected
                                ? const Color(0xFFFF6B35)
                                : Colors.white38,
                            size: 20),
                        const SizedBox(width: 12),
                        Text(item.label,
                            style: TextStyle(
                                color: isSelected
                                    ? const Color(
                                        0xFFFF6B35)
                                    : Colors.white54,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight
                                        .normal)),
                      ]),
                    ),
                  );
                }),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: () async {
                      await AuthService().signOut();
                      if (mounted) context.go('/login');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent
                            .withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.redAccent
                                .withOpacity(0.3)),
                      ),
                      child: const Row(children: [
                        Icon(Icons.logout,
                            color: Colors.redAccent,
                            size: 18),
                        SizedBox(width: 10),
                        Text('Sign Out',
                            style: TextStyle(
                                color: Colors.redAccent)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: [
              const _OverviewPage(),
              const _KycReviewPage(),
              const _AllUsersPage(),
              const _AdminLoansPage(),
              const _AdminInsurancePage(),
              const _AdminShipmentsPage(),
              const _AdminAuditLogPage(),
              const _SettingsPage(),
            ][_selectedNav],
          ),
        ],
      ),
    );
  }
}

// ─── OVERVIEW PAGE ────────────────────────────────
class _OverviewPage extends StatelessWidget {
  const _OverviewPage();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFFFF6B35)));
        }
        final docs = snapshot.data!.docs;
        final total = docs.length;
        final pending = docs
            .where((d) =>
                (d.data() as Map)['kycStatus'] ==
                'pending')
            .length;
        final approved = docs
            .where((d) =>
                (d.data() as Map)['kycStatus'] ==
                'approved')
            .length;
        final rejected = docs
            .where((d) =>
                (d.data() as Map)['kycStatus'] ==
                'rejected')
            .length;

        final roles = <String, int>{};
        for (final d in docs) {
          final role =
              (d.data() as Map)['role'] ?? 'unknown';
          roles[role] = (roles[role] ?? 0) + 1;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
            const Text('Overview',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 4),
            const Text('Platform summary at a glance',
                style:
                    TextStyle(color: Colors.white54)),
            const SizedBox(height: 32),
            Wrap(spacing: 16, runSpacing: 16, children: [
              _StatCard(
                  label: 'Total Users',
                  count: total,
                  color: const Color(0xFF6C63FF),
                  icon: Icons.people_rounded),
              _StatCard(
                  label: 'Pending Review',
                  count: pending,
                  color: const Color(0xFFFFB347),
                  icon: Icons.hourglass_top_rounded),
              _StatCard(
                  label: 'Approved',
                  count: approved,
                  color: Colors.greenAccent,
                  icon: Icons.check_circle_rounded),
              _StatCard(
                  label: 'Rejected',
                  count: rejected,
                  color: Colors.redAccent,
                  icon: Icons.cancel_rounded),
            ]),
            const SizedBox(height: 32),
            const Text('Users by Role',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: roles.entries.map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16162A),
                    borderRadius:
                        BorderRadius.circular(12),
                    border: Border.all(
                        color:
                            const Color(0xFF2D2D4E)),
                  ),
                  child: Column(children: [
                    Text('${e.value}',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6C63FF))),
                    Text(e.key.toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12)),
                  ]),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            const Text('Recent Registrations',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
            const SizedBox(height: 16),
            ...docs.take(5).map((d) {
              final data =
                  d.data() as Map<String, dynamic>;
              return Container(
                margin:
                    const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF16162A),
                  borderRadius:
                      BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF2D2D4E)),
                ),
                child: Row(children: [
                  const Icon(Icons.person_outline,
                      color: Colors.white38, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(
                          data['businessName'] ??
                              data['email'] ??
                              '',
                          style: const TextStyle(
                              color: Colors.white))),
                  _StatusBadge(
                      status: data['kycStatus'] ??
                          'pending'),
                ]),
              );
            }),
          ]),
        );
      },
    );
  }
}

// ─── KYC REVIEW PAGE ──────────────────────────────
class _KycReviewPage extends StatefulWidget {
  const _KycReviewPage();
  @override
  State<_KycReviewPage> createState() =>
      _KycReviewPageState();
}

class _KycReviewPageState extends State<_KycReviewPage> {
  String _filter = 'pending';
  String? _processingUid;
  final _rejectReasonCtrl = TextEditingController();

  Stream<List<UserModel>> _getUsers() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('kycStatus', isEqualTo: _filter)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => UserModel.fromMap(d.data()))
            .toList());
  }

  Future<void> _approve(UserModel user) async {
    setState(() => _processingUid = user.uid);
    try {
      await FirestoreService()
          .updateKycStatus(user.uid, 'approved');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(
          content: Text(
              '${user.businessName} approved successfully!'),
          backgroundColor: Colors.greenAccent.shade700,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      setState(() => _processingUid = null);
    }
  }

  Future<void> _showRejectDialog(UserModel user) async {
    _rejectReasonCtrl.clear();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16162A),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Application',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Business: ${user.businessName}',
                style: const TextStyle(
                    color: Colors.white70)),
            const SizedBox(height: 16),
            const Text('Reason:',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _rejectReasonCtrl,
              maxLines: 3,
              style:
                  const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText:
                    'e.g. PAN card image is blurry',
                hintStyle: const TextStyle(
                    color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF0D0D1A),
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: Color(0xFF2D2D4E))),
                enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: Color(0xFF2D2D4E))),
                focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: Colors.redAccent)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: Colors.white38))),
          ElevatedButton(
            onPressed: () async {
              if (_rejectReasonCtrl.text.trim().isEmpty)
                return;
              Navigator.pop(ctx);
              setState(
                  () => _processingUid = user.uid);
              await FirestoreService().updateKycStatus(
                  user.uid, 'rejected',
                  reason:
                      _rejectReasonCtrl.text.trim());
              setState(() => _processingUid = null);
              if (mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(
                  content:
                      Text('Application rejected.'),
                  backgroundColor: Colors.redAccent,
                ));
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            child: const Text('Reject',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        const Text('KYC Review',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 4),
        const Text(
            'Review and approve user identity documents',
            style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 24),
        Row(
          children: ['pending', 'approved', 'rejected']
              .map((f) {
            final isActive = _filter == f;
            final color = f == 'pending'
                ? const Color(0xFFFFB347)
                : f == 'approved'
                    ? Colors.greenAccent
                    : Colors.redAccent;
            return GestureDetector(
              onTap: () =>
                  setState(() => _filter = f),
              child: Container(
                margin:
                    const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive
                      ? color.withOpacity(0.15)
                      : const Color(0xFF16162A),
                  borderRadius:
                      BorderRadius.circular(8),
                  border: Border.all(
                      color: isActive
                          ? color
                          : const Color(0xFF2D2D4E)),
                ),
                child: Text(f.toUpperCase(),
                    style: TextStyle(
                        color: isActive
                            ? color
                            : Colors.white38,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<List<UserModel>>(
            stream: _getUsers(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFFF6B35)));
              }
              final users = snapshot.data!;
              if (users.isEmpty) {
                return Center(
                  child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                    const Icon(Icons.inbox_rounded,
                        color: Colors.white24,
                        size: 64),
                    const SizedBox(height: 16),
                    Text('No $_filter applications',
                        style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 16)),
                  ]),
                );
              }
              return ListView.separated(
                itemCount: users.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final user = users[i];
                  return _KycCard(
                    user: user,
                    filter: _filter,
                    isProcessing:
                        _processingUid == user.uid,
                    onApprove: () => _approve(user),
                    onReject: () =>
                        _showRejectDialog(user),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ─── ALL USERS PAGE ───────────────────────────────
class _AllUsersPage extends StatefulWidget {
  const _AllUsersPage();
  @override
  State<_AllUsersPage> createState() =>
      _AllUsersPageState();
}

class _AllUsersPageState extends State<_AllUsersPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        const Text('All Users',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 4),
        const Text('Complete list of registered users',
            style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 24),
        TextField(
          onChanged: (v) =>
              setState(() => _search = v.toLowerCase()),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText:
                'Search by name, email, PAN or GSTIN...',
            hintStyle:
                const TextStyle(color: Colors.white30),
            prefixIcon: const Icon(Icons.search,
                color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF16162A),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: Color(0xFF2D2D4E))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: Color(0xFF2D2D4E))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: Color(0xFFFF6B35))),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFFF6B35)));
              }
              var docs = snapshot.data!.docs
                  .map((d) => UserModel.fromMap(
                      d.data()
                          as Map<String, dynamic>))
                  .toList();
              if (_search.isNotEmpty) {
                docs = docs
                    .where((u) =>
                        u.businessName
                            .toLowerCase()
                            .contains(_search) ||
                        u.email
                            .toLowerCase()
                            .contains(_search) ||
                        u.pan
                            .toLowerCase()
                            .contains(_search) ||
                        u.gstin
                            .toLowerCase()
                            .contains(_search))
                    .toList();
              }
              if (docs.isEmpty) {
                return const Center(
                    child: Text('No users found',
                        style: TextStyle(
                            color: Colors.white38)));
              }
              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final u = docs[i];
                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16162A),
                      borderRadius:
                          BorderRadius.circular(10),
                      border: Border.all(
                          color: u.isBanned
                              ? Colors.redAccent
                                  .withOpacity(0.4)
                              : const Color(0xFF2D2D4E)),
                    ),
                    child: Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                        Row(children: [
                          Text(u.businessName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight:
                                      FontWeight.w600)),
                          const SizedBox(width: 8),
                          _RoleBadge(role: u.role),
                          if (u.isBanned) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.redAccent
                                    .withOpacity(0.15),
                                borderRadius:
                                    BorderRadius.circular(
                                        4),
                              ),
                              child: const Text('BANNED',
                                  style: TextStyle(
                                      color:
                                          Colors.redAccent,
                                      fontSize: 10,
                                      fontWeight:
                                          FontWeight.bold)),
                            ),
                          ],
                          if (u.deletionRequested) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(
                                        0xFFFFB347)
                                    .withOpacity(0.15),
                                borderRadius:
                                    BorderRadius.circular(
                                        4),
                              ),
                              child: const Text(
                                  'DELETING',
                                  style: TextStyle(
                                      color: Color(
                                          0xFFFFB347),
                                      fontSize: 10,
                                      fontWeight:
                                          FontWeight.bold)),
                            ),
                          ],
                        ]),
                        const SizedBox(height: 4),
                        Text(u.email,
                            style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12)),
                        if (u.customerId != null)
                          Text('ID: ${u.customerId}',
                              style: const TextStyle(
                                  color: Color(0xFF6C63FF),
                                  fontSize: 12,
                                  fontFamily: 'monospace')),
                      ])),
                      Column(children: [
                        _StatusBadge(status: u.kycStatus),
                        const SizedBox(height: 8),
                        Row(children: [
                          if (!u.isBanned)
                            IconButton(
                              icon: const Icon(
                                  Icons.block,
                                  color: Colors.redAccent,
                                  size: 18),
                              tooltip: 'Ban user',
                              onPressed: () =>
                                  _showBanDialog(
                                      context, u),
                            )
                          else
                            IconButton(
                              icon: const Icon(
                                  Icons
                                      .check_circle_outline,
                                  color: Colors.greenAccent,
                                  size: 18),
                              tooltip: 'Unban user',
                              onPressed: () async {
                                await FirestoreService()
                                    .unbanUser(u.uid);
                                await AuditService().log(
                                    'user_unbanned',
                                    'Admin unbanned ${u.businessName}',
                                    targetUid: u.uid);
                              },
                            ),
                          IconButton(
                            icon: const Icon(
                                Icons.delete_forever,
                                color: Colors.redAccent,
                                size: 18),
                            tooltip: 'Delete user',
                            onPressed: () =>
                                _showDeleteDialog(
                                    context, u),
                          ),
                        ]),
                      ]),
                    ]),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
  Future<void> _showBanDialog(
      BuildContext context, UserModel u) async {
    final reasonCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16162A),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Ban User',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Business: ${u.businessName}',
                style:
                    const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Reason for banning...',
                hintStyle:
                    const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF0D0D1A),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: Color(0xFF2D2D4E))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () async {
              if (reasonCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final admin =
                  FirebaseAuth.instance.currentUser;
              await FirestoreService().banUser(
                  u.uid,
                  reasonCtrl.text.trim(),
                  admin?.email ?? 'admin');
              await AuditService().log(
                  'user_banned',
                  'Admin banned ${u.businessName}: ${reasonCtrl.text.trim()}',
                  targetUid: u.uid);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            child: const Text('Ban User',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog(
      BuildContext context, UserModel u) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16162A),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete User Permanently?',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        content: Text(
            'This will permanently delete ${u.businessName}\'s account and profile data. This cannot be undone.',
            style: const TextStyle(
                color: Colors.white70, height: 1.4)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuditService().log(
                  'user_deleted_by_admin',
                  'Admin permanently deleted ${u.businessName}',
                  targetUid: u.uid);
              await FirestoreService()
                  .adminDeleteUser(u.uid);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            child: const Text('Delete Permanently',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── ADMIN LOANS PAGE ─────────────────────────────
class _AdminLoansPage extends StatefulWidget {
  const _AdminLoansPage();
  @override
  State<_AdminLoansPage> createState() =>
      _AdminLoansPageState();
}

class _AdminLoansPageState
    extends State<_AdminLoansPage> {
  String _filter = 'pending';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        const Text('Loan Applications',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 4),
        const Text(
            'Overview of all loans across the platform',
            style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 24),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              'pending',
              'approved',
              'active',
              'closed',
              'rejected'
            ].map((f) {
              final isActive = _filter == f;
              return GestureDetector(
                onTap: () =>
                    setState(() => _filter = f),
                child: Container(
                  margin: const EdgeInsets.only(
                      right: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFFF8C42)
                            .withOpacity(0.15)
                        : const Color(0xFF16162A),
                    borderRadius:
                        BorderRadius.circular(8),
                    border: Border.all(
                        color: isActive
                            ? const Color(0xFFFF8C42)
                            : const Color(0xFF2D2D4E)),
                  ),
                  child: Text(f.toUpperCase(),
                      style: TextStyle(
                          color: isActive
                              ? const Color(0xFFFF8C42)
                              : Colors.white38,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w600)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<List<LoanModel>>(
            stream: LoanService()
                .streamAllLoans(status: _filter),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFFF8C42)));
              }
              final loans = snapshot.data!;
              if (loans.isEmpty) {
                return Center(
                    child: Text('No $_filter loans',
                        style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 16)));
              }
              return ListView.separated(
                itemCount: loans.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final loan = loans[i];
                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16162A),
                      borderRadius:
                          BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              const Color(0xFF2D2D4E)),
                    ),
                    child: Row(children: [
                      Expanded(
                        child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                          Text(loan.businessName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight:
                                      FontWeight.w600,
                                  fontSize: 15)),
                          Text(
                              '₹${loan.amount.toStringAsFixed(0)} • ${loan.tenureMonths} months • ${loan.loanType}',
                              style: const TextStyle(
                                  color:
                                      Colors.white70)),
                          Text(
                              'Lender: ${loan.lenderName}',
                              style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13)),
                          Text(
                              'Customer ID: ${loan.customerId}',
                              style: const TextStyle(
                                  color:
                                      Color(0xFF6C63FF),
                                  fontSize: 12,
                                  fontFamily:
                                      'monospace')),
                          if (loan.interestRate != null)
                            Text(
                                'Rate: ${loan.interestRate}% p.a.',
                                style: const TextStyle(
                                    color: Colors
                                        .greenAccent,
                                    fontSize: 12)),
                        ]),
                      ),
                      _StatusBadge(
                          status: loan.status),
                    ]),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ─── ADMIN INSURANCE PAGE ─────────────────────────
class _AdminInsurancePage extends StatefulWidget {
  const _AdminInsurancePage();
  @override
  State<_AdminInsurancePage> createState() =>
      _AdminInsurancePageState();
}

class _AdminInsurancePageState
    extends State<_AdminInsurancePage> {
  String _filter = 'pending';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        const Text('Insurance Policies',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 4),
        const Text(
            'Overview of all insurance policies across the platform',
            style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 24),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              'pending',
              'active',
              'claim_filed',
              'settled',
              'closed'
            ].map((f) {
              final isActive = _filter == f;
              return GestureDetector(
                onTap: () =>
                    setState(() => _filter = f),
                child: Container(
                  margin: const EdgeInsets.only(
                      right: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFE07B39)
                            .withOpacity(0.15)
                        : const Color(0xFF16162A),
                    borderRadius:
                        BorderRadius.circular(8),
                    border: Border.all(
                        color: isActive
                            ? const Color(0xFFE07B39)
                            : const Color(0xFF2D2D4E)),
                  ),
                  child: Text(
                      f
                          .replaceAll('_', ' ')
                          .toUpperCase(),
                      style: TextStyle(
                          color: isActive
                              ? const Color(0xFFE07B39)
                              : Colors.white38,
                          fontSize: 11,
                          fontWeight:
                              FontWeight.w600)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<List<InsuranceModel>>(
            stream: InsuranceService()
                .streamAllPolicies(status: _filter),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFE07B39)));
              }
              final policies = snapshot.data!;
              if (policies.isEmpty) {
                return Center(
                    child: Text(
                        'No $_filter policies',
                        style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 16)));
              }
              return ListView.separated(
                itemCount: policies.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final p = policies[i];
                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16162A),
                      borderRadius:
                          BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              const Color(0xFF2D2D4E)),
                    ),
                    child: Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                        Text(
                            '${p.type == 'trade_credit' ? '🤝' : '🚚'} ${p.businessName}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight:
                                    FontWeight.w600,
                                fontSize: 15)),
                        Text(
                            'Type: ${p.type.replaceAll('_', ' ')}  •  Coverage: ₹${p.coverageAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13)),
                        Text(
                            'Insurer: ${p.insurerName}',
                            style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12)),
                        Text(
                            'Customer ID: ${p.customerId}',
                            style: const TextStyle(
                                color:
                                    Color(0xFF6C63FF),
                                fontSize: 12,
                                fontFamily: 'monospace')),
                      ])),
                      _StatusBadge(status: p.status),
                    ]),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ─── SETTINGS PAGE ────────────────────────────────
class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        const Text('Settings',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 4),
        const Text('Platform configuration',
            style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 32),
        _SettingsTile(
          icon: Icons.admin_panel_settings_rounded,
          title: 'Admin Emails',
          subtitle: 'admin@finnexus.com',
          color: const Color(0xFFFF6B35),
        ),
        _SettingsTile(
          icon: Icons.storage_rounded,
          title: 'Database',
          subtitle: 'Cloud Firestore — Active',
          color: const Color(0xFF6C63FF),
        ),
        _SettingsTile(
          icon: Icons.lock_rounded,
          title: 'Authentication',
          subtitle: 'Firebase Auth — Email/Password',
          color: Colors.greenAccent,
        ),
        _SettingsTile(
          icon: Icons.folder_rounded,
          title: 'Document Storage',
          subtitle: 'Firestore Base64 — Active',
          color: const Color(0xFFFFB347),
        ),
      ]),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _SettingsTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF2D2D4E)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600)),
          Text(subtitle,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 13)),
        ]),
      ]),
    );
  }
}

// ─── KYC CARD WITH DOCUMENT VIEWER ───────────────
class _KycCard extends StatefulWidget {
  final UserModel user;
  final String filter;
  final bool isProcessing;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  const _KycCard({
    required this.user,
    required this.filter,
    required this.isProcessing,
    required this.onApprove,
    required this.onReject,
  });
  @override
  State<_KycCard> createState() => _KycCardState();
}

class _KycCardState extends State<_KycCard> {
  bool _showDocs = false;
  Map<String, dynamic>? _docs;
  bool _loadingDocs = false;

  Future<void> _loadDocs() async {
    setState(() => _loadingDocs = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('kyc_documents')
          .where('uid', isEqualTo: widget.user.uid)
          .get();

      final combined = <String, dynamic>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final docKey = data['docKey'] as String? ??
            doc.id.replaceFirst(
                '${widget.user.uid}_', '');
        combined[docKey] = data;
      }
      setState(() {
        _docs = combined;
        _loadingDocs = false;
        _showDocs = true;
      });
    } catch (e) {
      setState(() {
        _docs = {};
        _loadingDocs = false;
        _showDocs = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF2D2D4E)),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(children: [
          Expanded(
            child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
              Row(children: [
                Text(widget.user.businessName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16)),
                const SizedBox(width: 10),
                _RoleBadge(role: widget.user.role),
                if (widget.user.isResubmission) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB347)
                          .withOpacity(0.15),
                      borderRadius:
                          BorderRadius.circular(4),
                    ),
                    child: const Text('RESUBMITTED',
                        style: TextStyle(
                            color: Color(0xFFFFB347),
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ]),
              const SizedBox(height: 6),
              Text(widget.user.email,
                  style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13)),
              const SizedBox(height: 6),
              Row(children: [
                _InfoChip(
                    label: 'PAN',
                    value: widget.user.pan),
                const SizedBox(width: 8),
                _InfoChip(
                    label: 'GSTIN',
                    value: widget.user.gstin),
              ]),
              if (widget.user.customerId != null) ...[
                const SizedBox(height: 6),
                Text(
                    'Customer ID: ${widget.user.customerId}',
                    style: const TextStyle(
                        color: Color(0xFF6C63FF),
                        fontSize: 13,
                        fontFamily: 'monospace')),
              ],
              if (widget.user.rejectionReason != null) ...[
                const SizedBox(height: 4),
                Text(
                    'Reason: ${widget.user.rejectionReason}',
                    style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12)),
              ],
            ]),
          ),
          if (widget.isProcessing)
            const CircularProgressIndicator(
                color: Color(0xFFFF6B35),
                strokeWidth: 2)
          else if (widget.filter == 'pending')
            Column(children: [
              ElevatedButton(
                onPressed: widget.onApprove,
                style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.greenAccent.shade700,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(8))),
                child: const Text('Approve',
                    style:
                        TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: widget.onReject,
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(8))),
                child: const Text('Reject',
                    style: TextStyle(
                        color: Colors.redAccent)),
              ),
            ]),
        ]),

        const SizedBox(height: 12),
        const Divider(color: Color(0xFF2D2D4E)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            if (!_showDocs) {
              _loadDocs();
            } else {
              setState(() => _showDocs = false);
            }
          },
          child: Row(children: [
            Icon(
              _showDocs
                  ? Icons.keyboard_arrow_up
                  : Icons.folder_open_outlined,
              color: const Color(0xFF6C63FF),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              _showDocs
                  ? 'Hide KYC Documents'
                  : 'View KYC Documents',
              style: const TextStyle(
                  color: Color(0xFF6C63FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
            if (_loadingDocs) ...[
              const SizedBox(width: 12),
              const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      color: Color(0xFF6C63FF),
                      strokeWidth: 2)),
            ],
          ]),
        ),

        if (_showDocs && _docs != null) ...[
          const SizedBox(height: 16),
          _docs!.isEmpty
              ? const Text(
                  'No documents found. User may need to re-upload.',
                  style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12))
              : DocumentViewer(documents: _docs!),
        ],
      ]),
    );
  }
}
// ─── SHARED WIDGETS ───────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  const _StatCard(
      {required this.label,
      required this.count,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 12),
        Text('$count',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color)),
        Text(label,
            style: const TextStyle(
                color: Colors.white54, fontSize: 12)),
      ]),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem({required this.icon, required this.label});
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color:
            const Color(0xFF6C63FF).withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: const Color(0xFF6C63FF)
                .withOpacity(0.4)),
      ),
      child: Text(role.toUpperCase(),
          style: const TextStyle(
              color: Color(0xFF6C63FF),
              fontSize: 10,
              fontWeight: FontWeight.bold)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color =
        status == 'approved' || status == 'active'
            ? Colors.greenAccent
            : status == 'rejected'
                ? Colors.redAccent
                : status == 'claim_filed'
                    ? const Color(0xFFFF8C42)
                    : status == 'settled'
                        ? const Color(0xFF6C63FF)
                        : const Color(0xFFFFB347);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border:
            Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
          status.replaceAll('_', ' ').toUpperCase(),
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip(
      {required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: const Color(0xFF2D2D4E)),
      ),
      child: Text('$label: $value',
          style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontFamily: 'monospace')),
    );
  }
}
// ─── ADMIN SHIPMENTS PAGE ─────────────────────────
class _AdminShipmentsPage extends StatefulWidget {
  const _AdminShipmentsPage();
  @override
  State<_AdminShipmentsPage> createState() =>
      _AdminShipmentsPageState();
}

class _AdminShipmentsPageState
    extends State<_AdminShipmentsPage> {
  String _filter = 'created';
  String? _assigning;

  Stream<List<ShipmentModel>> _stream() {
    if (_filter == 'all') {
      return OrderService().streamAllShipments();
    }
    return FirebaseFirestore.instance
        .collection('shipments')
        .where('status', isEqualTo: _filter)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ShipmentModel.fromMap(d.data()))
            .toList());
  }

  Future<void> _showAssignDialog(
      ShipmentModel shipment) async {
    // Load logistics partners
    final partners = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'logistics')
        .where('kycStatus', isEqualTo: 'approved')
        .get();

    if (!mounted) return;

    if (partners.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'No approved logistics partners available.'),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    String? selectedUid;
    String? selectedName;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF16162A),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('Assign Logistics Partner',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 400,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              Text(
                  'Shipment: ${shipment.id.substring(0, 8)}',
                  style: const TextStyle(
                      color: Colors.white70)),
              Text(
                  'Goods: ${shipment.goodsDescription}',
                  style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13)),
              Text('To: ${shipment.deliveryAddress}',
                  style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13)),
              const SizedBox(height: 16),
              const Text('Select Partner:',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13)),
              const SizedBox(height: 8),
              ...partners.docs.map((doc) {
                final data = doc.data();
                final uid = doc.id;
                final name =
                    data['businessName'] ?? 'Unknown';
                final sel = selectedUid == uid;
                return GestureDetector(
                  onTap: () => setDialogState(() {
                    selectedUid = uid;
                    selectedName = name;
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(
                        bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel
                          ? const Color(0xFF9C27B0)
                              .withOpacity(0.15)
                          : const Color(0xFF0D0D1A),
                      borderRadius:
                          BorderRadius.circular(8),
                      border: Border.all(
                          color: sel
                              ? const Color(0xFF9C27B0)
                              : const Color(0xFF2D2D4E)),
                    ),
                    child: Row(children: [
                      const Text('🚚',
                          style:
                              TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Text(name,
                          style: TextStyle(
                              color: sel
                                  ? Colors.white
                                  : Colors.white70,
                              fontWeight: sel
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                      const Spacer(),
                      if (sel)
                        const Icon(Icons.check_circle,
                            color: Color(0xFF9C27B0),
                            size: 16),
                    ]),
                  ),
                );
              }),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(
                        color: Colors.white38))),
            ElevatedButton(
              onPressed: selectedUid == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      setState(
                          () => _assigning = shipment.id);
                      await OrderService()
                          .assignLogisticsPartner(
                              shipment.id,
                              selectedUid!,
                              selectedName!);
                      setState(() => _assigning = null);
                      if (mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text(
                              'Partner assigned successfully!'),
                          backgroundColor:
                              Colors.greenAccent,
                        ));
                      }
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF9C27B0)),
              child: const Text('Assign',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        const Text('Shipment Management',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 4),
        const Text(
            'Assign logistics partners to shipments',
            style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 24),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              'created',
              'partner_assigned',
              'pickup_confirmed',
              'in_transit',
              'delivered',
              'all'
            ].map((f) {
              final isActive = _filter == f;
              return GestureDetector(
                onTap: () =>
                    setState(() => _filter = f),
                child: Container(
                  margin: const EdgeInsets.only(
                      right: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF9C27B0)
                            .withOpacity(0.15)
                        : const Color(0xFF16162A),
                    borderRadius:
                        BorderRadius.circular(8),
                    border: Border.all(
                        color: isActive
                            ? const Color(0xFF9C27B0)
                            : const Color(0xFF2D2D4E)),
                  ),
                  child: Text(
                      f == 'all'
                          ? 'ALL'
                          : f
                              .replaceAll('_', ' ')
                              .toUpperCase(),
                      style: TextStyle(
                          color: isActive
                              ? const Color(0xFF9C27B0)
                              : Colors.white38,
                          fontSize: 11,
                          fontWeight:
                              FontWeight.w600)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<List<ShipmentModel>>(
            stream: _stream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF9C27B0)));
              }
              final shipments = snapshot.data!;
              if (shipments.isEmpty) {
                return Center(
                    child: Text(
                        'No $_filter shipments',
                        style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 16)));
              }
              return ListView.separated(
                itemCount: shipments.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final s = shipments[i];
                  final isAssigning =
                      _assigning == s.id;
                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16162A),
                      borderRadius:
                          BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(
                              0xFF2D2D4E)),
                    ),
                    child: Row(children: [
                      Expanded(
                        child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                          Text(
                              'Shipment #${s.id.substring(0, 8)}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight:
                                      FontWeight.bold,
                                  fontFamily:
                                      'monospace')),
                          Text(
                              'Goods: ${s.goodsDescription}',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13)),
                          Text(
                              'Delivery to: ${s.deliveryAddress}',
                              style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12)),
                          if (s.logisticsPartnerName !=
                              null)
                            Text(
                                'Partner: ${s.logisticsPartnerName}',
                                style: const TextStyle(
                                    color: Color(
                                        0xFF9C27B0),
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.w600)),
                          // Status timeline
                          if (s.statusHistory.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            ...s.statusHistory.map(
                                (h) => Text(
                                    '• ${h['status']?.toString().replaceAll('_', ' ') ?? ''} — ${h['note'] ?? ''}',
                                    style: const TextStyle(
                                        color: Colors
                                            .white38,
                                        fontSize: 11))),
                          ],
                        ]),
                      ),
                      Column(children: [
                        _StatusBadge(status: s.status),
                        const SizedBox(height: 8),
                        if (s.status == 'created')
                          isAssigning
                              ? const CircularProgressIndicator(
                                  color: Color(
                                      0xFF9C27B0),
                                  strokeWidth: 2)
                              : ElevatedButton(
                                  onPressed: () =>
                                      _showAssignDialog(
                                          s),
                                  style: ElevatedButton
                                      .styleFrom(
                                          backgroundColor:
                                              const Color(
                                                  0xFF9C27B0),
                                          shape:
                                              RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(
                                                              8))),
                                  child: const Text(
                                      'Assign Partner',
                                      style: TextStyle(
                                          color: Colors
                                              .white)),
                                ),
                      ]),
                    ]),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
// ─── ADMIN AUDIT LOG PAGE ──────────────────────────
class _AdminAuditLogPage extends StatelessWidget {
  const _AdminAuditLogPage();

  Color _actionColor(String action) {
    if (action.contains('banned') ||
        action.contains('deleted') ||
        action.contains('rejected')) {
      return Colors.redAccent;
    }
    if (action.contains('approved') ||
        action.contains('unbanned') ||
        action.contains('cancelled')) {
      return Colors.greenAccent;
    }
    return const Color(0xFF6C63FF);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        const Text('Audit Log',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 4),
        const Text(
            'Complete history of platform actions',
            style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 24),
        Expanded(
          child: StreamBuilder<List<AuditLogModel>>(
            stream: AuditService().streamAllLogs(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF6C63FF)));
              }
              final logs = snapshot.data!;
              if (logs.isEmpty) {
                return const Center(
                    child: Text('No activity logged yet',
                        style: TextStyle(
                            color: Colors.white38)));
              }
              return ListView.separated(
                itemCount: logs.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final log = logs[i];
                  final color = _actionColor(log.action);
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16162A),
                      borderRadius:
                          BorderRadius.circular(10),
                      border: Border.all(
                          color: color.withOpacity(0.2)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                          Row(children: [
                            Text(
                                log.action
                                    .replaceAll('_', ' ')
                                    .toUpperCase(),
                                style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight:
                                        FontWeight.bold)),
                            const SizedBox(width: 10),
                            Text(log.actorEmail,
                                style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11)),
                          ]),
                          const SizedBox(height: 4),
                          Text(log.details,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13)),
                        ]),
                      ),
                      Text(
                          '${log.timestamp.toLocal()}'
                              .split('.')[0],
                          style: const TextStyle(
                              color: Colors.white24,
                              fontSize: 10)),
                    ]),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
