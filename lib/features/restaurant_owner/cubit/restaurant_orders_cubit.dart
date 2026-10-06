import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/core.dart';
import 'package:z_speed/features/order/model/order.dart';
import 'package:z_speed/features/order/model/order_item.dart';
import 'package:z_speed/core/enums/order_enums.dart';
import 'package:z_speed/features/order/repository/order_repository.dart';
import 'package:z_speed/features/order/repository/order_repository_impl.dart';
import 'package:z_speed/features/restaurant/datasource/restaurant_firebase_datasource.dart';
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_orders_state.dart';
import 'package:injectable/injectable.dart' hide Order;

@injectable
class RestaurantOrdersCubit extends Cubit<RestaurantOrdersState> {
  final OrderRepository _orderRepository;
  final RestaurantFirebaseDatasource _restaurantDatasource;
  final FirebaseAuth _auth;
  StreamSubscription<List<Order>>? _ordersSubscription;

  RestaurantOrdersCubit({
    OrderRepository? orderRepository,
    RestaurantFirebaseDatasource? restaurantDatasource,
    FirebaseAuth? auth,
  }) : _orderRepository = orderRepository ?? OrderRepositoryImpl(),
       _restaurantDatasource =
           restaurantDatasource ?? RestaurantFirebaseDatasource(),
       _auth = auth ?? FirebaseAuth.instance,
       super(const RestaurantOrdersState()) {
    init();
  }

  Future<void> init() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        emit(state.copyWith(isLoading: false, error: 'No authenticated user'));
        return;
      }

      final restaurant = await _restaurantDatasource.getByOwnerId(userId);
      if (restaurant != null) {
        emit(
          state.copyWith(
            isLoading: false,
            restaurantId: restaurant.id,
            currentRestaurant: restaurant,
          ),
        );
        _startListeningToOrders();
        _fetchItemTranslations(restaurant.id);
      } else {
        emit(
          state.copyWith(
            isLoading: false,
            error: 'No restaurant found for this owner',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Failed to initialize: $e'));
    }
  }

  void _startListeningToOrders() {
    if (state.restaurantId == null) return;

    _ordersSubscription?.cancel();
    _ordersSubscription = _orderRepository
        .streamRestaurantOrders(state.restaurantId!)
        .listen(
          (orders) {
            final sorted = List<Order>.from(orders)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            emit(state.copyWith(allOrders: sorted));
          },
          onError: (e) {
            emit(state.copyWith(error: 'Failed to stream orders: $e'));
          },
        );
  }

  void setFilter(VendorOrderFilter filter) {
    emit(state.copyWith(currentFilter: filter));
  }

  Future<List<OrderItem>?> getOrderItems(String orderId) async {
    try {
      final result = await _orderRepository.getOrderItems(orderId);
      switch (result) {
        case Success(:final data):
          return data;
        case Err():
          return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<bool> _processOrder(
    String orderId,
    Future<Result> Function() action,
    String errorPrefix,
  ) async {
    if (state.processingOrders.contains(orderId)) return false;
    final newProcessing = Set<String>.from(state.processingOrders)
      ..add(orderId);
    emit(state.copyWith(processingOrders: newProcessing));

    try {
      final result = await action();
      final doneProcessing = Set<String>.from(state.processingOrders)
        ..remove(orderId);

      switch (result) {
        case Success():
          emit(state.copyWith(processingOrders: doneProcessing));
          return true;
        case Err(:final failure):
          emit(
            state.copyWith(
              processingOrders: doneProcessing,
              error: failure.message,
            ),
          );
          return false;
      }
    } catch (e) {
      final doneProcessing = Set<String>.from(state.processingOrders)
        ..remove(orderId);
      emit(
        state.copyWith(
          processingOrders: doneProcessing,
          error: '$errorPrefix: $e',
        ),
      );
      return false;
    }
  }

  Future<bool> acceptOrder(String orderId) => _processOrder(
    orderId,
    () => _orderRepository.updateStatus(orderId, OrderStatus.accepted),
    'Failed to accept order',
  );

  Future<bool> rejectOrder(String orderId, String reason) => _processOrder(
    orderId,
    () => _orderRepository.rejectOrder(orderId, reason),
    'Failed to reject order',
  );

  Future<bool> startPreparing(String orderId) => _processOrder(
    orderId,
    () => _orderRepository.updateStatus(orderId, OrderStatus.preparing),
    'Failed to start preparing',
  );

  Future<bool> markReady(String orderId) => _processOrder(
    orderId,
    () => _orderRepository.updateStatus(orderId, OrderStatus.ready),
    'Failed to mark ready',
  );

  Future<bool> startSearching(String orderId) => _processOrder(
    orderId,
    () => _orderRepository.updateStatus(orderId, OrderStatus.searching),
    'Failed to start searching',
  );

  Future<bool> assignDriver(String orderId, String driverId) => _processOrder(
    orderId,
    () => _orderRepository.assignDriver(orderId, driverId),
    'Failed to assign driver',
  );

  Future<void> _fetchItemTranslations(String vendorId) async {
    final Map<String, String> translations = {};
    try {
      final List<Future<void>> futures = [];

      // 1. Fetch direct items under vendors/{vendorId}/items
      futures.add(
        FirebaseFirestore.instance
            .collection('vendors')
            .doc(vendorId)
            .collection('items')
            .get()
            .then((itemsSnap) {
              for (final doc in itemsSnap.docs) {
                final data = doc.data();
                final nameAr = data['nameAr'] as String?;
                if (nameAr != null && nameAr.isNotEmpty) {
                  translations[doc.id] = nameAr;
                }
              }
            }),
      );

      // 2. Fetch sections and then their items
      futures.add(
        FirebaseFirestore.instance
            .collection('vendors')
            .doc(vendorId)
            .collection('menuSections')
            .get()
            .then((sectionsSnap) async {
              final List<Future<void>> sectionFutures = [];
              for (final sectionDoc in sectionsSnap.docs) {
                sectionFutures.add(
                  sectionDoc.reference.collection('items').get().then((
                    itemsSnap,
                  ) {
                    for (final doc in itemsSnap.docs) {
                      final data = doc.data();
                      final nameAr = data['nameAr'] as String?;
                      if (nameAr != null && nameAr.isNotEmpty) {
                        translations[doc.id] = nameAr;
                      }
                    }
                  }),
                );
              }
              await Future.wait(sectionFutures);
            }),
      );

      await Future.wait(futures);
      emit(state.copyWith(itemTranslations: translations, translationsLoaded: true));
    } catch (_) {
      // Fail silently but mark as loaded to prevent infinite loading
      emit(state.copyWith(translationsLoaded: true));
    }
  }

  @override
  Future<void> close() {
    _ordersSubscription?.cancel();
    return super.close();
  }
}
