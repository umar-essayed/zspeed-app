import 'package:equatable/equatable.dart';
import 'package:z_speed/core/errors/failures.dart';
import 'package:z_speed/features/admin/model/admin_models.dart';

class AdminVendorsState extends Equatable {
  final bool isBusy;
  final bool hasError;
  final Failure? failure;
  final List<Restaurant> vendors;
  final List<AdminVendor> filteredVendors;
  final bool hasMore;
  final bool isLoadingMore;
  final VendorType? vendorTypeFilter;

  const AdminVendorsState({
    this.isBusy = false,
    this.hasError = false,
    this.failure,
    this.vendors = const [],
    this.filteredVendors = const [],
    this.hasMore = false,
    this.isLoadingMore = false,
    this.vendorTypeFilter,
  });

  AdminVendorsState copyWith({
    bool? isBusy,
    bool? hasError,
    Failure? failure,
    List<Restaurant>? vendors,
    List<AdminVendor>? filteredVendors,
    bool? hasMore,
    bool? isLoadingMore,
    VendorType? vendorTypeFilter,
    bool clearVendorTypeFilter = false,
  }) {
    return AdminVendorsState(
      isBusy: isBusy ?? this.isBusy,
      hasError: hasError ?? this.hasError,
      failure: failure ?? this.failure,
      vendors: vendors ?? this.vendors,
      filteredVendors: filteredVendors ?? this.filteredVendors,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      vendorTypeFilter: clearVendorTypeFilter
          ? null
          : (vendorTypeFilter ?? this.vendorTypeFilter),
    );
  }

  @override
  List<Object?> get props => [
        isBusy,
        hasError,
        failure,
        vendors,
        filteredVendors,
        hasMore,
        isLoadingMore,
        vendorTypeFilter,
      ];
}
