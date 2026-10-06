import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/features/auth/model/user_model.dart';
import 'package:z_speed/features/support_chat/datasource/support_chat_datasource.dart';
import 'package:z_speed/features/support_chat/cubit/support_chat_state.dart';

class SupportChatCubit extends Cubit<SupportChatState> {
  final SupportChatDatasource _datasource;
  StreamSubscription? _messagesSubscription;

  SupportChatCubit({SupportChatDatasource? datasource})
      : _datasource = datasource ?? SupportChatDatasource(),
        super(const SupportChatState());

  Future<void> initChat(AppUser customer) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final session = await _datasource.createOrGetChatSession(customer);
      emit(state.copyWith(session: session, isLoading: false));

      // Cancel previous subscription if any
      await _messagesSubscription?.cancel();

      // Listen to messages in real-time
      _messagesSubscription = _datasource.streamMessages(customer.id).listen(
        (messages) {
          emit(state.copyWith(messages: messages));
          // Once customer opens the chat, mark it as read by customer
          _datasource.markAsReadByCustomer(customer.id);
        },
        onError: (err) {
          emit(state.copyWith(error: err.toString()));
        },
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> sendTextMessage(String text, AppUser customer) async {
    final session = state.session;
    if (session == null || text.trim().isEmpty) return;

    try {
      await _datasource.sendMessage(
        chatId: session.id,
        senderId: customer.id,
        senderRole: 'customer',
        senderName: customer.name,
        text: text.trim(),
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  @override
  Future<void> close() async {
    await _messagesSubscription?.cancel();
    return super.close();
  }
}
