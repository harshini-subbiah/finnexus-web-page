class ProductChatModel {
  final String id;
  final String productId;
  final String productName;
  final String buyerUid;
  final String buyerName;
  final String vendorUid;
  final String vendorName;
  final List<Map<String, dynamic>> messages;
  final String status; // open, closed
  final DateTime createdAt;

  ProductChatModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.buyerUid,
    required this.buyerName,
    required this.vendorUid,
    required this.vendorName,
    required this.messages,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'productId': productId,
        'productName': productName,
        'buyerUid': buyerUid,
        'buyerName': buyerName,
        'vendorUid': vendorUid,
        'vendorName': vendorName,
        'messages': messages,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ProductChatModel.fromMap(
          Map<String, dynamic> m) =>
      ProductChatModel(
        id: m['id'] ?? '',
        productId: m['productId'] ?? '',
        productName: m['productName'] ?? '',
        buyerUid: m['buyerUid'] ?? '',
        buyerName: m['buyerName'] ?? '',
        vendorUid: m['vendorUid'] ?? '',
        vendorName: m['vendorName'] ?? '',
        messages: List<Map<String, dynamic>>.from(
            m['messages'] ?? []),
        status: m['status'] ?? 'open',
        createdAt: DateTime.parse(m['createdAt'] ??
            DateTime.now().toIso8601String()),
      );
}