import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductService {
  final _db = FirebaseFirestore.instance;

  Future<void> addProduct(ProductModel p) async {
    await _db
        .collection('products')
        .doc(p.id)
        .set(p.toMap());
  }

  Future<void> updateProduct(
      String id, Map<String, dynamic> data) async {
    await _db
        .collection('products')
        .doc(id)
        .update(data);
  }

  Future<void> deleteProduct(String id) async {
    await _db
        .collection('products')
        .doc(id)
        .update({'isActive': false});
  }

  Stream<List<ProductModel>> streamAllProducts(
      {String? category, String? search}) {
    Query<Map<String, dynamic>> q = _db
        .collection('products')
        .where('isActive', isEqualTo: true);
    if (category != null && category != 'All') {
      q = q.where('category', isEqualTo: category);
    }
    return q.snapshots().map((s) {
      var list = s.docs
          .map((d) => ProductModel.fromMap(d.data()))
          .toList();
      if (search != null && search.isNotEmpty) {
        final sq = search.toLowerCase();
        list = list
            .where((p) =>
                p.name.toLowerCase().contains(sq) ||
                p.description
                    .toLowerCase()
                    .contains(sq) ||
                p.vendorName
                    .toLowerCase()
                    .contains(sq))
            .toList();
      }
      return list;
    });
  }

  Stream<List<ProductModel>> streamVendorProducts(
      String vendorUid) {
    return _db
        .collection('products')
        .where('vendorUid', isEqualTo: vendorUid)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ProductModel.fromMap(d.data()))
            .toList());
  }

  Future<void> updateRating(
      String productId, double newRating) async {
    final doc = await _db
        .collection('products')
        .doc(productId)
        .get();
    if (!doc.exists) return;
    final data = doc.data()!;
    final oldRating = (data['rating'] ?? 0).toDouble();
    final count = (data['ratingCount'] ?? 0) + 1;
    final updated =
        ((oldRating * (count - 1)) + newRating) / count;
    await _db
        .collection('products')
        .doc(productId)
        .update({
      'rating': updated,
      'ratingCount': count,
    });
  }
}