import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/advisory_model.dart';

class AdvisoryService {
  final _db = FirebaseFirestore.instance;

  Future<void> submitRequest(
      AdvisoryModel request) async {
    await _db
        .collection('advisory')
        .doc(request.id)
        .set(request.toMap());
  }

  Stream<List<AdvisoryModel>> streamClientSessions(
      String clientUid) {
    return _db
        .collection('advisory')
        .where('clientUid', isEqualTo: clientUid)
        .snapshots()
        .map((s) => s.docs
            .map((d) => AdvisoryModel.fromMap(d.data()))
            .toList());
  }

  Stream<List<AdvisoryModel>> streamAdvisorSessions(
      String advisorUid) {
    return _db
        .collection('advisory')
        .where('advisorUid', isEqualTo: advisorUid)
        .snapshots()
        .map((s) => s.docs
            .map((d) => AdvisoryModel.fromMap(d.data()))
            .toList());
  }

  Stream<List<AdvisoryModel>> streamPendingRequests() {
    return _db
        .collection('advisory')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs
            .map((d) => AdvisoryModel.fromMap(d.data()))
            .toList());
  }

  Future<void> acceptSession(
      String sessionId,
      String advisorUid,
      String advisorCustomerId,
      String advisorName) async {
    await _db
        .collection('advisory')
        .doc(sessionId)
        .update({
      'advisorUid': advisorUid,
      'advisorCustomerId': advisorCustomerId,
      'advisorName': advisorName,
      'status': 'matched',
    });
  }

  Future<void> startSession(
      String sessionId, String? videoLink) async {
    await _db
        .collection('advisory')
        .doc(sessionId)
        .update({
      'status': 'active',
      'videoLink': videoLink,
    });
  }

  Future<void> sendMessage(
      String sessionId,
      String senderUid,
      String senderName,
      String message) async {
    await _db
        .collection('advisory')
        .doc(sessionId)
        .update({
      'messages': FieldValue.arrayUnion([
        {
          'senderUid': senderUid,
          'senderName': senderName,
          'message': message,
          'time': DateTime.now().toIso8601String(),
        }
      ]),
    });
  }

  Future<void> completeSession(
      String sessionId, String advisorNotes) async {
    await _db
        .collection('advisory')
        .doc(sessionId)
        .update({
      'status': 'completed',
      'advisorNotes': advisorNotes,
      'completedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> acknowledgeAndRate(
      String sessionId,
      String clientUid,
      int rating,
      String feedback) async {
    await _db
        .collection('advisory')
        .doc(sessionId)
        .update({
      'clientAcknowledged': true,
      'clientRating': rating,
      'clientFeedback': feedback,
    });
    await _db
        .collection('crr')
        .doc(clientUid)
        .update({
      'advisorySessions': FieldValue.arrayUnion([
        {
          'sessionId': sessionId,
          'rating': rating,
          'date': DateTime.now().toIso8601String(),
        }
      ]),
    });
  }
}