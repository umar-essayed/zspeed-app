import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/errors/failures.dart';
import 'package:z_speed/features/admin/cubit/admin_vendors_state.dart';
import 'package:z_speed/features/admin/model/admin_models.dart';
import 'package:z_speed/features/admin/repository/admin_repository.dart';
import 'package:injectable/injectable.dart' hide Order;
import 'package:cloud_firestore/cloud_firestore.dart';

@injectable
class AdminVendorsCubit extends Cubit<AdminVendorsState> {
  final AdminRepository _repository;
  Object? _lastDocument;

  AdminVendorsCubit({required this._repository})
    : super(const AdminVendorsState());

  Future<void> loadVendors({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (!state.hasMore || state.isLoadingMore) return;
      emit(state.copyWith(isLoadingMore: true));
    } else {
      emit(state.copyWith(isBusy: true, hasError: false, failure: null));
      _lastDocument = null;
    }

    try {
      final result = await _repository.getVendors(
        vendorType: state.vendorTypeFilter,
        startAfter: _lastDocument,
        limit: 20,
      );

      if (result.isSuccess) {
        final newVendors = result.data!.$1;
        _lastDocument = result.data!.$2;

        final allVendors = isLoadMore
            ? [...state.vendors, ...newVendors]
            : newVendors;
        final hasMore = newVendors.length >= 20;

        emit(
          state.copyWith(
            isBusy: false,
            isLoadingMore: false,
            vendors: allVendors,
            hasMore: hasMore,
            filteredVendors: _mapVendors(allVendors),
          ),
        );
      } else {
        emit(
          state.copyWith(
            isBusy: false,
            isLoadingMore: false,
            hasError: true,
            failure: result.error,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          isBusy: false,
          isLoadingMore: false,
          hasError: true,
          failure: ServerFailure(e.toString()),
        ),
      );
    }
  }

  Future<void> updateStatus(String vendorId, RestaurantStatus status) async {
    final result = await _repository.updateRestaurantStatus(vendorId, status);
    if (result.isSuccess) {
      final updatedList = state.vendors.map((v) {
        if (v.id == vendorId) {
          return v.copyWith(isActive: status == RestaurantStatus.active);
        }
        return v;
      }).toList();

      emit(
        state.copyWith(
          vendors: updatedList,
          filteredVendors: _mapVendors(updatedList),
        ),
      );
    }
  }

  Future<void> deleteVendor(String vendorId) async {
    final result = await _repository.deleteRestaurant(vendorId);
    if (result.isSuccess) {
      final updatedList = state.vendors.where((v) => v.id != vendorId).toList();

      emit(
        state.copyWith(
          vendors: updatedList,
          filteredVendors: _mapVendors(updatedList),
        ),
      );
    }
  }

  Future<void> updateVendorType(String vendorId, VendorType vendorType) async {
    final result = await _repository.updateRestaurantVendorType(
      vendorId,
      vendorType,
    );
    if (result.isSuccess) {
      final updatedList = state.vendors.map((v) {
        return v.id == vendorId ? v.copyWith(vendorType: vendorType) : v;
      }).toList();
      emit(
        state.copyWith(
          vendors: updatedList,
          filteredVendors: _mapVendors(updatedList),
        ),
      );
    }
  }

  Future<void> updateVendorPriority(String vendorId, int priority) async {
    final result = await _repository.updateRestaurantPriority(
      vendorId,
      priority,
    );
    if (result.isSuccess) {
      final updatedList = state.vendors.map((v) {
        return v.id == vendorId ? v.copyWith(priority: priority) : v;
      }).toList();
      emit(
        state.copyWith(
          vendors: updatedList,
          filteredVendors: _mapVendors(updatedList),
        ),
      );
    }
  }

  Future<void> updateVendor(Restaurant restaurant) async {
    final result = await _repository.updateRestaurant(restaurant);
    if (result.isSuccess) {
      final updatedList = state.vendors.map((v) {
        return v.id == restaurant.id ? restaurant : v;
      }).toList();
      emit(
        state.copyWith(
          vendors: updatedList,
          filteredVendors: _mapVendors(updatedList),
        ),
      );
    }
  }

  /// Creates a brand-new vendor in Firestore and prepends it to the local list.
  Future<bool> addVendor(Restaurant restaurant) async {
    try {
      final result = await _repository.createVendor(restaurant);
      if (result.isSuccess) {
        await loadVendors(); // reload to get the server-assigned ID
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> adjustVendorWallet(
    String vendorId,
    double amount,
    String description,
  ) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('vendors')
          .doc(vendorId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) throw Exception("Vendor not found");

        final currentBalance =
            (snapshot.data()?['walletBalance'] as num?)?.toDouble() ?? 0.0;
        final newBalance = currentBalance + amount;

        transaction.update(docRef, {
          'walletBalance': newBalance,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Log the transaction
        final txId = FirebaseFirestore.instance
            .collection('restaurantWalletTransactions')
            .doc()
            .id;
        final txRef = FirebaseFirestore.instance
            .collection('restaurantWalletTransactions')
            .doc(txId);
        transaction.set(txRef, {
          'id': txId,
          'restaurantId': vendorId,
          'orderId': '',
          'type': amount >= 0 ? 'credit' : 'debit',
          'amount': amount.abs(),
          'description': description,
          'status': 'confirmed',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // Update local state balance
      final updatedList = state.vendors.map((v) {
        if (v.id == vendorId) {
          return v.copyWith(walletBalance: v.walletBalance + amount);
        }
        return v;
      }).toList();

      emit(
        state.copyWith(
          vendors: updatedList,
          filteredVendors: _mapVendors(updatedList),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          hasError: true,
          failure: ServerFailure('Failed to adjust wallet: $e'),
        ),
      );
    }
  }

  void setVendorTypeFilter(VendorType? type) {
    final filtered = _applyFilter(state.vendors, type);
    emit(
      state.copyWith(
        filteredVendors: filtered,
        vendorTypeFilter: type,
        clearVendorTypeFilter: type == null,
      ),
    );
  }

  List<AdminVendor> _mapVendors(List<Restaurant> vendors) {
    return _applyFilter(vendors, state.vendorTypeFilter);
  }

  List<AdminVendor> _applyFilter(List<Restaurant> vendors, VendorType? filter) {
    final source = filter == null
        ? vendors
        : vendors.where((v) => v.vendorType == filter).toList();
    return source.map((v) {
      return AdminVendor(
        id: v.id,
        name: v.name,
        category: v.cuisineTypes.isNotEmpty
            ? v.cuisineTypes.first
            : v.vendorType.label,
        status: v.isActive
            ? RestaurantStatus.active
            : RestaurantStatus.suspended,
        rating: v.rating,
        ordersToday: 0,
        totalRevenue: 0.0,
        vendorType: v.vendorType,
      );
    }).toList();
  }
}
