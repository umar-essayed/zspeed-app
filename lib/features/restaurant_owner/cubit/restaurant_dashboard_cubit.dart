import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/enums/order_enums.dart';
import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/features/order/model/order.dart' as app_order;
import 'package:z_speed/features/order/repository/order_repository.dart';
import 'package:z_speed/features/order/repository/order_repository_impl.dart';
import 'package:z_speed/features/restaurant/datasource/restaurant_firebase_datasource.dart';
import 'package:z_speed/features/restaurant/model/restaurant.dart';
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_dashboard_state.dart';
import 'package:injectable/injectable.dart' hide Order;

@injectable
class RestaurantDashboardCubit extends Cubit<RestaurantDashboardState> {
  final OrderRepository _orderRepository;
  final RestaurantFirebaseDatasource _restaurantDatasource;
  final FirebaseAuth _auth;
  StreamSubscription<List<app_order.Order>>? _ordersSubscription;

  RestaurantDashboardCubit({
    OrderRepository? orderRepository,
    RestaurantFirebaseDatasource? restaurantDatasource,
    FirebaseAuth? auth,
  })  : _orderRepository = orderRepository ?? OrderRepositoryImpl(),
        _restaurantDatasource =
            restaurantDatasource ?? RestaurantFirebaseDatasource(),
        _auth = auth ?? FirebaseAuth.instance,
        super(const RestaurantDashboardState()) {
    init();
  }

  Future<void> init() async {
    if (isClosed) return;
    emit(
        state.copyWith(isLoading: true, clearError: true, noRestaurant: false));

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        if (isClosed) return;
        emit(state.copyWith(isLoading: false, error: 'No authenticated user'));
        return;
      }

      final restaurant = await _restaurantDatasource.getByOwnerId(userId);
      if (isClosed) return;
      if (restaurant == null) {
        final created = await _tryCreateFromApplication(userId);
        if (isClosed) return;
        if (!created) {
          emit(state.copyWith(isLoading: false, noRestaurant: true));
          return;
        }
        final newRestaurant = await _restaurantDatasource.getByOwnerId(userId);
        if (isClosed) return;
        if (newRestaurant == null) {
          emit(state.copyWith(isLoading: false, noRestaurant: true));
          return;
        }
        emit(state.copyWith(
          isLoading: false,
          restaurant: newRestaurant,
          restaurantId: newRestaurant.id,
        ));
        _startListening();
        return;
      }

      var currentRestaurant = restaurant;
      if (restaurant.name == 'My Restaurant' || restaurant.name.isEmpty) {
        await _tryRepairFromApplication(userId, restaurant.id);
        if (isClosed) return;
        final repaired = await _restaurantDatasource.getByOwnerId(userId);
        if (isClosed) return;
        if (repaired != null) currentRestaurant = repaired;
      }

      emit(state.copyWith(
        isLoading: false,
        restaurant: currentRestaurant,
        restaurantId: currentRestaurant.id,
      ));
      _startListening();
    } catch (e) {
      if (isClosed) return;
      emit(
          state.copyWith(isLoading: false, error: 'Dashboard init failed: $e'));
    }
  }

  Future<bool> createRestaurant({
    required String name,
    required String description,
    required String address,
    required String phone,
    List<String> cuisineTypes = const [],
  }) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        emit(state.copyWith(isLoading: false, error: 'No authenticated user'));
        return false;
      }

      final restaurant = Restaurant(
        id: '',
        ownerId: userId,
        name: name,
        description: description,
        logoUrl: '',
        coverImageUrl: '',
        address: address,
        phone: phone,
        cuisineTypes: cuisineTypes,
        deliveryFee: 0.0,
        minimumOrder: 0.0,
        deliveryTimeMin: 30,
        deliveryTimeMax: 60,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _restaurantDatasource.create(restaurant);
      await init();
      return true;
    } catch (e) {
      emit(state.copyWith(
          isLoading: false, error: 'Failed to create restaurant: $e'));
      return false;
    }
  }

  Future<bool> _tryCreateFromApplication(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('applications')
          .where('userId', isEqualTo: userId)
          .where('applicationType', whereIn: const ['restaurant', 'vendor'])
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return false;

      final data = snapshot.docs.first.data();
      final formData = Map<String, dynamic>.from(data['formData'] ?? {});
      final biz = Map<String, dynamic>.from(formData['businessInfo'] ?? {});
      final contact = Map<String, dynamic>.from(formData['contactInfo'] ?? {});
      final location =
          Map<String, dynamic>.from(formData['locationInfo'] ?? {});
      final branding = Map<String, dynamic>.from(formData['branding'] ?? {});

      final restaurant = Restaurant(
        id: '',
        ownerId: userId,
        vendorType: VendorTypeX.fromKey(formData['vendorType'] as String? ?? 'restaurant'),
        name: (biz['restaurantName'] as String?) ?? 'My Restaurant',
        description: (biz['description'] as String?) ?? '',
        logoUrl: (branding['logoUrl'] as String?) ?? '',
        coverImageUrl: (branding['coverUrl'] as String?) ?? '',
        phone: (contact['restaurantPhone'] as String?) ??
            (contact['ownerPhone'] as String?) ??
            '',
        address: (contact['address'] as String?) ??
            (location['address'] as String?) ??
            '',
        cuisineTypes: biz['cuisines'] is List
            ? List<String>.from(biz['cuisines'])
            : <String>[],
        deliveryFee: 0.0,
        minimumOrder: 0.0,
        deliveryTimeMin: 30,
        deliveryTimeMax: 60,
        latitude: (location['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (location['longitude'] as num?)?.toDouble() ?? 0.0,
        workingHours: location['operatingHours'] is Map
            ? (location['operatingHours'] as Map<String, dynamic>).map(
                (k, v) => MapEntry(
                    k, WorkingHours.fromMap(v as Map<String, dynamic>)),
              )
            : <String, WorkingHours>{},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _restaurantDatasource.create(restaurant);
      debugPrint(
          'DashboardCubit: auto-created restaurant from approved application');
      return true;
    } catch (e) {
      debugPrint('DashboardCubit: failed to auto-create from application: $e');
      return false;
    }
  }

  Future<void> _tryRepairFromApplication(
      String userId, String restaurantId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('applications')
          .where('userId', isEqualTo: userId)
          .where('applicationType', whereIn: const ['restaurant', 'vendor'])
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return;

      final formData = Map<String, dynamic>.from(
          snapshot.docs.first.data()['formData'] ?? {});
      final biz = Map<String, dynamic>.from(formData['businessInfo'] ?? {});
      final contact = Map<String, dynamic>.from(formData['contactInfo'] ?? {});
      final location =
          Map<String, dynamic>.from(formData['locationInfo'] ?? {});
      final branding = Map<String, dynamic>.from(formData['branding'] ?? {});

      final realName = (biz['restaurantName'] as String?) ?? '';
      if (realName.isEmpty) return;

      final updates = <String, dynamic>{
        'name': realName,
        if (formData['vendorType'] != null)
          'vendorType': formData['vendorType'],
        if ((biz['description'] as String?)?.isNotEmpty == true)
          'description': biz['description'],
        if ((branding['logoUrl'] as String?)?.isNotEmpty == true)
          'logoUrl': branding['logoUrl'],
        if ((branding['coverUrl'] as String?)?.isNotEmpty == true)
          'coverImageUrl': branding['coverUrl'],
        if ((contact['restaurantPhone'] as String?)?.isNotEmpty == true)
          'phone': contact['restaurantPhone']
        else if ((contact['ownerPhone'] as String?)?.isNotEmpty == true)
          'phone': contact['ownerPhone'],
        if ((contact['address'] as String?)?.isNotEmpty == true)
          'address': contact['address']
        else if ((location['address'] as String?)?.isNotEmpty == true)
          'address': location['address'],
        if (biz['cuisines'] is List && (biz['cuisines'] as List).isNotEmpty)
          'cuisineTypes': biz['cuisines'],
        if (location['operatingHours'] is Map)
          'workingHours': location['operatingHours'],
        if (location['latitude'] != null)
          'latitude': (location['latitude'] as num).toDouble(),
        if (location['longitude'] != null)
          'longitude': (location['longitude'] as num).toDouble(),
      };

      if (updates.length > 1) {
        await _restaurantDatasource.updateFields(restaurantId, updates);
        debugPrint('DashboardCubit: repaired restaurant from application data');
      }
    } catch (e) {
      debugPrint('DashboardCubit: repair from application failed: $e');
    }
  }

  void _startListening() {
    if (state.restaurantId == null) return;

    _ordersSubscription?.cancel();
    _ordersSubscription = _orderRepository
        .streamRestaurantOrders(state.restaurantId!)
        .listen((orders) {
      final stats = _recomputeStats(orders);
      emit(state.copyWith(allOrders: orders, stats: stats));
    }, onError: (e) {
      emit(state.copyWith(error: 'Order stream error: $e'));
    });
  }

  DashboardStats _recomputeStats(List<app_order.Order> allOrders) {
    final now = DateTime.now();
    final weekday = now.weekday;
    final thisWeekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));

    final thisWeekOrders =
        allOrders.where((o) => o.createdAt.isAfter(thisWeekStart)).toList();
    final lastWeekOrders = allOrders
        .where((o) =>
            o.createdAt.isAfter(lastWeekStart) &&
            o.createdAt.isBefore(thisWeekStart))
        .toList();

    final thisWeekRevenue = _sumRevenue(thisWeekOrders);
    final lastWeekRevenue = _sumRevenue(lastWeekOrders);
    final revenueChange = lastWeekRevenue > 0
        ? ((thisWeekRevenue - lastWeekRevenue) / lastWeekRevenue) * 100
        : 0.0;

    final active = allOrders
        .where((o) =>
            o.status != OrderStatus.delivered &&
            o.status != OrderStatus.cancelled &&
            o.status != OrderStatus.refunded)
        .length;
    final lastWeekActive = lastWeekOrders
        .where((o) =>
            o.status != OrderStatus.delivered &&
            o.status != OrderStatus.cancelled &&
            o.status != OrderStatus.refunded)
        .length;

    final thisCustomers =
        thisWeekOrders.map((o) => o.customerId).toSet().length;
    final lastCustomers =
        lastWeekOrders.map((o) => o.customerId).toSet().length;
    final customersChange = lastCustomers > 0
        ? ((thisCustomers - lastCustomers) / lastCustomers) * 100
        : 0.0;

    final thisAvg = _avgPrepMinutes(thisWeekOrders);
    final lastAvg = _avgPrepMinutes(lastWeekOrders);

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dailyRevenue = <String, double>{};
    for (var i = 0; i < 7; i++) {
      final dayStart = thisWeekStart.add(Duration(days: i));
      final dayEnd = dayStart.add(const Duration(days: 1));
      final dayOrders = thisWeekOrders
          .where((o) =>
              o.createdAt.isAfter(dayStart) && o.createdAt.isBefore(dayEnd))
          .toList();
      dailyRevenue[days[i]] = _sumRevenue(dayOrders);
    }

    return DashboardStats(
      totalRevenue: thisWeekRevenue,
      activeOrders: active,
      totalCustomers: thisCustomers,
      avgPrepMinutes: thisAvg,
      revenueChange: revenueChange,
      activeOrdersChange: (active - lastWeekActive).toDouble(),
      customersChange: customersChange,
      prepTimeChange: thisAvg - lastAvg,
      dailyRevenue: dailyRevenue,
    );
  }

  double _sumRevenue(List<app_order.Order> orders) {
    return orders
        .where((o) => o.status == OrderStatus.delivered)
        .fold(0.0, (total, o) => total + (o.subtotal - o.serviceFee));
  }

  int _avgPrepMinutes(List<app_order.Order> orders) {
    final completed =
        orders.where((o) => o.acceptedAt != null && o.readyAt != null);
    if (completed.isEmpty) return 0;
    final totalMinutes = completed.fold<int>(
      0,
      (total, o) => total + o.readyAt!.difference(o.acceptedAt!).inMinutes,
    );
    return (totalMinutes / completed.length).round();
  }

  Future<void> toggleOpen() async {
    if (state.restaurant == null) return;
    try {
      final newVal = !state.restaurant!.isOpen;
      await _restaurantDatasource
          .updateFields(state.restaurant!.id, {'isOpen': newVal});
      emit(state.copyWith(
          restaurant: state.restaurant!.copyWith(isOpen: newVal)));
    } catch (e) {
      debugPrint('DashboardCubit: toggleOpen failed: $e');
    }
  }

  Future<void> toggleBusy() async {
    if (state.restaurant == null) return;
    try {
      final newVal = !state.restaurant!.isBusy;
      await _restaurantDatasource
          .updateFields(state.restaurant!.id, {'isBusy': newVal});
      emit(state.copyWith(
          restaurant: state.restaurant!.copyWith(isBusy: newVal)));
    } catch (e) {
      debugPrint('DashboardCubit: toggleBusy failed: $e');
    }
  }

  @override
  Future<void> close() {
    _ordersSubscription?.cancel();
    return super.close();
  }
}
