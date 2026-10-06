import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:z_speed/core/services/media_upload_service.dart';
import 'package:z_speed/features/pharmacy_chat/datasource/pharmacy_chat_datasource.dart';
import 'package:z_speed/features/pharmacy_chat/models/chat_message.dart';
import 'package:z_speed/features/pharmacy_chat/models/prescription_request.dart';
import 'package:z_speed/features/pharmacy_chat/cubit/pharmacy_chat_state.dart';

class PharmacyChatCubit extends Cubit<PharmacyChatState> {
  final PharmacyChatDatasource _datasource;
  final MediaUploadService _uploadService;

  StreamSubscription<List<ChatMessage>>? _messagesSub;
  StreamSubscription<PrescriptionRequest?>? _requestSub;
  StreamSubscription<QuerySnapshot>? _requestsSub;

  PharmacyChatCubit({
    PharmacyChatDatasource? datasource,
    MediaUploadService? uploadService,
  })  : _datasource = datasource ?? PharmacyChatDatasource(),
        _uploadService = uploadService ?? MediaUploadService(),
        super(const PharmacyChatState());

  // Helper to upload prescription image & create chat via backend service
  Future<Map<String, String>> _uploadPrescriptionViaBackend(
    XFile xFile, {
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String pharmacyId,
    required String pharmacyName,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // 1. Upload to Firebase Storage using MediaUploadService
    final uploadResult = await _uploadService.uploadXFile(
      xFile,
      'prescriptions/$customerId',
    );

    // 2. Create prescription request and chat session via datasource
    final requestId = await _datasource.createPrescriptionRequest(
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      pharmacyId: pharmacyId,
      pharmacyName: pharmacyName,
      imageUrl: uploadResult.url,
    );

    final chatId = 'chat_cust_${customerId}_pharm_$pharmacyId';

    return {
      'requestId': requestId,
      'chatId': chatId,
    };
  }

  /// Sets up real-time listener for an existing chat session and prescription.
  void initChat({required String chatId, String? requestId}) {
    emit(state.copyWith(isLoading: true, chatId: chatId, requestId: requestId));

    // Listen to messages
    _messagesSub?.cancel();
    _messagesSub = _datasource.streamMessages(chatId).listen(
      (messages) {
        emit(state.copyWith(messages: messages, isLoading: false));
      },
      onError: (e) {
        emit(state.copyWith(error: e.toString(), isLoading: false));
      },
    );

    // Listen to all prescription requests for this chat session
    _requestsSub?.cancel();
    _requestsSub = FirebaseFirestore.instance
        .collection('prescription_requests')
        .where('chatId', isEqualTo: chatId)
        .snapshots()
        .listen(
      (snap) {
        final reqs = snap.docs
            .map((d) => PrescriptionRequest.fromMap(d.data(), d.id))
            .toList();

        // Auto-select active request
        PrescriptionRequest? active = state.activeRequest;
        if (active == null) {
          if (requestId != null) {
            active = reqs.firstWhere((r) => r.id == requestId,
                orElse: () => reqs.first);
          } else if (reqs.isNotEmpty) {
            active = reqs.first;
          }
        } else {
          final activeId = active.id;
          if (!reqs.any((r) => r.id == activeId)) {
            if (requestId != null) {
              active = reqs.firstWhere((r) => r.id == requestId,
                  orElse: () => reqs.first);
            } else if (reqs.isNotEmpty) {
              active = reqs.first;
            }
          } else {
            active = reqs.firstWhere((r) => r.id == activeId);
          }
        }

        emit(state.copyWith(
          prescriptionRequests: reqs,
          activeRequest: active,
          prescriptionRequest: active,
        ));
      },
      onError: (e) {
        // Non-blocking error
      },
    );

    // Listen to prescription request if provided
    if (requestId != null) {
      _requestSub?.cancel();
      _requestSub = _datasource.streamPrescriptionRequest(requestId).listen(
        (request) {
          emit(state.copyWith(
            prescriptionRequest: request,
            activeRequest: request,
          ));
        },
        onError: (e) {
          // Non-blocking error for status updates
        },
      );
    }
  }

  /// Sets the currently active prescription request to interact with
  void selectActiveRequest(PrescriptionRequest request) {
    emit(state.copyWith(
      activeRequest: request,
      prescriptionRequest: request,
    ));
  }

  /// Uploads selected prescription photo, initiates the request & starts a chat.
  /// Returns a map containing the generated 'requestId' and 'chatId'.
  Future<Map<String, String>?> uploadPrescriptionAndStartChat({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String pharmacyId,
    required String pharmacyName,
    required XFile xFile,
  }) async {
    emit(state.copyWith(isUploadingPrescription: true, clearError: true));
    try {
      // Upload prescription image AND create chat via backend endpoint to bypass Firestore rules
      final result = await _uploadPrescriptionViaBackend(
        xFile,
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        pharmacyId: pharmacyId,
        pharmacyName: pharmacyName,
      );

      final requestId = result['requestId']!;
      final chatId = result['chatId']!;

      emit(state.copyWith(
        isUploadingPrescription: false,
        requestId: requestId,
        chatId: chatId,
      ));

      // Automatically listen to this new chat session
      initChat(chatId: chatId, requestId: requestId);

      return result;
    } catch (e) {
      emit(state.copyWith(
        isUploadingPrescription: false,
        error: 'Failed to upload prescription: ${e.toString()}',
      ));
      return null;
    }
  }

  /// Sends a text message to the pharmacy chat.
  Future<void> sendTextMessage(String text) async {
    final chatId = state.chatId;
    // final requestId = state.prescriptionRequest?.id ?? state.requestId;
    if (chatId == null || text.trim().isEmpty) return;

    final customerId = state.prescriptionRequest?.customerId ??
        chatId.replaceFirst('chat_cust_', '').split('_pharm_')[0];

    try {
      await _datasource.sendMessage(
        chatId: chatId,
        senderId: customerId,
        senderRole: 'customer',
        text: text.trim(),
      );
    } catch (e) {
      emit(state.copyWith(error: 'Failed to send message: ${e.toString()}'));
    }
  }

  /// Reopens a closed chat (if user wants to start a fresh chat or query again).
  Future<void> reopenChat() async {
    final chatId = state.chatId;
    if (chatId == null) return;
    try {
      await _datasource.reopenChat(chatId);
    } catch (e) {
      emit(state.copyWith(error: 'Failed to reopen chat: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _messagesSub?.cancel();
    _requestSub?.cancel();
    _requestsSub?.cancel();
    return super.close();
  }
}
