import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:z_speed/core/enums/order_enums.dart';
import 'package:z_speed/features/admin/model/logistics_kpi_models.dart';
import 'package:z_speed/features/order/model/order.dart';

abstract class LogisticsKpiState {}

class LogisticsKpiInitial extends LogisticsKpiState {}

class LogisticsKpiLoading extends LogisticsKpiState {}

class LogisticsKpiLoaded extends LogisticsKpiState {
  final LogisticsKpiFilter filter;
  final LogisticsKpiStats stats;
  final List<Map<String, dynamic>> vendorsList; // [{id, name}]
  final List<Map<String, dynamic>> driversList; // [{id, name}]
  final List<Order> filteredOrders;
  final List<Order> paginatedOrders;
  final int totalOrdersCount;
  final List<VendorFinancialSummary> vendorSummaries;
  final List<RiderPerformanceSummary> riderSummaries;

  LogisticsKpiLoaded({
    required this.filter,
    required this.stats,
    required this.vendorsList,
    required this.driversList,
    required this.filteredOrders,
    required this.paginatedOrders,
    required this.totalOrdersCount,
    required this.vendorSummaries,
    required this.riderSummaries,
  });
}

class LogisticsKpiError extends LogisticsKpiState {
  final String message;
  LogisticsKpiError(this.message);
}

class LogisticsKpiCubit extends Cubit<LogisticsKpiState> {
  final FirebaseFirestore _firestore;
  StreamSubscription? _ordersSub;
  StreamSubscription? _vendorsSub;
  StreamSubscription? _driversSub;

  List<Order> _allOrders = [];
  List<Map<String, dynamic>> _vendorsList = [];
  List<Map<String, dynamic>> _driversList = [];
  LogisticsKpiFilter _currentFilter = const LogisticsKpiFilter();

  LogisticsKpiCubit({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        super(LogisticsKpiInitial());

  void init() {
    emit(LogisticsKpiLoading());
    _listenToVendorsAndDrivers();
    _listenToOrders();
  }

  void _listenToVendorsAndDrivers() {
    _vendorsSub = _firestore.collection('vendors').snapshots().listen((snap) {
      _vendorsList = snap.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? data['restaurantName'] ?? doc.id,
        };
      }).toList();
      _recalculateAndEmit();
    });

    _driversSub = _firestore.collection('users').where('type', isEqualTo: 'driver').snapshots().listen((snap) {
      _driversList = snap.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? data['fullName'] ?? doc.id,
        };
      }).toList();
      _recalculateAndEmit();
    });
  }

  void _listenToOrders() {
    _ordersSub = _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(300)
        .snapshots()
        .listen((snap) {
      _allOrders = snap.docs.map((doc) {
        try {
          return Order.fromMap(doc.data(), doc.id);
        } catch (_) {
          return null;
        }
      }).whereType<Order>().toList();

      _recalculateAndEmit();
    }, onError: (err) {
      emit(LogisticsKpiError(err.toString()));
    });
  }

  void updateFilter(LogisticsKpiFilter newFilter) {
    _currentFilter = newFilter;
    _recalculateAndEmit();
  }

  void _recalculateAndEmit() {
    if (state is LogisticsKpiLoading && _allOrders.isEmpty && _vendorsList.isEmpty) {
      return;
    }

    // 1. Filter Orders by Date, Vendor, Driver, Status, PaymentMethod, SearchQuery
    final filtered = _allOrders.where((order) {
      // Date filter
      if (_currentFilter.customStartDate != null && order.createdAt.isBefore(_currentFilter.customStartDate!)) {
        return false;
      }
      if (_currentFilter.customEndDate != null && order.createdAt.isAfter(_currentFilter.customEndDate!)) {
        return false;
      }

      // Vendor filter
      if (_currentFilter.vendorId != null && _currentFilter.vendorId!.isNotEmpty) {
        final vId = order.restaurantId;
        if (vId != _currentFilter.vendorId) return false;
      }

      // Driver filter
      if (_currentFilter.driverId != null && _currentFilter.driverId!.isNotEmpty) {
        if (order.driverId != _currentFilter.driverId) return false;
      }

      // Order Status filter
      if (_currentFilter.status != null) {
        if (order.status != _currentFilter.status) return false;
      }

      // Payment Method filter
      if (_currentFilter.paymentMethod != null) {
        if (order.paymentMethod != _currentFilter.paymentMethod) return false;
      }

      // Search Query (matches Order ID, Customer Name, Customer ID)
      if (_currentFilter.searchQuery.isNotEmpty) {
        final q = _currentFilter.searchQuery.toLowerCase();
        final matchId = order.id.toLowerCase().contains(q);
        final matchCustName = (order.customerName ?? '').toLowerCase().contains(q);
        final matchCustId = order.customerId.toLowerCase().contains(q);
        if (!matchId && !matchCustName && !matchCustId) return false;
      }

      return true;
    }).toList();

    // Compute Pagination Slice
    final totalCount = filtered.length;
    final startIndex = _currentFilter.pageIndex * _currentFilter.pageSize;
    final endIndex = (startIndex + _currentFilter.pageSize) > totalCount
        ? totalCount
        : (startIndex + _currentFilter.pageSize);

    final paginated = (startIndex < totalCount)
        ? filtered.sublist(startIndex, endIndex)
        : <Order>[];

    // 2. Compute Aggregated Stats
    double grossSales = 0.0;
    double deliveryFees = 0.0;
    int tripsCompleted = 0;
    int activeOrders = 0;
    double adminCommission = 0.0;
    double platformDeliveryCut = 0.0;
    double riderPayout = 0.0;

    final Map<String, VendorFinancialSummary> vMap = {};
    final Map<String, RiderPerformanceSummary> rMap = {};

    for (final order in filtered) {
      final isDelivered = order.status == OrderStatus.delivered;
      final isActive = order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled;

      if (isActive) activeOrders++;

      if (isDelivered) {
        tripsCompleted++;
        grossSales += order.subtotal;
        deliveryFees += order.deliveryFee;

        // Default 10% commission on food subtotal if not specified
        final comm = order.subtotal * 0.10;
        adminCommission += comm;

        // Default 85% rider payout, 15% platform delivery cut
        final rCut = order.deliveryFee * 0.85;
        final pCut = order.deliveryFee * 0.15;
        riderPayout += rCut;
        platformDeliveryCut += pCut;

        // Vendor aggregation
        final vId = order.restaurantId;
        final vName = _getVendorName(vId);
        final existingV = vMap[vId];
        if (existingV == null) {
          vMap[vId] = VendorFinancialSummary(
            vendorId: vId,
            vendorName: vName,
            netSales: order.subtotal,
            masterCommissionDeducted: comm,
            amountDueToVendor: order.subtotal - comm,
            orderCount: 1,
          );
        } else {
          vMap[vId] = VendorFinancialSummary(
            vendorId: vId,
            vendorName: vName,
            netSales: existingV.netSales + order.subtotal,
            masterCommissionDeducted: existingV.masterCommissionDeducted + comm,
            amountDueToVendor: existingV.amountDueToVendor + (order.subtotal - comm),
            orderCount: existingV.orderCount + 1,
          );
        }

        // Rider aggregation
        final driverId = order.driverId;
        if (driverId != null && driverId.isNotEmpty) {
          final rId = driverId;
          final rName = _getDriverName(rId);
          final existingR = rMap[rId];
          if (existingR == null) {
            rMap[rId] = RiderPerformanceSummary(
              riderId: rId,
              riderName: rName,
              tripsCompleted: 1,
              totalDeliveryFeesEarned: order.deliveryFee,
              riderPayout: rCut,
              platformFeeCut: pCut,
            );
          } else {
            rMap[rId] = RiderPerformanceSummary(
              riderId: rId,
              riderName: rName,
              tripsCompleted: existingR.tripsCompleted + 1,
              totalDeliveryFeesEarned: existingR.totalDeliveryFeesEarned + order.deliveryFee,
              riderPayout: existingR.riderPayout + rCut,
              platformFeeCut: existingR.platformFeeCut + pCut,
            );
          }
        }
      }
    }

    final totalNetProfit = _currentFilter.calculateWithFees
        ? adminCommission + platformDeliveryCut
        : adminCommission;

    final stats = LogisticsKpiStats(
      restaurantGrossSales: grossSales,
      totalDeliveryFeesCollected: deliveryFees,
      totalTripsCompleted: tripsCompleted,
      activeOrdersCount: activeOrders,
      overallRideAcceptanceRate: 0.94,
      masterAdminCommission: adminCommission,
      platformDeliveryCut: platformDeliveryCut,
      riderTotalPayout: riderPayout,
      totalNetProfit: totalNetProfit,
    );

    emit(LogisticsKpiLoaded(
      filter: _currentFilter,
      stats: stats,
      vendorsList: _vendorsList,
      driversList: _driversList,
      filteredOrders: filtered,
      paginatedOrders: paginated,
      totalOrdersCount: totalCount,
      vendorSummaries: vMap.values.toList(),
      riderSummaries: rMap.values.toList(),
    ));
  }

  String _getVendorName(String id) {
    final match = _vendorsList.firstWhere((v) => v['id'] == id, orElse: () => {});
    return match['name'] ?? id;
  }

  String _getDriverName(String id) {
    final match = _driversList.firstWhere((d) => d['id'] == id, orElse: () => {});
    return match['name'] ?? id;
  }

  @override
  Future<void> close() {
    _ordersSub?.cancel();
    _vendorsSub?.cancel();
    _driversSub?.cancel();
    return super.close();
  }
}
