import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_chat_model.dart';

class ProductChatService {
  final _db = FirebaseFirestore.instance;

  Future<String> getOrCreateChat({
    required String productId,
    required String productName,
    required String buyerUid,
    required String buyerName,
    required String vendorUid,
    required String vendorName,
  }) async {
    final existing = await _db
        .collection('product_chats')
        .where('productId', isEqualTo: productId)
        .where('buyerUid', isEqualTo: buyerUid)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    final docRef =
        _db.collection('product_chats').doc();
    final chat = ProductChatModel(
      id: docRef.id,
      productId: productId,
      productName: productName,
      buyerUid: buyerUid,
      buyerName: buyerName,
      vendorUid: vendorUid,
      vendorName: vendorName,
      messages: [],
      status: 'open',
      createdAt: DateTime.now(),
    );
    await docRef.set(chat.toMap());
    return docRef.id;
  }

  Stream<ProductChatModel?> streamChat(String chatId) {
    return _db
        .collection('product_chats')
        .doc(chatId)
        .snapshots()
        .map((d) =>
            d.exists ? ProductChatModel.fromMap(d.data()!) : null);
  }

  Future<void> sendMessage(
      String chatId,
      String senderUid,
      String senderName,
      String message) async {
    await _db.collection('product_chats').doc(chatId).update({
      'messages': FieldValue.arrayUnion([
        {
          'senderUid': senderUid,
          'senderName': senderName,
          'message': message,
          'time': DateTime.now().toIso8601String(),
        }
      ]),
    });
  }

  Stream<List<ProductChatModel>> streamVendorChats(
      String vendorUid) {
    return _db
        .collection('product_chats')
        .where('vendorUid', isEqualTo: vendorUid)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ProductChatModel.fromMap(d.data()))
            .toList());
  }

  Stream<List<ProductChatModel>> streamBuyerChats(
      String buyerUid) {
    return _db
        .collection('product_chats')
        .where('buyerUid', isEqualTo: buyerUid)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ProductChatModel.fromMap(d.data()))
            .toList());
  }
}