import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/insurance_model.dart';

class InsuranceService {
  final _db = FirebaseFirestore.instance;

  Future<void> applyInsurance(
      InsuranceModel policy) async {
    await _db
        .collection('insurance')
        .doc(policy.id)
        .set(policy.toMap());
  }

  Stream<List<InsuranceModel>> streamUserPolicies(
      String uid) {
    return _db
        .collection('insurance')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((s) => s.docs
            .map((d) => InsuranceModel.fromMap(d.data()))
            .toList());
  }

  Stream<List<InsuranceModel>> streamInsurerPolicies(
      String insurerUid,
      {String? status}) {
    Query q = _db
        .collection('insurance')
        .where('insurerUid', isEqualTo: insurerUid);
    if (status != null) {
      q = q.where('status', isEqualTo: status);
    }
    return q.snapshots().map((s) => s.docs
        .map((d) => InsuranceModel.fromMap(
            d.data() as Map<String, dynamic>))
        .toList());
  }

  Stream<List<InsuranceModel>> streamAllPolicies(
      {String? status}) {
    Query q = _db.collection('insurance');
    if (status != null) {
      q = q.where('status', isEqualTo: status);
    }
    return q.snapshots().map((s) => s.docs
        .map((d) => InsuranceModel.fromMap(
            d.data() as Map<String, dynamic>))
        .toList());
  }

  Future<void> activatePolicy(String policyId) async {
    await _db
        .collection('insurance')
        .doc(policyId)
        .update({'status': 'active'});
  }

  Future<void> rejectPolicy(
      String policyId, String reason) async {
    await _db
        .collection('insurance')
        .doc(policyId)
        .update({
      'status': 'closed',
      'claimReason': reason,
    });
  }

  Future<void> fileClaim(
      String policyId, String reason) async {
    await _db
        .collection('insurance')
        .doc(policyId)
        .update({
      'status': 'claim_filed',
      'claimReason': reason,
      'claimStatus': 'pending',
    });
  }

  Future<void> settleClaim(
      String policyId, String uid) async {
    await _db
        .collection('insurance')
        .doc(policyId)
        .update({
      'status': 'settled',
      'claimStatus': 'approved',
      'closedAt': DateTime.now().toIso8601String(),
    });
    await _db.collection('crr').doc(uid).update({
      'insuranceClaims': FieldValue.arrayUnion([
        {
          'policyId': policyId,
          'settledAt': DateTime.now().toIso8601String()
        }
      ])
    });
  }

  Future<void> closePolicy(String policyId) async {
    await _db
        .collection('insurance')
        .doc(policyId)
        .update({
      'status': 'closed',
      'closedAt': DateTime.now().toIso8601String(),
    });
  }
}