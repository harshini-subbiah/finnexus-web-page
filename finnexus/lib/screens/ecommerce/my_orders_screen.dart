import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import '../../models/order_model.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16162A),
        title: const Text('My Orders',
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Colors.white),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: OrderService().streamBuyerOrders(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF6C63FF)));
          }
          final orders = snapshot.data!;
          if (orders.isEmpty) {
            return Center(
              child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                const Icon(Icons.shopping_bag_outlined,
                    color: Colors.white24, size: 64),
                const SizedBox(height: 16),
                const Text('No orders yet',
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
                      style:
                          TextStyle(color: Colors.white)),
                ),
              ]),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: orders.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: 12),
            itemBuilder: (context, i) =>
                _OrderCard(order: orders[i]),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final OrderModel order;
  const _OrderCard({required this.order});
  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  final _otpCtrl = TextEditingController();
  final _ratingNotifier = ValueNotifier<int>(0);
  final _feedbackCtrl = TextEditingController();
  bool _showOtp = false;
  bool _showRating = false;
  bool _otpLoading = false;
  String? _error;

  Color get _statusColor {
    switch (widget.order.orderStatus) {
      case 'confirmed':
        return const Color(0xFF6C63FF);
      case 'dispatched':
        return const Color(0xFFFFB347);
      case 'in_transit':
        return const Color(0xFFFF8C42);
      case 'delivered':
        return Colors.greenAccent;
      case 'completed':
        return Colors.greenAccent;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return const Color(0xFFFFB347);
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _otpLoading = true;
      _error = null;
    });
    try {
      await OrderService().verifyDeliveryOtp(
          widget.order.id, _otpCtrl.text.trim());
      setState(() {
        _showOtp = false;
        _showRating = true;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _otpLoading = false);
    }
  }

  Future<void> _submitRating() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await OrderService().submitRating(
        widget.order.id,
        _ratingNotifier.value,
        _feedbackCtrl.text.trim(),
        uid);
    for (final item in widget.order.items) {
      await ProductService().updateRating(
          item.productId,
          _ratingNotifier.value.toDouble());
    }
    setState(() => _showRating = false);
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: _statusColor.withOpacity(0.3)),
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
              Text(
                  'Order #${o.id.substring(0, 8)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace')),
              Text(
                  '${o.items.length} item(s) • ₹${o.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Colors.white70)),
              Text(
                  o.createdAt
                      .toLocal()
                      .toString()
                      .split(' ')[0],
                  style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: _statusColor.withOpacity(0.5)),
            ),
            child: Text(
                o.orderStatus
                    .replaceAll('_', ' ')
                    .toUpperCase(),
                style: TextStyle(
                    color: _statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
        ]),

        const SizedBox(height: 10),
        ...o.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                  '• ${item.productName} ×${item.quantity} — ₹${item.totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13)),
            )),
          // Show the OTP whenever order isn't delivered yet
        if (!o.otpVerified &&
            o.deliveryOtp != null &&
            o.orderStatus != 'cancelled') ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color:
                  const Color(0xFFFFB347).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFFFFB347)
                      .withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.lock_clock,
                  color: Color(0xFFFFB347), size: 16),
              const SizedBox(width: 8),
              const Text('Delivery OTP:',
                  style: TextStyle(
                      color: Color(0xFFFFB347),
                      fontSize: 12)),
              const SizedBox(width: 8),
              Text(o.deliveryOtp!,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 3,
                      fontFamily: 'monospace')),
            ]),
          ),
        ],
        // Delivery OTP entry
        if ((o.orderStatus == 'in_transit' ||
                o.orderStatus == 'dispatched') &&
            !o.otpVerified) ...[
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF2D2D4E)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () =>
                setState(() => _showOtp = !_showOtp),
            child: const Row(children: [
              Icon(Icons.lock_outline,
                  color: Color(0xFFFFB347), size: 16),
              SizedBox(width: 8),
              Text('Enter Delivery OTP',
                  style: TextStyle(
                      color: Color(0xFFFFB347),
                      fontWeight: FontWeight.w600)),
            ]),
          ),
          if (_showOtp) ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter 6-digit OTP',
                    hintStyle: const TextStyle(
                        color: Colors.white30),
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
                            color: Color(0xFFFFB347))),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed:
                    _otpLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFFFB347),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(8))),
                child: _otpLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2)
                    : const Text('Verify',
                        style: TextStyle(
                            color: Colors.white)),
              ),
            ]),
            if (_error != null)
              Text(_error!,
                  style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12)),
          ],
        ],

        // Rating
        if ((o.orderStatus == 'delivered' &&
                o.buyerRating == null) ||
            _showRating) ...[
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF2D2D4E)),
          const SizedBox(height: 8),
          const Text('Rate this order:',
              style: TextStyle(
                  color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          ValueListenableBuilder<int>(
            valueListenable: _ratingNotifier,
            builder: (context, rating, _) => Row(
              children: List.generate(5, (i) {
                return GestureDetector(
                  onTap: () =>
                      _ratingNotifier.value = i + 1,
                  child: Icon(Icons.star,
                      color: i < rating
                          ? Colors.amber
                          : Colors.white24,
                      size: 28),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _feedbackCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Share your feedback...',
              hintStyle: const TextStyle(
                  color: Colors.white30),
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
                      color: Colors.amber)),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _submitRating,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(8))),
            child: const Text('Submit Rating',
                style: TextStyle(color: Colors.black)),
          ),
        ],

        if (o.buyerRating != null) ...[
          const SizedBox(height: 8),
          Row(children: [
            ...List.generate(
                5,
                (i) => Icon(Icons.star,
                    color: i < o.buyerRating!
                        ? Colors.amber
                        : Colors.white24,
                    size: 16)),
            const SizedBox(width: 8),
            Text(o.buyerFeedback ?? '',
                style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12)),
          ]),
        ],
      ]),
    );
  }
}