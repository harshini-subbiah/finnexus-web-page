import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import '../../services/product_service.dart';
import '../../services/firestore_service.dart';
import '../../services/product_chat_service.dart';
import '../../models/product_model.dart';
import '../../widgets/workflow_stepper.dart';

class CartState {
  static final List<Map<String, dynamic>> items = [];
  static String customerType = 'b2c';

  static void addItem(ProductModel p, {int quantity = 1}) {
    final idx =
        items.indexWhere((i) => i['productId'] == p.id);
    if (idx >= 0) {
      items[idx]['quantity'] += quantity;
    } else {
      items.add({
        'productId': p.id,
        'product': p,
        'quantity': quantity,
      });
    }
  }

  static int get totalCount =>
      items.fold(0, (s, i) => s + (i['quantity'] as int));

  static void clear() => items.clear();
}

class ProductCatalogueScreen extends StatefulWidget {
  const ProductCatalogueScreen({super.key});
  @override
  State<ProductCatalogueScreen> createState() =>
      _ProductCatalogueScreenState();
}

class _ProductCatalogueScreenState
    extends State<ProductCatalogueScreen> {
  String _search = '';
  String _category = 'All';
  String _selectedVendor = 'All Vendors';
  int _cartCount = 0;

  final _categories = [
    'All',
    'Electronics',
    'Raw Materials',
    'Machinery',
    'FMCG',
    'Textiles',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserType();
    _cartCount = CartState.totalCount;
  }

  Future<void> _loadUserType() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final user = await FirestoreService().getUser(uid);
    if (user != null && mounted) {
      CartState.customerType =
          (user.role == 'vendor' ||
                  user.role == 'lender' ||
                  user.role == 'advisor')
              ? 'b2b'
              : 'b2c';
      setState(() {});
    }
  }

  void _addToCart(ProductModel p, int qty) {
    CartState.addItem(p, quantity: qty);
    setState(() => _cartCount = CartState.totalCount);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$qty × ${p.name} added to cart'),
        backgroundColor: Colors.greenAccent.shade700,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _openChat(ProductModel p) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final user = await FirestoreService().getUser(uid);
    final chatId =
        await ProductChatService().getOrCreateChat(
      productId: p.id,
      productName: p.name,
      buyerUid: uid,
      buyerName: user?.businessName ?? '',
      vendorUid: p.vendorUid,
      vendorName: p.vendorName,
    );
    if (mounted) {
      context.go('/product-chat',
          extra: {'chatId': chatId});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16162A),
        title: const Text('Product Catalogue',
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Colors.white),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(
                vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D1A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFF2D2D4E)),
            ),
            child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
              _typeBtn('B2C', 'b2c'),
              _typeBtn('B2B', 'b2b'),
            ]),
          ),
          Stack(children: [
            IconButton(
              icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.white),
              onPressed: () => context.go('/cart'),
            ),
            if (_cartCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Text('$_cartCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ),
          ]),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: ProductService().streamAllProducts(
            category: _category, search: _search),
        builder: (context, snapshot) {
          final allProducts = snapshot.data ?? [];
          final vendorNames = <String>{'All Vendors'};
          for (final p in allProducts) {
            vendorNames.add(p.vendorName);
          }

          final filtered =
              _selectedVendor == 'All Vendors'
                  ? allProducts
                  : allProducts
                      .where((p) =>
                          p.vendorName == _selectedVendor)
                      .toList();

          return Column(children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF12121E),
              child: Column(children: [
                TextField(
                  onChanged: (v) =>
                      setState(() => _search = v),
                  style: const TextStyle(
                      color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    hintStyle: const TextStyle(
                        color: Colors.white30),
                    prefixIcon: const Icon(Icons.search,
                        color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF0D0D1A),
                    contentPadding:
                        const EdgeInsets.symmetric(
                            vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF2D2D4E))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF2D2D4E))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF6C63FF))),
                  ),
                ),
                const SizedBox(height: 10),

                // Category filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((c) {
                      final isActive = _category == c;
                      return GestureDetector(
                        onTap: () => setState(
                            () => _category = c),
                        child: Container(
                          margin: const EdgeInsets.only(
                              right: 8),
                          padding: const EdgeInsets
                              .symmetric(
                              horizontal: 14,
                              vertical: 7),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF6C63FF)
                                : const Color(0xFF16162A),
                            borderRadius:
                                BorderRadius.circular(20),
                            border: Border.all(
                                color: isActive
                                    ? const Color(
                                        0xFF6C63FF)
                                    : const Color(
                                        0xFF2D2D4E)),
                          ),
                          child: Text(c,
                              style: TextStyle(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.white54,
                                  fontSize: 12,
                                  fontWeight: isActive
                                      ? FontWeight.w600
                                      : FontWeight
                                          .normal)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),

                // Vendor dropdown
                Row(children: [
                  const Icon(Icons.storefront,
                      color: Colors.white38, size: 16),
                  const SizedBox(width: 8),
                  const Text('Vendor:',
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 13)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D0D1A),
                        borderRadius:
                            BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(
                                0xFF2D2D4E)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: vendorNames.contains(
                                  _selectedVendor)
                              ? _selectedVendor
                              : 'All Vendors',
                          isExpanded: true,
                          dropdownColor:
                              const Color(0xFF16162A),
                          icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white54),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13),
                          items: vendorNames.map((v) {
                            return DropdownMenuItem(
                                value: v,
                                child: Text(v));
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() =>
                                  _selectedVendor = v);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ]),
              ]),
            ),

            // Order workflow banner
            const _OrderWorkflowBanner(),

            Expanded(
              child: !snapshot.hasData
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF6C63FF)))
                  : filtered.isEmpty
                      ? const Center(
                          child: Text(
                              'No products found',
                              style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 16)))
                      : GridView.builder(
                          padding:
                              const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 0.62,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) =>
                              _ProductCard(
                            product: filtered[i],
                            customerType:
                                CartState.customerType,
                            onAddToCart: (qty) =>
                                _addToCart(
                                    filtered[i], qty),
                            onChat: () =>
                                _openChat(filtered[i]),
                          ),
                        ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _typeBtn(String label, String value) {
    final sel = CartState.customerType == value;
    return GestureDetector(
      onTap: () =>
          setState(() => CartState.customerType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: sel
              ? const Color(0xFF6C63FF)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: TextStyle(
                color:
                    sel ? Colors.white : Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Order workflow collapsible banner ────────────────
class _OrderWorkflowBanner extends StatefulWidget {
  const _OrderWorkflowBanner();
  @override
  State<_OrderWorkflowBanner> createState() =>
      _OrderWorkflowBannerState();
}

class _OrderWorkflowBannerState
    extends State<_OrderWorkflowBanner> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF12121E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFF6C63FF)
                .withOpacity(0.2)),
      ),
      child: Column(children: [
        GestureDetector(
          onTap: () =>
              setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            child: Row(children: [
              const Icon(Icons.info_outline,
                  color: Color(0xFF6C63FF), size: 15),
              const SizedBox(width: 8),
              const Text('How ordering works',
                  style: TextStyle(
                      color: Color(0xFF6C63FF),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: const Color(0xFF6C63FF),
                  size: 16),
            ]),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                12, 0, 12, 12),
            child: const WorkflowStepper(
              steps: Workflows.orderPlacement,
              currentStep: 0,
              color: Color(0xFF6C63FF),
            ),
          ),
      ]),
    );
  }
}

// ── Product Card ─────────────────────────────────────
class _ProductCard extends StatefulWidget {
  final ProductModel product;
  final String customerType;
  final Function(int quantity) onAddToCart;
  final VoidCallback onChat;

  const _ProductCard({
    required this.product,
    required this.customerType,
    required this.onAddToCart,
    required this.onChat,
  });

  @override
  State<_ProductCard> createState() =>
      _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final price =
        widget.customerType == 'b2b' &&
                product.b2bPrice != null
            ? product.b2bPrice!
            : product.b2cPrice;
    final maxQty = product.stockQuantity;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF2D2D4E)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
            ),
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: product.imageBase64 != null
                  ? Image.memory(
                      base64Decode(
                          product.imageBase64!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(
                        color: const Color(0xFF6C63FF)
                            .withOpacity(0.08),
                        child: const Icon(
                            Icons.inventory_2,
                            color: Colors.white24,
                            size: 36),
                      ),
                    )
                  : Container(
                      color: const Color(0xFF6C63FF)
                          .withOpacity(0.08),
                      child: const Icon(
                          Icons.inventory_2,
                          color: Colors.white24,
                          size: 36),
                    ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
                10, 8, 10, 10),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(product.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(product.vendorName,
                    style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (product.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(product.description,
                      style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.star,
                      color: Colors.amber, size: 12),
                  const SizedBox(width: 2),
                  Text(
                      product.rating
                          .toStringAsFixed(1),
                      style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11)),
                  const Spacer(),
                  Text(
                      maxQty > 0
                          ? '$maxQty left'
                          : 'Out of stock',
                      style: TextStyle(
                          color: maxQty > 0
                              ? Colors.white38
                              : Colors.redAccent,
                          fontSize: 10)),
                ]),
                const SizedBox(height: 4),
                Text(
                  '₹${price.toStringAsFixed(0)}/${product.unit}',
                  style: const TextStyle(
                      color: Color(0xFF6C63FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
                if (widget.customerType == 'b2b' &&
                    product.b2bPrice != null)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent
                          .withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(4),
                    ),
                    child: const Text('B2B PRICE',
                        style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 9,
                            fontWeight:
                                FontWeight.bold)),
                  ),

                if (maxQty > 0) ...[
                  const SizedBox(height: 8),
                  // Qty stepper
                  Row(children: [
                    GestureDetector(
                      onTap: () => setState(() {
                        if (_qty > 1) _qty--;
                      }),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF0D0D1A),
                          borderRadius:
                              BorderRadius.circular(6),
                          border: Border.all(
                              color: const Color(
                                  0xFF2D2D4E)),
                        ),
                        child: const Icon(Icons.remove,
                            color: Colors.white54,
                            size: 14),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text('$_qty',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 13)),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        if (_qty < maxQty) _qty++;
                      }),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF0D0D1A),
                          borderRadius:
                              BorderRadius.circular(6),
                          border: Border.all(
                              color: const Color(
                                  0xFF2D2D4E)),
                        ),
                        child: const Icon(Icons.add,
                            color: Colors.white54,
                            size: 14),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 6),
                ] else
                  const SizedBox(height: 8),

                // Add + chat
                Row(children: [
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: maxQty > 0
                            ? () =>
                                widget.onAddToCart(_qty)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF6C63FF),
                          disabledBackgroundColor:
                              const Color(0xFF2D2D4E),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      8)),
                        ),
                        child: Text(
                          maxQty > 0
                              ? 'Add to Cart'
                              : 'Out of Stock',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Material(
                    color: const Color(0xFF2D2D4E),
                    borderRadius:
                        BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius:
                          BorderRadius.circular(8),
                      onTap: widget.onChat,
                      child: const SizedBox(
                        width: 40,
                        height: 32,
                        child: Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.white70,
                            size: 17),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}