import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/loan_model.dart';

class LoanService {
  final _db = FirebaseFirestore.instance;

  Future<bool> hasActiveLoan(String uid) async {
    final result = await _db
        .collection('loans')
        .where('uid', isEqualTo: uid)
        .where('status',
            whereIn: ['active', 'pending', 'approved'])
        .get();
    return result.docs.isNotEmpty;
  }

  Future<void> applyLoan(LoanModel loan) async {
    await _db
        .collection('loans')
        .doc(loan.id)
        .set(loan.toMap());
    await _db.collection('crr').doc(loan.uid).update({
      'loanHistory': FieldValue.arrayUnion([
        {
          'loanId': loan.id,
          'amount': loan.amount,
          'status': 'pending',
          'date': DateTime.now().toIso8601String()
        }
      ])
    });
  }

  Stream<List<LoanModel>> streamUserLoans(String uid) {
    return _db
        .collection('loans')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((s) => s.docs
            .map((d) => LoanModel.fromMap(d.data()))
            .toList());
  }

  Stream<List<LoanModel>> streamLenderLoans(
      String lenderUid,
      {String? status}) {
    Query q = _db
        .collection('loans')
        .where('lenderUid', isEqualTo: lenderUid);
    if (status != null) {
      q = q.where('status', isEqualTo: status);
    }
    return q.snapshots().map((s) => s.docs
        .map((d) =>
            LoanModel.fromMap(d.data() as Map<String, dynamic>))
        .toList());
  }

  Stream<List<LoanModel>> streamAllLoans(
      {String? status}) {
    Query q = _db.collection('loans');
    if (status != null) {
      q = q.where('status', isEqualTo: status);
    }
    return q.snapshots().map((s) => s.docs
        .map((d) =>
            LoanModel.fromMap(d.data() as Map<String, dynamic>))
        .toList());
  }

  Future<void> approveLoan(
      String loanId, double interestRate) async {
    await _db.collection('loans').doc(loanId).update({
      'status': 'approved',
      'interestRate': interestRate,
    });
  }

  Future<void> rejectLoan(
      String loanId, String reason) async {
    await _db.collection('loans').doc(loanId).update({
      'status': 'rejected',
      'rejectionReason': reason,
    });
  }

  Future<void> disburseLoan(
      String loanId, String uid) async {
    await _db.collection('loans').doc(loanId).update({
      'status': 'active',
      'disbursedAt': DateTime.now().toIso8601String(),
    });
    await _db
        .collection('crr')
        .doc(uid)
        .update({'hasActiveLoan': true});
  }

  Future<void> recordEmi(
      String loanId, String uid, double amount) async {
    await _db.collection('loans').doc(loanId).update({
      'emiHistory': FieldValue.arrayUnion([
        {
          'amount': amount,
          'paidAt': DateTime.now().toIso8601String(),
          'status': 'paid'
        }
      ])
    });
  }

  Future<void> closeLoan(
      String loanId, String uid) async {
    await _db
        .collection('loans')
        .doc(loanId)
        .update({'status': 'closed'});
    await _db.collection('crr').doc(uid).update({
      'hasActiveLoan': false,
      'creditScore': FieldValue.increment(10),
    });
  }
}