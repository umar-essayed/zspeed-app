import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:z_speed/core/core.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/features/admin/model/application_model.dart';
import 'package:z_speed/features/admin/repository/application_repository.dart';
import 'package:z_speed/features/admin/repository/application_repository_impl.dart';
import 'package:z_speed/features/auth/model/user_model.dart';
import 'package:z_speed/features/auth/repository/auth_repository.dart';
import 'package:z_speed/features/auth/repository/auth_repository_impl.dart';
import 'package:z_speed/core/services/media_upload_service.dart';
import 'package:z_speed/features/restaurant_owner/widgets/documents_step.dart';
import 'package:z_speed/features/restaurant/datasource/cuisine_type_datasource.dart';
import 'package:z_speed/core/injection.dart';
import 'package:z_speed/core/services/routing_service.dart';
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_application_state.dart';
import 'package:injectable/injectable.dart' hide Order;

@injectable
class RestaurantApplicationCubit extends Cubit<RestaurantApplicationState> {
  final AuthRepository _authRepo;
  final ApplicationRepository _appRepo;
  final MediaUploadService _uploadService;
  final CuisineTypeDatasource _cuisineDatasource;

  RestaurantApplicationCubit({
    AuthRepository? authRepo,
    ApplicationRepository? appRepo,
    MediaUploadService? uploadService,
    CuisineTypeDatasource? cuisineDatasource,
  })  : _authRepo = authRepo ?? AuthRepositoryImpl(),
        _appRepo = appRepo ?? ApplicationRepositoryImpl(),
        _uploadService = uploadService ?? MediaUploadService(),
        _cuisineDatasource =
            cuisineDatasource ?? getIt<CuisineTypeDatasource>(),
        super(_getInitialState()) {
    _loadCuisines();
  }

  static RestaurantApplicationState _getInitialState() {
    return RestaurantApplicationState(
      operatingHours: {
        for (final day in [
          'Saturday',
          'Sunday',
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
        ])
          day: {
            'open': const TimeOfDay(hour: 9, minute: 0),
            'close': const TimeOfDay(hour: 22, minute: 0),
            'closed': day == 'Friday',
          },
      },
    );
  }

  void reset() {
    emit(_getInitialState().copyWith(
        availableCuisines: state.availableCuisines, isLoadingCuisines: false));
  }

  Future<void> _loadCuisines() async {
    try {
      final cuisines = await _cuisineDatasource.getAll();
      final activeCuisines = cuisines.where((c) => c.isActive).toList();
      emit(state.copyWith(
        availableCuisines: activeCuisines,
        isLoadingCuisines: false,
      ));
    } catch (e) {
      debugPrint('Failed to load cuisines: $e');
      emit(state.copyWith(isLoadingCuisines: false));
    }
  }

  static List<String> getStepLabels(AppLocalizations l10n) => [
        l10n.vendorTypeStep,
        l10n.accountSetup,
        l10n.businessInfoStep,
        l10n.locationAndHoursStep,
        l10n.documentsStep,
        l10n.brandingStep,
        l10n.bankInfoStep,
        l10n.reviewStep,
      ];

  void goToStep(int step) {
    if (step >= 0 && step < RestaurantApplicationState.totalSteps) {
      emit(state.copyWith(
        currentStep: step,
        clearError: true,
      ));
    }
  }

  void nextStep() => goToStep(state.currentStep + 1);
  void previousStep() => goToStep(state.currentStep - 1);

  void setVendorType(VendorType type) {
    if (state.vendorType == type) return;
    emit(state.copyWith(vendorType: type, selectedCuisines: []));
  }

  void setSelectedCuisines(List<String> cuisines) {
    emit(state.copyWith(selectedCuisines: cuisines));
  }

  void toggleCuisine(String cuisine) {
    final updated = List<String>.from(state.selectedCuisines);
    if (updated.contains(cuisine)) {
      updated.remove(cuisine);
    } else {
      updated.add(cuisine);
    }
    emit(state.copyWith(selectedCuisines: updated));
  }

  void updateHours(String day, String field, dynamic value) {
    final updated =
        Map<String, Map<String, dynamic>>.from(state.operatingHours);
    updated[day] = Map<String, dynamic>.from(updated[day]!);
    updated[day]![field] = value;
    emit(state.copyWith(operatingHours: updated));
  }

  Map<String, dynamic> _serialiseHours() {
    return state.operatingHours.map((day, hours) {
      final isClosed = hours['closed'] as bool;
      final open = hours['open'] as TimeOfDay;
      final close = hours['close'] as TimeOfDay;
      return MapEntry(day, {
        'closed': isClosed,
        if (!isClosed)
          'open': '${open.hour}:${open.minute.toString().padLeft(2, '0')}',
        if (!isClosed)
          'close': '${close.hour}:${close.minute.toString().padLeft(2, '0')}',
      });
    });
  }

  void setDocument(String label, XFile file) {
    final docs = Map<String, XFile?>.from(state.pickedDocuments);
    docs[label] = file;
    final statuses =
        Map<String, RestaurantUploadStatus>.from(state.uploadStatuses);
    statuses[label] = RestaurantUploadStatus();
    emit(state.copyWith(pickedDocuments: docs, uploadStatuses: statuses));
  }

  void setLogoImage(XFile file) {
    emit(state.copyWith(logoImage: file));
  }

  void setCoverImage(XFile file) {
    emit(state.copyWith(coverImage: file));
  }

  Future<String?> getCurrentLocation() async {
    emit(state.copyWith(isGettingLocation: true));

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      final position = await Geolocator.getCurrentPosition();

      // Reverse geocode to get the address
      final address = await RoutingService.instance.reverseGeocode(
        position.latitude,
        position.longitude,
      );

      emit(state.copyWith(
        isGettingLocation: false,
        latitude: position.latitude,
        longitude: position.longitude,
      ));

      return address;
    } catch (e) {
      debugPrint('Failed to get location: $e');
      emit(state.copyWith(isGettingLocation: false));
      return null;
    }
  }

  void setLocation(double lat, double lng) {
    emit(state.copyWith(latitude: lat, longitude: lng));
  }

  Future<AppUser?> submitApplication({
    required Map<String, dynamic> businessInfo,
    required Map<String, dynamic> contactInfo,
    required Map<String, dynamic> bankInfo,
    required String password,
    required String creatingAccountLabel,
    required String uploadingDocsLabel,
    required String uploadingBrandingLabel,
    required String savingAppLabel,
  }) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      // 1. Register
      emit(state.copyWith(uploadStageLabel: creatingAccountLabel));

      final email = contactInfo['ownerEmail'] as String? ?? '';
      final ownerName = businessInfo['ownerName'] as String? ?? '';

      AppUser user;
      final currentUserResult = await _authRepo.getCurrentUser();
      if (currentUserResult.isSuccess &&
          currentUserResult.data != null &&
          currentUserResult.data!.email.trim().toLowerCase() ==
              email.trim().toLowerCase()) {
        user = currentUserResult.data!;
        debugPrint('[RestaurantApp] User already registered and signed in with matching email: $email. Skipping registration.');
      } else {
        final newUser = AppUser(
          id: '',
          name: ownerName,
          email: email,
          type: UserType.vendor,
          phone: contactInfo['ownerPhone'] as String?,
          latitude: state.latitude,
          longitude: state.longitude,
          password: password,
          applicationStatus: ApplicationStatus.pending,
        );

        final regResult = await _authRepo.register(newUser);
        switch (regResult) {
          case Err(:final failure):
            emit(state.copyWith(isLoading: false, error: failure.message));
            return null;
          case Success():
            break;
        }

        final userResult = await _authRepo.getCurrentUser();
        switch (userResult) {
          case Success(:final data):
            user = data;
          case Err():
            user = newUser;
        }
      }
      emit(state.copyWith(registeredUser: user));

      // 2. Upload documents
      emit(state.copyWith(uploadStageLabel: uploadingDocsLabel));
      final uploadedDocs = await _uploadAllDocuments(user.id);

      // Validate that all required documents were successfully uploaded (no missing/empty URLs)
      final requiredKeys = ['commercialRegistration', 'businessLicense', 'healthCertificate', 'taxRegistration'];
      final hasEmptyDocs = requiredKeys.any((key) => !uploadedDocs.containsKey(key) || uploadedDocs[key]!.isEmpty);
      if (hasEmptyDocs) {
        emit(state.copyWith(
          isLoading: false,
          uploadStageLabel: '',
          error: 'فشل رفع بعض المستندات المطلوبة. يرجى إعادة المحاولة والتأكد من جودة اتصال الإنترنت.',
        ));
        return null;
      }

      // 3. Upload branding
      emit(state.copyWith(uploadStageLabel: uploadingBrandingLabel));
      final brandingUrls = await _uploadBrandingImages(user.id);

      // 4. Submit application
      emit(state.copyWith(uploadStageLabel: savingAppLabel));

      final formData = <String, dynamic>{
        'vendorType': state.vendorType.name,
        'businessInfo': {
          ...businessInfo,
          'cuisines': state.selectedCuisines,
        },
        'locationInfo': {
          'address': contactInfo['address'] ?? businessInfo['address'] ?? '',
          'city': contactInfo['city'] ?? businessInfo['city'] ?? '',
          'latitude': state.latitude,
          'longitude': state.longitude,
          'operatingHours': _serialiseHours(),
        },
        'contactInfo': contactInfo,
        'bankInfo': bankInfo,
        'branding': brandingUrls,
        'documents': uploadedDocs,
      };

      final documentUrls = [
        uploadedDocs['commercialRegistration'] ?? '',
        uploadedDocs['businessLicense'] ?? '',
        uploadedDocs['healthCertificate'] ?? '',
        uploadedDocs['taxRegistration'] ?? '',
      ];

      final submitResult = await _appRepo.submitApplication(
        userId: user.id,
        type: ApplicationType.restaurant,
        formData: formData,
        documentUrls: documentUrls,
      );

      switch (submitResult) {
        case Err(:final failure):
          emit(state.copyWith(isLoading: false, error: failure.message));
          return null;
        case Success():
          break;
      }

      emit(state.copyWith(isLoading: false, uploadStageLabel: ''));
      return user;
    } catch (e) {
      emit(state.copyWith(
          isLoading: false, uploadStageLabel: '', error: e.toString()));
      return null;
    }
  }

  Future<Map<String, String>> _uploadAllDocuments(String userId) async {
    await _uploadService.authorize();
    final urls = <String, String>{};

    for (final entry in state.pickedDocuments.entries) {
      final file = entry.value;
      if (file == null) continue;

      final statuses =
          Map<String, RestaurantUploadStatus>.from(state.uploadStatuses);
      statuses[entry.key] = RestaurantUploadStatus(isUploading: true);
      emit(state.copyWith(uploadStatuses: statuses));

      try {
        final result = await _uploadService.uploadXFile(
          file,
          'restaurants/$userId/documents',
          onProgress: (p) {
            final s =
                Map<String, RestaurantUploadStatus>.from(state.uploadStatuses);
            s[entry.key] =
                RestaurantUploadStatus(isUploading: true, progress: p);
            emit(state.copyWith(uploadStatuses: s));
          },
        );
        final s =
            Map<String, RestaurantUploadStatus>.from(state.uploadStatuses);
        s[entry.key] = RestaurantUploadStatus(
          isUploading: false,
          progress: 1.0,
          resultUrl: result.url,
        );
        emit(state.copyWith(uploadStatuses: s));
        urls[entry.key] = result.url;
      } catch (e) {
        final s =
            Map<String, RestaurantUploadStatus>.from(state.uploadStatuses);
        s[entry.key] = RestaurantUploadStatus(
          isUploading: false,
          hasError: true,
          errorMessage: 'Upload failed: $e',
        );
        emit(state.copyWith(uploadStatuses: s));
      }
    }

    return urls;
  }

  Future<Map<String, String>> _uploadBrandingImages(String userId) async {
    final result = <String, String>{};

    if (state.logoImage != null) {
      final logoResult = await _uploadService.uploadXFile(
        state.logoImage!,
        'restaurants/$userId/branding',
      );
      result['logoUrl'] = logoResult.url;
    }

    if (state.coverImage != null) {
      final coverResult = await _uploadService.uploadXFile(
        state.coverImage!,
        'restaurants/$userId/branding',
      );
      result['coverUrl'] = coverResult.url;
    }

    return result;
  }
}
