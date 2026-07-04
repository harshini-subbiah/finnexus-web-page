import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import '../../services/product_service.dart';
import '../../services/firestore_service.dart';
import '../../models/product_model.dart';

class VendorProductsScreen extends StatefulWidget {
  const VendorProductsScreen({super.key});
  @override
  State<VendorProductsScreen> createState() =>
      _VendorProductsScreenState();
}

class _VendorProductsScreenState
    extends State<VendorProductsScreen> {
  bool _showForm = false;

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _b2cPriceCtrl = TextEditingController();
  final _b2bPriceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  String _category = 'Electronics';
  bool _saving = false;
  PlatformFile? _imageFile;
  String? _imageError;

  final _categories = [
    'Electronics',
    'Raw Materials',
    'Machinery',
    'FMCG',
    'Textiles',
    'Other'
  ];

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes == null) return;
        if (file.size > 600 * 1024) {
          setState(() =>
              _imageError = 'Image must be under 600KB');
          return;
        }
        setState(() {
          _imageFile = file;
          _imageError = null;
        });
      }
    } catch (e) {
      setState(() => _imageError = 'Could not load image');
    }
  }

  Future<void> _saveProduct() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _b2cPriceCtrl.text.trim().isEmpty) return;

    setState(() => _saving = true);
    try {
      final uid =
          FirebaseAuth.instance.currentUser!.uid;
      final user =
          await FirestoreService().getUser(uid);

      String? imageBase64;
      if (_imageFile != null) {
        imageBase64 = base64Encode(_imageFile!.bytes!);
      }

      final product = ProductModel(
        id: const Uuid().v4(),
        vendorUid: uid,
        vendorName: user?.businessName ?? '',
        vendorCustomerId: user?.customerId ?? '',
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _category,
        b2cPrice: double.tryParse(
                _b2cPriceCtrl.text.trim()) ??
            0,
        b2bPrice: _b2bPriceCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(
                _b2bPriceCtrl.text.trim()),
        stockQuantity:
            int.tryParse(_stockCtrl.text.trim()) ??
                0,
        unit: _unitCtrl.text.trim().isEmpty
            ? 'piece'
            : _unitCtrl.text.trim(),
        imageUrls: [],
        imageBase64: imageBase64,
        rating: 0,
        ratingCount: 0,
        isActive: true,
        createdAt: DateTime.now(),
      );
      await ProductService().addProduct(product);
      setState(() {
        _showForm = false;
        _imageFile = null;
      });
      _nameCtrl.clear();
      _descCtrl.clear();
      _b2cPriceCtrl.clear();
      _b2bPriceCtrl.clear();
      _stockCtrl.clear();
      _unitCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Product added!'),
              backgroundColor: Colors.greenAccent),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16162A),
        title: const Text('My Products',
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Colors.white),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          TextButton.icon(
            onPressed: () =>
                setState(() => _showForm = !_showForm),
            icon: Icon(
                _showForm ? Icons.close : Icons.add,
                color: const Color(0xFFFF8C42)),
            label: Text(
                _showForm ? 'Cancel' : 'Add Product',
                style: const TextStyle(
                    color: Color(0xFFFF8C42))),
          ),
        ],
      ),
      body: Column(children: [
        if (_showForm)
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF12121E),
            child: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                const Text('Add New Product',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 16),

                // Image upload
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0D1A),
                      borderRadius:
                          BorderRadius.circular(10),
                      border: Border.all(
                          color: _imageFile != null
                              ? Colors.greenAccent
                              : const Color(0xFF2D2D4E)),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius:
                                BorderRadius.circular(10),
                            child: Image.memory(
                              _imageFile!.bytes!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 140,
                            ),
                          )
                        : const Center(
                            child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,
                                children: [
                              Icon(
                                  Icons
                                      .add_photo_alternate_outlined,
                                  color: Colors.white38,
                                  size: 32),
                              SizedBox(height: 6),
                              Text(
                                  'Tap to upload product image\n(max 600KB)',
                                  textAlign:
                                      TextAlign.center,
                                  style: TextStyle(
                                      color:
                                          Colors.white38,
                                      fontSize: 12)),
                            ]),
                          ),
                  ),
                ),
                if (_imageError != null)
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 6),
                    child: Text(_imageError!,
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12)),
                  ),
                if (_imageFile != null)
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 6),
                    child: TextButton.icon(
                      onPressed: () => setState(
                          () => _imageFile = null),
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent,
                          size: 16),
                      label: const Text('Remove image',
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12)),
                    ),
                  ),

                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                      child: _field('Product Name *',
                          _nameCtrl)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _field(
                          'Unit (e.g. kg, piece)',
                          _unitCtrl)),
                ]),
                const SizedBox(height: 12),
                _field('Description', _descCtrl,
                    maxLines: 2),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: _field('B2C Price (₹) *',
                          _b2cPriceCtrl)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _field('B2B Price (₹)',
                          _b2bPriceCtrl)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _field('Stock Qty *',
                          _stockCtrl)),
                ]),
                const SizedBox(height: 12),
                const Text('Category',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _categories.map((c) {
                    final sel = _category == c;
                    return GestureDetector(
                      onTap: () => setState(
                          () => _category = c),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6),
                        decoration: BoxDecoration(
                          color: sel
                              ? const Color(0xFFFF8C42)
                                  .withOpacity(0.2)
                              : const Color(0xFF16162A),
                          borderRadius:
                              BorderRadius.circular(6),
                          border: Border.all(
                              color: sel
                                  ? const Color(
                                      0xFFFF8C42)
                                  : const Color(
                                      0xFF2D2D4E)),
                        ),
                        child: Text(c,
                            style: TextStyle(
                                color: sel
                                    ? const Color(
                                        0xFFFF8C42)
                                    : Colors.white54,
                                fontSize: 12)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed:
                      _saving ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFFFF8C42),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8))),
                  child: _saving
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2)
                      : const Text('Save Product',
                          style: TextStyle(
                              color: Colors.white)),
                ),
              ]),
            ),
          ),

        Expanded(
          child: StreamBuilder<List<ProductModel>>(
            stream: ProductService()
                .streamVendorProducts(uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFFF8C42)));
              }
              final products = snapshot.data!;
              if (products.isEmpty) {
                return const Center(
                    child: Text(
                        'No products yet. Add your first product.',
                        style: TextStyle(
                            color: Colors.white38)));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: products.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final p = products[i];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16162A),
                      borderRadius:
                          BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              const Color(0xFF2D2D4E)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8C42)
                              .withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(8),
                        ),
                        child: p.imageBase64 != null
                            ? ClipRRect(
                                borderRadius:
                                    BorderRadius
                                        .circular(8),
                                child: Image.memory(
                                  base64Decode(
                                      p.imageBase64!),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(
                                Icons.inventory_2_outlined,
                                color: Colors.white24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                          child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                        Text(p.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight:
                                    FontWeight.w600)),
                        Text(p.category,
                            style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 12)),
                        Text(
                            'B2C: ₹${p.b2cPrice}${p.b2bPrice != null ? '  •  B2B: ₹${p.b2bPrice}' : ''}',
                            style: const TextStyle(
                                color:
                                    Color(0xFFFF8C42),
                                fontSize: 13)),
                        Text(
                            'Stock: ${p.stockQuantity} ${p.unit}',
                            style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12)),
                      ])),
                      Column(children: [
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3),
                          decoration: BoxDecoration(
                            color: p.isActive
                                ? Colors.greenAccent
                                    .withOpacity(0.1)
                                : Colors.redAccent
                                    .withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(
                                    4),
                          ),
                          child: Text(
                              p.isActive
                                  ? 'Active'
                                  : 'Inactive',
                              style: TextStyle(
                                  color: p.isActive
                                      ? Colors
                                          .greenAccent
                                      : Colors
                                          .redAccent,
                                  fontSize: 11)),
                        ),
                        IconButton(
                          icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 20),
                          onPressed: () =>
                              ProductService()
                                  .deleteProduct(p.id),
                        ),
                      ]),
                    ]),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _field(String label,
      TextEditingController ctrl,
      {int maxLines = 1}) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      Text(label,
          style: const TextStyle(
              color: Colors.white70, fontSize: 12)),
      const SizedBox(height: 4),
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFF0D0D1A),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 10),
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
                  color: Color(0xFFFF8C42))),
        ),
      ),
    ]);
  }
}