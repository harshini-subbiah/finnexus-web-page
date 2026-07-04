class OrderItem {
  final String productId;
  final String productName;
  final String vendorUid;
  final String vendorName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.vendorUid,
    required this.vendorName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'vendorUid': vendorUid,
        'vendorName': vendorName,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'totalPrice': totalPrice,
      };

  factory OrderItem.fromMap(Map<String, dynamic> m) =>
      OrderItem(
        productId: m['productId'] ?? '',
        productName: m['productName'] ?? '',
        vendorUid: m['vendorUid'] ?? '',
        vendorName: m['vendorName'] ?? '',
        quantity: m['quantity'] ?? 0,
        unitPrice: (m['unitPrice'] ?? 0).toDouble(),
        totalPrice: (m['totalPrice'] ?? 0).toDouble(),
      );
}

class OrderModel {
  final String id;
  final String buyerUid;
  final String buyerCustomerId;
  final String buyerBusinessName;
  final List<OrderItem> items;
  final double totalAmount;
  final String customerType; // b2c or b2b
  final String paymentMethod; // immediate or credit
  final String paymentStatus; // pending, paid
  final String orderStatus;
  // pending, confirmed, dispatched, in_transit,
  // delivered, completed, cancelled
  final String deliveryAddress;
  final String? deliveryOtp;
  final bool otpVerified;
  final bool gitInsurancePrompted;
  final bool gitInsuranceAccepted;
  final String? rfqNote;
  final int? buyerRating;
  final String? buyerFeedback;
  final DateTime createdAt;
  final String? confirmedAt;
  final String? deliveredAt;

  OrderModel({
    required this.id,
    required this.buyerUid,
    required this.buyerCustomerId,
    required this.buyerBusinessName,
    required this.items,
    required this.totalAmount,
    required this.customerType,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    required this.deliveryAddress,
    this.deliveryOtp,
    required this.otpVerified,
    required this.gitInsurancePrompted,
    required this.gitInsuranceAccepted,
    this.rfqNote,
    this.buyerRating,
    this.buyerFeedback,
    required this.createdAt,
    this.confirmedAt,
    this.deliveredAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'buyerUid': buyerUid,
        'buyerCustomerId': buyerCustomerId,
        'buyerBusinessName': buyerBusinessName,
        'items': items.map((i) => i.toMap()).toList(),
        'totalAmount': totalAmount,
        'customerType': customerType,
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'orderStatus': orderStatus,
        'deliveryAddress': deliveryAddress,
        'deliveryOtp': deliveryOtp,
        'otpVerified': otpVerified,
        'gitInsurancePrompted': gitInsurancePrompted,
        'gitInsuranceAccepted': gitInsuranceAccepted,
        'rfqNote': rfqNote,
        'buyerRating': buyerRating,
        'buyerFeedback': buyerFeedback,
        'createdAt': createdAt.toIso8601String(),
        'confirmedAt': confirmedAt,
        'deliveredAt': deliveredAt,
      };

  factory OrderModel.fromMap(Map<String, dynamic> m) =>
      OrderModel(
        id: m['id'] ?? '',
        buyerUid: m['buyerUid'] ?? '',
        buyerCustomerId: m['buyerCustomerId'] ?? '',
        buyerBusinessName: m['buyerBusinessName'] ?? '',
        items: (m['items'] as List? ?? [])
            .map((i) =>
                OrderItem.fromMap(i as Map<String, dynamic>))
            .toList(),
        totalAmount: (m['totalAmount'] ?? 0).toDouble(),
        customerType: m['customerType'] ?? 'b2c',
        paymentMethod: m['paymentMethod'] ?? 'immediate',
        paymentStatus: m['paymentStatus'] ?? 'pending',
        orderStatus: m['orderStatus'] ?? 'pending',
        deliveryAddress: m['deliveryAddress'] ?? '',
        deliveryOtp: m['deliveryOtp'],
        otpVerified: m['otpVerified'] ?? false,
        gitInsurancePrompted:
            m['gitInsurancePrompted'] ?? false,
        gitInsuranceAccepted:
            m['gitInsuranceAccepted'] ?? false,
        rfqNote: m['rfqNote'],
        buyerRating: m['buyerRating'],
        buyerFeedback: m['buyerFeedback'],
        createdAt: DateTime.parse(
            m['createdAt'] ?? DateTime.now().toIso8601String()),
        confirmedAt: m['confirmedAt'],
        deliveredAt: m['deliveredAt'],
      );
}