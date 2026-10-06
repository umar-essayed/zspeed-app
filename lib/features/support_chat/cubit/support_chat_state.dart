import 'package:equatable/equatable.dart';
import 'package:z_speed/features/support_chat/models/support_chat_session.dart';
import 'package:z_speed/features/support_chat/models/support_chat_message.dart';

class SupportChatState extends Equatable {
  final bool isLoading;
  final SupportChatSession? session;
  final List<SupportChatMessage> messages;
  final String? error;

  const SupportChatState({
    this.isLoading = false,
    this.session,
    this.messages = const [],
    this.error,
  });

  SupportChatState copyWith({
    bool? isLoading,
    SupportChatSession? session,
    List<SupportChatMessage>? messages,
    String? error,
    bool clearError = false,
  }) {
    return SupportChatState(
      isLoading: isLoading ?? this.isLoading,
      session: session ?? this.session,
      messages: messages ?? this.messages,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [isLoading, session, messages, error];
}
