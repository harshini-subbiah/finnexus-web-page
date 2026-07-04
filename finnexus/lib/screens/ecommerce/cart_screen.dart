import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../services/order_service.dart';
import '../../services/firestore_service.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import 'product_catalogue_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String _paymentMethod = 'immediate';
  bool _loading = false;
  String? _error;
  final _addressCtrl = TextEditingController();

  double get _total =>
      CartState.items.fold(0, (sum, item) {
        final p = item['product'] as ProductModel;
        final qty = item['quantity'] as int;
        final price =
            CartState.customerType == 'b2b' &&
                    p.b2bPrice != null
                ? p.b2bPrice!
                : p.b2cPrice;
        return sum + (price * qty);
      });

  Future<void> _placeOrder() async {
    if (_addressCtrl.text.trim().isEmpty) {
      setState(() =>
          _error = 'Delivery address is required');
      return;
    }
    if (CartState.items.isEmpty) {
      setState(() => _error = 'Cart is empty');
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
      final orderId = const Uuid().v4();

      final items = CartState.items.map((item) {
        final p = item['product'] as ProductModel;
        final qty = item['quantity'] as int;
        final price =
            CartState.customerType == 'b2b' &&
                    p.b2bPrice != null
                ? p.b2bPrice!
                : p.b2cPrice;
        return OrderItem(
          productId: p.id,
          productName: p.name,
          vendorUid: p.vendorUid,
          vendorName: p.vendorName,
          quantity: qty,
          unitPrice: price,
          totalPrice: price * qty,
        );
      }).toList();

      final order = OrderModel(
        id: orderId,
        buyerUid: uid,
        buyerCustomerId: user?.customerId ?? '',
        buyerBusinessName: user?.businessName ?? '',
        items: items,
        totalAmount: _total,
        customerType: CartState.customerType,
        paymentMethod: _paymentMethod,
        paymentStatus: 'pending',
        orderStatus: 'pending',
        deliveryAddress: _addressCtrl.text.trim(),
        otpVerified: false,
        gitInsurancePrompted: false,
        gitInsuranceAccepted: false,
        rfqNote: null,
        createdAt: DateTime.now(),
      );

      // Order is recorded but stock is NOT touched here.
      // Stock only decrements once payment is confirmed.
      await OrderService().placeOrder(order);

      if (!mounted) return;
      context.go('/payment',
          extra: {
            'orderId': orderId,
            'order': order,
            'paymentMethod': _paymentMethod
          });
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
        title: const Text('Your Cart',
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Colors.white),
          onPressed: () => context.go('/catalogue'),
        ),
      ),
      body: CartState.items.isEmpty
          ? Center(
              child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.white24,
                    size: 64),
                const SizedBox(height: 16),
                const Text('Your cart is empty',
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 16)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      context.go('/catalogue'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF6C63FF)),
                  child: const Text('Browse Products',
                      style: TextStyle(
                          color: Colors.white)),
                ),
              ]))
          : Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text('Order Items',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 16),
                      ...CartState.items.map((item) {
                        final p =
                            item['product'] as ProductModel;
                        final qty =
                            item['quantity'] as int;
                        final price =
                            CartState.customerType ==
                                        'b2b' &&
                                    p.b2bPrice != null
                                ? p.b2bPrice!
                                : p.b2cPrice;
                        return Container(
                          margin: const EdgeInsets.only(
                              bottom: 12),
                          padding:
                              const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF16162A),
                            borderRadius:
                                BorderRadius.circular(
                                    12),
                            border: Border.all(
                                color: const Color(
                                    0xFF2D2D4E)),
                          ),
                          child: Row(children: [
                            Expanded(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                Text(p.name,
                                    style: const TextStyle(
                                        color:
                                            Colors.white,
                                        fontWeight:
                                            FontWeight
                                                .w600)),
                                const SizedBox(height: 2),
                                Text(p.vendorName,
                                    style: const TextStyle(
                                        color:
                                            Colors.white38,
                                        fontSize: 12)),
                                Text(
                                    '₹${price.toStringAsFixed(0)} × $qty = ₹${(price * qty).toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        color: Color(
                                            0xFF6C63FF),
                                        fontWeight:
                                            FontWeight
                                                .w600)),
                              ]),
                            ),
                            Row(children: [
                              IconButton(
                                icon: const Icon(
                                    Icons.remove,
                                    color: Colors.white54,
                                    size: 18),
                                onPressed: () =>
                                    setState(() {
                                  if (qty > 1) {
                                    item['quantity']--;
                                  } else {
                                    CartState.items
                                        .remove(item);
                                  }
                                }),
                              ),
                              Text('$qty',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight:
                                          FontWeight
                                              .bold)),
                              IconButton(
                                icon: const Icon(
                                    Icons.add,
                                    color: Colors.white54,
                                    size: 18),
                                onPressed: () =>
                                    setState(() =>
                                        item['quantity']++),
                              ),
                              IconButton(
                                icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                    size: 18),
                                onPressed: () =>
                                    setState(() =>
                                        CartState.items
                                            .remove(item)),
                              ),
                            ]),
                          ]),
                        );
                      }),
                    ],
                  ),
                ),

                Container(
                  width: 340,
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16162A),
                    borderRadius:
                        BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF2D2D4E)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                      const Text('Order Summary',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 20),

                      _label('Delivery Address *'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _addressCtrl,
                        maxLines: 2,
                        style: const TextStyle(
                            color: Colors.white),
                        decoration: _deco(
                            'Full delivery address'),
                      ),
                      const SizedBox(height: 16),

                      // Payment Terms — visible to ALL
                      // customer types, not just B2B
                      _label('Payment Terms'),
                      const SizedBox(height: 8),
                      Row(children: [
                        _payBtn('Pay Now', 'immediate'),
                        const SizedBox(width: 8),
                        _payBtn('30/60 Day Credit',
                            'credit'),
                      ]),
                      if (_paymentMethod == 'credit')
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 8),
                          child: Container(
                            padding:
                                const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(
                                      0xFFFFB347)
                                  .withOpacity(0.08),
                              borderRadius:
                                  BorderRadius.circular(
                                      8),
                              border: Border.all(
                                  color: const Color(
                                          0xFFFFB347)
                                      .withOpacity(0.3)),
                            ),
                            child: const Row(children: [
                              Icon(Icons.info_outline,
                                  color:
                                      Color(0xFFFFB347),
                                  size: 14),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                    'A credit invoice will be raised. Payment due within the agreed credit period.',
                                    style: TextStyle(
                                        color: Color(
                                            0xFFFFB347),
                                        fontSize: 11)),
                              ),
                            ]),
                          ),
                        ),
                      const SizedBox(height: 16),

                      const Divider(
                          color: Color(0xFF2D2D4E)),
                      const SizedBox(height: 12),

                      ...CartState.items.map((item) {
                        final p = item['product']
                            as ProductModel;
                        final qty =
                            item['quantity'] as int;
                        final price =
                            CartState.customerType ==
                                        'b2b' &&
                                    p.b2bPrice != null
                                ? p.b2bPrice!
                                : p.b2cPrice;
                        return Padding(
                          padding: const EdgeInsets.only(
                              bottom: 6),
                          child: Row(children: [
                            Expanded(
                                child: Text(
                                    '${p.name} ×$qty',
                                    style: const TextStyle(
                                        color:
                                            Colors.white54,
                                        fontSize: 12),
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow
                                            .ellipsis)),
                            Text(
                                '₹${(price * qty).toStringAsFixed(0)}',
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12)),
                          ]),
                        );
                      }),

                      const Divider(
                          color: Color(0xFF2D2D4E)),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Text('Total',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 16)),
                        const Spacer(),
                        Text(
                            '₹${_total.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: Color(0xFF6C63FF),
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 22)),
                      ]),

                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!,
                            style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13)),
                      ],

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              _loading ? null : _placeOrder,
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF6C63FF),
                            padding:
                                const EdgeInsets.symmetric(
                                    vertical: 14),
                            shape:
                                RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                                10)),
                          ),
                          icon: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(
                                          color: Colors
                                              .white,
                                          strokeWidth:
                                              2))
                              : const Icon(
                                  Icons.payment,
                                  color: Colors.white,
                                  size: 18),
                          label: Text(
                            _loading
                                ? 'Processing...'
                                : _paymentMethod ==
                                        'immediate'
                                    ? 'Proceed to Payment'
                                    : 'Continue with Credit',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          color: Colors.white70, fontSize: 13));

  Widget _payBtn(String label, String value) {
    final sel = _paymentMethod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () =>
            setState(() => _paymentMethod = value),
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: 10),
          decoration: BoxDecoration(
            color: sel
                ? const Color(0xFF6C63FF)
                    .withOpacity(0.2)
                : const Color(0xFF0D0D1A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: sel
                    ? const Color(0xFF6C63FF)
                    : const Color(0xFF2D2D4E)),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: sel
                      ? const Color(0xFF6C63FF)
                      : Colors.white54,
                  fontSize: 12,
                  fontWeight: sel
                      ? FontWeight.bold
                      : FontWeight.normal)),
        ),
      ),
    );
  }

  InputDecoration _deco(String hint) =>
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
                color: Color(0xFF6C63FF))),
      );
}