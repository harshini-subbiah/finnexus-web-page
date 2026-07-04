class InsuranceModel {
  final String id;
  final String uid;
  final String customerId;
  final String businessName;
  final String insurerUid;
  final String insurerName;
  final String type;
  final String status;
  final double coverageAmount;
  // Trade Credit fields
  final String? buyerCustomerId;
  final String? buyerBusinessName;
  final double? invoiceValue;
  final int? creditPeriodDays;
  final String? tradeHistory;
  // GIT fields
  final String? orderId;
  final String? shipmentOrigin;
  final String? shipmentDestination;
  final String? goodsDescription;
  final double? shipmentValue;
  final String? transportMode;
  // Claim fields
  final String? claimReason;
  final String? claimStatus;
  final DateTime createdAt;
  final String? closedAt;

  InsuranceModel({
    required this.id,
    required this.uid,
    required this.customerId,
    required this.businessName,
    required this.insurerUid,
    required this.insurerName,
    required this.type,
    required this.status,
    required this.coverageAmount,
    this.buyerCustomerId,
    this.buyerBusinessName,
    this.invoiceValue,
    this.creditPeriodDays,
    this.tradeHistory,
    this.orderId,
    this.shipmentOrigin,
    this.shipmentDestination,
    this.goodsDescription,
    this.shipmentValue,
    this.transportMode,
    this.claimReason,
    this.claimStatus,
    required this.createdAt,
    this.closedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'uid': uid,
        'customerId': customerId,
        'businessName': businessName,
        'insurerUid': insurerUid,
        'insurerName': insurerName,
        'type': type,
        'status': status,
        'coverageAmount': coverageAmount,
        'buyerCustomerId': buyerCustomerId,
        'buyerBusinessName': buyerBusinessName,
        'invoiceValue': invoiceValue,
        'creditPeriodDays': creditPeriodDays,
        'tradeHistory': tradeHistory,
        'orderId': orderId,
        'shipmentOrigin': shipmentOrigin,
        'shipmentDestination': shipmentDestination,
        'goodsDescription': goodsDescription,
        'shipmentValue': shipmentValue,
        'transportMode': transportMode,
        'claimReason': claimReason,
        'claimStatus': claimStatus,
        'createdAt': createdAt.toIso8601String(),
        'closedAt': closedAt,
      };

  factory InsuranceModel.fromMap(Map<String, dynamic> map) => InsuranceModel(
        id: map['id'] ?? '',
        uid: map['uid'] ?? '',
        customerId: map['customerId'] ?? '',
        businessName: map['businessName'] ?? '',
        insurerUid: map['insurerUid'] ?? '',
        insurerName: map['insurerName'] ?? '',
        type: map['type'] ?? '',
        status: map['status'] ?? 'pending',
        coverageAmount: (map['coverageAmount'] ?? 0).toDouble(),
        buyerCustomerId: map['buyerCustomerId'],
        buyerBusinessName: map['buyerBusinessName'],
        invoiceValue: map['invoiceValue']?.toDouble(),
        creditPeriodDays: map['creditPeriodDays'],
        tradeHistory: map['tradeHistory'],
        orderId: map['orderId'],
        shipmentOrigin: map['shipmentOrigin'],
        shipmentDestination: map['shipmentDestination'],
        goodsDescription: map['goodsDescription'],
        shipmentValue: map['shipmentValue']?.toDouble(),
        transportMode: map['transportMode'],
        claimReason: map['claimReason'],
        claimStatus: map['claimStatus'],
        createdAt: DateTime.parse(map['createdAt']),
        closedAt: map['closedAt'],
      );
}