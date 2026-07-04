import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../services/advisory_service.dart';
import '../../services/firestore_service.dart';
import '../../models/advisory_model.dart';

class AdvisoryRequestScreen extends StatefulWidget {
  const AdvisoryRequestScreen({super.key});
  @override
  State<AdvisoryRequestScreen> createState() =>
      _AdvisoryRequestScreenState();
}

class _AdvisoryRequestScreenState
    extends State<AdvisoryRequestScreen> {
  final _topicCtrl = TextEditingController();
  String _category = 'Financial';
  String _language = 'English';
  String _urgency = 'normal';
  bool _loading = false;
  String? _error;
  bool _hasActiveSession = false;

  final _categories = [
    'Financial', 'Legal', 'Business Strategy',
    'Tax', 'Insurance', 'Investment', 'Other'
  ];
  final _languages = [
    'English', 'Hindi', 'Tamil', 'Telugu',
    'Kannada', 'Marathi', 'Bengali'
  ];

  @override
  void initState() {
    super.initState();
    _checkActiveSession();
  }

  Future<void> _checkActiveSession() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final stream =
        AdvisoryService().streamClientSessions(uid);
    stream.first.then((sessions) {
      final active = sessions.any((s) =>
          s.status == 'pending' ||
          s.status == 'matched' ||
          s.status == 'active');
      if (mounted) {
        setState(() => _hasActiveSession = active);
      }
    });
  }

  Future<void> _submit() async {
    if (_topicCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please describe your topic');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final uid =
          FirebaseAuth.instance.currentUser!.uid;
      final user =
          await FirestoreService().getUser(uid);
      final session = AdvisoryModel(
        id: const Uuid().v4(),
        clientUid: uid,
        clientCustomerId: user?.customerId ?? '',
        clientBusinessName: user?.businessName ?? '',
        category: _category,
        topic: _topicCtrl.text.trim(),
        preferredLanguage: _language,
        urgency: _urgency,
        status: 'pending',
        messages: [],
        clientAcknowledged: false,
        createdAt: DateTime.now(),
      );
      await AdvisoryService().submitRequest(session);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Advisory request submitted!'),
            backgroundColor: Colors.greenAccent),
      );
      context.go('/my-advisory');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16162A),
        title: const Text('Request Advisory Session',
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Colors.white),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: Center(
        child: Container(
          width: 520,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: const Color(0xFF16162A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFF2196F3)
                    .withOpacity(0.3)),
          ),
          child: _hasActiveSession
              ? _blockedView()
              : _formView(),
        ),
      ),
    );
  }

  Widget _blockedView() {
    return Column(mainAxisSize: MainAxisSize.min,
        children: [
      const Icon(Icons.block,
          color: Colors.redAccent, size: 64),
      const SizedBox(height: 20),
      const Text('Active Session Exists',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white)),
      const SizedBox(height: 12),
      const Text(
          'You already have an active advisory session. Please complete it before starting a new one.',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white60, height: 1.5)),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: () => context.go('/my-advisory'),
        style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2196F3)),
        child: const Text('View My Sessions',
            style: TextStyle(color: Colors.white)),
      ),
    ]);
  }

  Widget _formView() {
    return SingleChildScrollView(
      child: Column(crossAxisAlignment:
          CrossAxisAlignment.start, children: [
        const Row(children: [
          Text('💼', style: TextStyle(fontSize: 28)),
          SizedBox(width: 12),
          Text('Advisory Request',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ]),
        const SizedBox(height: 24),

        _label('Category *'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((c) {
            final sel = _category == c;
            return GestureDetector(
              onTap: () =>
                  setState(() => _category = c),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: sel
                      ? const Color(0xFF2196F3)
                          .withOpacity(0.2)
                      : const Color(0xFF0D0D1A),
                  borderRadius:
                      BorderRadius.circular(8),
                  border: Border.all(
                      color: sel
                          ? const Color(0xFF2196F3)
                          : const Color(0xFF2D2D4E)),
                ),
                child: Text(c,
                    style: TextStyle(
                        color: sel
                            ? const Color(0xFF2196F3)
                            : Colors.white54,
                        fontSize: 13)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        _label('Topic / Description *'),
        const SizedBox(height: 6),
        TextField(
          controller: _topicCtrl,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDeco(
              'Describe what you need advice on...'),
        ),
        const SizedBox(height: 16),

        _label('Preferred Language'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _languages.map((l) {
            final sel = _language == l;
            return GestureDetector(
              onTap: () =>
                  setState(() => _language = l),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: sel
                      ? const Color(0xFF2196F3)
                          .withOpacity(0.2)
                      : const Color(0xFF0D0D1A),
                  borderRadius:
                      BorderRadius.circular(6),
                  border: Border.all(
                      color: sel
                          ? const Color(0xFF2196F3)
                          : const Color(0xFF2D2D4E)),
                ),
                child: Text(l,
                    style: TextStyle(
                        color: sel
                            ? const Color(0xFF2196F3)
                            : Colors.white54,
                        fontSize: 12)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        _label('Urgency'),
        const SizedBox(height: 8),
        Row(children: [
          _urgencyBtn('Normal', 'normal'),
          const SizedBox(width: 10),
          _urgencyBtn('Urgent', 'urgent'),
        ]),

        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 13)),
        ],

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              padding: const EdgeInsets.symmetric(
                  vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(10)),
            ),
            child: _loading
                ? const CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2)
                : const Text('Submit Request',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15)),
          ),
        ),
      ]),
    );
  }

  Widget _urgencyBtn(String label, String value) {
    final sel = _urgency == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _urgency = value),
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: 10),
          decoration: BoxDecoration(
            color: sel
                ? (value == 'urgent'
                        ? Colors.redAccent
                        : const Color(0xFF2196F3))
                    .withOpacity(0.2)
                : const Color(0xFF0D0D1A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: sel
                    ? (value == 'urgent'
                        ? Colors.redAccent
                        : const Color(0xFF2196F3))
                    : const Color(0xFF2D2D4E)),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: sel
                      ? (value == 'urgent'
                          ? Colors.redAccent
                          : const Color(0xFF2196F3))
                      : Colors.white54,
                  fontWeight: sel
                      ? FontWeight.bold
                      : FontWeight.normal)),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          color: Colors.white70, fontSize: 13));

  InputDecoration _inputDeco(String hint) =>
      InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: Colors.white30),
        filled: true,
        fillColor: const Color(0xFF0D0D1A),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
                color: Color(0xFF2D2D4E))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
                color: Color(0xFF2D2D4E))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
                color: Color(0xFF2196F3))),
      );
}