class ProductModel {
  final String id;
  final String vendorUid;
  final String vendorName;
  final String vendorCustomerId;
  final String name;
  final String description;
  final String category;
  final double b2cPrice;
  final double? b2bPrice;
  final int stockQuantity;
  final String unit;
  final List<String> imageUrls;
  final String? imageBase64;
  final double rating;
  final int ratingCount;
  final bool isActive;
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.vendorUid,
    required this.vendorName,
    required this.vendorCustomerId,
    required this.name,
    required this.description,
    required this.category,
    required this.b2cPrice,
    this.b2bPrice,
    required this.stockQuantity,
    required this.unit,
    required this.imageUrls,
    this.imageBase64,
    required this.rating,
    required this.ratingCount,
    required this.isActive,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'vendorUid': vendorUid,
        'vendorName': vendorName,
        'vendorCustomerId': vendorCustomerId,
        'name': name,
        'description': description,
        'category': category,
        'b2cPrice': b2cPrice,
        'b2bPrice': b2bPrice,
        'stockQuantity': stockQuantity,
        'unit': unit,
        'imageUrls': imageUrls,
        'imageBase64': imageBase64,
        'rating': rating,
        'ratingCount': ratingCount,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ProductModel.fromMap(Map<String, dynamic> m) =>
      ProductModel(
        id: m['id'] ?? '',
        vendorUid: m['vendorUid'] ?? '',
        vendorName: m['vendorName'] ?? '',
        vendorCustomerId: m['vendorCustomerId'] ?? '',
        name: m['name'] ?? '',
        description: m['description'] ?? '',
        category: m['category'] ?? '',
        b2cPrice: (m['b2cPrice'] ?? 0).toDouble(),
        b2bPrice: m['b2bPrice']?.toDouble(),
        stockQuantity: m['stockQuantity'] ?? 0,
        unit: m['unit'] ?? 'piece',
        imageUrls: List<String>.from(m['imageUrls'] ?? []),
        imageBase64: m['imageBase64'],
        rating: (m['rating'] ?? 0).toDouble(),
        ratingCount: m['ratingCount'] ?? 0,
        isActive: m['isActive'] ?? true,
        createdAt: DateTime.parse(
            m['createdAt'] ?? DateTime.now().toIso8601String()),
      );
}