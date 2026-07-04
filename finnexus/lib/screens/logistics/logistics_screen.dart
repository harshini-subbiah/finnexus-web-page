import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/order_service.dart';
import '../../models/shipment_model.dart';

class LogisticsScreen extends StatefulWidget {
  const LogisticsScreen({super.key});
  @override
  State<LogisticsScreen> createState() =>
      _LogisticsScreenState();
}

class _LogisticsScreenState extends State<LogisticsScreen> {
  String _filter = 'active';

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Container(
      color: const Color(0xFF0D0D1A),
      child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 28, 32, 0),
          child: Row(children: [
            const Expanded(
              child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                Text('My Shipments',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                SizedBox(height: 4),
                Text(
                    'Shipments assigned to you by the platform admin',
                    style: TextStyle(color: Colors.white54)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 20),

        // Stats summary
        StreamBuilder<List<ShipmentModel>>(
          stream: OrderService()
              .streamLogisticsShipments(uid),
          builder: (context, snapshot) {
            final shipments = snapshot.data ?? [];
            final active = shipments
                .where((s) =>
                    s.status != 'delivered' &&
                    s.status != 'disputed')
                .length;
            final delivered = shipments
                .where((s) => s.status == 'delivered')
                .length;
            final pendingPickup = shipments
                .where((s) =>
                    s.status == 'partner_assigned')
                .length;

            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32),
              child: Row(children: [
                _statCard('Active', active,
                    const Color(0xFF9C27B0)),
                const SizedBox(width: 12),
                _statCard('Awaiting Pickup',
                    pendingPickup,
                    const Color(0xFFFFB347)),
                const SizedBox(width: 12),
                _statCard('Delivered', delivered,
                    Colors.greenAccent),
              ]),
            );
          },
        ),

        const SizedBox(height: 20),

        // Filter tabs
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 32),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                'active',
                'partner_assigned',
                'pickup_confirmed',
                'in_transit',
                'delivered',
                'all'
              ].map((f) {
                final isActive = _filter == f;
                return GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF9C27B0)
                          : const Color(0xFF16162A),
                      borderRadius:
                          BorderRadius.circular(8),
                      border: Border.all(
                          color: isActive
                              ? const Color(0xFF9C27B0)
                              : const Color(0xFF2D2D4E)),
                    ),
                    child: Text(
                        f == 'all'
                            ? 'All'
                            : f
                                .replaceAll('_', ' ')
                                .toUpperCase(),
                        style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : Colors.white54,
                            fontSize: 11,
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.normal)),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),

        Expanded(
          child: StreamBuilder<List<ShipmentModel>>(
            stream: OrderService()
                .streamLogisticsShipments(uid),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(
                            color: Colors.redAccent)));
              }
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF9C27B0)));
              }
              var shipments = snapshot.data!;
              if (_filter == 'active') {
                shipments = shipments
                    .where((s) =>
                        s.status != 'delivered' &&
                        s.status != 'disputed')
                    .toList();
              } else if (_filter != 'all') {
                shipments = shipments
                    .where((s) => s.status == _filter)
                    .toList();
              }
              if (shipments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      const Icon(
                          Icons.local_shipping_outlined,
                          color: Colors.white24,
                          size: 56),
                      const SizedBox(height: 14),
                      Text(
                          _filter == 'active'
                              ? 'No active shipments right now'
                              : 'No shipments in this category',
                          style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 15)),
                      const SizedBox(height: 6),
                      const Text(
                          'New shipments appear here once the admin assigns one to you.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white24,
                              fontSize: 12)),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                    32, 0, 32, 24),
                itemCount: shipments.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, i) =>
                    _ShipmentCard(
                        shipment: shipments[i]),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _statCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF16162A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text('$count',
              style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 12)),
        ]),
      ),
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  final ShipmentModel shipment;
  const _ShipmentCard({required this.shipment});

  Color get _color {
    switch (shipment.status) {
      case 'partner_assigned':
        return const Color(0xFFFFB347);
      case 'pickup_confirmed':
        return const Color(0xFF6C63FF);
      case 'in_transit':
        return const Color(0xFFFF8C42);
      case 'delivered':
        return Colors.greenAccent;
      default:
        return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = shipment;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(children: [
          Expanded(
            child: Text(
                'Shipment #${s.id.substring(0, 8)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace')),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: _color.withOpacity(0.5)),
            ),
            child: Text(
                s.status
                    .replaceAll('_', ' ')
                    .toUpperCase(),
                style: TextStyle(
                    color: _color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 8),
        Text('Goods: ${s.goodsDescription}',
            style: const TextStyle(
                color: Colors.white70)),
        Text(
            'From: ${s.pickupAddress.isEmpty ? 'Vendor address' : s.pickupAddress}',
            style: const TextStyle(
                color: Colors.white54, fontSize: 13)),
        Text('To: ${s.deliveryAddress}',
            style: const TextStyle(
                color: Colors.white54, fontSize: 13)),
        Text(
            'Order ID: ${s.orderId.substring(0, 8)}',
            style: const TextStyle(
                color: Color(0xFF6C63FF),
                fontSize: 12,
                fontFamily: 'monospace')),
        const SizedBox(height: 12),

        if (s.status == 'partner_assigned')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  OrderService().updateShipmentStatus(
                      s.id,
                      'pickup_confirmed',
                      'Pickup confirmed by logistics partner'),
              style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF6C63FF),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(8))),
              icon: const Icon(Icons.check,
                  color: Colors.white, size: 16),
              label: const Text('Confirm Pickup',
                  style: TextStyle(color: Colors.white)),
            ),
          ),

        if (s.status == 'pickup_confirmed')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  OrderService().updateShipmentStatus(
                      s.id,
                      'in_transit',
                      'Shipment in transit'),
              style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFFF8C42),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(8))),
              icon: const Icon(Icons.local_shipping,
                  color: Colors.white, size: 16),
              label: const Text('Mark In Transit',
                  style: TextStyle(color: Colors.white)),
            ),
          ),

        if (s.status == 'in_transit')
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color:
                      Colors.greenAccent.withOpacity(0.3)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline,
                  color: Colors.greenAccent, size: 14),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                    'Waiting for buyer to confirm delivery with OTP.',
                    style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 12)),
              ),
            ]),
          ),

        if (s.statusHistory.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF2D2D4E)),
          const SizedBox(height: 8),
          const Text('Status Timeline:',
              style: TextStyle(
                  color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 6),
          ...s.statusHistory.map((h) => Padding(
                padding:
                    const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  const Icon(Icons.circle,
                      color: Color(0xFF9C27B0), size: 8),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        '${h['status']?.toString().replaceAll('_', ' ') ?? ''} — ${h['note'] ?? ''}',
                        style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11)),
                  ),
                ]),
              )),
        ],
      ]),
    );
  }
}