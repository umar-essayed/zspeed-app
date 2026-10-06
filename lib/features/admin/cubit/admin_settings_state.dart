import 'package:equatable/equatable.dart';
import 'package:z_speed/core/errors/failures.dart';
import 'package:z_speed/features/restaurant/model/cuisine_type.dart';
import 'package:z_speed/features/restaurant/model/vendor_section.dart';
import 'package:z_speed/features/admin/datasource/settings_datasource.dart';

class AdminSettingsState extends Equatable {
  final bool isBusy;
  final bool hasError;
  final Failure? failure;
  final double deliveryFeeRate;
  final double platformCommission;
  final double driverEarningsLimit;
  final bool maintenanceMode;
  final bool allowNewSignups;
  final String signupDisabledMessage;
  final List<BlacklistItem> blacklist;
  final String minRequiredVersion;
  final String latestVersion;
  final String iosUpdateUrl;
  final String androidUpdateUrl;
  final String updateUrl;
  final List<CuisineType> cuisineTypes;
  final List<VendorSection> supermarketSections;
  final List<VendorSection> pharmacySections;

  const AdminSettingsState({
    this.isBusy = false,
    this.hasError = false,
    this.failure,
    this.deliveryFeeRate = 0.10,
    this.platformCommission = 0.15,
    this.driverEarningsLimit = 0.0,
    this.maintenanceMode = false,
    this.allowNewSignups = true,
    this.signupDisabledMessage = '',
    this.blacklist = const [],
    this.minRequiredVersion = '1.0.0',
    this.latestVersion = '1.0.0',
    this.iosUpdateUrl = '',
    this.androidUpdateUrl = '',
    this.updateUrl = '',
    this.cuisineTypes = const [],
    this.supermarketSections = const [],
    this.pharmacySections = const [],
  });

  AdminSettingsState copyWith({
    bool? isBusy,
    bool? hasError,
    Failure? failure,
    double? deliveryFeeRate,
    double? platformCommission,
    double? driverEarningsLimit,
    bool? maintenanceMode,
    bool? allowNewSignups,
    String? signupDisabledMessage,
    List<BlacklistItem>? blacklist,
    String? minRequiredVersion,
    String? latestVersion,
    String? iosUpdateUrl,
    String? androidUpdateUrl,
    String? updateUrl,
    List<CuisineType>? cuisineTypes,
    List<VendorSection>? supermarketSections,
    List<VendorSection>? pharmacySections,
  }) {
    return AdminSettingsState(
      isBusy: isBusy ?? this.isBusy,
      hasError: hasError ?? this.hasError,
      failure: failure ?? this.failure,
      deliveryFeeRate: deliveryFeeRate ?? this.deliveryFeeRate,
      platformCommission: platformCommission ?? this.platformCommission,
      driverEarningsLimit: driverEarningsLimit ?? this.driverEarningsLimit,
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      allowNewSignups: allowNewSignups ?? this.allowNewSignups,
      signupDisabledMessage: signupDisabledMessage ?? this.signupDisabledMessage,
      blacklist: blacklist ?? this.blacklist,
      minRequiredVersion: minRequiredVersion ?? this.minRequiredVersion,
      latestVersion: latestVersion ?? this.latestVersion,
      iosUpdateUrl: iosUpdateUrl ?? this.iosUpdateUrl,
      androidUpdateUrl: androidUpdateUrl ?? this.androidUpdateUrl,
      updateUrl: updateUrl ?? this.updateUrl,
      cuisineTypes: cuisineTypes ?? this.cuisineTypes,
      supermarketSections: supermarketSections ?? this.supermarketSections,
      pharmacySections: pharmacySections ?? this.pharmacySections,
    );
  }

  @override
  List<Object?> get props => [
        isBusy,
        hasError,
        failure,
        deliveryFeeRate,
        platformCommission,
        driverEarningsLimit,
        maintenanceMode,
        allowNewSignups,
        signupDisabledMessage,
        blacklist,
        minRequiredVersion,
        latestVersion,
        iosUpdateUrl,
        androidUpdateUrl,
        updateUrl,
        cuisineTypes,
        supermarketSections,
        pharmacySections,
      ];
}
