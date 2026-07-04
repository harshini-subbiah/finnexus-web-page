import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../services/product_chat_service.dart';
import '../../models/product_chat_model.dart';

class VendorChatsScreen extends StatelessWidget {
  const VendorChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Container(
      color: const Color(0xFF0D0D1A),
      padding: const EdgeInsets.all(32),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        const Text('Product Inquiries',
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 4),
        const Text(
            'Messages from buyers about your products',
            style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<List<ProductChatModel>>(
            stream: ProductChatService()
                .streamVendorChats(uid),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Text(
                        'Error loading inquiries: ${snapshot.error}',
                        style: const TextStyle(
                            color: Colors.redAccent)));
              }
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFFF8C42)));
              }
              final chats = snapshot.data!;
              if (chats.isEmpty) {
                return const Center(
                    child: Text('No inquiries yet',
                        style: TextStyle(
                            color: Colors.white38)));
              }
              return ListView.separated(
                itemCount: chats.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final c = chats[i];
                  final lastMsg = c.messages.isNotEmpty
                      ? c.messages.last['message']
                      : 'No messages yet';
                  return GestureDetector(
                    onTap: () => context.go('/product-chat',
                        extra: {'chatId': c.id}),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16162A),
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF2D2D4E)),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8C42)
                                .withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          child: const Icon(
                              Icons.chat_bubble_outline,
                              color: Color(0xFFFF8C42)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                            Text(c.productName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight:
                                        FontWeight.w600)),
                            Text('From: ${c.buyerName}',
                                style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12)),
                            Text(lastMsg.toString(),
                                style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12),
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis),
                          ]),
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            color: Colors.white38, size: 14),
                      ]),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}