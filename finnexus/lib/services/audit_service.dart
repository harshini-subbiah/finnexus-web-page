import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/audit_log_model.dart';

class AuditService {
  final _db = FirebaseFirestore.instance;

  Future<void> log(String action, String details,
      {String? targetUid}) async {
    final user = FirebaseAuth.instance.currentUser;
    final entry = AuditLogModel(
      id: const Uuid().v4(),
      uid: user?.uid ?? 'system',
      actorEmail: user?.email ?? 'system',
      action: action,
      details: details,
      targetUid: targetUid,
      timestamp: DateTime.now(),
    );
    await _db
        .collection('audit_logs')
        .doc(entry.id)
        .set(entry.toMap());
  }

  Stream<List<AuditLogModel>> streamAllLogs(
      {int limit = 200}) {
    return _db
        .collection('audit_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs
            .map((d) => AuditLogModel.fromMap(d.data()))
            .toList());
  }

  Stream<List<AuditLogModel>> streamUserLogs(
      String uid) {
    return _db
        .collection('audit_logs')
        .where('uid', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => AuditLogModel.fromMap(d.data()))
            .toList());
  }
}