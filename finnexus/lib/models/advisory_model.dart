class AdvisoryModel {
  final String id;
  final String clientUid;
  final String clientCustomerId;
  final String clientBusinessName;
  final String? advisorUid;
  final String? advisorCustomerId;
  final String? advisorName;
  final String category;
  final String topic;
  final String preferredLanguage;
  final String urgency; // normal, urgent
  final String status;
  // pending, matched, active, completed, cancelled
  final List<Map<String, dynamic>> messages;
  final String? videoLink;
  final bool clientAcknowledged;
  final int? clientRating;
  final String? clientFeedback;
  final String? advisorNotes;
  final DateTime createdAt;
  final String? completedAt;

  AdvisoryModel({
    required this.id,
    required this.clientUid,
    required this.clientCustomerId,
    required this.clientBusinessName,
    this.advisorUid,
    this.advisorCustomerId,
    this.advisorName,
    required this.category,
    required this.topic,
    required this.preferredLanguage,
    required this.urgency,
    required this.status,
    required this.messages,
    this.videoLink,
    required this.clientAcknowledged,
    this.clientRating,
    this.clientFeedback,
    this.advisorNotes,
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'clientUid': clientUid,
        'clientCustomerId': clientCustomerId,
        'clientBusinessName': clientBusinessName,
        'advisorUid': advisorUid,
        'advisorCustomerId': advisorCustomerId,
        'advisorName': advisorName,
        'category': category,
        'topic': topic,
        'preferredLanguage': preferredLanguage,
        'urgency': urgency,
        'status': status,
        'messages': messages,
        'videoLink': videoLink,
        'clientAcknowledged': clientAcknowledged,
        'clientRating': clientRating,
        'clientFeedback': clientFeedback,
        'advisorNotes': advisorNotes,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt,
      };

  factory AdvisoryModel.fromMap(
          Map<String, dynamic> m) =>
      AdvisoryModel(
        id: m['id'] ?? '',
        clientUid: m['clientUid'] ?? '',
        clientCustomerId: m['clientCustomerId'] ?? '',
        clientBusinessName:
            m['clientBusinessName'] ?? '',
        advisorUid: m['advisorUid'],
        advisorCustomerId: m['advisorCustomerId'],
        advisorName: m['advisorName'],
        category: m['category'] ?? '',
        topic: m['topic'] ?? '',
        preferredLanguage:
            m['preferredLanguage'] ?? 'English',
        urgency: m['urgency'] ?? 'normal',
        status: m['status'] ?? 'pending',
        messages: List<Map<String, dynamic>>.from(
            m['messages'] ?? []),
        videoLink: m['videoLink'],
        clientAcknowledged:
            m['clientAcknowledged'] ?? false,
        clientRating: m['clientRating'],
        clientFeedback: m['clientFeedback'],
        advisorNotes: m['advisorNotes'],
        createdAt: DateTime.parse(m['createdAt'] ??
            DateTime.now().toIso8601String()),
        completedAt: m['completedAt'],
      );
}