import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../services/advisory_service.dart';
import '../../services/firestore_service.dart';
import '../../models/advisory_model.dart';

class AdvisorSessionsScreen extends StatefulWidget {
  const AdvisorSessionsScreen({super.key});
  @override
  State<AdvisorSessionsScreen> createState() =>
      _AdvisorSessionsScreenState();
}

class _AdvisorSessionsScreenState
    extends State<AdvisorSessionsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    // Wrap in a Container with explicit dark background
    // so if the route is hit standalone via browser
    // back/forward, there is no white flash
    return Container(
      color: const Color(0xFF0D0D1A),
      child: Column(children: [
        Container(
          color: const Color(0xFF12121E),
          child: Row(children: [
            _tabBtn('Pending Requests', 0),
            _tabBtn('My Sessions', 1),
          ]),
        ),
        Expanded(
          child: _tab == 0
              ? _pendingView(uid)
              : _mySessionsView(uid),
        ),
      ]),
    );
  }

  Widget _tabBtn(String label, int index) {
    final isActive = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF12121E),
            border: Border(
              bottom: BorderSide(
                color: isActive
                    ? const Color(0xFF2196F3)
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isActive
                      ? const Color(0xFF2196F3)
                      : Colors.white54,
                  fontWeight: isActive
                      ? FontWeight.w600
                      : FontWeight.normal)),
        ),
      ),
    );
  }

  Widget _pendingView(String uid) {
    return StreamBuilder<List<AdvisoryModel>>(
      stream: AdvisoryService().streamPendingRequests(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF2196F3)));
        }
        final requests = snapshot.data!;
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                const Icon(Icons.inbox_rounded,
                    color: Colors.white24, size: 56),
                const SizedBox(height: 16),
                const Text('No pending requests',
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 15)),
                const SizedBox(height: 8),
                const Text(
                    'New client requests will appear here',
                    style: TextStyle(
                        color: Colors.white24,
                        fontSize: 12)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: requests.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: 12),
          itemBuilder: (context, i) =>
              _PendingRequestCard(
            request: requests[i],
            advisorUid: uid,
          ),
        );
      },
    );
  }

  Widget _mySessionsView(String uid) {
    return StreamBuilder<List<AdvisoryModel>>(
      stream:
          AdvisoryService().streamAdvisorSessions(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF2196F3)));
        }
        final sessions = snapshot.data!;
        if (sessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                const Icon(
                    Icons.support_agent_outlined,
                    color: Colors.white24,
                    size: 56),
                const SizedBox(height: 16),
                const Text('No sessions accepted yet',
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 15)),
                const SizedBox(height: 8),
                const Text(
                    'Accept a pending request to start a session',
                    style: TextStyle(
                        color: Colors.white24,
                        fontSize: 12)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: sessions.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: 12),
          itemBuilder: (context, i) => SessionCard(
              session: sessions[i], isAdvisor: true),
        );
      },
    );
  }
}

class _PendingRequestCard extends StatefulWidget {
  final AdvisoryModel request;
  final String advisorUid;
  const _PendingRequestCard(
      {required this.request, required this.advisorUid});
  @override
  State<_PendingRequestCard> createState() =>
      _PendingRequestCardState();
}

class _PendingRequestCardState
    extends State<_PendingRequestCard> {
  bool _accepting = false;

  Future<void> _accept() async {
    setState(() => _accepting = true);
    try {
      final user = await FirestoreService()
          .getUser(widget.advisorUid);
      await AdvisoryService().acceptSession(
        widget.request.id,
        widget.advisorUid,
        user?.customerId ?? '',
        user?.businessName ?? '',
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(
          content: Text('Session accepted!'),
          backgroundColor: Colors.greenAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF2196F3)
                .withOpacity(0.3)),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
            Text(r.clientBusinessName,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
            const SizedBox(height: 4),
            Text('Category: ${r.category}',
                style: const TextStyle(
                    color: Colors.white70)),
            Text('Topic: ${r.topic}',
                style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            Text(
                'Language: ${r.preferredLanguage}',
                style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12)),
            if (r.urgency == 'urgent')
              Container(
                margin:
                    const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.redAccent
                      .withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(4),
                  border: Border.all(
                      color: Colors.redAccent
                          .withOpacity(0.3)),
                ),
                child: const Text('URGENT',
                    style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 11,
                        fontWeight:
                            FontWeight.bold)),
              ),
          ]),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _accepting ? null : _accept,
          style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF2196F3),
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(8))),
          child: _accepting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2))
              : const Text('Accept',
                  style:
                      TextStyle(color: Colors.white)),
        ),
      ]),
    );
  }
}

// ─── Shared session card — used by advisor + client ───
class SessionCard extends StatelessWidget {
  final AdvisoryModel session;
  final bool isAdvisor;
  const SessionCard(
      {super.key,
      required this.session,
      required this.isAdvisor});

  Color get _color {
    switch (session.status) {
      case 'pending':
        return const Color(0xFFFFB347);
      case 'matched':
        return const Color(0xFF2196F3);
      case 'active':
        return Colors.greenAccent;
      case 'completed':
        return Colors.white54;
      default:
        return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = session;
    return GestureDetector(
      onTap: () => context.go('/session', extra: {
        'sessionId': s.id,
        'isAdvisor': isAdvisor,
      }),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF16162A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: _color.withOpacity(0.3)),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
              Text(s.category,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(s.topic,
                  style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              if (isAdvisor)
                Text(
                    'Client: ${s.clientBusinessName}',
                    style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12))
              else if (s.advisorName != null)
                Text('Advisor: ${s.advisorName}',
                    style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12)),
              if (s.clientRating != null) ...[
                const SizedBox(height: 4),
                Row(children: List.generate(
                    5,
                    (i) => Icon(Icons.star,
                        color: i < s.clientRating!
                            ? Colors.amber
                            : Colors.white24,
                        size: 14))),
              ],
            ]),
          ),
          Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
            _StatusBadge(status: s.status),
            const SizedBox(height: 8),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white38, size: 14),
          ]),
        ]),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color =
        status == 'active' || status == 'completed'
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