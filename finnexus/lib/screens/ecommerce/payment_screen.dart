import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/order_service.dart';
import '../../models/order_model.dart';
import 'product_catalogue_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});
  @override
  State<PaymentScreen> createState() =>
      _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _orderId;
  OrderModel? _order;
  String _paymentMethod = 'immediate';
  bool _processing = false;
  bool _paid = false;
  String _selectedCard = 'upi';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra
        as Map<String, dynamic>?;
    if (extra != null) {
      _orderId = extra['orderId'];
      _order = extra['order'];
      _paymentMethod =
          extra['paymentMethod'] ?? 'immediate';
    }
  }

  Future<void> _confirmPayment() async {
    setState(() => _processing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (_orderId != null) {
      await OrderService().confirmOrder(_orderId!);
    }
    CartState.clear();
    setState(() {
      _processing = false;
      _paid = true;
    });
    await Future.delayed(const Duration(seconds: 1));
    if (mounted && _order != null) {
      context.go('/order-confirmed',
          extra: {
            'orderId': _orderId,
            'order': _order
          });
    }
  }

  Future<void> _confirmCredit() async {
    setState(() => _processing = true);
    await Future.delayed(
        const Duration(milliseconds: 800));
    if (_orderId != null) {
      await OrderService().confirmOrder(_orderId!);
    }
    CartState.clear();
    setState(() => _processing = false);
    if (mounted && _order != null) {
      context.go('/order-confirmed',
          extra: {
            'orderId': _orderId,
            'order': _order
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_order == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.go('/catalogue'),
            child: const Text('Go to Catalogue'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16162A),
        title: const Text('Payment',
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Colors.white),
          onPressed: () => context.go('/cart'),
        ),
      ),
      // ← Key fix: scrollable body
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(36),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF16162A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF6C63FF)
                      .withOpacity(0.3)),
            ),
            child: _paid
                ? _paidView()
                : _paymentMethod == 'credit'
                    ? _creditView()
                    : _razorpayView(),
          ),
        ),
      ),
    );
  }

  Widget _paidView() {
    return Column(mainAxisSize: MainAxisSize.min,
        children: [
      const SizedBox(height: 20),
      const Icon(Icons.check_circle,
          color: Colors.greenAccent, size: 72),
      const SizedBox(height: 16),
      const Text('Payment Successful!',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white)),
      const SizedBox(height: 8),
      const Text('Redirecting to your order...',
          style: TextStyle(color: Colors.white54)),
      const SizedBox(height: 24),
      const CircularProgressIndicator(
          color: Color(0xFF6C63FF)),
      const SizedBox(height: 20),
    ]);
  }

  Widget _creditView() {
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      const Row(children: [
        Text('📋', style: TextStyle(fontSize: 28)),
        SizedBox(width: 12),
        Text('Credit Order',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ]),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFB347)
              .withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: const Color(0xFFFFB347)
                  .withOpacity(0.4)),
        ),
        child: const Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
          Row(children: [
            Icon(Icons.info_outline,
                color: Color(0xFFFFB347), size: 16),
            SizedBox(width: 8),
            Text('30/60 Day Credit Terms',
                style: TextStyle(
                    color: Color(0xFFFFB347),
                    fontWeight: FontWeight.bold)),
          ]),
          SizedBox(height: 8),
          Text(
              'A credit invoice will be raised. Payment is due within the agreed credit period.',
              style: TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                  height: 1.4)),
        ]),
      ),
      const SizedBox(height: 20),
      _OrderSummaryMini(order: _order!),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed:
              _processing ? null : _confirmCredit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFB347),
            padding: const EdgeInsets.symmetric(
                vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(10)),
          ),
          child: _processing
              ? const CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2)
              : const Text('Confirm Credit Order',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
        ),
      ),
    ]);
  }

  Widget _razorpayView() {
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      // Razorpay branding
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF2F80ED),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text('razorpay',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1)),
        ),
        const SizedBox(width: 10),
        const Text('Secure Payment',
            style: TextStyle(
                color: Colors.white54, fontSize: 13)),
        const Spacer(),
        const Icon(Icons.lock,
            color: Colors.greenAccent, size: 16),
        const SizedBox(width: 4),
        const Text('SSL Secured',
            style: TextStyle(
                color: Colors.greenAccent, fontSize: 11)),
      ]),
      const SizedBox(height: 20),

      _OrderSummaryMini(order: _order!),
      const SizedBox(height: 20),

      const Text('Select Payment Method',
          style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),

      ...[
        {
          'id': 'upi',
          'label': 'UPI',
          'icon': '📱',
          'sub': 'Google Pay, PhonePe, Paytm'
        },
        {
          'id': 'card',
          'label': 'Credit / Debit Card',
          'icon': '💳',
          'sub': 'Visa, Mastercard, RuPay'
        },
        {
          'id': 'netbanking',
          'label': 'Net Banking',
          'icon': '🏦',
          'sub': 'All major banks supported'
        },
      ].map((method) {
        final sel = _selectedCard == method['id'];
        return GestureDetector(
          onTap: () => setState(
              () => _selectedCard = method['id']!),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: sel
                  ? const Color(0xFF2F80ED)
                      .withOpacity(0.1)
                  : const Color(0xFF0D0D1A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: sel
                      ? const Color(0xFF2F80ED)
                      : const Color(0xFF2D2D4E)),
            ),
            child: Row(children: [
              Text(method['icon']!,
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                  Text(method['label']!,
                      style: TextStyle(
                          color: sel
                              ? Colors.white
                              : Colors.white70,
                          fontWeight:
                              FontWeight.w600)),
                  Text(method['sub']!,
                      style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11)),
                ]),
              ),
              if (sel)
                const Icon(Icons.check_circle,
                    color: Color(0xFF2F80ED), size: 18),
            ]),
          ),
        );
      }),

      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.greenAccent.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color:
                  Colors.greenAccent.withOpacity(0.2)),
        ),
        child: const Row(children: [
          Icon(Icons.info_outline,
              color: Colors.greenAccent, size: 14),
          SizedBox(width: 8),
          Expanded(
            child: Text(
                'Simulated payment — no real transaction will occur.',
                style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 11)),
          ),
        ]),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed:
              _processing ? null : _confirmPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2F80ED),
            padding: const EdgeInsets.symmetric(
                vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(10)),
          ),
          child: _processing
              ? const Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('Processing Payment...',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15)),
                  ],
                )
              : Text(
                  'Pay ₹${_order!.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
        ),
      ),
      const SizedBox(height: 8),
    ]);
  }
}

class _OrderSummaryMini extends StatelessWidget {
  final OrderModel order;
  const _OrderSummaryMini({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFF2D2D4E)),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        const Text('Order Summary',
            style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
        const SizedBox(height: 8),
        ...order.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                Expanded(
                    child: Text(
                        '${item.productName} ×${item.quantity}',
                        style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12),
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis)),
                Text(
                    '₹${item.totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12)),
              ]),
            )),
        const Divider(color: Color(0xFF2D2D4E)),
        Row(children: [
          const Text('Total',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(
              '₹${order.totalAmount.toStringAsFixed(0)}',
              style: const TextStyle(
                  color: Color(0xFF6C63FF),
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ]),
      ]),
    );
  }
}