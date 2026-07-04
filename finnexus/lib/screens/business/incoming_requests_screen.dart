import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/loan_model.dart';
import '../../models/insurance_model.dart';
import '../../services/loan_service.dart';
import '../../services/insurance_service.dart';
import '../../widgets/document_viewer.dart';

class IncomingRequestsScreen extends StatefulWidget {
  final UserModel user;
  const IncomingRequestsScreen(
      {super.key, required this.user});
  @override
  State<IncomingRequestsScreen> createState() =>
      _IncomingRequestsScreenState();
}

class _IncomingRequestsScreenState
    extends State<IncomingRequestsScreen> {
  String _filter = 'pending';
  final _rateCtrl = TextEditingController();
  final _rejectCtrl = TextEditingController();
  String? _processing;

  @override
  void dispose() {
    _rateCtrl.dispose();
    _rejectCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLender = widget.user.role == 'lender';
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text(
            isLender
                ? 'Loan Applications'
                : 'Insurance Applications',
            style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 4),
        Text(
            isLender
                ? 'Review and manage incoming loan requests'
                : 'Review and manage incoming insurance requests',
            style: const TextStyle(color: Colors.white54)),
        const SizedBox(height: 24),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: (isLender
                    ? [
                        'pending',
                        'approved',
                        'active',
                        'rejected',
                        'closed'
                      ]
                    : [
                        'pending',
                        'active',
                        'claim_filed',
                        'settled',
                        'closed'
                      ])
                .map((f) {
              final isActive = _filter == f;
              final color = f == 'pending'
                  ? const Color(0xFFFFB347)
                  : f == 'approved' || f == 'active'
                      ? Colors.greenAccent
                      : f == 'rejected'
                          ? Colors.redAccent
                          : f == 'claim_filed'
                              ? const Color(0xFFFF8C42)
                              : Colors.white38;
              return GestureDetector(
                onTap: () =>
                    setState(() => _filter = f),
                child: Container(
                  margin:
                      const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? color.withOpacity(0.15)
                        : const Color(0xFF16162A),
                    borderRadius:
                        BorderRadius.circular(8),
                    border: Border.all(
                        color: isActive
                            ? color
                            : const Color(0xFF2D2D4E)),
                  ),
                  child: Text(
                      f
                          .replaceAll('_', ' ')
                          .toUpperCase(),
                      style: TextStyle(
                          color: isActive
                              ? color
                              : Colors.white38,
                          fontSize: 11,
                          fontWeight:
                              FontWeight.w600)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        Expanded(
          child: isLender
              ? _loanList()
              : _insuranceList(),
        ),
      ]),
    );
  }

  Widget _loanList() {
    return StreamBuilder<List<LoanModel>>(
      stream: LoanService().streamLenderLoans(
          widget.user.uid,
          status: _filter),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF4CAF82)));
        }
        final loans = snapshot.data!;
        if (loans.isEmpty) {
          return _emptyState(
              'No $_filter loan applications');
        }
        return ListView.separated(
          itemCount: loans.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: 12),
          itemBuilder: (context, i) => _LoanCard(
            loan: loans[i],
            filter: _filter,
            processing: _processing,
            onApprove: _showApproveDialog,
            onReject: _showRejectLoanDialog,
            onDisburse: (loan) async {
              setState(
                  () => _processing = loan.id);
              await LoanService()
                  .disburseLoan(loan.id, loan.uid);
              setState(() => _processing = null);
            },
            onClose: (loan) async {
              setState(
                  () => _processing = loan.id);
              await LoanService()
                  .closeLoan(loan.id, loan.uid);
              setState(() => _processing = null);
            },
          ),
        );
      },
    );
  }

  Widget _insuranceList() {
    return StreamBuilder<List<InsuranceModel>>(
      stream: InsuranceService().streamInsurerPolicies(
          widget.user.uid,
          status: _filter),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFFE07B39)));
        }
        final policies = snapshot.data!;
        if (policies.isEmpty) {
          return _emptyState(
              'No $_filter insurance applications');
        }
        return ListView.separated(
          itemCount: policies.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: 12),
          itemBuilder: (context, i) => _InsuranceCard(
            policy: policies[i],
            filter: _filter,
            processing: _processing,
            onActivate: (p) async {
              setState(() => _processing = p.id);
              await InsuranceService()
                  .activatePolicy(p.id);
              setState(() => _processing = null);
            },
            onReject: _showRejectInsuranceDialog,
            onSettle: (p) async {
              setState(() => _processing = p.id);
              await InsuranceService()
                  .settleClaim(p.id, p.uid);
              setState(() => _processing = null);
            },
            onClose: (p) async {
              setState(() => _processing = p.id);
              await InsuranceService()
                  .closePolicy(p.id);
              setState(() => _processing = null);
            },
          ),
        );
      },
    );
  }

  Widget _emptyState(String msg) {
    return Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          const Icon(Icons.inbox_rounded,
              color: Colors.white24, size: 64),
          const SizedBox(height: 16),
          Text(msg,
              style: const TextStyle(
                  color: Colors.white38, fontSize: 16)),
        ]));
  }

  Future<void> _showApproveDialog(
      LoanModel loan) async {
    _rateCtrl.clear();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16162A),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Approve Loan Application',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
              _DialogRow('Applicant', loan.businessName),
              _DialogRow('Amount',
                  '₹${loan.amount.toStringAsFixed(0)}'),
              _DialogRow('Tenure',
                  '${loan.tenureMonths} months'),
              _DialogRow('Purpose', loan.purpose),
              const SizedBox(height: 16),
              TextField(
                controller: _rateCtrl,
                keyboardType: TextInputType.number,
                style:
                    const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText:
                      'Set Interest Rate (% p.a.)',
                  labelStyle: const TextStyle(
                      color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF0D0D1A),
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Color(0xFF2D2D4E))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Colors.greenAccent)),
                ),
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: Colors.white38))),
          ElevatedButton(
            onPressed: () async {
              final rate = double.tryParse(
                  _rateCtrl.text.trim());
              if (rate == null) return;
              Navigator.pop(ctx);
              setState(
                  () => _processing = loan.id);
              await LoanService()
                  .approveLoan(loan.id, rate);
              setState(() => _processing = null);
              if (mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(
                  content: Text('Loan approved!'),
                  backgroundColor: Colors.greenAccent,
                ));
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.greenAccent.shade700),
            child: const Text('Approve',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showRejectLoanDialog(
      LoanModel loan) async {
    _rejectCtrl.clear();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16162A),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Loan Application',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _rejectCtrl,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Reason for rejection...',
            hintStyle: const TextStyle(
                color: Colors.white30),
            filled: true,
            fillColor: const Color(0xFF0D0D1A),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                    color: Color(0xFF2D2D4E))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                    color: Colors.redAccent)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: Colors.white38))),
          ElevatedButton(
            onPressed: () async {
              if (_rejectCtrl.text.trim().isEmpty)
                return;
              Navigator.pop(ctx);
              setState(
                  () => _processing = loan.id);
              await LoanService().rejectLoan(
                  loan.id, _rejectCtrl.text.trim());
              setState(() => _processing = null);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            child: const Text('Reject',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showRejectInsuranceDialog(
      InsuranceModel policy) async {
    _rejectCtrl.clear();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16162A),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text(
            'Reject Insurance Application',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _rejectCtrl,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Reason for rejection...',
            hintStyle: const TextStyle(
                color: Colors.white30),
            filled: true,
            fillColor: const Color(0xFF0D0D1A),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                    color: Color(0xFF2D2D4E))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                    color: Colors.redAccent)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: Colors.white38))),
          ElevatedButton(
            onPressed: () async {
              if (_rejectCtrl.text.trim().isEmpty)
                return;
              Navigator.pop(ctx);
              setState(
                  () => _processing = policy.id);
              await InsuranceService().rejectPolicy(
                  policy.id, _rejectCtrl.text.trim());
              setState(() => _processing = null);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            child: const Text('Reject',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── LOAN CARD ────────────────────────────────────────────────────
class _LoanCard extends StatefulWidget {
  final LoanModel loan;
  final String filter;
  final String? processing;
  final Function(LoanModel) onApprove;
  final Function(LoanModel) onReject;
  final Function(LoanModel) onDisburse;
  final Function(LoanModel) onClose;
  const _LoanCard({
    required this.loan,
    required this.filter,
    required this.processing,
    required this.onApprove,
    required this.onReject,
    required this.onDisburse,
    required this.onClose,
  });
  @override
  State<_LoanCard> createState() => _LoanCardState();
}

class _LoanCardState extends State<_LoanCard> {
  bool _showDocs = false;
  Map<String, dynamic>? _docs;
  bool _loadingDocs = false;

  Future<void> _loadDocs() async {
    setState(() => _loadingDocs = true);
    try {
      // KYC documents
      final kycSnap = await FirebaseFirestore.instance
          .collection('kyc_documents')
          .where('uid', isEqualTo: widget.loan.uid)
          .get();

      // Loan documents — now split one-per-doc
      final loanSnap = await FirebaseFirestore.instance
          .collection('loan_documents')
          .where('loanId', isEqualTo: widget.loan.id)
          .get();

      final combined = <String, dynamic>{};

      for (final doc in kycSnap.docs) {
        final data = doc.data();
        final key =
            data['docKey'] as String? ?? doc.id;
        combined[key] = data;
      }

      for (final doc in loanSnap.docs) {
        final data = doc.data();
        final key =
            data['docKey'] as String? ?? doc.id;
        combined['loan_$key'] = data;
      }

      setState(() {
        _docs = combined;
        _loadingDocs = false;
        _showDocs = true;
      });
    } catch (e) {
      setState(() {
        _docs = {};
        _loadingDocs = false;
        _showDocs = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProcessing =
        widget.processing == widget.loan.id;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF2D2D4E)),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(children: [
          Expanded(
            child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
              Text(widget.loan.businessName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16)),
              const SizedBox(height: 4),
              Text(
                  '₹${widget.loan.amount.toStringAsFixed(0)}  •  ${widget.loan.tenureMonths} months  •  ${widget.loan.loanType}',
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13)),
              Text(
                  'Purpose: ${widget.loan.purpose}',
                  style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13)),
              Text(
                  'Customer ID: ${widget.loan.customerId}',
                  style: const TextStyle(
                      color: Color(0xFF6C63FF),
                      fontSize: 12,
                      fontFamily: 'monospace')),
              if (widget.loan.annualIncome != null)
                Text(
                    'Annual Income: ₹${widget.loan.annualIncome?.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12)),
              if (widget.loan.collateral != null &&
                  widget.loan.collateral!.isNotEmpty)
                Text(
                    'Collateral: ${widget.loan.collateral}',
                    style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12)),
              if (widget.loan.interestRate != null)
                Text(
                    'Rate: ${widget.loan.interestRate}% p.a.',
                    style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 12)),
              if (widget.loan.rejectionReason != null)
                Text(
                    'Rejection: ${widget.loan.rejectionReason}',
                    style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12)),
            ]),
          ),
          if (isProcessing)
            const CircularProgressIndicator(
                color: Color(0xFF4CAF82), strokeWidth: 2)
          else
            Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
              if (widget.filter == 'pending') ...[
                ElevatedButton(
                  onPressed: () =>
                      widget.onApprove(widget.loan),
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.greenAccent.shade700,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8))),
                  child: const Text('Approve',
                      style: TextStyle(
                          color: Colors.white)),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () =>
                      widget.onReject(widget.loan),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8))),
                  child: const Text('Reject',
                      style: TextStyle(
                          color: Colors.redAccent)),
                ),
              ],
              if (widget.filter == 'approved')
                ElevatedButton(
                  onPressed: () =>
                      widget.onDisburse(widget.loan),
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF6C63FF),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8))),
                  child: const Text('Disburse',
                      style: TextStyle(
                          color: Colors.white)),
                ),
              if (widget.filter == 'active')
                ElevatedButton(
                  onPressed: () =>
                      widget.onClose(widget.loan),
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.greenAccent.shade700,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8))),
                  child: const Text('Close Loan',
                      style: TextStyle(
                          color: Colors.white)),
                ),
            ]),
        ]),

        const SizedBox(height: 12),
        const Divider(color: Color(0xFF2D2D4E)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            if (!_showDocs) {
              _loadDocs();
            } else {
              setState(() => _showDocs = false);
            }
          },
          child: Row(children: [
            Icon(
              _showDocs
                  ? Icons.keyboard_arrow_up
                  : Icons.folder_open_outlined,
              color: const Color(0xFF6C63FF),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              _showDocs
                  ? 'Hide Documents'
                  : 'View Documents',
              style: const TextStyle(
                  color: Color(0xFF6C63FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
            if (_loadingDocs) ...[
              const SizedBox(width: 12),
              const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      color: Color(0xFF6C63FF),
                      strokeWidth: 2)),
            ],
          ]),
        ),

        if (_showDocs && _docs != null) ...[
          const SizedBox(height: 16),
          DocumentViewer(documents: _docs!),
        ],
      ]),
    );
  }
}

// ─── INSURANCE CARD ───────────────────────────────────────────────
class _InsuranceCard extends StatefulWidget {
  final InsuranceModel policy;
  final String filter;
  final String? processing;
  final Function(InsuranceModel) onActivate;
  final Function(InsuranceModel) onReject;
  final Function(InsuranceModel) onSettle;
  final Function(InsuranceModel) onClose;
  const _InsuranceCard({
    required this.policy,
    required this.filter,
    required this.processing,
    required this.onActivate,
    required this.onReject,
    required this.onSettle,
    required this.onClose,
  });
  @override
  State<_InsuranceCard> createState() =>
      _InsuranceCardState();
}

class _InsuranceCardState
    extends State<_InsuranceCard> {
  bool _showDocs = false;
  Map<String, dynamic>? _docs;
  bool _loadingDocs = false;

  Future<void> _loadDocs() async {
    setState(() => _loadingDocs = true);
    try {
      // KYC documents
      final kycSnap = await FirebaseFirestore.instance
          .collection('kyc_documents')
          .where('uid', isEqualTo: widget.policy.uid)
          .get();

      // Insurance documents — now split one-per-doc
      final insuranceSnap =
          await FirebaseFirestore.instance
              .collection('insurance_documents')
              .where('policyId',
                  isEqualTo: widget.policy.id)
              .get();

      final combined = <String, dynamic>{};

      for (final doc in kycSnap.docs) {
        final data = doc.data();
        final key =
            data['docKey'] as String? ?? doc.id;
        combined[key] = data;
      }

      for (final doc in insuranceSnap.docs) {
        final data = doc.data();
        final key =
            data['docKey'] as String? ?? doc.id;
        combined['ins_$key'] = data;
      }

      setState(() {
        _docs = combined;
        _loadingDocs = false;
        _showDocs = true;
      });
    } catch (e) {
      setState(() {
        _docs = {};
        _loadingDocs = false;
        _showDocs = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProcessing =
        widget.processing == widget.policy.id;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF2D2D4E)),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(children: [
          Expanded(
            child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
              Row(children: [
                Text(
                    widget.policy.type == 'trade_credit'
                        ? '🤝'
                        : '🚚',
                    style:
                        const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(widget.policy.businessName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16)),
              ]),
              const SizedBox(height: 4),
              Text(
                  'Type: ${widget.policy.type.replaceAll('_', ' ')}  •  Coverage: ₹${widget.policy.coverageAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13)),
              if (widget.policy.buyerCustomerId != null)
                Text(
                    'Buyer ID: ${widget.policy.buyerCustomerId}',
                    style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12)),
              if (widget.policy.shipmentOrigin != null)
                Text(
                    'Route: ${widget.policy.shipmentOrigin} → ${widget.policy.shipmentDestination}',
                    style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12)),
              if (widget.policy.invoiceValue != null)
                Text(
                    'Invoice Value: ₹${widget.policy.invoiceValue?.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12)),
              if (widget.policy.claimReason != null)
                Text(
                    'Claim: ${widget.policy.claimReason}',
                    style: const TextStyle(
                        color: Color(0xFFFFB347),
                        fontSize: 12)),
              Text(
                  'Customer ID: ${widget.policy.customerId}',
                  style: const TextStyle(
                      color: Color(0xFF6C63FF),
                      fontSize: 12,
                      fontFamily: 'monospace')),
            ]),
          ),
          if (isProcessing)
            const CircularProgressIndicator(
                color: Color(0xFFE07B39), strokeWidth: 2)
          else
            Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
              if (widget.filter == 'pending') ...[
                ElevatedButton(
                  onPressed: () =>
                      widget.onActivate(widget.policy),
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.greenAccent.shade700,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8))),
                  child: const Text('Activate',
                      style: TextStyle(
                          color: Colors.white)),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () =>
                      widget.onReject(widget.policy),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8))),
                  child: const Text('Reject',
                      style: TextStyle(
                          color: Colors.redAccent)),
                ),
              ],
              if (widget.filter == 'claim_filed')
                ElevatedButton(
                  onPressed: () =>
                      widget.onSettle(widget.policy),
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF6C63FF),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8))),
                  child: const Text('Settle Claim',
                      style: TextStyle(
                          color: Colors.white)),
                ),
              if (widget.filter == 'active')
                OutlinedButton(
                  onPressed: () =>
                      widget.onClose(widget.policy),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Colors.white38),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8))),
                  child: const Text('Close Policy',
                      style: TextStyle(
                          color: Colors.white38)),
                ),
            ]),
        ]),

        const SizedBox(height: 12),
        const Divider(color: Color(0xFF2D2D4E)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            if (!_showDocs) {
              _loadDocs();
            } else {
              setState(() => _showDocs = false);
            }
          },
          child: Row(children: [
            Icon(
              _showDocs
                  ? Icons.keyboard_arrow_up
                  : Icons.folder_open_outlined,
              color: const Color(0xFFE07B39),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              _showDocs
                  ? 'Hide Documents'
                  : 'View Documents',
              style: const TextStyle(
                  color: Color(0xFFE07B39),
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
            if (_loadingDocs) ...[
              const SizedBox(width: 12),
              const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      color: Color(0xFFE07B39),
                      strokeWidth: 2)),
            ],
          ]),
        ),

        if (_showDocs && _docs != null) ...[
          const SizedBox(height: 16),
          DocumentViewer(documents: _docs!),
        ],
      ]),
    );
  }
}

class _DialogRow extends StatelessWidget {
  final String label, value;
  const _DialogRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13))),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13))),
      ]),
    );
  }
}