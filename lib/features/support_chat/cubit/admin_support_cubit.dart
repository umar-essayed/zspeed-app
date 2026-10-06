import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/features/auth/model/user_model.dart';
import 'package:z_speed/features/support_chat/datasource/support_chat_datasource.dart';
import 'package:z_speed/features/support_chat/models/support_chat_session.dart';
import 'package:z_speed/features/support_chat/cubit/admin_support_state.dart';

class AdminSupportCubit extends Cubit<AdminSupportState> {
  final SupportChatDatasource _datasource;
  StreamSubscription? _sessionsSubscription;
  StreamSubscription? _messagesSubscription;

  AdminSupportCubit({SupportChatDatasource? datasource})
      : _datasource = datasource ?? SupportChatDatasource(),
        super(const AdminSupportState());

  void loadSessions() {
    emit(state.copyWith(isLoading: true, clearError: true));
    _sessionsSubscription?.cancel();
    _sessionsSubscription = _datasource.streamSupportSessions().listen(
      (sessions) {
        emit(state.copyWith(sessions: sessions, isLoading: false));
        
        // If there's an active session, update its properties in the state
        if (state.activeSession != null) {
          final updatedActive = sessions.firstWhere(
            (s) => s.id == state.activeSession!.id,
            orElse: () => state.activeSession!,
          );
          emit(state.copyWith(activeSession: updatedActive));
        }
      },
      onError: (err) {
        emit(state.copyWith(isLoading: false, error: err.toString()));
      },
    );
  }

  void selectActiveSession(SupportChatSession session) {
    emit(state.copyWith(activeSession: session, clearError: true));
    
    // Mark as read by admin in Firestore
    _datasource.markAsReadByAdmin(session.id);

    // Cancel message subscription
    _messagesSubscription?.cancel();

    // Listen to messages of active session
    _messagesSubscription = _datasource.streamMessages(session.id).listen(
      (messages) {
        emit(state.copyWith(activeMessages: messages));
      },
      onError: (err) {
        emit(state.copyWith(error: err.toString()));
      },
    );
  }

  void clearActiveSession() {
    _messagesSubscription?.cancel();
    emit(state.copyWith(clearActiveSession: true, activeMessages: const []));
  }

  Future<void> sendAdminReply(String text, AppUser admin) async {
    final session = state.activeSession;
    if (session == null || text.trim().isEmpty) return;

    try {
      await _datasource.sendMessage(
        chatId: session.id,
        senderId: admin.id,
        senderRole: admin.type.name, // 'admin' or 'superAdmin'
        senderName: admin.name,
        text: text.trim(),
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> toggleSessionStatus(String chatId, bool isOpen) async {
    try {
      await _datasource.toggleChatStatus(chatId, isOpen);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  @override
  Future<void> close() async {
    await _sessionsSubscription?.cancel();
    await _messagesSubscription?.cancel();
    return super.close();
  }
}
