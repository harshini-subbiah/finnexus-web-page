import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/advisory_service.dart';
import '../../models/advisory_model.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});
  @override
  State<SessionScreen> createState() =>
      _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  AdvisoryModel? _session;
  String? _sessionId;
  bool _isAdvisor = false;
  final _messageCtrl = TextEditingController();
  final _videoLinkCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  int _rating = 0;
  final _feedbackCtrl = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra
        as Map<String, dynamic>?;
    if (extra != null) {
      _sessionId = extra['sessionId'];
      _isAdvisor = extra['isAdvisor'] ?? false;
    }
  }

  Future<void> _sendMessage() async {
    if (_messageCtrl.text.trim().isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await AdvisoryService().sendMessage(
      _sessionId!,
      uid,
      _session?.advisorName ??
          _session?.clientBusinessName ??
          '',
      _messageCtrl.text.trim(),
    );
    _messageCtrl.clear();
  }
  Future<void> _openVideoLink(String link) async {
    var url = link.trim();
    if (!url.startsWith('http://') &&
        !url.startsWith('https://')) {
      url = 'https://$url';
    }
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri,
          mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not open link'),
            backgroundColor: Colors.redAccent),
      );
    }
  }

  void _copyVideoLink(String link) {
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Link copied to clipboard'),
          backgroundColor: Colors.greenAccent,
          duration: Duration(seconds: 1)),
    );
  }
  Future<void> _startSession() async {
    await AdvisoryService().startSession(
        _sessionId!, _videoLinkCtrl.text.trim());
  }

  Future<void> _completeSession() async {
    await AdvisoryService().completeSession(
        _sessionId!, _notesCtrl.text.trim());
  }

  Future<void> _acknowledge() async {
    if (_rating == 0) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await AdvisoryService().acknowledgeAndRate(
        _sessionId!, uid, _rating,
        _feedbackCtrl.text.trim());
    if (mounted) context.go('/my-advisory');
  }

  Stream<QuerySnapshot> _sessionStream() {
    return FirebaseFirestore.instance
        .collection('advisory')
        .where(FieldPath.documentId,
            isEqualTo: _sessionId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    if (_sessionId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.go('/dashboard'),
            child: const Text('Go Back'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16162A),
        title: const Text('Advisory Session',
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Colors.white),
          onPressed: () => _isAdvisor
              ? context.go('/advisor-sessions')
              : context.go('/my-advisory'),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _sessionStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF2196F3)));
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
                child: Text('Session not found',
                    style: TextStyle(
                        color: Colors.white38)));
          }
          final data =
              docs.first.data() as Map<String, dynamic>;
          _session = AdvisoryModel.fromMap(data);
          final s = _session!;
          final uid =
              FirebaseAuth.instance.currentUser!.uid;

          return Column(children: [
            // Session info bar
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF12121E),
              child: Row(children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                    Text(
                        _isAdvisor
                            ? 'Client: ${s.clientBusinessName}'
                            : 'Advisor: ${s.advisorName ?? 'Matching...'}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                    Text('${s.category} — ${s.topic}',
                        style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ]),
                ),
                _StatusChip(status: s.status),
              ]),
            ),

            // Video link bar
            // Video link bar — clickable + copyable
            if (s.videoLink != null &&
                s.videoLink!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                color: const Color(0xFF2196F3)
                    .withOpacity(0.1),
                child: Row(children: [
                  const Icon(Icons.video_call,
                      color: Color(0xFF2196F3)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _openVideoLink(s.videoLink!),
                      child: Text(s.videoLink!,
                          style: const TextStyle(
                              color: Color(0xFF2196F3),
                              fontSize: 13,
                              decoration:
                                  TextDecoration.underline)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy,
                        color: Color(0xFF2196F3), size: 16),
                    tooltip: 'Copy link',
                    onPressed: () => _copyVideoLink(s.videoLink!),
                  ),
                  IconButton(
                    icon: const Icon(Icons.open_in_new,
                        color: Color(0xFF2196F3), size: 16),
                    tooltip: 'Open in new tab',
                    onPressed: () => _openVideoLink(s.videoLink!),
                  ),
                ]),
              ),

            // Chat messages
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: s.messages.length,
                itemBuilder: (context, i) {
                  final msg = s.messages[i];
                  final isMe = msg['senderUid'] == uid;
                  return Align(
                    alignment: isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(
                          bottom: 10),
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10),
                      constraints:
                          const BoxConstraints(maxWidth: 300),
                      decoration: BoxDecoration(
                        color: isMe
                            ? const Color(0xFF2196F3)
                            : const Color(0xFF16162A),
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                        Text(msg['senderName'] ?? '',
                            style: TextStyle(
                                color: isMe
                                    ? Colors.white70
                                    : Colors.white38,
                                fontSize: 10)),
                        const SizedBox(height: 2),
                        Text(msg['message'] ?? '',
                            style: const TextStyle(
                                color: Colors.white)),
                      ]),
                    ),
                  );
                },
              ),
            ),

            // Advisor: start session controls
            if (_isAdvisor &&
                s.status == 'matched') ...[
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF12121E),
                child: Column(children: [
                  TextField(
                    controller: _videoLinkCtrl,
                    style: const TextStyle(
                        color: Colors.white),
                    decoration: InputDecoration(
                      hintText:
                          'Paste Google Meet / Zoom link (optional)',
                      hintStyle: const TextStyle(
                          color: Colors.white30),
                      filled: true,
                      fillColor:
                          const Color(0xFF0D0D1A),
                      prefixIcon: const Icon(
                          Icons.video_call,
                          color: Colors.white38),
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color:
                                  Color(0xFF2D2D4E))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color:
                                  Color(0xFF2D2D4E))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color:
                                  Color(0xFF2196F3))),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _startSession,
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF2196F3),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      8))),
                      child: const Text('Start Session',
                          style: TextStyle(
                              color: Colors.white)),
                    ),
                  ),
                ]),
              ),
            ],

            // Advisor: complete session
            if (_isAdvisor && s.status == 'active') ...[
              Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFF12121E),
                child: Column(children: [
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 2,
                    style: const TextStyle(
                        color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Session notes...',
                      hintStyle: const TextStyle(
                          color: Colors.white30),
                      filled: true,
                      fillColor:
                          const Color(0xFF0D0D1A),
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color:
                                  Color(0xFF2D2D4E))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color:
                                  Color(0xFF2D2D4E))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color:
                                  Color(0xFF2196F3))),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _completeSession,
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.greenAccent.shade700,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    8))),
                    child: const Text(
                        'Complete Session',
                        style: TextStyle(
                            color: Colors.white)),
                  ),
                ]),
              ),
            ],

            // Client: acknowledge + rate
            if (!_isAdvisor &&
                s.status == 'completed' &&
                !s.clientAcknowledged) ...[
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF12121E),
                child: Column(children: [
                  const Text(
                      'Session completed. Please acknowledge and rate:',
                      style: TextStyle(
                          color: Colors.white70)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children:
                        List.generate(5, (i) {
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _rating = i + 1),
                        child: Icon(Icons.star,
                            color: i < _rating
                                ? Colors.amber
                                : Colors.white24,
                            size: 32),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _feedbackCtrl,
                    style: const TextStyle(
                        color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Feedback...',
                      hintStyle: const TextStyle(
                          color: Colors.white30),
                      filled: true,
                      fillColor:
                          const Color(0xFF0D0D1A),
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color:
                                  Color(0xFF2D2D4E))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color:
                                  Color(0xFF2D2D4E))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: Colors.amber)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed:
                        _rating > 0 ? _acknowledge : null,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    8))),
                    child: const Text(
                        'Acknowledge & Complete',
                        style: TextStyle(
                            color: Colors.black)),
                  ),
                ]),
              ),
            ],

            // Message input
            if (s.status == 'active') ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                color: const Color(0xFF16162A),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _messageCtrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      style: const TextStyle(
                          color: Colors.white),
                      decoration: InputDecoration(
                        hintText:
                            'Type a message and press Enter...',
                        hintStyle: const TextStyle(
                            color: Colors.white30),
                        filled: true,
                        fillColor:
                            const Color(0xFF0D0D1A),
                        contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    24),
                            borderSide:
                                const BorderSide(
                                    color: Color(
                                        0xFF2D2D4E))),
                        enabledBorder:
                            OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                        24),
                                borderSide:
                                    const BorderSide(
                                        color: Color(
                                            0xFF2D2D4E))),
                        focusedBorder:
                            OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                        24),
                                borderSide:
                                    const BorderSide(
                                        color: Color(
                                            0xFF2196F3))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor:
                        const Color(0xFF2196F3),
                    child: IconButton(
                      icon: const Icon(Icons.send,
                          color: Colors.white, size: 18),
                      onPressed: _sendMessage,
                    ),
                  ),
                ]),
              ),
            ],
          ]);
        },
      ),
    );
  }
}

// ─── Status chip used inside session screen ───────
class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == 'active' ||
            status == 'completed'
        ? Colors.greenAccent
        : status == 'matched'
            ? const Color(0xFF2196F3)
            : status == 'pending'
                ? const Color(0xFFFFB347)
                : Colors.white38;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border:
            Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold)),
    );
  }
}