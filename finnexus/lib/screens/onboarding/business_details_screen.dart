import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../widgets/workflow_stepper.dart';

class BusinessDetailsScreen extends StatefulWidget {
  const BusinessDetailsScreen({super.key});
  @override
  State<BusinessDetailsScreen> createState() =>
      _BusinessDetailsScreenState();
}

class _BusinessDetailsScreenState
    extends State<BusinessDetailsScreen> {
  final _bizName = TextEditingController();
  final _address = TextEditingController();
  final _gstin = TextEditingController();
  final _pan = TextEditingController();
  final _bank = TextEditingController();
  bool _loading = false;
  String? _error;

  // ── Regex validators ─────────────────────────
  static final _gstinRegex =
      RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
  static final _panRegex =
      RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
  static final _bankRegex =
      RegExp(r'^\d{9,18}$');

  String? _validateAll() {
    if (_bizName.text.trim().isEmpty) {
      return 'Business name is required';
    }
    if (_address.text.trim().isEmpty) {
      return 'Address is required';
    }
    if (!_gstinRegex.hasMatch(_gstin.text.trim().toUpperCase())) {
      return 'Invalid GSTIN — must be 15 characters (e.g. 22ABCDE1234F1Z5)';
    }
    if (!_panRegex.hasMatch(_pan.text.trim().toUpperCase())) {
      return 'Invalid PAN — must be 10 characters (e.g. ABCDE1234F)';
    }
    if (!_bankRegex.hasMatch(_bank.text.trim())) {
      return 'Invalid bank account — must be 9 to 18 digits';
    }
    return null;
  }

  Future<void> _submit(String role) async {
    final validationError = _validateAll();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final svc = FirestoreService();
      final isDup = await svc.isDuplicate(
          _pan.text.trim().toUpperCase(),
          _gstin.text.trim().toUpperCase());
      if (isDup) {
        setState(() => _error =
            'PAN or GSTIN already registered. Contact support.');
        return;
      }
      final user = FirebaseAuth.instance.currentUser!;
      final model = UserModel(
        uid: user.uid,
        email: user.email!,
        role: role,
        businessName: _bizName.text.trim(),
        gstin: _gstin.text.trim().toUpperCase(),
        pan: _pan.text.trim().toUpperCase(),
        address: _address.text.trim(),
        bankAccount: _bank.text.trim(),
        kycStatus: 'pending',
        createdAt: DateTime.now(),
      );
      await svc.saveUser(model);
      if (!mounted) return;
      context.go('/kyc');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role =
        GoRouterState.of(context).extra as String? ??
            'customer';
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 520,
            padding: const EdgeInsets.all(40),
            margin: const EdgeInsets.symmetric(
                vertical: 32),
            decoration: BoxDecoration(
              color: const Color(0xFF16162A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF6C63FF)
                      .withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // Workflow stepper — step 2
                const WorkflowStepper(
                  steps: Workflows.onboarding,
                  currentStep: 2,
                  color: Color(0xFF6C63FF),
                ),
                const SizedBox(height: 24),

                const Text('Business Details',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 4),
                const Text(
                    'Please fill in your business information',
                    style:
                        TextStyle(color: Colors.white54)),
                const SizedBox(height: 28),

                _field('Legal Business Name *',
                    _bizName,
                    hint: 'Registered business name'),
                const SizedBox(height: 16),
                _field('Registered Address *', _address,
                    maxLines: 2),
                const SizedBox(height: 16),
                _field('GSTIN *', _gstin,
                    hint: 'e.g. 22ABCDE1234F1Z5',
                    helperText:
                        '15-character GST Identification Number',
                    onChanged: (v) {
                  _gstin.value = _gstin.value.copyWith(
                    text: v.toUpperCase(),
                    selection: TextSelection.collapsed(
                        offset: v.length),
                  );
                }),
                const SizedBox(height: 16),
                _field('PAN Number *', _pan,
                    hint: 'e.g. ABCDE1234F',
                    helperText:
                        '10-character Permanent Account Number',
                    onChanged: (v) {
                  _pan.value = _pan.value.copyWith(
                    text: v.toUpperCase(),
                    selection: TextSelection.collapsed(
                        offset: v.length),
                  );
                }),
                const SizedBox(height: 16),
                _field('Bank Account Number *', _bank,
                    hint: '9 to 18 digit account number',
                    helperText:
                        'Must be 9 to 18 digits, numbers only'),

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent
                          .withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.redAccent
                              .withOpacity(0.4)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent,
                          size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(_error!,
                              style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13))),
                    ]),
                  ),
                ],

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading
                        ? null
                        : () => _submit(role),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF6C63FF),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10)),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2)
                        : const Text(
                            'Continue to KYC Upload',
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String? hint,
    String? helperText,
    int maxLines = 1,
    void Function(String)? onChanged,
  }) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      Text(label,
          style: const TextStyle(
              color: Colors.white70, fontSize: 13)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: Colors.white30),
          helperText: helperText,
          helperStyle:
              const TextStyle(color: Colors.white38,
                  fontSize: 11),
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
                  color: Color(0xFF6C63FF))),
        ),
      ),
    ]);
  }
}