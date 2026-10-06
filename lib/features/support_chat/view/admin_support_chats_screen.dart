import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/features/auth/model/user_model.dart';
import 'package:z_speed/features/support_chat/cubit/admin_support_cubit.dart';
import 'package:z_speed/features/support_chat/cubit/admin_support_state.dart';
import 'package:z_speed/features/support_chat/models/support_chat_session.dart';
import 'package:z_speed/features/support_chat/models/support_chat_message.dart';

class AdminSupportChatsScreen extends StatefulWidget {
  const AdminSupportChatsScreen({super.key});

  @override
  State<AdminSupportChatsScreen> createState() =>
      _AdminSupportChatsScreenState();
}

class _AdminSupportChatsScreenState extends State<AdminSupportChatsScreen> {
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Color _brandOrange = const Color(0xFFF35535);

  // Filter options: 'open', 'closed', 'all'
  String _filterStatus = 'open';

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendReply() {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    final admin = context.read<AuthCubit>().state.user;
    if (admin != null) {
      context.read<AdminSupportCubit>().sendAdminReply(text, admin);
      _replyController.clear();

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

  List<SupportChatSession> _filterSessions(List<SupportChatSession> sessions) {
    if (_filterStatus == 'open') {
      return sessions.where((s) => s.isOpen).toList();
    } else if (_filterStatus == 'closed') {
      return sessions.where((s) => !s.isOpen).toList();
    }
    return sessions;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adminUser = context.read<AuthCubit>().state.user;

    return BlocBuilder<AdminSupportCubit, AdminSupportState>(
      builder: (context, state) {
        final filteredSessions = _filterSessions(state.sessions);

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 768;

              if (isDesktop) {
                return Row(
                  children: [
                    // Left Pane: Session list
                    SizedBox(
                      width: 320,
                      child: _buildSessionListPane(
                        filteredSessions,
                        state.activeSession,
                      ),
                    ),
                    const VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Color(0xFFEEEEEE),
                    ),
                    // Right Pane: Active chat or placeholder
                    Expanded(
                      child: state.activeSession == null
                          ? _buildPlaceholderPane(l10n)
                          : _buildActiveChatPane(
                              state.activeSession!,
                              state.activeMessages,
                              adminUser,
                            ),
                    ),
                  ],
                );
              } else {
                // Mobile layout: show list, or chat detail if activeSession is selected
                if (state.activeSession != null) {
                  return Scaffold(
                    appBar: AppBar(
                      backgroundColor: Colors.white,
                      elevation: 0.5,
                      leading: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.black87,
                        ),
                        onPressed: () {
                          // Clear active session to return to list
                          context
                              .read<AdminSupportCubit>()
                              .clearActiveSession();
                          context.read<AdminSupportCubit>().loadSessions();
                        },
                      ),
                      title: Text(state.activeSession!.customerName),
                    ),
                    body: _buildActiveChatPane(
                      state.activeSession!,
                      state.activeMessages,
                      adminUser,
                    ),
                  );
                } else {
                  return _buildSessionListPane(filteredSessions, null);
                }
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildSessionListPane(
    List<SupportChatSession> sessions,
    SupportChatSession? activeSession,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Filter Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'open',
                        label: Text(l10n.localeName == 'ar' ? 'مفتوح' : 'Open'),
                      ),
                      ButtonSegment(
                        value: 'closed',
                        label: Text(
                          l10n.localeName == 'ar' ? 'مغلق' : 'Closed',
                        ),
                      ),
                      ButtonSegment(
                        value: 'all',
                        label: Text(l10n.localeName == 'ar' ? 'الكل' : 'All'),
                      ),
                    ],
                    selected: {_filterStatus},
                    onSelectionChanged: (val) {
                      setState(() {
                        _filterStatus = val.first;
                      });
                    },
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: _brandOrange,
                      selectedForegroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // List
          Expanded(
            child: sessions.isEmpty
                ? Center(
                    child: Text(
                      l10n.noSupportChats,
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                : ListView.separated(
                    itemCount: sessions.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final s = sessions[index];
                      final isActive = activeSession?.id == s.id;
                      final bool isBold = s.unreadByAdmin;

                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          selected: isActive,
                          selectedTileColor: _brandOrange.withValues(
                            alpha: 0.05,
                          ),
                          onTap: () {
                            context
                                .read<AdminSupportCubit>()
                                .selectActiveSession(s);
                          },
                          leading: CircleAvatar(
                            backgroundColor: isActive
                                ? _brandOrange
                                : Colors.grey.shade200,
                            foregroundColor: isActive
                                ? Colors.white
                                : Colors.black87,
                            child: Text(
                              s.customerName.isNotEmpty
                                  ? s.customerName[0].toUpperCase()
                                  : 'C',
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s.customerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: isBold
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              if (s.unreadByAdmin)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isBold ? Colors.black87 : Colors.grey,
                                  fontWeight: isBold
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat(
                                  'MMM d, h:mm a',
                                ).format(s.lastMessageAt),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderPane(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.support_agent_rounded,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.localeName == 'ar'
                ? 'حدد محادثة من القائمة للبدء'
                : 'Select a chat from list to begin',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveChatPane(
    SupportChatSession session,
    List<SupportChatMessage> messages,
    AppUser? adminUser,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = l10n.localeName == 'ar';

    return Column(
      children: [
        // Action Header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      session.customerEmail,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<AdminSupportCubit>().toggleSessionStatus(
                    session.id,
                    !session.isOpen,
                  );
                },
                icon: Icon(
                  session.isOpen ? Icons.lock : Icons.lock_open,
                  size: 16,
                  color: Colors.white,
                ),
                label: Text(
                  session.isOpen ? l10n.closeChat : l10n.reopenChat,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: session.isOpen
                      ? Colors.red.shade600
                      : Colors.green.shade600,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Chat list
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              final isMe =
                  msg.senderRole == 'admin' || msg.senderRole == 'superAdmin';
              return _AdminChatBubble(
                message: msg,
                isMe: isMe,
                brandOrange: _brandOrange,
              );
            },
          ),
        ),

        // Input
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
          child: !session.isOpen
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
                          controller: _replyController,
                          minLines: 1,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: isAr
                                ? 'اكتب ردك هنا...'
                                : 'Type your reply here...',
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
                        icon: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: _sendReply,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _AdminChatBubble extends StatelessWidget {
  final SupportChatMessage message;
  final bool isMe;
  final Color brandOrange;

  const _AdminChatBubble({
    required this.message,
    required this.isMe,
    required this.brandOrange,
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
                message.senderName,
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
