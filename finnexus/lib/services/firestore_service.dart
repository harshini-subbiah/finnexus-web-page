import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // ── Ban / Unban ──────────────────────────────
  Future<void> banUser(
      String uid, String reason, String adminEmail) async {
    await _db.collection('users').doc(uid).update({
      'isBanned': true,
      'banReason': reason,
      'bannedBy': adminEmail,
      'bannedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> unbanUser(String uid) async {
    await _db.collection('users').doc(uid).update({
      'isBanned': false,
      'banReason': null,
      'bannedBy': null,
      'bannedAt': null,
    });
  }

  // ── Admin hard delete ─────────────────────────
  Future<void> adminDeleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  // ── Self deletion request ─────────────────────
  Future<void> requestSelfDeletion(String uid) async {
    final scheduledAt = DateTime.now()
        .add(const Duration(minutes: 5));
    await _db.collection('users').doc(uid).update({
      'deletionRequested': true,
      'deletionScheduledAt':
          scheduledAt.toIso8601String(),
    });
  }

  Future<void> cancelSelfDeletion(String uid) async {
    await _db.collection('users').doc(uid).update({
      'deletionRequested': false,
      'deletionScheduledAt': null,
    });
  }

  // ── Pending payment check before deletion ─────
  Future<bool> hasPendingPayments(String uid) async {
    // Active/pending loans
    final loans = await _db
        .collection('loans')
        .where('uid', isEqualTo: uid)
        .where('status',
            whereIn: ['pending', 'approved', 'active'])
        .get();
    if (loans.docs.isNotEmpty) return true;

    // Active insurance policies
    final policies = await _db
        .collection('insurance')
        .where('uid', isEqualTo: uid)
        .where('status',
            whereIn: ['pending', 'active', 'claim_filed'])
        .get();
    if (policies.docs.isNotEmpty) return true;

    // Orders with unpaid credit terms or undelivered
    final orders = await _db
        .collection('orders')
        .where('buyerUid', isEqualTo: uid)
        .where('orderStatus', whereIn: [
      'pending',
      'confirmed',
      'dispatched',
      'in_transit'
    ]).get();
    if (orders.docs.isNotEmpty) return true;

    return false;
  }
  // Check for duplicate PAN or GSTIN
  Future<bool> isDuplicate(String pan, String gstin) async {
    final panCheck = await _db
        .collection('users')
        .where('pan', isEqualTo: pan)
        .get();
    if (panCheck.docs.isNotEmpty) return true;

    final gstCheck = await _db
        .collection('users')
        .where('gstin', isEqualTo: gstin)
        .get();
    if (gstCheck.docs.isNotEmpty) return true;

    return false;
  }

  // Save user profile
  Future<void> saveUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  // Get user profile
  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  // Generate Customer ID (FNX-[ROLE]-[YEAR]-[SEQUENCE])
  Future<String> generateCustomerId(String role) async {
    final year = DateTime.now().year;
    final roleCode = role.toUpperCase().substring(0, 3);
    final counter = await _db.collection('counters').doc('customer_id').get();
    int sequence = 1;
    if (counter.exists) {
      sequence = (counter.data()!['count'] ?? 0) + 1;
    }
    await _db.collection('counters').doc('customer_id').set({'count': sequence});
    return 'FNX-$roleCode-$year-${sequence.toString().padLeft(5, '0')}';
  }

  // Update KYC status (called by admin)
  Future<void> updateKycStatus(String uid, String status,
      {String? reason}) async {
    final updates = <String, dynamic>{'kycStatus': status};
    if (status == 'approved') {
      final userDoc = await _db.collection('users').doc(uid).get();
      final role = userDoc.data()!['role'];
      final customerId = await generateCustomerId(role);
      updates['customerId'] = customerId;
      // Initialise CRR record
      await _db.collection('crr').doc(uid).set({
        'customerId': customerId,
        'uid': uid,
        'creditScore': null,
        'loanHistory': [],
        'orderHistory': [],
        'fraudAlerts': [],
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
    if (reason != null) updates['rejectionReason'] = reason;
    await _db.collection('users').doc(uid).update(updates);
  }

  // Stream user changes (for real-time status updates)
  Stream<UserModel?> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!);
    });
  }
}