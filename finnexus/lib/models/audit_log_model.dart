class AuditLogModel {
  final String id;
  final String uid;
  final String actorEmail;
  final String action;
  final String details;
  final String? targetUid;
  final DateTime timestamp;

  AuditLogModel({
    required this.id,
    required this.uid,
    required this.actorEmail,
    required this.action,
    required this.details,
    this.targetUid,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'uid': uid,
        'actorEmail': actorEmail,
        'action': action,
        'details': details,
        'targetUid': targetUid,
        'timestamp': timestamp.toIso8601String(),
      };

  factory AuditLogModel.fromMap(Map<String, dynamic> m) =>
      AuditLogModel(
        id: m['id'] ?? '',
        uid: m['uid'] ?? '',
        actorEmail: m['actorEmail'] ?? '',
        action: m['action'] ?? '',
        details: m['details'] ?? '',
        targetUid: m['targetUid'],
        timestamp: DateTime.parse(m['timestamp'] ??
            DateTime.now().toIso8601String()),
      );
}