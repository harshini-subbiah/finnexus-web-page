import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';

class OrderConfirmedScreen extends StatefulWidget {
  const OrderConfirmedScreen({super.key});
  @override
  State<OrderConfirmedScreen> createState() =>
      _OrderConfirmedScreenState();
}

class _OrderConfirmedScreenState
    extends State<OrderConfirmedScreen> {
  bool _gitDecided = false;
  bool _gitAccepted = false;
  String? _orderId;
  OrderModel? _order;
  String? _deliveryOtp;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra
        as Map<String, dynamic>?;
    if (extra != null) {
      _orderId = extra['orderId'];
      _order = extra['order'];
      _fetchOtp();
    }
  }

  Future<void> _fetchOtp() async {
    if (_orderId == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('orders')
        .doc(_orderId)
        .get();
    if (mounted) {
      setState(() {
        _deliveryOtp =
            doc.data()?['deliveryOtp'] as String?;
      });
    }
  }

  Future<void> _acceptGIT() async {
    setState(() => _gitAccepted = true);
    context.go('/insurance-apply');
  }

  Future<void> _declineGIT() async {
    setState(() => _gitDecided = true);
    if (_orderId != null && _order != null) {
      await OrderService().createShipment(_order!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 520,
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: const Color(0xFF16162A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.greenAccent
                      .withOpacity(0.3)),
            ),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.greenAccent, size: 72),
              const SizedBox(height: 20),
              const Text('Order Confirmed!',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 8),
              Text('Order ID: ${_orderId ?? '—'}',
                  style: const TextStyle(
                      color: Color(0xFF6C63FF),
                      fontFamily: 'monospace',
                      fontSize: 14)),
              if (_order != null) ...[
                const SizedBox(height: 8),
                Text(
                    'Total: ₹${_order!.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16)),
                if (_order!.paymentMethod == 'credit')
                  const Text('Payment: 30/60 day credit',
                      style: TextStyle(
                          color: Color(0xFFFFB347),
                          fontSize: 13)),
              ],

              // ── DELIVERY OTP — prominently shown ──
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB347)
                      .withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFFFFB347)
                          .withOpacity(0.5),
                      width: 1.5),
                ),
                child: Column(children: [
                  const Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                    Icon(Icons.lock_clock,
                        color: Color(0xFFFFB347),
                        size: 20),
                    SizedBox(width: 8),
                    Text('Your Delivery OTP',
                        style: TextStyle(
                            color: Color(0xFFFFB347),
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ]),
                  const SizedBox(height: 12),
                  _deliveryOtp == null
                      ? const SizedBox(
                          height: 36,
                          child: Center(
                              child:
                                  CircularProgressIndicator(
                                      color: Color(
                                          0xFFFFB347),
                                      strokeWidth: 2)))
                      : Text(_deliveryOtp!,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                              fontFamily: 'monospace')),
                  const SizedBox(height: 12),
                  const Text(
                      'Share this OTP with the delivery partner when your order arrives. You will also find it anytime in "My Orders".',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          height: 1.4)),
                ]),
              ),

              // GIT Insurance Prompt
              if (!_gitDecided && !_gitAccepted) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE07B39)
                        .withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFFE07B39)
                            .withOpacity(0.4)),
                  ),
                  child: Column(children: [
                    const Row(children: [
                      Text('🛡️',
                          style:
                              TextStyle(fontSize: 24)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                            'Protect your shipment?',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 16)),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    const Text(
                        'Add Goods in Transit insurance to protect your order against loss or damage during delivery.',
                        style: TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                            height: 1.4)),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _acceptGIT,
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFFE07B39),
                            shape:
                                RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                                8)),
                          ),
                          child: const Text(
                              'Yes, Add Insurance',
                              style: TextStyle(
                                  color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _declineGIT,
                          style:
                              OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Colors.white38),
                            shape:
                                RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                                8)),
                          ),
                          child: const Text(
                              'No Thanks',
                              style: TextStyle(
                                  color:
                                      Colors.white54)),
                        ),
                      ),
                    ]),
                  ]),
                ),
              ],

              if (_gitDecided || _gitAccepted) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        context.go('/my-orders'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF6C63FF),
                      padding:
                          const EdgeInsets.symmetric(
                              vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  10)),
                    ),
                    child: const Text('Track My Order',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15)),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}