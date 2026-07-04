import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import '../../widgets/workflow_stepper.dart';
import 'dart:typed_data';
import '../../services/watermark_service.dart';

class KycUploadScreen extends StatefulWidget {
  const KycUploadScreen({super.key});
  @override
  State<KycUploadScreen> createState() =>
      _KycUploadScreenState();
}

class _KycUploadScreenState
    extends State<KycUploadScreen> {
  final Map<String, PlatformFile?> _files = {
    'GST Certificate': null,
    'PAN Card': null,
    'Aadhaar Card': null,
    'Bank Statement': null,
  };
  bool _loading = false;
  String? _error;
  String _uploadProgress = '';
  bool _isResubmission = false;
  String? _previousRejectionReason;

  @override
  void initState() {
    super.initState();
    _checkIfResubmission();
  }

  Future<void> _checkIfResubmission() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (doc.exists && mounted) {
      final data = doc.data()!;
      final status = data['kycStatus'] as String? ?? '';
      if (status == 'rejected') {
        setState(() {
          _isResubmission = true;
          _previousRejectionReason =
              data['rejectionReason'] as String?;
        });
      }
    }
  }

  Future<void> _pickFile(String docType) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
        allowCompression: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Could not read file. Please try again.'),
                  backgroundColor: Colors.redAccent),
            );
          }
          return;
        }
        if (file.size > 700 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('File too large. Please use a file under 700KB.'),
                  backgroundColor: Colors.redAccent),
            );
          }
          return;
        }
        setState(() => _files[docType] = file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error selecting file: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _submitDocuments() async {
    if (_files.values.any((f) => f == null)) {
      setState(() =>
          _error = 'Please upload all 4 required documents');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _uploadProgress = 'Preparing documents...';
    });

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Get user info for watermark text
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final customerId =
          userDoc.data()?['customerId'] as String? ??
              uid.substring(0, 8);
      final businessName =
          userDoc.data()?['businessName'] as String? ??
              '';
      final watermarkText = WatermarkService
          .buildWatermarkText(customerId, businessName);

      // Delete old docs if resubmitting
      if (_isResubmission) {
        setState(() =>
            _uploadProgress =
                'Clearing previous submission...');
        final oldDocs = await FirebaseFirestore.instance
            .collection('kyc_documents')
            .where('uid', isEqualTo: uid)
            .get();
        final batch =
            FirebaseFirestore.instance.batch();
        for (final doc in oldDocs.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      int count = 0;
      for (final entry in _files.entries) {
        count++;
        final docKey = entry.key
            .replaceAll(' ', '_')
            .toLowerCase();
        final file = entry.value!;

        setState(() => _uploadProgress =
            'Watermarking ${entry.key} ($count/4)...');

        // Watermark before encoding
        Uint8List processedBytes;
        try {
          processedBytes =
              await WatermarkService.watermarkImage(
            file.bytes!,
            file.extension ?? 'pdf',
            watermarkText,
          );
        } catch (_) {
          // Watermarking failed — use original bytes
          processedBytes = file.bytes!;
        }

        setState(() => _uploadProgress =
            'Uploading ${entry.key} ($count/4)...');

        final base64String =
            base64Encode(processedBytes);

        await FirebaseFirestore.instance
            .collection('kyc_documents')
            .doc('${uid}_$docKey')
            .set({
          'uid': uid,
          'docType': entry.key,
          'docKey': docKey,
          'fileName': file.name,
          'fileSize': file.size,
          'extension': file.extension ?? 'pdf',
          'data': base64String,
          'watermarked': true,
          'watermarkText': watermarkText,
          'uploadedAt': DateTime.now().toIso8601String(),
        });
      }

      setState(() =>
          _uploadProgress = 'Resetting review status...');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
        'kycStatus': 'pending',
        'kycSubmitted': true,
        'rejectionReason': FieldValue.delete(),
        'resubmittedAt':
            _isResubmission
                ? DateTime.now().toIso8601String()
                : null,
        'isResubmission': _isResubmission,
      });

      setState(() =>
          _uploadProgress = 'Verifying submission...');

      // Verify write succeeded before navigating
      final verifyDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final verifiedStatus =
          verifyDoc.data()?['kycStatus'] as String?;

      if (verifiedStatus != 'pending') {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({
          'kycStatus': 'pending',
          'rejectionReason': FieldValue.delete(),
        });
      }

      if (!mounted) return;
      context.go('/pending');
    } catch (e) {
      setState(() {
        _error = 'Upload failed: $e';
        _uploadProgress = '';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final allUploaded =
        _files.values.every((f) => f != null);
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(40),
          margin: const EdgeInsets.symmetric(vertical: 32),
          decoration: BoxDecoration(
            color: const Color(0xFF16162A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFF6C63FF)
                    .withOpacity(0.3)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                WorkflowStepper(
                  steps: Workflows.onboarding,
                  currentStep: _isResubmission ? 3 : 3,
                  color: const Color(0xFF6C63FF),
                ),
                const SizedBox(height: 24),
                Text(
                    _isResubmission
                        ? 'Resubmit KYC Documents'
                        : 'KYC Documents',
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 4),
                const Text(
                    'Upload clear copies — PDF, JPG or PNG, max 700KB each',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13)),

                // Rejection reason banner
                if (_isResubmission) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.redAccent
                          .withOpacity(0.08),
                      borderRadius:
                          BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.redAccent
                              .withOpacity(0.3)),
                    ),
                    child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                      const Row(children: [
                        Icon(Icons.history,
                            color: Colors.redAccent,
                            size: 16),
                        SizedBox(width: 8),
                        Text(
                            'Previous Application Rejected',
                            style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ]),
                      if (_previousRejectionReason !=
                          null) ...[
                        const SizedBox(height: 6),
                        Text(
                            'Reason: $_previousRejectionReason',
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12)),
                      ],
                      const SizedBox(height: 6),
                      const Text(
                          'Please address the issue above and re-upload all 4 documents. Your application will go back into the admin\'s review queue.',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              height: 1.4)),
                    ]),
                  ),
                ],

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF)
                        .withOpacity(0.08),
                    borderRadius:
                        BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF6C63FF)
                            .withOpacity(0.2)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.info_outline,
                        color: Color(0xFF6C63FF),
                        size: 14),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                          'Each document is uploaded separately to stay within storage limits.',
                          style: TextStyle(
                              color: Color(0xFF6C63FF),
                              fontSize: 11)),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),

                ..._files.keys.map((docType) {
                  final file = _files[docType];
                  return GestureDetector(
                    onTap: _loading
                        ? null
                        : () => _pickFile(docType),
                    child: Container(
                      margin: const EdgeInsets.only(
                          bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: file != null
                            ? const Color(0xFF1A3A2A)
                            : const Color(0xFF0D0D1A),
                        borderRadius:
                            BorderRadius.circular(10),
                        border: Border.all(
                          color: file != null
                              ? Colors.greenAccent
                              : const Color(0xFF2D2D4E),
                        ),
                      ),
                      child: Row(children: [
                        Icon(
                          file != null
                              ? Icons.check_circle
                              : Icons.upload_file_rounded,
                          color: file != null
                              ? Colors.greenAccent
                              : Colors.white38,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                            Text(docType,
                                style: TextStyle(
                                    color: file != null
                                        ? Colors
                                            .greenAccent
                                        : Colors.white,
                                    fontWeight:
                                        FontWeight.w500)),
                            const SizedBox(height: 2),
                            if (file != null)
                              Text(
                                  '${file.name}  •  ${_formatSize(file.size)}',
                                  style: const TextStyle(
                                      color:
                                          Colors.white54,
                                      fontSize: 12))
                            else
                              const Text(
                                  'Tap to upload — max 700KB',
                                  style: TextStyle(
                                      color:
                                          Colors.white38,
                                      fontSize: 12)),
                          ]),
                        ),
                        if (file != null)
                          const Icon(Icons.edit_rounded,
                              color: Colors.white38,
                              size: 16),
                      ]),
                    ),
                  );
                }),

                const SizedBox(height: 8),
                Row(children: [
                  Text(
                      '${_files.values.where((f) => f != null).length} of 4 uploaded',
                      style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: _files.values
                              .where((f) => f != null)
                              .length /
                          4,
                      backgroundColor:
                          const Color(0xFF2D2D4E),
                      color: allUploaded
                          ? Colors.greenAccent
                          : const Color(0xFF6C63FF),
                    ),
                  ),
                ]),

                if (_loading &&
                    _uploadProgress.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF)
                          .withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFF6C63FF)
                              .withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Color(0xFF6C63FF),
                            strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(_uploadProgress,
                            style: const TextStyle(
                                color: Color(0xFF6C63FF),
                                fontSize: 13)),
                      ),
                    ]),
                  ),
                ],

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
                    onPressed:
                        (_loading || !allUploaded)
                            ? null
                            : _submitDocuments,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: allUploaded
                          ? const Color(0xFF6C63FF)
                          : const Color(0xFF2D2D4E),
                      padding:
                          const EdgeInsets.symmetric(
                              vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10)),
                    ),
                    child: _loading
                        ? const Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(
                                          color:
                                              Colors.white,
                                          strokeWidth: 2)),
                              SizedBox(width: 12),
                              Text('Uploading...',
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white)),
                            ],
                          )
                        : Text(
                            _isResubmission
                                ? 'Resubmit for Review'
                                : 'Submit for Review',
                            style: const TextStyle(
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
}