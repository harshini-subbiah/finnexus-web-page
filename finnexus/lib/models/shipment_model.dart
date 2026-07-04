class ShipmentModel {
  final String id;
  final String orderId;
  final String buyerUid;
  final String buyerCustomerId;
  final String vendorUid;
  final String vendorCustomerId;
  final String? logisticsPartnerUid;
  final String? logisticsPartnerName;
  final String status;
  // created, partner_assigned, pickup_confirmed,
  // in_transit, delivered, disputed
  final String pickupAddress;
  final String deliveryAddress;
  final double weightKg;
  final String goodsDescription;
  final List<Map<String, dynamic>> statusHistory;
  final DateTime createdAt;
  final String? deliveredAt;

  ShipmentModel({
    required this.id,
    required this.orderId,
    required this.buyerUid,
    required this.buyerCustomerId,
    required this.vendorUid,
    required this.vendorCustomerId,
    this.logisticsPartnerUid,
    this.logisticsPartnerName,
    required this.status,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.weightKg,
    required this.goodsDescription,
    required this.statusHistory,
    required this.createdAt,
    this.deliveredAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'orderId': orderId,
        'buyerUid': buyerUid,
        'buyerCustomerId': buyerCustomerId,
        'vendorUid': vendorUid,
        'vendorCustomerId': vendorCustomerId,
        'logisticsPartnerUid': logisticsPartnerUid,
        'logisticsPartnerName': logisticsPartnerName,
        'status': status,
        'pickupAddress': pickupAddress,
        'deliveryAddress': deliveryAddress,
        'weightKg': weightKg,
        'goodsDescription': goodsDescription,
        'statusHistory': statusHistory,
        'createdAt': createdAt.toIso8601String(),
        'deliveredAt': deliveredAt,
      };

  factory ShipmentModel.fromMap(
          Map<String, dynamic> m) =>
      ShipmentModel(
        id: m['id'] ?? '',
        orderId: m['orderId'] ?? '',
        buyerUid: m['buyerUid'] ?? '',
        buyerCustomerId: m['buyerCustomerId'] ?? '',
        vendorUid: m['vendorUid'] ?? '',
        vendorCustomerId: m['vendorCustomerId'] ?? '',
        logisticsPartnerUid: m['logisticsPartnerUid'],
        logisticsPartnerName: m['logisticsPartnerName'],
        status: m['status'] ?? 'created',
        pickupAddress: m['pickupAddress'] ?? '',
        deliveryAddress: m['deliveryAddress'] ?? '',
        weightKg: (m['weightKg'] ?? 0).toDouble(),
        goodsDescription: m['goodsDescription'] ?? '',
        statusHistory: List<Map<String, dynamic>>.from(
            m['statusHistory'] ?? []),
        createdAt: DateTime.parse(
            m['createdAt'] ??
                DateTime.now().toIso8601String()),
        deliveredAt: m['deliveredAt'],
      );
}