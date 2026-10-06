import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/errors/failures.dart';
import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/features/admin/cubit/admin_settings_state.dart';
import 'package:z_speed/features/restaurant/datasource/cuisine_type_datasource.dart';
import 'package:z_speed/features/restaurant/datasource/vendor_section_datasource.dart';
import 'package:z_speed/features/restaurant/model/cuisine_type.dart';
import 'package:z_speed/features/restaurant/model/vendor_section.dart';
import 'package:injectable/injectable.dart' hide Order;
import 'package:z_speed/features/admin/datasource/settings_datasource.dart';

@injectable
class AdminSettingsCubit extends Cubit<AdminSettingsState> {
  final CuisineTypeDatasource _cuisineDatasource;
  final VendorSectionDatasource _vendorSectionDatasource;
  final SettingsDatasource _settingsDatasource;

  AdminSettingsCubit({
    CuisineTypeDatasource? cuisineDatasource,
    VendorSectionDatasource? vendorSectionDatasource,
    SettingsDatasource? settingsDatasource,
  })  : _cuisineDatasource = cuisineDatasource ?? CuisineTypeDatasource(),
        _vendorSectionDatasource = vendorSectionDatasource ?? VendorSectionDatasource(),
        _settingsDatasource = settingsDatasource ?? SettingsDatasource(),
        super(const AdminSettingsState());

  Future<void> loadSettings() async {
    emit(state.copyWith(isBusy: true, hasError: false, failure: null));
    
    // Load settings and cuisines independently so one failure doesn't block the other
    Map<String, dynamic> settings = {};
    List<CuisineType> cuisines = [];

    // 1. Load platform settings and blacklist
    List<BlacklistItem> blacklist = [];
    try {
      settings = await _settingsDatasource.getSettings();
      blacklist = await _settingsDatasource.getBlacklist();
      debugPrint('[AdminSettings] Loaded settings: $settings');
    } catch (e) {
      debugPrint('[AdminSettings] Failed to load settings: $e');
    }

    // 2. Seed default cuisines if collection is empty, then load all
    try {
      await _cuisineDatasource.seedIfEmpty();
      await _cuisineDatasource.syncMissingCuisines();
      cuisines = await _cuisineDatasource.getAll();
      debugPrint('[AdminSettings] Loaded ${cuisines.length} cuisine types');
    } catch (e) {
      debugPrint('[AdminSettings] Failed to load cuisines: $e');
    }

    // 3. Seed vendor sections if empty, then load all
    List<VendorSection> supermarketSections = [];
    List<VendorSection> pharmacySections = [];
    try {
      await _vendorSectionDatasource.deduplicateAll();
      await _vendorSectionDatasource.seedIfEmpty();
      supermarketSections = await _vendorSectionDatasource.getByType(VendorType.supermarket);
      pharmacySections = await _vendorSectionDatasource.getByType(VendorType.pharmacy);
      debugPrint('[AdminSettings] Loaded ${supermarketSections.length} supermarket, ${pharmacySections.length} pharmacy sections');
    } catch (e) {
      debugPrint('[AdminSettings] Failed to load vendor sections: $e');
    }

    emit(state.copyWith(
      isBusy: false,
      cuisineTypes: cuisines,
      supermarketSections: supermarketSections,
      pharmacySections: pharmacySections,
      deliveryFeeRate: (settings['deliveryFeeRate'] as num?)?.toDouble() ?? 0.10,
      platformCommission: (settings['platformCommission'] as num?)?.toDouble() ?? 0.15,
      driverEarningsLimit: (settings['driverEarningsLimit'] as num?)?.toDouble() ?? 0.0,
      maintenanceMode: settings['maintenanceMode'] as bool? ?? false,
      allowNewSignups: settings['allowNewSignups'] as bool? ?? true,
      signupDisabledMessage: settings['signupDisabledMessage'] as String? ?? '',
      blacklist: blacklist,
      minRequiredVersion: settings['minRequiredVersion'] as String? ?? '1.0.0',
      latestVersion: settings['latestVersion'] as String? ?? '1.0.0',
      iosUpdateUrl: settings['iosUpdateUrl'] as String? ?? '',
      androidUpdateUrl: settings['androidUpdateUrl'] as String? ?? '',
      updateUrl: settings['updateUrl'] as String? ?? '',
    ));
  }

  Future<void> updateDeliveryFeeRate(double val) async {
    try {
      await _settingsDatasource.updateSettings({'deliveryFeeRate': val});
      emit(state.copyWith(deliveryFeeRate: val));
    } catch (e) {
      emit(state.copyWith(hasError: true, failure: ServerFailure(e.toString())));
    }
  }

  Future<void> updatePlatformCommission(double val) async {
    try {
      await _settingsDatasource.updateSettings({'platformCommission': val});
      emit(state.copyWith(platformCommission: val));
    } catch (e) {
      emit(state.copyWith(hasError: true, failure: ServerFailure(e.toString())));
    }
  }

  Future<void> toggleMaintenanceMode(UserType userType) async {
    if (userType != UserType.superAdmin) {
      emit(state.copyWith(
        hasError: true,
        failure: ServerFailure("Unauthorized: Only super admin can toggle maintenance mode"),
      ));
      return;
    }
    try {
      final newValue = !state.maintenanceMode;
      await _settingsDatasource.updateSettings({'maintenanceMode': newValue});
      emit(state.copyWith(maintenanceMode: newValue));
    } catch (e) {
      emit(state.copyWith(hasError: true, failure: ServerFailure(e.toString())));
    }
  }

  Future<void> updateVersionSettings({
    required UserType userType,
    required String minRequiredVersion,
    required String latestVersion,
    required String iosUpdateUrl,
    required String androidUpdateUrl,
    required String updateUrl,
  }) async {
    if (userType != UserType.superAdmin) {
      emit(state.copyWith(
        hasError: true,
        failure: ServerFailure("Unauthorized: Only super admin can configure version settings"),
      ));
      return;
    }
    try {
      await _settingsDatasource.updateSettings({
        'minRequiredVersion': minRequiredVersion,
        'latestVersion': latestVersion,
        'iosUpdateUrl': iosUpdateUrl,
        'androidUpdateUrl': androidUpdateUrl,
        'updateUrl': updateUrl,
      });
      emit(state.copyWith(
        minRequiredVersion: minRequiredVersion,
        latestVersion: latestVersion,
        iosUpdateUrl: iosUpdateUrl,
        androidUpdateUrl: androidUpdateUrl,
        updateUrl: updateUrl,
      ));
    } catch (e) {
      emit(state.copyWith(hasError: true, failure: ServerFailure(e.toString())));
    }
  }

  Future<void> toggleCuisineTypeActive(CuisineType ct) async {
    final updated = ct.copyWith(isActive: !ct.isActive);
    try {
      await _cuisineDatasource.update(updated);
      await loadSettings();
    } catch (e) {
      emit(state.copyWith(hasError: true, failure: ServerFailure(e.toString())));
    }
  }

  Future<void> deleteCuisineType(String id) async {
    try {
      await _cuisineDatasource.delete(id);
      await loadSettings();
    } catch (e) {
      emit(state.copyWith(hasError: true, failure: ServerFailure(e.toString())));
    }
  }

  Future<bool> createCuisineType({
    required String name,
    required String nameAr,
    required bool isActive,
    String? imageUrl,
  }) async {
    try {
      final order = state.cuisineTypes.length;
      final newCt = CuisineType(
        id: '', // Generated by datasource
        name: name,
        nameAr: nameAr,
        imageUrl: imageUrl,
        sortOrder: order,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _cuisineDatasource.create(newCt);
      await loadSettings();
      return true;
    } catch (e) {
      emit(state.copyWith(hasError: true, failure: ServerFailure(e.toString())));
      return false;
    }
  }

  Future<void> updateCuisineType(CuisineType updated) async {
    try {
      await _cuisineDatasource.update(updated);
      await loadSettings();
    } catch (e) {
      emit(state.copyWith(hasError: true, failure: ServerFailure(e.toString())));
    }
  }

  // ── Vendor Section (Supermarket / Pharmacy) ─────────────────────────────────

  Future<bool> createVendorSection({
    required String name,
    required String nameAr,
    required VendorType vendorType,
    required bool isActive,
    String? imageUrl,
  }) async {
    try {
      final list = vendorType == VendorType.supermarket
          ? state.supermarketSections
          : state.pharmacySections;
      final section = VendorSection(
        id: '',
        name: name,
        nameAr: nameAr,
        imageUrl: imageUrl,
        vendorType: vendorType,
        sortOrder: list.length,
        isActive: isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _vendorSectionDatasource.create(section);
      await loadSettings();
      return true;
    } catch (e) {
      emit(state.copyWith(hasError: true, failure: ServerFailure(e.toString())));
      return false;
    }
  }

  Future<void> toggleVendorSectionActive(VendorSection section) async {
    try {
      await _vendorSectionDatasource.update(section.copyWith(isActive: !section.isActive));
      await loadSettings();
    } catch (e) {
      emit(state.copyWith(hasError: true, failure: ServerFailure(e.toString())));
    }
  }

  Future<void> updateVendorSection(VendorSection updated) async {
    try {
      await _vendorSectionDatasource.update(updated);
      await loadSettings();
    } catch (e) {
      emit(state.copyWith(hasError: true, failure: ServerFailure(e.toString())));
    }
  }

  Future<void> deleteVendorSection(String id) async {
    try {
      await _vendorSectionDatasource.delete(id);
      await loadSettings();
    } catch (e) {
      emit(state.copyWith(hasError: true, failure: ServerFailure(e.toString())));
    }
  }

  Future<void> updateDriverEarningsLimit(double val, UserType userType) async {
    if (userType != UserType.superAdmin) {
      emit(state.copyWith(
        hasError: true,
        failure: ServerFailure("Unauthorized: Only super admin can set the driver earnings limit"),
      ));
      return;
    }
    try {
      await _settingsDatasource.updateSettings({'driverEarningsLimit': val});
      emit(state.copyWith(driverEarningsLimit: val));
    } catch (e) {
      emit(state.copyWith(hasError: true, failure: ServerFailure(e.toString())));
    }
  }

  Future<void> toggleAllowNewSignups(UserType userType) async {
    if (userType != UserType.superAdmin) {
      emit(state.copyWith(
        hasError: true,
        failure: ServerFailure("Unauthorized: Only super admin can toggle user registrations"),
      ));
      return;
    }
    try {
      final newValue = !state.allowNewSignups;
      await _settingsDatasource.updateSettings({'allowNewSignups': newValue});
      emit(state.copyWith(allowNewSignups: newValue));
    } catch (e) {
      emit(state.copyWith(hasError: true, failure: ServerFailure(e.toString())));
    }
  }

  Future<void> updateSignupDisabledMessage(String message, UserType userType) async {
    if (userType != UserType.superAdmin) {
      emit(state.copyWith(
        hasError: true,
        failure: ServerFailure("Unauthorized: Only super admin can update signup message"),
      ));
      return;
    }
    try {
      await _settingsDatasource.updateSettings({'signupDisabledMessage': message.trim()});
      emit(state.copyWith(signupDisabledMessage: message.trim()));
    } catch (e) {
      emit(state.copyWith(hasError: true, failure: ServerFailure(e.toString())));
    }
  }

  Future<bool> addToBlacklist({
    required String type,
    required String value,
    String? reason,
    required UserType userType,
  }) async {
    if (userType != UserType.superAdmin && userType != UserType.admin) {
      emit(state.copyWith(
        hasError: true,
        failure: ServerFailure("Unauthorized: Only administrators can manage the blacklist"),
      ));
      return false;
    }
    try {
      await _settingsDatasource.addToBlacklist(
        type: type,
        value: value,
        reason: reason,
      );
      final updatedBlacklist = await _settingsDatasource.getBlacklist();
      emit(state.copyWith(blacklist: updatedBlacklist));
      return true;
    } catch (e) {
      emit(state.copyWith(hasError: true, failure: ServerFailure(e.toString())));
      return false;
    }
  }

  Future<bool> removeFromBlacklist(String docId, UserType userType) async {
    if (userType != UserType.superAdmin && userType != UserType.admin) {
      emit(state.copyWith(
        hasError: true,
        failure: ServerFailure("Unauthorized: Only administrators can manage the blacklist"),
      ));
      return false;
    }
    try {
      await _settingsDatasource.removeFromBlacklist(docId);
      final updatedBlacklist = await _settingsDatasource.getBlacklist();
      emit(state.copyWith(blacklist: updatedBlacklist));
      return true;
    } catch (e) {
      emit(state.copyWith(hasError: true, failure: ServerFailure(e.toString())));
      return false;
    }
  }
}
