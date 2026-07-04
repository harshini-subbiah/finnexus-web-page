import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../services/product_chat_service.dart';
import '../../models/product_chat_model.dart';

class ProductChatScreen extends StatefulWidget {
  const ProductChatScreen({super.key});
  @override
  State<ProductChatScreen> createState() =>
      _ProductChatScreenState();
}

class _ProductChatScreenState extends State<ProductChatScreen> {
  String? _chatId;
  final _msgCtrl = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra
        as Map<String, dynamic>?;
    if (extra != null) {
      _chatId = extra['chatId'];
    }
  }

  Future<void> _send() async {
    if (_msgCtrl.text.trim().isEmpty || _chatId == null) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final email =
        FirebaseAuth.instance.currentUser!.email ?? '';
    await ProductChatService().sendMessage(
        _chatId!, uid, email, _msgCtrl.text.trim());
    _msgCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (_chatId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.go('/catalogue'),
            child: const Text('Go to Catalogue'),
          ),
        ),
      );
    }
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16162A),
        title: const Text('Product Inquiry',
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Colors.white),
          onPressed: () => context.go('/catalogue'),
        ),
      ),
      body: StreamBuilder<ProductChatModel?>(
        stream: ProductChatService().streamChat(_chatId!),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF6C63FF)));
          }
          final chat = snapshot.data!;
          return Column(children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF12121E),
              child: Row(children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                    Text(chat.productName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                    Text('Vendor: ${chat.vendorName}',
                        style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12)),
                  ]),
                ),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              color: const Color(0xFF6C63FF).withOpacity(0.08),
              child: const Row(children: [
                Icon(Icons.info_outline,
                    color: Color(0xFF6C63FF), size: 14),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                      'Use this chat to negotiate price, ask for bulk quotes, or clarify product details before purchasing.',
                      style: TextStyle(
                          color: Color(0xFF6C63FF),
                          fontSize: 11)),
                ),
              ]),
            ),
            Expanded(
              child: chat.messages.isEmpty
                  ? const Center(
                      child: Text(
                          'No messages yet. Say hello!',
                          style: TextStyle(
                              color: Colors.white38)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: chat.messages.length,
                      itemBuilder: (context, i) {
                        final msg = chat.messages[i];
                        final isMe =
                            msg['senderUid'] == uid;
                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(
                                bottom: 10),
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10),
                            constraints:
                                const BoxConstraints(
                                    maxWidth: 320),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? const Color(0xFF6C63FF)
                                  : const Color(0xFF16162A),
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                              Text(
                                  msg['senderName'] ?? '',
                                  style: TextStyle(
                                      color: isMe
                                          ? Colors.white70
                                          : Colors.white38,
                                      fontSize: 10)),
                              const SizedBox(height: 2),
                              Text(msg['message'] ?? '',
                                  style: const TextStyle(
                                      color: Colors.white)),
                            ]),
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              color: const Color(0xFF16162A),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    style:
                        const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(
                          color: Colors.white30),
                      filled: true,
                      fillColor: const Color(0xFF0D0D1A),
                      contentPadding:
                          const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(24),
                          borderSide: const BorderSide(
                              color: Color(0xFF2D2D4E))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(24),
                          borderSide: const BorderSide(
                              color: Color(0xFF2D2D4E))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(24),
                          borderSide: const BorderSide(
                              color: Color(0xFF6C63FF))),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF6C63FF),
                  child: IconButton(
                    icon: const Icon(Icons.send,
                        color: Colors.white, size: 18),
                    onPressed: _send,
                  ),
                ),
              ]),
            ),
          ]);
        },
      ),
    );
  }
}