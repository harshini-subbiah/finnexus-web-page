import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class BusinessProfileScreen extends StatefulWidget {
  final UserModel user;
  const BusinessProfileScreen({super.key, required this.user});
  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final _descCtrl = TextEditingController();
  final _minAmountCtrl = TextEditingController();
  final _maxAmountCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _productsCtrl = TextEditingController();
  bool _loading = false;
  bool _saved = false;
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final doc = await FirebaseFirestore.instance
        .collection('business_profiles')
        .doc(widget.user.uid)
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      _descCtrl.text = data['description'] ?? '';
      _minAmountCtrl.text = data['minLoanAmount']?.toString() ??
          data['minCoverage']?.toString() ?? '';
      _maxAmountCtrl.text = data['maxLoanAmount']?.toString() ??
          data['maxCoverage']?.toString() ?? '';
      _rateCtrl.text = data['interestRateFrom']?.toString() ?? '';
      _productsCtrl.text = data['productsOffered'] ?? '';
    }
    setState(() => _dataLoaded = true);
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final role = widget.user.role;
    final data = <String, dynamic>{
      'uid': widget.user.uid,
      'customerId': widget.user.customerId,
      'businessName': widget.user.businessName,
      'role': role,
      'email': widget.user.email,
      'description': _descCtrl.text.trim(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (role == 'lender') {
      data['minLoanAmount'] =
          double.tryParse(_minAmountCtrl.text.trim()) ?? 0;
      data['maxLoanAmount'] =
          double.tryParse(_maxAmountCtrl.text.trim()) ?? 0;
      data['interestRateFrom'] =
          double.tryParse(_rateCtrl.text.trim()) ?? 0;
    }

    if (role == 'insurer') {
      data['productsOffered'] = _productsCtrl.text.trim();
      data['minCoverage'] =
          double.tryParse(_minAmountCtrl.text.trim()) ?? 0;
      data['maxCoverage'] =
          double.tryParse(_maxAmountCtrl.text.trim()) ?? 0;
    }

    await FirebaseFirestore.instance
        .collection('business_profiles')
        .doc(widget.user.uid)
        .set(data);

    setState(() {
      _loading = false;
      _saved = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_dataLoaded) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
    }

    final role = widget.user.role;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Business Profile',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 4),
        const Text('This is what customers see when browsing providers',
            style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 28),

        // Read-only registered details
        _Section(
          title: 'Registered Details',
          child: Column(children: [
            _ReadRow(label: 'Business Name', value: widget.user.businessName),
            _ReadRow(label: 'Customer ID', value: widget.user.customerId ?? '—'),
            _ReadRow(label: 'PAN', value: widget.user.pan),
            _ReadRow(label: 'GSTIN', value: widget.user.gstin),
            _ReadRow(label: 'Email', value: widget.user.email),
            _ReadRow(label: 'Address', value: widget.user.address),
          ]),
        ),
        const SizedBox(height: 24),

        // Editable public info
        _Section(
          title: 'Public Business Information',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _EditField('Business Description', _descCtrl,
                hint: 'Describe your business and what you offer',
                maxLines: 3),
            const SizedBox(height: 16),

            if (role == 'lender') ...[
              _EditField('Minimum Loan Amount (₹)', _minAmountCtrl,
                  hint: 'e.g. 50000'),
              const SizedBox(height: 12),
              _EditField('Maximum Loan Amount (₹)', _maxAmountCtrl,
                  hint: 'e.g. 5000000'),
              const SizedBox(height: 12),
              _EditField('Interest Rate From (% p.a.)', _rateCtrl,
                  hint: 'e.g. 10.5'),
            ],

            if (role == 'insurer') ...[
              _EditField('Insurance Products Offered', _productsCtrl,
                  hint: 'e.g. Trade Credit, Goods in Transit',
                  maxLines: 2),
              const SizedBox(height: 12),
              _EditField('Minimum Coverage Amount (₹)', _minAmountCtrl,
                  hint: 'e.g. 100000'),
              const SizedBox(height: 12),
              _EditField('Maximum Coverage Amount (₹)', _maxAmountCtrl,
                  hint: 'e.g. 10000000'),
            ],

            const SizedBox(height: 20),
            Row(children: [
              ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                    : const Text('Save Profile',
                        style: TextStyle(color: Colors.white)),
              ),
              if (_saved) ...[
                const SizedBox(width: 16),
                const Icon(Icons.check_circle, color: Colors.greenAccent),
                const SizedBox(width: 6),
                const Text('Saved!',
                    style: TextStyle(color: Colors.greenAccent)),
              ],
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D2D4E)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                color: Colors.white70)),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }
}

class _ReadRow extends StatelessWidget {
  final String label, value;
  const _ReadRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 13))),
        Expanded(
            child: Text(value,
                style: const TextStyle(color: Colors.white, fontSize: 13,
                    fontFamily: 'monospace'))),
      ]),
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String? hint;
  final int maxLines;
  const _EditField(this.label, this.ctrl, {this.hint, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(color: Colors.white70, fontSize: 13)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white30),
          filled: true,
          fillColor: const Color(0xFF0D0D1A),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2D2D4E))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2D2D4E))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF6C63FF))),
        ),
      ),
    ]);
  }
}