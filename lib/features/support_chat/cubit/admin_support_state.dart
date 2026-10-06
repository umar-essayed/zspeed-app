import 'package:equatable/equatable.dart';
import 'package:z_speed/features/support_chat/models/support_chat_session.dart';
import 'package:z_speed/features/support_chat/models/support_chat_message.dart';

class AdminSupportState extends Equatable {
  final bool isLoading;
  final List<SupportChatSession> sessions;
  final SupportChatSession? activeSession;
  final List<SupportChatMessage> activeMessages;
  final String? error;

  const AdminSupportState({
    this.isLoading = false,
    this.sessions = const [],
    this.activeSession,
    this.activeMessages = const [],
    this.error,
  });

  AdminSupportState copyWith({
    bool? isLoading,
    List<SupportChatSession>? sessions,
    SupportChatSession? activeSession,
    List<SupportChatMessage>? activeMessages,
    String? error,
    bool clearActiveSession = false,
    bool clearError = false,
  }) {
    return AdminSupportState(
      isLoading: isLoading ?? this.isLoading,
      sessions: sessions ?? this.sessions,
      activeSession: clearActiveSession ? null : (activeSession ?? this.activeSession),
      activeMessages: activeMessages ?? this.activeMessages,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [isLoading, sessions, activeSession, activeMessages, error];
}
