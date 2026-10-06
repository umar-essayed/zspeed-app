import 'package:equatable/equatable.dart';
import 'package:z_speed/features/pharmacy_chat/models/chat_message.dart';
import 'package:z_speed/features/pharmacy_chat/models/prescription_request.dart';

class PharmacyChatState extends Equatable {
  final bool isLoading;
  final String? error;
  final String? requestId;
  final String? chatId;
  final PrescriptionRequest? prescriptionRequest;
  final List<ChatMessage> messages;
  final bool isUploadingPrescription;
  final List<PrescriptionRequest> prescriptionRequests;
  final PrescriptionRequest? activeRequest;

  const PharmacyChatState({
    this.isLoading = false,
    this.error,
    this.requestId,
    this.chatId,
    this.prescriptionRequest,
    this.messages = const [],
    this.isUploadingPrescription = false,
    this.prescriptionRequests = const [],
    this.activeRequest,
  });

  PharmacyChatState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? requestId,
    String? chatId,
    PrescriptionRequest? prescriptionRequest,
    List<ChatMessage>? messages,
    bool? isUploadingPrescription,
    List<PrescriptionRequest>? prescriptionRequests,
    PrescriptionRequest? activeRequest,
    bool clearActiveRequest = false,
  }) {
    return PharmacyChatState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      requestId: requestId ?? this.requestId,
      chatId: chatId ?? this.chatId,
      prescriptionRequest: prescriptionRequest ?? this.prescriptionRequest,
      messages: messages ?? this.messages,
      isUploadingPrescription:
          isUploadingPrescription ?? this.isUploadingPrescription,
      prescriptionRequests: prescriptionRequests ?? this.prescriptionRequests,
      activeRequest:
          clearActiveRequest ? null : (activeRequest ?? this.activeRequest),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        error,
        requestId,
        chatId,
        prescriptionRequest,
        messages,
        isUploadingPrescription,
        prescriptionRequests,
        activeRequest,
      ];
}
