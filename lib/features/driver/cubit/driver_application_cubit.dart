import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:z_speed/core/core.dart';
import 'package:z_speed/core/services/media_upload_service.dart';
import 'package:z_speed/features/admin/model/application_model.dart';
import 'package:z_speed/features/admin/repository/application_repository.dart';
import 'package:z_speed/features/auth/model/user_model.dart';
import 'package:z_speed/features/auth/repository/auth_repository.dart';
import 'package:z_speed/features/driver/cubit/driver_application_state.dart';
import 'package:injectable/injectable.dart' hide Order;

@injectable
class DriverApplicationCubit extends Cubit<DriverApplicationState> {
  final AuthRepository _authRepo;
  final ApplicationRepository _appRepo;
  final MediaUploadService _mediaService;

  static const int totalSteps = 5;
  static const List<String> stepLabels = [
    'Account',
    'Personal Info',
    'Vehicle',
    'Documents',
    'Review',
  ];

  static const List<String> requiredDocumentLabels = [
    'National ID',
    'Driver\'s License',
    'Vehicle Registration',
    'Vehicle Insurance',
    'Police Clearance',
    'Face Photo',
    'Vehicle Photo',
  ];

  DriverApplicationCubit({
    required this._authRepo,
    required this._appRepo,
    required this._mediaService,
  }) : super(const DriverApplicationState());

  int get currentStep => state.currentStep;
  ViewState get stateStatus => state.state;
  String get uploadStageLabel => state.uploadStageLabel;
  Map<String, XFile> get pickedDocuments => state.pickedDocuments;
  Map<String, String> get uploadStatuses => state.uploadStatuses;
  bool get allDocumentsPicked => state.allDocumentsPicked;
  dynamic get failure => state.failure;

  void goToStep(int step) {
    if (step >= 0 && step < totalSteps) {
      emit(
        state.copyWith(
          currentStep: step,
          state: ViewState.initial,
          clearFailure: true,
        ),
      );
    }
  }

  void nextStep() {
    if (state.currentStep < totalSteps - 1) {
      emit(
        state.copyWith(
          currentStep: state.currentStep + 1,
          state: ViewState.initial,
          clearFailure: true,
        ),
      );
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      emit(
        state.copyWith(
          currentStep: state.currentStep - 1,
          state: ViewState.initial,
          clearFailure: true,
        ),
      );
    }
  }

  void setDocument(String label, XFile file) {
    final docs = Map<String, XFile>.from(state.pickedDocuments);
    docs[label] = file;
    emit(state.copyWith(pickedDocuments: docs));
  }

  Future<AppUser?> submitApplication({
    required Map<String, dynamic> personalInfo,
    required Map<String, dynamic> vehicleInfo,
    required String password,
  }) async {
    emit(
      state.copyWith(
        state: ViewState.loading,
        uploadStageLabel: 'Creating account...',
        clearFailure: true,
      ),
    );

    try {
      final email = personalInfo['email'] as String;
      final currentUserResult = await _authRepo.getCurrentUser();
      String userId;
      AppUser? currentUser;

      if (currentUserResult.isSuccess &&
          currentUserResult.data != null &&
          currentUserResult.data!.email.trim().toLowerCase() ==
              email.trim().toLowerCase()) {
        currentUser = currentUserResult.data;
        userId = currentUser!.id;
        log(
          '[DriverApp] User already registered and signed in with matching email: $email. Skipping registration.',
        );
      } else {
        final newUser = AppUser(
          id: '',
          email: email,
          name: personalInfo['name'] as String,
          type: UserType.driver,
          phone: personalInfo['phone'] as String,
          applicationStatus: ApplicationStatus.pending,
        );

        final regResult = await _authRepo.register(
          newUser.copyWith(password: password),
        );
        switch (regResult) {
          case Err(:final failure):
            emit(
              state.copyWith(
                state: ViewState.error,
                failure: failure,
                uploadStageLabel: '',
              ),
            );
            return null;
          case Success():
            break;
        }

        final accountResult = await _authRepo.getCurrentUser();
        if (!accountResult.isSuccess || accountResult.data == null) {
          emit(
            state.copyWith(
              state: ViewState.error,
              failure: accountResult.failure,
              uploadStageLabel: '',
            ),
          );
          return null;
        }
        currentUser = accountResult.data!;
        userId = currentUser.id;
      }

      emit(state.copyWith(uploadStageLabel: 'Uploading documents...'));
      final documentUrls = await _uploadAllDocuments(userId);

      // Validate that all documents uploaded successfully (no empty links)
      final failedLabels = <String>[];
      for (int i = 0; i < requiredDocumentLabels.length; i++) {
        if (i >= documentUrls.length || documentUrls[i].isEmpty) {
          failedLabels.add(requiredDocumentLabels[i]);
        }
      }

      if (failedLabels.isNotEmpty) {
        final failed = failedLabels.join(', ');
        log('[DriverApp] Submission blocked — failed uploads: $failed');
        emit(
          state.copyWith(
            state: ViewState.error,
            failure: ServerFailure(
              'فشل رفع: $failed\nيرجى إعادة المحاولة والتأكد من جودة اتصال الإنترنت.',
            ),
            uploadStageLabel: '',
          ),
        );
        return null;
      }

      emit(state.copyWith(uploadStageLabel: 'Saving application...'));

      final documentsMap = {
        'nationalId': documentUrls.isNotEmpty ? documentUrls[0] : '',
        'driversLicense': documentUrls.length > 1 ? documentUrls[1] : '',
        'vehicleRegistration': documentUrls.length > 2 ? documentUrls[2] : '',
        'vehicleInsurance': documentUrls.length > 3 ? documentUrls[3] : '',
        'policeClearance': documentUrls.length > 4 ? documentUrls[4] : '',
        'facePhoto': documentUrls.length > 5 ? documentUrls[5] : '',
        'vehiclePhoto': documentUrls.length > 6 ? documentUrls[6] : '',
      };

      final formData = {
        'personalInfo': personalInfo,
        'vehicleInfo': vehicleInfo,
        'documents': documentsMap,
      };

      final submitResult = await _appRepo.submitApplication(
        userId: userId,
        type: ApplicationType.driver,
        formData: formData,
        documentUrls: documentUrls,
      );

      if (!submitResult.isSuccess) {
        emit(
          state.copyWith(
            state: ViewState.error,
            failure: submitResult.failure,
            uploadStageLabel: '',
          ),
        );
        return null;
      }

      emit(state.copyWith(state: ViewState.success, uploadStageLabel: ''));
      return currentUser;
    } catch (e) {
      emit(
        state.copyWith(
          state: ViewState.error,
          failure: ServerFailure(e.toString()),
          uploadStageLabel: '',
        ),
      );
      return null;
    }
  }

  Future<List<String>> _uploadAllDocuments(String userId) async {
    final List<String> urls = [];
    final docs = state.pickedDocuments;
    final statuses = Map<String, String>.from(state.uploadStatuses);

    for (final label in requiredDocumentLabels) {
      final file = docs[label];
      if (file == null) {
        log('[DriverApp] No file picked for "$label" — skipping');
        urls.add('');
        continue;
      }

      statuses[label] = 'uploading';
      emit(state.copyWith(uploadStatuses: statuses));

      try {
        log(
          '[DriverApp] Uploading "$label": name=${file.name} mimeType=${file.mimeType} path=${file.path.substring(0, file.path.length > 40 ? 40 : file.path.length)}',
        );
        final result = await _mediaService.uploadXFile(
          file,
          'drivers/$userId/documents',
        );
        log(
          '[DriverApp] Upload OK "$label" → ${result.url.substring(0, 60)}...',
        );
        statuses[label] = 'done';
        urls.add(result.url);
      } catch (e) {
        log('[DriverApp] Upload FAILED "$label": $e');
        statuses[label] = 'error';
        urls.add(''); // Keep index alignment in case of error
      }
      emit(state.copyWith(uploadStatuses: statuses));
    }

    return urls;
  }
}
