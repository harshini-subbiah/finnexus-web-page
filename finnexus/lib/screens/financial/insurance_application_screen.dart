import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../services/insurance_service.dart';
import '../../services/firestore_service.dart';
import '../../services/watermark_service.dart';
import '../../models/insurance_model.dart';
import '../../widgets/document_upload_widget.dart';
import '../../widgets/workflow_stepper.dart';

class InsuranceApplicationScreen extends StatefulWidget {
  const InsuranceApplicationScreen({super.key});
  @override
  State<InsuranceApplicationScreen> createState() =>
      _InsuranceApplicationScreenState();
}

class _InsuranceApplicationScreenState
    extends State<InsuranceApplicationScreen> {
  int _step = 0;
  Map<String, dynamic>? _selectedInsurer;
  String _type = 'trade_credit';

  final _coverageCtrl = TextEditingController();
  final _buyerIdCtrl = TextEditingController();
  final _buyerNameCtrl = TextEditingController();
  final _invoiceCtrl = TextEditingController();
  final _creditPeriodCtrl = TextEditingController();
  final _tradeHistoryCtrl = TextEditingController();
  final _shipmentValueCtrl = TextEditingController();
  final _goodsDescCtrl = TextEditingController();
  final _originCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  String _transportMode = 'Road';

  final Map<String, PlatformFile?> _insuranceDocs = {
    'Invoice / Contract': null,
    'Business Registration': null,
    'Previous Insurance (if any)': null,
  };

  bool _loading = false;
  String? _error;

  final _transportModes = [
    'Road', 'Rail', 'Air', 'Sea', 'Multi-modal'
  ];

  @override
  void dispose() {
    _coverageCtrl.dispose();
    _buyerIdCtrl.dispose();
    _buyerNameCtrl.dispose();
    _invoiceCtrl.dispose();
    _creditPeriodCtrl.dispose();
    _tradeHistoryCtrl.dispose();
    _shipmentValueCtrl.dispose();
    _goodsDescCtrl.dispose();
    _originCtrl.dispose();
    _destCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedInsurer == null) {
      setState(() => _error = 'No insurer selected');
      return;
    }
    if (_coverageCtrl.text.trim().isEmpty) {
      setState(
          () => _error = 'Coverage amount is required');
      return;
    }
    final coverage =
        double.tryParse(_coverageCtrl.text.trim());
    if (coverage == null || coverage <= 0) {
      setState(() =>
          _error = 'Enter a valid coverage amount');
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

      // Generate policyId first so both document
      // saves and the policy record use the same ID
      final policyId = const Uuid().v4();

      // Build watermark text from user info
      final watermarkText =
          WatermarkService.buildWatermarkText(
              user?.customerId ?? uid.substring(0, 8),
              user?.businessName ?? '');

      // Save each insurance document as its own
      // Firestore document (avoids 1MB limit).
      // Each image is watermarked before encoding.
      for (final entry in _insuranceDocs.entries) {
        if (entry.value != null) {
          final file = entry.value!;
          final docKey = entry.key
              .replaceAll(' ', '_')
              .replaceAll('/', '')
              .replaceAll('(', '')
              .replaceAll(')', '')
              .toLowerCase();

          // Watermark image files; PDFs are returned
          // unchanged by WatermarkService
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
              .collection('insurance_documents')
              .doc('${policyId}_$docKey')
              .set({
            'policyId': policyId,
            'uid': uid,
            'docType': entry.key,
            'docKey': docKey,
            'fileName': file.name,
            'fileSize': file.size,
            'extension': file.extension ?? 'pdf',
            'data': base64Encode(processedBytes),
            'watermarked': true,
            'watermarkText': watermarkText,
            'uploadedAt':
                DateTime.now().toIso8601String(),
          });
        }
      }

      final policy = InsuranceModel(
        id: policyId,
        uid: uid,
        customerId: user?.customerId ?? '',
        businessName: user?.businessName ?? '',
        insurerUid:
            _selectedInsurer!['uid'] as String? ?? '',
        insurerName:
            _selectedInsurer!['businessName']
                    as String? ??
                '',
        type: _type,
        status: 'pending',
        coverageAmount: coverage,
        buyerCustomerId: _type == 'trade_credit'
            ? _buyerIdCtrl.text.trim()
            : null,
        buyerBusinessName: _type == 'trade_credit'
            ? _buyerNameCtrl.text.trim()
            : null,
        invoiceValue: _type == 'trade_credit'
            ? double.tryParse(_invoiceCtrl.text.trim())
            : null,
        creditPeriodDays: _type == 'trade_credit'
            ? int.tryParse(
                _creditPeriodCtrl.text.trim())
            : null,
        tradeHistory: _type == 'trade_credit'
            ? _tradeHistoryCtrl.text.trim()
            : null,
        shipmentValue: _type == 'goods_in_transit'
            ? double.tryParse(
                _shipmentValueCtrl.text.trim())
            : null,
        goodsDescription: _type == 'goods_in_transit'
            ? _goodsDescCtrl.text.trim()
            : null,
        shipmentOrigin: _type == 'goods_in_transit'
            ? _originCtrl.text.trim()
            : null,
        shipmentDestination:
            _type == 'goods_in_transit'
                ? _destCtrl.text.trim()
                : null,
        transportMode: _type == 'goods_in_transit'
            ? _transportMode
            : null,
        createdAt: DateTime.now(),
      );

      await InsuranceService().applyInsurance(policy);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Insurance application submitted!'),
            backgroundColor: Colors.greenAccent),
      );
      context.go('/dashboard');
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
        title: Text(
          _step == 0
              ? 'Choose an Insurer'
              : _step == 1
                  ? 'Select Policy Type'
                  : 'Application Details',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Colors.white),
          onPressed: () {
            if (_step > 0) {
              setState(() => _step--);
            } else {
              context.go('/dashboard');
            }
          },
        ),
      ),
      body: _step == 0
          ? _insurerPickerView()
          : _step == 1
              ? _typePickerView()
              : _formView(),
    );
  }

  Widget _insurerPickerView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('business_profiles')
          .where('role', isEqualTo: 'insurer')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(
                      color: Colors.redAccent)));
        }
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFFE07B39)));
        }
        final insurers = snapshot.data!.docs;
        if (insurers.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined,
                    color: Colors.white24, size: 64),
                SizedBox(height: 16),
                Text('No insurers available yet',
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 16)),
                SizedBox(height: 8),
                Text(
                    'An insurer must register and set up their profile first',
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
            const WorkflowStepper(
              steps: Workflows.insuranceApplication,
              currentStep: 0,
              color: Color(0xFFE07B39),
            ),
            const SizedBox(height: 24),
            const Text('Select an Insurer',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 6),
            const Text(
                'Choose the insurer you want to apply to',
                style:
                    TextStyle(color: Colors.white54)),
            const SizedBox(height: 20),
            ...insurers.map((doc) {
              final data =
                  doc.data() as Map<String, dynamic>;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedInsurer = data;
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
                        color: const Color(0xFFE07B39)
                            .withOpacity(0.4)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE07B39)
                            .withOpacity(0.15),
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: const Center(
                          child: Text('🛡️',
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
                              data['businessName'] ?? '',
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
                          if (data['productsOffered'] !=
                              null)
                            Text(
                                'Products: ${data['productsOffered']}',
                                style: const TextStyle(
                                    color:
                                        Color(0xFFE07B39),
                                    fontSize: 12)),
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

  Widget _typePickerView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        const WorkflowStepper(
          steps: Workflows.insuranceApplication,
          currentStep: 1,
          color: Color(0xFFE07B39),
        ),
        const SizedBox(height: 24),
        const Text('Select Policy Type',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 6),
        const Text(
            'Choose the type of insurance you need',
            style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 24),
        _TypeCard(
          icon: '🤝',
          title: 'Trade Credit Insurance',
          desc:
              'Protects your business if a buyer defaults on payment.',
          selected: _type == 'trade_credit',
          onTap: () =>
              setState(() => _type = 'trade_credit'),
        ),
        const SizedBox(height: 16),
        _TypeCard(
          icon: '🚚',
          title: 'Goods in Transit Insurance',
          desc:
              'Covers your goods against loss or damage during transportation.',
          selected: _type == 'goods_in_transit',
          onTap: () => setState(
              () => _type = 'goods_in_transit'),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => setState(() => _step = 2),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE07B39),
              padding: const EdgeInsets.symmetric(
                  vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(10)),
            ),
            child: const Text('Continue',
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.white)),
          ),
        ),
      ]),
    );
  }

  Widget _formView() {
    if (_selectedInsurer == null) {
      return const Center(
          child: Text(
              'Something went wrong. Go back and try again.',
              style:
                  TextStyle(color: Colors.redAccent)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        const WorkflowStepper(
          steps: Workflows.insuranceApplication,
          currentStep: 2,
          color: Color(0xFFE07B39),
        ),
        const SizedBox(height: 24),

        // Insurer banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE07B39)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: const Color(0xFFE07B39)
                    .withOpacity(0.4)),
          ),
          child: Row(children: [
            const Text('🛡️',
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
                  _selectedInsurer!['businessName']
                          ?.toString() ??
                      '',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
              Text(
                _type == 'trade_credit'
                    ? '🤝 Trade Credit Insurance'
                    : '🚚 Goods in Transit Insurance',
                style: const TextStyle(
                    color: Color(0xFFE07B39),
                    fontSize: 13),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 24),

        _field('Coverage Amount Required (₹) *',
            _coverageCtrl,
            hint: 'e.g. 500000'),
        const SizedBox(height: 20),

        if (_type == 'trade_credit') ...[
          _sectionTitle('Buyer Information'),
          const SizedBox(height: 12),
          _field("Buyer's Customer ID *", _buyerIdCtrl,
              hint: 'e.g. FNX-CUS-2025-00002'),
          const SizedBox(height: 12),
          _field("Buyer's Business Name *",
              _buyerNameCtrl,
              hint: 'Registered business name'),
          const SizedBox(height: 12),
          _field('Invoice Value (₹) *', _invoiceCtrl,
              hint:
                  'Total invoice amount to be covered'),
          const SizedBox(height: 12),
          _field('Credit Period (Days) *',
              _creditPeriodCtrl,
              hint: 'e.g. 90'),
          const SizedBox(height: 12),
          _field('Trade History with Buyer',
              _tradeHistoryCtrl,
              hint:
                  'How long have you traded? Any past defaults?',
              maxLines: 3),
        ],

        if (_type == 'goods_in_transit') ...[
          _sectionTitle('Shipment Details'),
          const SizedBox(height: 12),
          _field('Goods Description *', _goodsDescCtrl,
              hint: 'Describe the goods being shipped',
              maxLines: 2),
          const SizedBox(height: 12),
          _field('Shipment Value (₹) *',
              _shipmentValueCtrl,
              hint: 'Total value of goods'),
          const SizedBox(height: 12),
          _field('Origin (From) *', _originCtrl,
              hint: 'City, State'),
          const SizedBox(height: 12),
          _field('Destination (To) *', _destCtrl,
              hint: 'City, State'),
          const SizedBox(height: 12),
          const Text('Mode of Transport *',
              style: TextStyle(
                  color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _transportModes.map((m) {
              final sel = _transportMode == m;
              return GestureDetector(
                onTap: () =>
                    setState(() => _transportMode = m),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel
                        ? const Color(0xFFE07B39)
                            .withOpacity(0.2)
                        : const Color(0xFF16162A),
                    borderRadius:
                        BorderRadius.circular(8),
                    border: Border.all(
                        color: sel
                            ? const Color(0xFFE07B39)
                            : const Color(0xFF2D2D4E)),
                  ),
                  child: Text(m,
                      style: TextStyle(
                          color: sel
                              ? const Color(0xFFE07B39)
                              : Colors.white54,
                          fontSize: 13)),
                ),
              );
            }).toList(),
          ),
        ],

        const SizedBox(height: 24),
        _sectionTitle('Supporting Documents'),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFE07B39)
                .withOpacity(0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: const Color(0xFFE07B39)
                    .withOpacity(0.2)),
          ),
          child: const Row(children: [
            Icon(Icons.verified_outlined,
                color: Color(0xFFE07B39), size: 14),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                  'Images will be watermarked with your Customer ID before upload.',
                  style: TextStyle(
                      color: Color(0xFFE07B39),
                      fontSize: 11)),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        DocumentUploadWidget(
          files: _insuranceDocs,
          onFileSelected: (docType, file) {
            setState(
                () => _insuranceDocs[docType] = file);
          },
        ),

        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: Colors.redAccent
                      .withOpacity(0.4)),
            ),
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
              backgroundColor: const Color(0xFFE07B39),
              padding: const EdgeInsets.symmetric(
                  vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(10)),
            ),
            child: _loading
                ? const CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2)
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
                  color: Color(0xFFE07B39))),
        ),
      ),
    ]);
  }
}

class _TypeCard extends StatelessWidget {
  final String icon, title, desc;
  final bool selected;
  final VoidCallback onTap;
  const _TypeCard(
      {required this.icon,
      required this.title,
      required this.desc,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFE07B39).withOpacity(0.1)
              : const Color(0xFF16162A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected
                  ? const Color(0xFFE07B39)
                  : const Color(0xFF2D2D4E),
              width: selected ? 2 : 1),
        ),
        child: Row(children: [
          Text(icon,
              style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
            Text(title,
                style: TextStyle(
                    color: selected
                        ? const Color(0xFFE07B39)
                        : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
            const SizedBox(height: 4),
            Text(desc,
                style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    height: 1.4)),
          ])),
          if (selected)
            const Icon(Icons.check_circle,
                color: Color(0xFFE07B39)),
        ]),
      ),
    );
  }
}