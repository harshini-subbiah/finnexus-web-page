import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../../services/loan_service.dart';
import '../../services/firestore_service.dart';
import '../../models/loan_model.dart';
import '../../widgets/document_upload_widget.dart';
import '../../widgets/workflow_stepper.dart';
import 'dart:typed_data';
import '../../services/watermark_service.dart';

class LoanApplicationScreen extends StatefulWidget {
  const LoanApplicationScreen({super.key});
  @override
  State<LoanApplicationScreen> createState() =>
      _LoanApplicationScreenState();
}

class _LoanApplicationScreenState
    extends State<LoanApplicationScreen> {
  int _step = 0;
  Map<String, dynamic>? _selectedLender;
  bool _checking = true;
  bool _hasActiveLoan = false;

  final _amountCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  final _incomeCtrl = TextEditingController();
  final _existingLoansCtrl = TextEditingController();
  final _collateralCtrl = TextEditingController();
  final _collateralValueCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  String _loanType = 'Working Capital';
  int _tenure = 12;
  bool _loading = false;
  String? _error;

  final Map<String, PlatformFile?> _documents = {
    'Income Proof': null,
    'Bank Statement (6 months)': null,
    'Business Registration': null,
    'Collateral Document (if any)': null,
  };

  final _loanTypes = [
    'Working Capital',
    'Business Expansion',
    'Equipment Purchase',
    'Invoice Financing',
    'Personal Loan',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final hasLoan =
        await LoanService().hasActiveLoan(uid);
    setState(() {
      _hasActiveLoan = hasLoan;
      _checking = false;
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _purposeCtrl.dispose();
    _incomeCtrl.dispose();
    _existingLoansCtrl.dispose();
    _collateralCtrl.dispose();
    _collateralValueCtrl.dispose();
    _bankCtrl.dispose();
    _ifscCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if ([
      _amountCtrl,
      _purposeCtrl,
      _incomeCtrl,
      _bankCtrl,
      _ifscCtrl
    ].any((c) => c.text.trim().isEmpty)) {
      setState(
          () => _error = 'Please fill all required fields');
      return;
    }
    final amount =
        double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      setState(
          () => _error = 'Enter a valid loan amount');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uid =
          FirebaseAuth.instance.currentUser!.uid;
      final user =
          await FirestoreService().getUser(uid);
      final loanId = const Uuid().v4();
      final watermarkText = WatermarkService
          .buildWatermarkText(
              user?.customerId ?? uid.substring(0, 8),
              user?.businessName ?? '');

      // Save documents
     // Save each loan document as its own Firestore
      // document to avoid the 1MB per-document limit.
      // Pattern: loan_documents/{loanId}_{docKey}
      for (final entry in _documents.entries) {
        if (entry.value != null) {
          final file = entry.value!;
          final docKey = entry.key
              .replaceAll(' ', '_')
              .replaceAll('(', '')
              .replaceAll(')', '')
              .toLowerCase();

          Uint8List processedBytes;
          try {
            processedBytes =
                await WatermarkService.watermarkImage(
              file.bytes!,
              file.extension ?? 'pdf',
              watermarkText,
            );
          } catch (_) {
            processedBytes = file.bytes!;
          }

          await FirebaseFirestore.instance
              .collection('loan_documents')
              .doc('${loanId}_$docKey')
              .set({
            'loanId': loanId,
            'uid': uid,
            'docType': entry.key,
            'docKey': docKey,
            'fileName': file.name,
            'fileSize': file.size,
            'extension': file.extension ?? 'pdf',
            'data': base64Encode(processedBytes),
            'watermarked': true,
            'uploadedAt':
                DateTime.now().toIso8601String(),
          });
        }
      }

      final loan = LoanModel(
        id: loanId,
        uid: uid,
        customerId: user?.customerId ?? '',
        businessName: user?.businessName ?? '',
        lenderUid: _selectedLender!['uid']
                as String? ??
            '',
        lenderName: _selectedLender!['businessName']
                as String? ??
            '',
        amount: amount,
        tenureMonths: _tenure,
        purpose: _purposeCtrl.text.trim(),
        loanType: _loanType,
        annualIncome: double.tryParse(
            _incomeCtrl.text.trim()),
        existingLoans:
            _existingLoansCtrl.text.trim(),
        collateral:
            _collateralCtrl.text.trim().isEmpty
                ? null
                : _collateralCtrl.text.trim(),
        collateralValue:
            _collateralValueCtrl.text.trim().isEmpty
                ? null
                : _collateralValueCtrl.text.trim(),
        bankAccount: _bankCtrl.text.trim(),
        ifscCode: _ifscCtrl.text.trim(),
        status: 'pending',
        emiHistory: [],
        createdAt: DateTime.now(),
      );
      await LoanService().applyLoan(loan);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Loan application submitted to lender!'),
            backgroundColor: Colors.greenAccent),
      );
      context.go('/dashboard');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted)
        setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
          backgroundColor: Color(0xFF0D0D1A),
          body: Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF6C63FF))));
    }
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16162A),
        title: Text(
          _step == 0
              ? 'Choose a Lender'
              : 'Loan Application',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Colors.white),
          onPressed: () {
            if (_step == 1) {
              setState(() => _step = 0);
            } else {
              context.go('/dashboard');
            }
          },
        ),
      ),
      body: _hasActiveLoan
          ? _blockedView()
          : _step == 0
              ? _lenderPickerView()
              : _formView(),
    );
  }

  Widget _blockedView() {
    return Center(
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(40),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          const Icon(Icons.block,
              color: Colors.redAccent, size: 64),
          const SizedBox(height: 20),
          const Text('Active Loan Exists',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 12),
          const Text(
              'You already have an active or pending loan. Please complete it before applying again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white60, height: 1.5)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () =>
                context.go('/dashboard'),
            style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF6C63FF)),
            child: const Text('Back to Dashboard',
                style: TextStyle(color: Colors.white)),
          ),
        ]),
      ),
    );
  }

  Widget _lenderPickerView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('business_profiles')
          .where('role', isEqualTo: 'lender')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF4CAF82)));
        }
        final lenders = snapshot.data!.docs;
        if (lenders.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(Icons.account_balance_outlined,
                    color: Colors.white24, size: 64),
                SizedBox(height: 16),
                Text('No lenders available yet',
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 16)),
                SizedBox(height: 8),
                Text(
                    'A lender must register and set up their profile first',
                    style: TextStyle(
                        color: Colors.white24,
                        fontSize: 13)),
              ],
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Loan workflow stepper
            const WorkflowStepper(
              steps: Workflows.loanApplication,
              currentStep: 0,
              color: Color(0xFF4CAF82),
            ),
            const SizedBox(height: 24),

            const Text('Select a Lender',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 6),
            const Text(
                'Choose the lender you want to apply to',
                style:
                    TextStyle(color: Colors.white54)),
            const SizedBox(height: 20),
            ...lenders.map((doc) {
              final data =
                  doc.data() as Map<String, dynamic>;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedLender = data;
                  _step = 1;
                }),
                child: Container(
                  margin:
                      const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16162A),
                    borderRadius:
                        BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFF4CAF82)
                            .withOpacity(0.4)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF82)
                            .withOpacity(0.15),
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: const Center(
                          child: Text('🏦',
                              style: TextStyle(
                                  fontSize: 24))),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                        child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                          Text(
                              data['businessName'] ??
                                  '',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight:
                                      FontWeight.w600,
                                  fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(
                              data['description'] ??
                                  'No description provided',
                              style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13),
                              maxLines: 2,
                              overflow:
                                  TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          Wrap(spacing: 8, children: [
                            if (data['minLoanAmount'] !=
                                null)
                              _Chip(
                                  'Min: ₹${data['minLoanAmount']}'),
                            if (data['maxLoanAmount'] !=
                                null)
                              _Chip(
                                  'Max: ₹${data['maxLoanAmount']}'),
                            if (data[
                                    'interestRateFrom'] !=
                                null)
                              _Chip(
                                  'From ${data['interestRateFrom']}% p.a.'),
                          ]),
                        ])),
                    const Icon(Icons.arrow_forward_ios,
                        color: Colors.white38, size: 16),
                  ]),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _formView() {
    if (_selectedLender == null) {
      return const Center(
          child: Text('Go back and select a lender',
              style: TextStyle(
                  color: Colors.redAccent)));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        // Workflow stepper at step 2
        const WorkflowStepper(
          steps: Workflows.loanApplication,
          currentStep: 1,
          color: Color(0xFF4CAF82),
        ),
        const SizedBox(height: 24),

        // Selected lender banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF82)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: const Color(0xFF4CAF82)
                    .withOpacity(0.4)),
          ),
          child: Row(children: [
            const Text('🏦',
                style: TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
              const Text('Applying to:',
                  style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12)),
              Text(
                  _selectedLender!['businessName']
                          ?.toString() ??
                      '',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
            ]),
          ]),
        ),
        const SizedBox(height: 24),

        _sectionTitle('Loan Details'),
        const SizedBox(height: 12),
        _field('Loan Amount (₹) *', _amountCtrl,
            hint: 'e.g. 500000'),
        const SizedBox(height: 12),
        const Text('Loan Type *',
            style: TextStyle(
                color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _loanTypes.map((t) {
            final sel = _loanType == t;
            return GestureDetector(
              onTap: () =>
                  setState(() => _loanType = t),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: sel
                      ? const Color(0xFF4CAF82)
                          .withOpacity(0.2)
                      : const Color(0xFF16162A),
                  borderRadius:
                      BorderRadius.circular(8),
                  border: Border.all(
                      color: sel
                          ? const Color(0xFF4CAF82)
                          : const Color(0xFF2D2D4E)),
                ),
                child: Text(t,
                    style: TextStyle(
                        color: sel
                            ? const Color(0xFF4CAF82)
                            : Colors.white54,
                        fontSize: 13)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        _field('Purpose of Loan *', _purposeCtrl,
            hint: 'Describe why you need this loan',
            maxLines: 2),
        const SizedBox(height: 12),
        const Text('Repayment Tenure *',
            style: TextStyle(
                color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [6, 12, 18, 24, 36, 48].map((m) {
            final sel = _tenure == m;
            return GestureDetector(
              onTap: () =>
                  setState(() => _tenure = m),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: sel
                      ? const Color(0xFF4CAF82)
                          .withOpacity(0.2)
                      : const Color(0xFF16162A),
                  borderRadius:
                      BorderRadius.circular(8),
                  border: Border.all(
                      color: sel
                          ? const Color(0xFF4CAF82)
                          : const Color(0xFF2D2D4E)),
                ),
                child: Text('$m mo',
                    style: TextStyle(
                        color: sel
                            ? const Color(0xFF4CAF82)
                            : Colors.white54,
                        fontWeight: sel
                            ? FontWeight.bold
                            : FontWeight.normal)),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),
        _sectionTitle('Financial Information'),
        const SizedBox(height: 12),
        _field('Annual Business Income (₹) *',
            _incomeCtrl,
            hint: 'e.g. 2400000'),
        const SizedBox(height: 12),
        _field('Existing Loans / EMIs',
            _existingLoansCtrl,
            hint: 'List any existing EMIs (or "None")'),

        const SizedBox(height: 24),
        _sectionTitle('Collateral (if any)'),
        const SizedBox(height: 12),
        _field('Collateral Description',
            _collateralCtrl,
            hint: 'e.g. Property, Gold, FD'),
        const SizedBox(height: 12),
        _field('Estimated Collateral Value (₹)',
            _collateralValueCtrl,
            hint: 'e.g. 1000000'),

        const SizedBox(height: 24),
        _sectionTitle('Disbursement Account'),
        const SizedBox(height: 12),
        _field('Bank Account Number *', _bankCtrl,
            hint: 'Enter account number'),
        const SizedBox(height: 12),
        _field('IFSC Code *', _ifscCtrl,
            hint: 'e.g. HDFC0001234'),

        const SizedBox(height: 24),
        _sectionTitle('Supporting Documents'),
        const SizedBox(height: 4),
        const Text(
            'Upload documents to support your application',
            style: TextStyle(
                color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 12),
        DocumentUploadWidget(
          files: _documents,
          onFileSelected: (docType, file) {
            setState(
                () => _documents[docType] = file);
          },
        ),

        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.redAccent
                    .withOpacity(0.1),
                borderRadius:
                    BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.redAccent
                        .withOpacity(0.4))),
            child: Text(_error!,
                style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 13)),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF4CAF82),
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
                : const Text('Submit Application',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white)),
          ),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white70));

  Widget _field(String label,
      TextEditingController ctrl,
      {String? hint, int maxLines = 1}) {
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
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: Colors.white30),
          filled: true,
          fillColor: const Color(0xFF16162A),
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
                  color: Color(0xFF4CAF82))),
        ),
      ),
    ]);
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:
            const Color(0xFF4CAF82).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: const Color(0xFF4CAF82)
                .withOpacity(0.3)),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Color(0xFF4CAF82),
              fontSize: 11)),
    );
  }
}