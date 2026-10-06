import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:z_speed/core/services/routing_config.dart';
import 'package:z_speed/features/admin/cubit/admin_transport_cubit.dart';
import 'package:z_speed/features/admin/cubit/admin_transport_state.dart';
import 'package:z_speed/features/transport/model/ride_model.dart';
import 'package:z_speed/core/injection.dart';

class AdminTransportScreen extends StatelessWidget {
  const AdminTransportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AdminTransportCubit>()..watchAllTransports(),
      child: const DefaultTabController(
        length: 3,
        child: AdminTransportBody(),
      ),
    );
  }
}

class AdminTransportBody extends StatefulWidget {
  const AdminTransportBody({super.key});

  @override
  State<AdminTransportBody> createState() => _AdminTransportBodyState();
}

class _AdminTransportBodyState extends State<AdminTransportBody> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminTransportCubit, AdminTransportState>(
      builder: (context, state) {
        if (state is AdminTransportLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is AdminTransportError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        if (state is AdminTransportLoaded) {
          final l10n = AppLocalizations.of(context)!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Beautiful Custom Tab Bar Container
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: TabBar(
                  indicatorColor: const Color(0xFFF35535),
                  labelColor: const Color(0xFFF35535),
                  unselectedLabelColor: Colors.black54,
                  indicatorWeight: 3,
                  labelStyle:
                      const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: [
                    Tab(
                        icon: const Icon(Icons.map_outlined, size: 20),
                        text: l10n.operationsTab),
                    Tab(
                        icon: const Icon(Icons.account_balance_wallet_outlined,
                            size: 20),
                        text: l10n.financialsTab),
                    Tab(
                        icon: const Icon(Icons.analytics_outlined, size: 20),
                        text: l10n.analyticsAndHistoryTab),
                  ],
                ),
              ),

              // Tab Content Area
              Expanded(
                child: TabBarView(
                  children: [
                    // Tab 1: Map Operations
                    Column(
                      children: [
                        _buildStatsRow(context, state),
                        Expanded(
                          child: Stack(
                            children: [
                              _buildLiveMap(state.allRides),
                              Positioned(
                                bottom: 16,
                                right: 16,
                                child: FloatingActionButton(
                                  backgroundColor: Colors.black87,
                                  mini: true,
                                  onPressed: () {
                                    _mapController.move(
                                        const LatLng(29.9602, 31.6981), 11);
                                  },
                                  child: const Icon(Icons.my_location,
                                      color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildRidesList(context, state.allRides),
                      ],
                    ),

                    // Tab 2: Financial Pricing & Commission Settings
                    _FinancialSettingsTab(state: state),

                    // Tab 3: Analytics & Ride History
                    _AnalyticsHistoryTab(state: state),
                  ],
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildStatsRow(BuildContext context, AdminTransportLoaded state) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statCard(
              l10n.activeRides, state.activeRidesCount.toString(), Colors.blue),
          _statCard(
              l10n.completed, state.completedRidesCount.toString(), Colors.green),
          _statCard(l10n.statTotalRevenue,
              '${state.totalRevenue.toStringAsFixed(0)} EGP', Colors.orange),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w900, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildLiveMap(List<RideModel> rides) {
    final activeMarkers = rides
        .where((r) =>
            r.status != RideStatus.completed &&
            r.status != RideStatus.cancelled)
        .map((r) => Marker(
              point:
                  LatLng(r.pickupLocation.latitude, r.pickupLocation.longitude),
              width: 45,
              height: 45,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 6)
                  ],
                ),
                child: const Icon(Icons.directions_car,
                    color: Colors.blue, size: 24),
              ),
            ))
        .toList();

    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
        initialCenter: LatLng(29.9602, 31.6981), // New Administrative Capital
        initialZoom: 11,
      ),
      children: [
        TileLayer(
          urlTemplate: RoutingConfig.tileUrl,
          subdomains: RoutingConfig.tileSubdomains,
          userAgentPackageName: RoutingConfig.userAgentPackageName,
        ),
        MarkerLayer(markers: activeMarkers),
      ],
    );
  }

  Widget _buildRidesList(BuildContext context, List<RideModel> rides) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 220,
      decoration: const BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 12, spreadRadius: 2)
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.recentTrips,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      '${l10n.total} ${rides.length}',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: rides.isEmpty
                  ? Center(
                      child: Text(l10n.noRidesRegisteredToday,
                          style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    )
                  : ListView.separated(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: rides.length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (context, index) {
                        final ride = rides[index];
                        final isActive = ride.status != RideStatus.completed &&
                            ride.status != RideStatus.cancelled;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.blue.shade50
                                  : Colors.grey.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              ride.status == RideStatus.completed
                                  ? Icons.check_circle
                                  : ride.status == RideStatus.cancelled
                                      ? Icons.cancel
                                      : Icons.local_taxi,
                              color: ride.status == RideStatus.completed
                                  ? Colors.green
                                  : ride.status == RideStatus.cancelled
                                      ? Colors.red
                                      : Colors.blue,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            '${ride.pickupLocation.address} -> ${ride.dropoffLocation.address}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            l10n.statusAndFare(
                              _getRideStatusText(l10n, ride.status),
                              ride.totalFare.toStringAsFixed(2),
                            ),
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              size: 12, color: Colors.grey),
                          onTap: () {
                            // Center on map and zoom
                            _mapController.move(
                              LatLng(ride.pickupLocation.latitude,
                                  ride.pickupLocation.longitude),
                              14.5,
                            );
                            _showRideDetailsBottomSheet(context, ride);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRideStatusText(AppLocalizations l10n, RideStatus status) {
    switch (status) {
      case RideStatus.completed:
        return l10n.completed;
      case RideStatus.cancelled:
        return l10n.cancelled;
      case RideStatus.pending:
        return l10n.pendingVerification;
      default:
        return status.name.toUpperCase();
    }
  }

  void _showRideDetailsBottomSheet(BuildContext context, RideModel ride) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final isActive = ride.status != RideStatus.completed &&
            ride.status != RideStatus.cancelled;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Trip #${ride.id.substring(0, 8)}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ),
                  _buildStatusPill(ride.status),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailItem(
                  Icons.person, 'Customer', ride.customerName ?? 'Guest'),
              if (ride.customerPhone != null)
                _buildDetailItem(Icons.phone, 'Phone', ride.customerPhone!),
              _buildDetailItem(
                  Icons.location_on, 'Pickup', ride.pickupLocation.address),
              _buildDetailItem(Icons.navigation, 'Destination',
                  ride.dropoffLocation.address),
              _buildDetailItem(
                  Icons.local_offer, 'Total Fare', '${ride.totalFare} EGP'),
              _buildDetailItem(
                  Icons.directions_car, 'Vehicle Type', ride.vehicleType),
              const SizedBox(height: 24),
              if (isActive)
                WidgetListTileButton(rideId: ride.id)
              else
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusPill(RideStatus status) {
    Color bg;
    Color fg;
    switch (status) {
      case RideStatus.completed:
        bg = Colors.green.shade50;
        fg = Colors.green;
      case RideStatus.cancelled:
        bg = Colors.red.shade50;
        fg = Colors.red;
      case RideStatus.pending:
        bg = Colors.orange.shade50;
        fg = Colors.orange;
      default:
        bg = Colors.blue.shade50;
        fg = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                children: [
                  TextSpan(
                      text: '$label: ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WidgetListTileButton extends StatelessWidget {
  final String rideId;
  const WidgetListTileButton({super.key, required this.rideId});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: () {
          context
              .read<AdminTransportCubit>()
              .updateRideStatus(rideId, RideStatus.cancelled);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trip marked as CANCELLED')),
          );
        },
        child: const Text('Cancel Trip',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Financial Settings Tab
// ─────────────────────────────────────────────────────────────────────────────
class _FinancialSettingsTab extends StatefulWidget {
  final AdminTransportLoaded state;
  const _FinancialSettingsTab({required this.state});

  @override
  State<_FinancialSettingsTab> createState() => _FinancialSettingsTabState();
}

class _FinancialSettingsTabState extends State<_FinancialSettingsTab> {
  final _formKey = GlobalKey<FormState>();

  // Sedan Controllers
  final _sedanBaseFareCtrl = TextEditingController();
  final _sedanPricePerKmCtrl = TextEditingController();
  final _sedanProfitValueCtrl = TextEditingController();
  String _sedanProfitType = 'percentage';
  final _sedanCustomerCommValueCtrl = TextEditingController();
  String _sedanCustomerCommType = 'percentage';

  // Moto Controllers
  final _motoBaseFareCtrl = TextEditingController();
  final _motoPricePerKmCtrl = TextEditingController();
  final _motoProfitValueCtrl = TextEditingController();
  String _motoProfitType = 'percentage';
  final _motoCustomerCommValueCtrl = TextEditingController();
  String _motoCustomerCommType = 'percentage';

  // Luxury Controllers
  final _luxuryBaseFareCtrl = TextEditingController();
  final _luxuryPricePerKmCtrl = TextEditingController();
  final _luxuryProfitValueCtrl = TextEditingController();
  String _luxuryProfitType = 'percentage';
  final _luxuryCustomerCommValueCtrl = TextEditingController();
  String _luxuryCustomerCommType = 'percentage';

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadValues();
  }

  void _loadValues() {
    final config = widget.state.pricingConfig;

    _sedanBaseFareCtrl.text = (config['sedan_baseFare'] ?? 15.0).toString();
    _sedanPricePerKmCtrl.text = (config['sedan_pricePerKm'] ?? 5.0).toString();
    _sedanProfitValueCtrl.text =
        (config['sedan_profitValue'] ?? 20.0).toString();
    _sedanProfitType = config['sedan_profitType'] ?? 'percentage';
    _sedanCustomerCommValueCtrl.text =
        (config['sedan_customerCommValue'] ?? 0.0).toString();
    _sedanCustomerCommType = config['sedan_customerCommType'] ?? 'percentage';

    _motoBaseFareCtrl.text = (config['moto_baseFare'] ?? 10.0).toString();
    _motoPricePerKmCtrl.text = (config['moto_pricePerKm'] ?? 3.0).toString();
    _motoProfitValueCtrl.text = (config['moto_profitValue'] ?? 15.0).toString();
    _motoProfitType = config['moto_profitType'] ?? 'percentage';
    _motoCustomerCommValueCtrl.text =
        (config['moto_customerCommValue'] ?? 0.0).toString();
    _motoCustomerCommType = config['moto_customerCommType'] ?? 'percentage';

    _luxuryBaseFareCtrl.text = (config['luxury_baseFare'] ?? 25.0).toString();
    _luxuryPricePerKmCtrl.text =
        (config['luxury_pricePerKm'] ?? 8.0).toString();
    _luxuryProfitValueCtrl.text =
        (config['luxury_profitValue'] ?? 20.0).toString();
    _luxuryProfitType = config['luxury_profitType'] ?? 'percentage';
    _luxuryCustomerCommValueCtrl.text =
        (config['luxury_customerCommValue'] ?? 0.0).toString();
    _luxuryCustomerCommType = config['luxury_customerCommType'] ?? 'percentage';
  }

  @override
  void didUpdateWidget(covariant _FinancialSettingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.pricingConfig != widget.state.pricingConfig) {
      _loadValues();
    }
  }

  @override
  void dispose() {
    _sedanBaseFareCtrl.dispose();
    _sedanPricePerKmCtrl.dispose();
    _sedanProfitValueCtrl.dispose();
    _sedanCustomerCommValueCtrl.dispose();
    _motoBaseFareCtrl.dispose();
    _motoPricePerKmCtrl.dispose();
    _motoProfitValueCtrl.dispose();
    _motoCustomerCommValueCtrl.dispose();
    _luxuryBaseFareCtrl.dispose();
    _luxuryPricePerKmCtrl.dispose();
    _luxuryProfitValueCtrl.dispose();
    _luxuryCustomerCommValueCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final newConfig = {
      'sedan_baseFare': double.tryParse(_sedanBaseFareCtrl.text) ?? 15.0,
      'sedan_pricePerKm': double.tryParse(_sedanPricePerKmCtrl.text) ?? 5.0,
      'sedan_profitType': _sedanProfitType,
      'sedan_profitValue': double.tryParse(_sedanProfitValueCtrl.text) ?? 20.0,
      'sedan_customerCommType': _sedanCustomerCommType,
      'sedan_customerCommValue':
          double.tryParse(_sedanCustomerCommValueCtrl.text) ?? 0.0,
      'moto_baseFare': double.tryParse(_motoBaseFareCtrl.text) ?? 10.0,
      'moto_pricePerKm': double.tryParse(_motoPricePerKmCtrl.text) ?? 3.0,
      'moto_profitType': _motoProfitType,
      'moto_profitValue': double.tryParse(_motoProfitValueCtrl.text) ?? 15.0,
      'moto_customerCommType': _motoCustomerCommType,
      'moto_customerCommValue':
          double.tryParse(_motoCustomerCommValueCtrl.text) ?? 0.0,
      'luxury_baseFare': double.tryParse(_luxuryBaseFareCtrl.text) ?? 25.0,
      'luxury_pricePerKm': double.tryParse(_luxuryPricePerKmCtrl.text) ?? 8.0,
      'luxury_profitType': _luxuryProfitType,
      'luxury_profitValue':
          double.tryParse(_luxuryProfitValueCtrl.text) ?? 20.0,
      'luxury_customerCommType': _luxuryCustomerCommType,
      'luxury_customerCommValue':
          double.tryParse(_luxuryCustomerCommValueCtrl.text) ?? 0.0,
    };

    try {
      await context.read<AdminTransportCubit>().savePricingConfig(newConfig);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Financial settings updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Pricing & Commissions',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure base fares, price per kilometer, and the app\'s profit commission settings for each vehicle type.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            _buildVehicleConfigCard(
              title: 'Standard Sedan (سيارة عادية)',
              icon: Icons.directions_car,
              color: Colors.blue,
              baseCtrl: _sedanBaseFareCtrl,
              priceCtrl: _sedanPricePerKmCtrl,
              driverProfitCtrl: _sedanProfitValueCtrl,
              driverProfitType: _sedanProfitType,
              onDriverProfitTypeChanged: (val) =>
                  setState(() => _sedanProfitType = val!),
              customerProfitCtrl: _sedanCustomerCommValueCtrl,
              customerProfitType: _sedanCustomerCommType,
              onCustomerProfitTypeChanged: (val) =>
                  setState(() => _sedanCustomerCommType = val!),
            ),
            const SizedBox(height: 20),
            _buildVehicleConfigCard(
              title: 'Motorcycle (موتوسيكل)',
              icon: Icons.motorcycle,
              color: Colors.green,
              baseCtrl: _motoBaseFareCtrl,
              priceCtrl: _motoPricePerKmCtrl,
              driverProfitCtrl: _motoProfitValueCtrl,
              driverProfitType: _motoProfitType,
              onDriverProfitTypeChanged: (val) =>
                  setState(() => _motoProfitType = val!),
              customerProfitCtrl: _motoCustomerCommValueCtrl,
              customerProfitType: _motoCustomerCommType,
              onCustomerProfitTypeChanged: (val) =>
                  setState(() => _motoCustomerCommType = val!),
            ),
            const SizedBox(height: 20),
            _buildVehicleConfigCard(
              title: 'Premium Luxury (بريميوم)',
              icon: Icons.stars,
              color: Colors.amber.shade700,
              baseCtrl: _luxuryBaseFareCtrl,
              priceCtrl: _luxuryPricePerKmCtrl,
              driverProfitCtrl: _luxuryProfitValueCtrl,
              driverProfitType: _luxuryProfitType,
              onDriverProfitTypeChanged: (val) =>
                  setState(() => _luxuryProfitType = val!),
              customerProfitCtrl: _luxuryCustomerCommValueCtrl,
              customerProfitType: _luxuryCustomerCommType,
              onCustomerProfitTypeChanged: (val) =>
                  setState(() => _luxuryCustomerCommType = val!),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF35535),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Save Financial Settings',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleConfigCard({
    required String title,
    required IconData icon,
    required Color color,
    required TextEditingController baseCtrl,
    required TextEditingController priceCtrl,
    required TextEditingController driverProfitCtrl,
    required String driverProfitType,
    required ValueChanged<String?> onDriverProfitTypeChanged,
    required TextEditingController customerProfitCtrl,
    required String customerProfitType,
    required ValueChanged<String?> onCustomerProfitTypeChanged,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87)),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: baseCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Base Fare (EGP)',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    validator: (v) {
                      if (v == null || double.tryParse(v) == null) {
                        return 'Enter number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Price per Km (EGP)',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    validator: (v) {
                      if (v == null || double.tryParse(v) == null) {
                        return 'Enter number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Driver Commission (Sourced from Driver)',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black54)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: driverProfitType,
                    items: const [
                      DropdownMenuItem(
                          value: 'percentage', child: Text('Percent (%)')),
                      DropdownMenuItem(
                          value: 'flat_per_km',
                          child: Text('Flat per Km (EGP)')),
                      DropdownMenuItem(
                          value: 'flat_per_ride',
                          child: Text('Flat per Ride (EGP)')),
                    ],
                    onChanged: onDriverProfitTypeChanged,
                    decoration: const InputDecoration(
                      labelText: 'Profit Type',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: driverProfitCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Value',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    validator: (v) {
                      if (v == null || double.tryParse(v) == null) {
                        return 'Enter number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Customer Commission (Added to Customer Fare)',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black54)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: customerProfitType,
                    items: const [
                      DropdownMenuItem(
                          value: 'percentage', child: Text('Percent (%)')),
                      DropdownMenuItem(
                          value: 'flat_per_km',
                          child: Text('Flat per Km (EGP)')),
                      DropdownMenuItem(
                          value: 'flat_per_ride',
                          child: Text('Flat per Ride (EGP)')),
                    ],
                    onChanged: onCustomerProfitTypeChanged,
                    decoration: const InputDecoration(
                      labelText: 'Commission Type',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: customerProfitCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Value',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    validator: (v) {
                      if (v == null || double.tryParse(v) == null) {
                        return 'Enter number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Analytics & History Tab
// ─────────────────────────────────────────────────────────────────────────────
class _AnalyticsHistoryTab extends StatefulWidget {
  final AdminTransportLoaded state;
  const _AnalyticsHistoryTab({required this.state});

  @override
  State<_AnalyticsHistoryTab> createState() => _AnalyticsHistoryTabState();
}

class _AnalyticsHistoryTabState extends State<_AnalyticsHistoryTab> {
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _vehicleFilter = 'all';

  double _calculateRideProfit(RideModel ride) {
    final config = widget.state.pricingConfig;
    final type = ride.vehicleType.toLowerCase();

    final distanceInMeters = Geolocator.distanceBetween(
      ride.pickupLocation.latitude,
      ride.pickupLocation.longitude,
      ride.dropoffLocation.latitude,
      ride.dropoffLocation.longitude,
    );
    final distance = distanceInMeters / 1000.0;

    final double calculatedFare = distance * 7.0;
    final baseCost = calculatedFare > 35.0 ? calculatedFare : 35.0;

    // 1. Customer Commission
    final custCommType = config['${type}_customerCommType'] ?? 'percentage';
    final custCommVal =
        (config['${type}_customerCommValue'] as num?)?.toDouble() ?? 0.0;
    double customerComm = 0.0;
    if (custCommType == 'percentage') {
      customerComm = baseCost * (custCommVal / 100.0);
    } else if (custCommType == 'flat_per_km') {
      customerComm = distance * custCommVal;
    } else {
      customerComm = custCommVal;
    }

    // 2. Driver Commission
    final drvCommType = config['${type}_profitType'] ?? 'percentage';
    final drvCommVal =
        (config['${type}_profitValue'] as num?)?.toDouble() ?? 20.0;
    double driverComm = 0.0;
    if (drvCommType == 'percentage') {
      driverComm = baseCost * (drvCommVal / 100.0);
    } else if (drvCommType == 'flat_per_km') {
      driverComm = distance * drvCommVal;
    } else {
      driverComm = drvCommVal;
    }

    return customerComm + driverComm;
  }

  @override
  Widget build(BuildContext context) {
    double totalRevenue = 0;
    double appProfits = 0;
    int completedCount = 0;

    for (var r in widget.state.allRides) {
      if (r.status == RideStatus.completed) {
        totalRevenue += r.totalFare;
        completedCount++;
        appProfits += _calculateRideProfit(r);
      }
    }

    final double driverEarnings = totalRevenue - appProfits;

    final filteredRides = widget.state.allRides.where((r) {
      final name = (r.customerName ?? '').toLowerCase();
      final phone = (r.customerPhone ?? '').toLowerCase();
      final destination = r.dropoffLocation.address.toLowerCase();
      final matchesSearch = name.contains(_searchQuery.toLowerCase()) ||
          phone.contains(_searchQuery.toLowerCase()) ||
          destination.contains(_searchQuery.toLowerCase());

      bool matchesStatus = true;
      if (_statusFilter == 'completed') {
        matchesStatus = r.status == RideStatus.completed;
      } else if (_statusFilter == 'cancelled') {
        matchesStatus = r.status == RideStatus.cancelled;
      } else if (_statusFilter == 'active') {
        matchesStatus = r.status != RideStatus.completed &&
            r.status != RideStatus.cancelled;
      }

      bool matchesVehicle = true;
      if (_vehicleFilter != 'all') {
        matchesVehicle = r.vehicleType.toLowerCase() == _vehicleFilter;
      }

      return matchesSearch && matchesStatus && matchesVehicle;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFinancialCard(
                  title: 'Revenue ($completedCount Trips)',
                  value: '${totalRevenue.toStringAsFixed(0)} EGP',
                  icon: Icons.monetization_on,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFinancialCard(
                  title: 'App profit',
                  value: '${appProfits.toStringAsFixed(0)} EGP',
                  icon: Icons.account_balance,
                  color: const Color(0xFFF35535),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFinancialCard(
                  title: 'Drivers Payout',
                  value: '${driverEarnings.toStringAsFixed(0)} EGP',
                  icon: Icons.people,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search customer, phone, or destination...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _statusFilter,
                        items: const [
                          DropdownMenuItem(
                              value: 'all', child: Text('All Statuses')),
                          DropdownMenuItem(
                              value: 'completed', child: Text('Completed')),
                          DropdownMenuItem(
                              value: 'active', child: Text('Active Only')),
                          DropdownMenuItem(
                              value: 'cancelled', child: Text('Cancelled')),
                        ],
                        onChanged: (v) => setState(() => _statusFilter = v!),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _vehicleFilter,
                        items: const [
                          DropdownMenuItem(
                              value: 'all', child: Text('All Vehicles')),
                          DropdownMenuItem(
                              value: 'sedan', child: Text('Sedan')),
                          DropdownMenuItem(
                              value: 'moto', child: Text('Motorcycle')),
                          DropdownMenuItem(
                              value: 'luxury', child: Text('Premium')),
                        ],
                        onChanged: (v) => setState(() => _vehicleFilter = v!),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ride History (${filteredRides.length} found)',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Text(
                'Total rides in system: ${widget.state.allRides.length}',
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filteredRides.isEmpty
                ? const Center(child: Text('No rides match filters.'))
                : ListView.separated(
                    itemCount: filteredRides.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final ride = filteredRides[index];
                      final isCompleted = ride.status == RideStatus.completed;
                      final profit =
                          isCompleted ? _calculateRideProfit(ride) : 0.0;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: ride.status == RideStatus.completed
                              ? Colors.green.shade50
                              : ride.status == RideStatus.cancelled
                                  ? Colors.red.shade50
                                  : Colors.blue.shade50,
                          child: Icon(
                            ride.status == RideStatus.completed
                                ? Icons.check_circle_outline
                                : ride.status == RideStatus.cancelled
                                    ? Icons.highlight_off
                                    : Icons.access_time,
                            color: ride.status == RideStatus.completed
                                ? Colors.green
                                : ride.status == RideStatus.cancelled
                                    ? Colors.red
                                    : Colors.blue,
                          ),
                        ),
                        title: Text(
                          '${ride.customerName ?? "Guest"} | ${ride.vehicleType.toUpperCase()}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${ride.pickupLocation.address} -> ${ride.dropoffLocation.address}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Requested: ${ride.requestedAt.toString().substring(0, 16)}',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${ride.totalFare.toStringAsFixed(0)} EGP',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87),
                            ),
                            if (isCompleted)
                              Text(
                                'Profit: ${profit.toStringAsFixed(1)} EGP',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                        onTap: () {
                          _showRideDetailsBottomSheet(context, ride, profit);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }

  void _showRideDetailsBottomSheet(
      BuildContext context, RideModel ride, double profit) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final isActive = ride.status != RideStatus.completed &&
            ride.status != RideStatus.cancelled;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Trip #${ride.id.substring(0, 8)}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ),
                  _buildStatusPill(ride.status),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailItem(
                  Icons.person, 'Customer', ride.customerName ?? 'Guest'),
              if (ride.customerPhone != null)
                _buildDetailItem(Icons.phone, 'Phone', ride.customerPhone!),
              _buildDetailItem(
                  Icons.location_on, 'Pickup', ride.pickupLocation.address),
              _buildDetailItem(Icons.navigation, 'Destination',
                  ride.dropoffLocation.address),
              _buildDetailItem(
                  Icons.local_offer, 'Total Fare', '${ride.totalFare} EGP'),
              if (ride.status == RideStatus.completed)
                _buildDetailItem(Icons.trending_up, 'App Profit Margin',
                    '${profit.toStringAsFixed(1)} EGP'),
              _buildDetailItem(
                  Icons.directions_car, 'Vehicle Type', ride.vehicleType),
              const SizedBox(height: 24),
              if (isActive)
                WidgetListTileButton(rideId: ride.id)
              else
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusPill(RideStatus status) {
    Color bg;
    Color fg;
    switch (status) {
      case RideStatus.completed:
        bg = Colors.green.shade50;
        fg = Colors.green;
      case RideStatus.cancelled:
        bg = Colors.red.shade50;
        fg = Colors.red;
      case RideStatus.pending:
        bg = Colors.orange.shade50;
        fg = Colors.orange;
      default:
        bg = Colors.blue.shade50;
        fg = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                children: [
                  TextSpan(
                      text: '$label: ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
