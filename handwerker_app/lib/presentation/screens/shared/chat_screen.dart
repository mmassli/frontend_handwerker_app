import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:handwerker_app/core/theme/app_theme.dart';
import 'package:handwerker_app/core/animations/micro_animations.dart';
import 'package:handwerker_app/data/models/models.dart';
import 'package:handwerker_app/data/providers/app_providers.dart';

final chatMessagesProvider =
    FutureProvider.family<List<ChatMessage>, String>((ref, orderId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.listMessages(orderId);
  final data = response.data['data'] as List;
  return data.map((e) => ChatMessage.fromJson(e)).toList();
});

class ChatScreen extends ConsumerStatefulWidget {
  final String orderId;
  const ChatScreen({super.key, required this.orderId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _pollTimer;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      ref.invalidate(chatMessagesProvider(widget.orderId));
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await ref.read(apiServiceProvider).sendMessage(
            widget.orderId,
            text: text,
          );
      ref.invalidate(chatMessagesProvider(widget.orderId));
    } catch (_) {}

    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.orderId));
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.slate900,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceCard,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Noch keine Nachrichten',
                      style: TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        color: AppTheme.slate500,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[messages.length - 1 - index];
                    final isMine = msg.senderId == authState.userId;
                    return _ChatBubble(
                      message: msg,
                      isMine: isMine,
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.amber),
              ),
              error: (_, __) => const Center(
                child: Text('Fehler',
                    style: TextStyle(color: AppTheme.error)),
              ),
            ),
          ),

          // Input bar
          Container(
            padding: EdgeInsets.fromLTRB(
              16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              border: Border(
                top: BorderSide(color: AppTheme.slate700, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                // Media button
                GestureDetector(
                  onTap: () {}, // Open media picker
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.slate800,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: AppTheme.slate400,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Text field
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.slate800,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 14,
                        color: AppTheme.slate100,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Nachricht...',
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Send button
                TapScale(
                  onTap: _isSending ? null : _send,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _isSending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.slate900,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: AppTheme.slate900,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;

  const _ChatBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isMine ? AppTheme.amber : AppTheme.slate800,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMine ? 16 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (message.text != null)
                Text(
                  message.text!,
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 14,
                    color: isMine ? AppTheme.slate900 : AppTheme.slate100,
                    height: 1.4,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                _formatTime(message.sentAt),
                style: TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontSize: 10,
                  color: isMine
                      ? AppTheme.slate900.withOpacity(0.5)
                      : AppTheme.slate500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
