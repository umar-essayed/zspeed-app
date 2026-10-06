import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:z_speed/features/auth/model/user_model.dart';
import 'package:z_speed/features/restaurant_owner/widgets/documents_step.dart';
import 'package:z_speed/features/restaurant/model/cuisine_type.dart';

class RestaurantApplicationState extends Equatable {
  final bool isLoading;
  final String? error;
  final int currentStep;
  final List<String> selectedCuisines;
  final Map<String, Map<String, dynamic>> operatingHours;
  final Map<String, XFile?> pickedDocuments;
  final Map<String, RestaurantUploadStatus> uploadStatuses;
  final XFile? logoImage;
  final XFile? coverImage;
  final String uploadStageLabel;
  final double? latitude;
  final double? longitude;
  final bool isGettingLocation;
  final AppUser? registeredUser;
  final List<CuisineType> availableCuisines;
  final bool isLoadingCuisines;
  final VendorType vendorType;

  static const int totalSteps = 8;

  const RestaurantApplicationState({
    this.isLoading = false,
    this.error,
    this.currentStep = 0,
    this.selectedCuisines = const [],
    this.operatingHours = const {},
    this.pickedDocuments = const {
      'commercialRegistration': null,
      'businessLicense': null,
      'healthCertificate': null,
      'taxRegistration': null,
    },
    this.uploadStatuses = const {},
    this.logoImage,
    this.coverImage,
    this.uploadStageLabel = '',
    this.latitude,
    this.longitude,
    this.isGettingLocation = false,
    this.registeredUser,
    this.availableCuisines = const [],
    this.isLoadingCuisines = true,
    this.vendorType = VendorType.restaurant,
  });

  bool get allDocumentsPicked => pickedDocuments.values.every((f) => f != null);
  bool get allBrandingPicked => logoImage != null && coverImage != null;

  RestaurantApplicationState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    int? currentStep,
    List<String>? selectedCuisines,
    Map<String, Map<String, dynamic>>? operatingHours,
    Map<String, XFile?>? pickedDocuments,
    Map<String, RestaurantUploadStatus>? uploadStatuses,
    XFile? logoImage,
    bool clearLogo = false,
    XFile? coverImage,
    bool clearCover = false,
    String? uploadStageLabel,
    double? latitude,
    double? longitude,
    bool? isGettingLocation,
    AppUser? registeredUser,
    List<CuisineType>? availableCuisines,
    bool? isLoadingCuisines,
    VendorType? vendorType,
  }) {
    return RestaurantApplicationState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentStep: currentStep ?? this.currentStep,
      selectedCuisines: selectedCuisines ?? this.selectedCuisines,
      operatingHours: operatingHours ?? this.operatingHours,
      pickedDocuments: pickedDocuments ?? this.pickedDocuments,
      uploadStatuses: uploadStatuses ?? this.uploadStatuses,
      logoImage: clearLogo ? null : (logoImage ?? this.logoImage),
      coverImage: clearCover ? null : (coverImage ?? this.coverImage),
      uploadStageLabel: uploadStageLabel ?? this.uploadStageLabel,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isGettingLocation: isGettingLocation ?? this.isGettingLocation,
      registeredUser: registeredUser ?? this.registeredUser,
      availableCuisines: availableCuisines ?? this.availableCuisines,
      isLoadingCuisines: isLoadingCuisines ?? this.isLoadingCuisines,
      vendorType: vendorType ?? this.vendorType,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        error,
        currentStep,
        selectedCuisines,
        operatingHours,
        pickedDocuments,
        uploadStatuses,
        logoImage,
        coverImage,
        uploadStageLabel,
        latitude,
        longitude,
        isGettingLocation,
        registeredUser,
        availableCuisines,
        isLoadingCuisines,
        vendorType,
      ];
}
