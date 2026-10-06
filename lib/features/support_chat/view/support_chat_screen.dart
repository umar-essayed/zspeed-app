import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/features/support_chat/cubit/support_chat_cubit.dart';
import 'package:z_speed/features/support_chat/cubit/support_chat_state.dart';
import 'package:z_speed/features/support_chat/models/support_chat_message.dart';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Color _brandOrange = const Color(0xFFF35535);

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthCubit>().state.user;
    if (user != null) {
      context.read<SupportChatCubit>().initChat(user);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final user = context.read<AuthCubit>().state.user;
    if (user != null) {
      context.read<SupportChatCubit>().sendTextMessage(text, user);
      _messageController.clear();

      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return BlocBuilder<SupportChatCubit, SupportChatState>(
      builder: (context, state) {
        final session = state.session;
        final isOpen = session?.isOpen ?? true;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            iconTheme: const IconThemeData(color: Colors.black87),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.liveChat,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 4,
                      backgroundColor: isOpen ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOpen ? l10n.onlineStatus : l10n.chatClosed,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              if (state.error != null)
                Container(
                  color: Colors.red.shade50,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    state.error!,
                    style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                  ),
                ),

              // Chat Messages List
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) {
                          final msg = state.messages[index];
                          final isMe = msg.senderRole == 'customer';
                          return _SupportChatBubble(
                            message: msg,
                            isMe: isMe,
                            brandOrange: _brandOrange,
                            isAr: isAr,
                          );
                        },
                      ),
              ),

              // Input panel or closed banner
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
                ),
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 10,
                  bottom: MediaQuery.of(context).padding.bottom + 10,
                ),
                child: !isOpen
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l10n.ticketClosed,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: TextField(
                                controller: _messageController,
                                minLines: 1,
                                maxLines: 5,
                                decoration: InputDecoration(
                                  hintText: l10n.typeYourMessage,
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          CircleAvatar(
                            backgroundColor: _brandOrange,
                            radius: 22,
                            child: IconButton(
                              icon: const Icon(Icons.send, color: Colors.white, size: 18),
                              onPressed: _sendMessage,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SupportChatBubble extends StatelessWidget {
  final SupportChatMessage message;
  final bool isMe;
  final Color brandOrange;
  final bool isAr;

  const _SupportChatBubble({
    required this.message,
    required this.isMe,
    required this.brandOrange,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    if (message.senderRole == 'system') {
      return Align(
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    final String timeStr = DateFormat('h:mm a').format(message.createdAt);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? brandOrange : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: isMe ? null : Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMe) ...[
              Text(
                message.senderRole == 'superAdmin' ? 'Super Admin' : 'Support',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              message.text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 14.5,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                timeStr,
                style: TextStyle(
                  color: isMe ? Colors.white60 : Colors.grey,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
