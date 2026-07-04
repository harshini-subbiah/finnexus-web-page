import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/shipment_model.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';

class OrderService {
  final _db = FirebaseFirestore.instance;

  String _generateOtp() {
    final r = Random();
    return (100000 + r.nextInt(900000)).toString();
  }

  Future<void> placeOrder(OrderModel order) async {
    // Just create the order record — stock is NOT
    // touched here. It only decrements once payment
    // is confirmed via confirmOrder().
    await _db
        .collection('orders')
        .doc(order.id)
        .set(order.toMap());

    await _db
        .collection('crr')
        .doc(order.buyerUid)
        .update({
      'orderHistory': FieldValue.arrayUnion([
        {
          'orderId': order.id,
          'amount': order.totalAmount,
          'date': DateTime.now().toIso8601String(),
        }
      ])
    });
  }

  Future<void> confirmOrder(String orderId) async {
    final otp = _generateOtp();

    final orderDoc =
        await _db.collection('orders').doc(orderId).get();
    if (!orderDoc.exists) return;
    final order = OrderModel.fromMap(orderDoc.data()!);

    // Decrement stock NOW — only after payment is confirmed
    for (final item in order.items) {
      await _db
          .collection('products')
          .doc(item.productId)
          .update({
        'stockQuantity':
            FieldValue.increment(-item.quantity),
      });
    }

    await _db.collection('orders').doc(orderId).update({
      'orderStatus': 'confirmed',
      'paymentStatus': 'paid',
      'confirmedAt': DateTime.now().toIso8601String(),
      'deliveryOtp': otp,
    });
  }

  Future<String> createShipment(OrderModel order) async {
    final shipmentId = const Uuid().v4();
    final shipment = ShipmentModel(
      id: shipmentId,
      orderId: order.id,
      buyerUid: order.buyerUid,
      buyerCustomerId: order.buyerCustomerId,
      vendorUid: order.items.first.vendorUid,
      vendorCustomerId: '',
      status: 'created',
      pickupAddress: '',
      deliveryAddress: order.deliveryAddress,
      weightKg: 0,
      goodsDescription:
          order.items.map((i) => i.productName).join(', '),
      statusHistory: [
        {
          'status': 'created',
          'time': DateTime.now().toIso8601String(),
          'note': 'Shipment created automatically',
        }
      ],
      createdAt: DateTime.now(),
    );
    await _db
        .collection('shipments')
        .doc(shipmentId)
        .set(shipment.toMap());
    await _db
        .collection('orders')
        .doc(order.id)
        .update({'orderStatus': 'dispatched'});
    return shipmentId;
  }

  Future<void> verifyDeliveryOtp(
      String orderId, String enteredOtp) async {
    final doc = await _db
        .collection('orders')
        .doc(orderId)
        .get();
    final stored = doc.data()?['deliveryOtp'];
    if (stored != enteredOtp) {
      throw Exception('Invalid OTP. Please try again.');
    }
    await _db
        .collection('orders')
        .doc(orderId)
        .update({
      'otpVerified': true,
      'orderStatus': 'delivered',
      'deliveredAt': DateTime.now().toIso8601String(),
    });
    final shipSnap = await _db
        .collection('shipments')
        .where('orderId', isEqualTo: orderId)
        .get();
    for (final s in shipSnap.docs) {
      await s.reference.update({
        'status': 'delivered',
        'deliveredAt': DateTime.now().toIso8601String(),
        'statusHistory': FieldValue.arrayUnion([
          {
            'status': 'delivered',
            'time': DateTime.now().toIso8601String(),
            'note': 'OTP verified by buyer',
          }
        ]),
      });
    }
  }

  Future<void> submitRating(
      String orderId,
      int rating,
      String feedback,
      String buyerUid) async {
    await _db
        .collection('orders')
        .doc(orderId)
        .update({
      'buyerRating': rating,
      'buyerFeedback': feedback,
      'orderStatus': 'completed',
    });
    await _db.collection('crr').doc(buyerUid).update({
      'buyerReliabilityScore': FieldValue.increment(1),
    });
  }

  Stream<List<OrderModel>> streamBuyerOrders(
      String buyerUid) {
    return _db
        .collection('orders')
        .where('buyerUid', isEqualTo: buyerUid)
        .snapshots()
        .map((s) => s.docs
            .map((d) => OrderModel.fromMap(d.data()))
            .toList());
  }

  Stream<List<OrderModel>> streamVendorOrders(
      String vendorUid) {
    return _db
        .collection('orders')
        .snapshots()
        .map((s) => s.docs
            .map((d) => OrderModel.fromMap(d.data()))
            .where((o) => o.items
                .any((i) => i.vendorUid == vendorUid))
            .toList());
  }

  Stream<List<ShipmentModel>> streamLogisticsShipments(
      String partnerUid) {
    return _db
        .collection('shipments')
        .where('logisticsPartnerUid',
            isEqualTo: partnerUid)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ShipmentModel.fromMap(d.data()))
            .toList());
  }

  Stream<List<ShipmentModel>> streamAllShipments() {
    return _db
        .collection('shipments')
        .snapshots()
        .map((s) => s.docs
            .map((d) => ShipmentModel.fromMap(d.data()))
            .toList());
  }

  Future<void> updateShipmentStatus(
      String shipmentId,
      String status,
      String note) async {
    await _db
        .collection('shipments')
        .doc(shipmentId)
        .update({
      'status': status,
      'statusHistory': FieldValue.arrayUnion([
        {
          'status': status,
          'time': DateTime.now().toIso8601String(),
          'note': note,
        }
      ]),
    });
  }

  Future<void> assignLogisticsPartner(
      String shipmentId,
      String partnerUid,
      String partnerName) async {
    await _db
        .collection('shipments')
        .doc(shipmentId)
        .update({
      'logisticsPartnerUid': partnerUid,
      'logisticsPartnerName': partnerName,
      'status': 'partner_assigned',
      'statusHistory': FieldValue.arrayUnion([
        {
          'status': 'partner_assigned',
          'time': DateTime.now().toIso8601String(),
          'note': 'Partner assigned: $partnerName',
        }
      ]),
    });
  }
}