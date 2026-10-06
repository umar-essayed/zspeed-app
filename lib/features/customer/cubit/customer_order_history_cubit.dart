import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/features/order/model/order.dart';
import 'package:z_speed/features/order/repository/order_repository.dart';
import 'package:z_speed/features/order/repository/order_repository_impl.dart';
import 'package:z_speed/features/customer/cubit/customer_order_history_state.dart';
import 'package:injectable/injectable.dart' hide Order;

@injectable
class CustomerOrderHistoryCubit extends Cubit<CustomerOrderHistoryState> {
  final OrderRepository _orderRepository;
  final FirebaseAuth _auth;
  StreamSubscription<List<Order>>? _ordersSubscription;

  CustomerOrderHistoryCubit({
    OrderRepository? orderRepository,
    FirebaseAuth? auth,
  })  : _orderRepository = orderRepository ?? OrderRepositoryImpl(),
        _auth = auth ?? FirebaseAuth.instance,
        super(const CustomerOrderHistoryState()) {
    init();
  }

  Future<void> init() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        emit(state.copyWith(isLoading: false, error: 'User not authenticated'));
        return;
      }

      _ordersSubscription?.cancel();
      _ordersSubscription =
          _orderRepository.streamCustomerOrders(currentUser.uid).listen(
        (orders) {
          final sortedOrders = List<Order>.from(orders);
          sortedOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          emit(state.copyWith(
            isLoading: false,
            allOrders: sortedOrders,
            clearError: true,
          ));
        },
        onError: (error) {
          emit(state.copyWith(
            isLoading: false,
            error: 'Failed to load orders: $error',
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to initialize: $e',
      ));
    }
  }

  @override
  Future<void> close() {
    _ordersSubscription?.cancel();
    return super.close();
  }
}
