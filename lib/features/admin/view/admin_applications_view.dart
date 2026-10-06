import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/features/admin/model/application_model.dart';
import 'package:z_speed/features/admin/model/admin_theme.dart';
import 'package:z_speed/features/admin/cubit/admin_application_cubit.dart';
import 'package:z_speed/features/admin/cubit/admin_application_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/features/admin/view/admin_application_detail_view.dart';
import 'package:z_speed/core/errors/failure_localization_ext.dart';

/// Unified Onboarding & Application Review Portal.
///
/// Combines Driver applications and all categories of Vendor applications
/// into a single dashboard using sub-tabs, filter chips, and search.
class AdminApplicationsView extends StatefulWidget {
  const AdminApplicationsView({super.key});

  @override
  State<AdminApplicationsView> createState() => _AdminApplicationsViewState();
}

class _AdminApplicationsViewState extends State<AdminApplicationsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedDriverSegment = 0; // 0=Pending, 1=Approved, 2=Rejected
  int _selectedVendorSegment = 0; // 0=Pending, 1=Approved, 2=Rejected
  String _driverSearchQuery = '';
  String _vendorSearchQuery = '';
  VendorType? _selectedVendorType; // null means 'All Categories'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<AdminApplicationCubit, AdminApplicationState>(
      builder: (context, state) {
        if (state.isBusy) {
          return Center(
            child: CircularProgressIndicator(
              color: AdminTheme.primaryOrange,
            ),
          );
        }

        if (state.hasError && state.failure != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AdminTheme.errorRed),
                const SizedBox(height: 16),
                Text(
                  state.failure?.getLocalizedMessage(context) ??
                      'Failed to load applications',
                  style: TextStyle(color: AdminTheme.textDark, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () =>
                      context.read<AdminApplicationCubit>().loadApplications(),
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.retry),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.primaryOrange,
                    foregroundColor: AdminTheme.white,
                  ),
                ),
              ],
            ),
          );
        }

        final allApps = state.applications;

        // Statistics calculation
        final totalPending = allApps.where((a) => a.isPending).length;
        final pendingDrivers = allApps
            .where((a) => a.applicationType == ApplicationType.driver && a.isPending)
            .length;
        final pendingVendors = allApps
            .where((a) =>
                (a.applicationType == ApplicationType.restaurant ||
                    a.applicationType == ApplicationType.vendor) &&
                a.isPending)
            .length;

        // Driver application filtering
        final driverApps = allApps
            .where((a) => a.applicationType == ApplicationType.driver)
            .toList();
        final driverPending = driverApps.where((a) => a.isPending).toList();
        final driverApproved = driverApps.where((a) => a.isApproved).toList();
        final driverRejected = driverApps.where((a) => a.isRejected).toList();
        final List<List<Application>> driverSegments = [
          driverPending,
          driverApproved,
          driverRejected,
        ];
        final currentDriverApps =
            _filterDriverBySearch(driverSegments[_selectedDriverSegment]);

        // Vendor application filtering
        final vendorApps = allApps
            .where((a) =>
                a.applicationType == ApplicationType.restaurant ||
                a.applicationType == ApplicationType.vendor)
            .where((a) {
              if (_selectedVendorType == null) return true;
              final vt = a.formData['vendorType'] as String? ?? 'restaurant';
              return vt == _selectedVendorType!.name;
            })
            .toList();
        final vendorPending = vendorApps.where((a) => a.isPending).toList();
        final vendorApproved = vendorApps.where((a) => a.isApproved).toList();
        final vendorRejected = vendorApps.where((a) => a.isRejected).toList();
        final List<List<Application>> vendorSegments = [
          vendorPending,
          vendorApproved,
          vendorRejected,
        ];
        final currentVendorApps =
            _filterVendorBySearch(vendorSegments[_selectedVendorSegment]);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Refresh Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.applicationsTitle,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AdminTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.applicationsSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AdminTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      context.read<AdminApplicationCubit>().loadApplications(),
                  icon: Icon(Icons.refresh, color: AdminTheme.textMedium),
                  tooltip: l10n.refreshTooltip,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Statistics Dashboard Cards
            _buildStatsCards(
              totalPending: totalPending,
              pendingDrivers: pendingDrivers,
              pendingVendors: pendingVendors,
            ),
            const SizedBox(height: 20),

            // Main TabBar Navigation
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AdminTheme.borderColor, width: 1.5),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AdminTheme.primaryOrange,
                labelColor: AdminTheme.primaryOrange,
                unselectedLabelColor: AdminTheme.textMedium,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                tabs: [
                  Tab(text: l10n.driversTab),
                  Tab(text: l10n.vendorsTab),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab Views Wrapper
            SizedBox(
              height: 650, // Fixed height or can wrap inside flexible constraints
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Drivers Tab View
                  _buildDriversTabView(currentDriverApps, driverPending.length,
                      driverApproved.length, driverRejected.length, l10n),

                  // Vendors Tab View
                  _buildVendorsTabView(currentVendorApps, vendorPending.length,
                      vendorApproved.length, vendorRejected.length, l10n),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Metrics Row Cards ──────────────────────────────────────────────────────

  Widget _buildStatsCards({
    required int totalPending,
    required int pendingDrivers,
    required int pendingVendors,
  }) {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 600;

      final cards = [
        _buildMetricCard(
          title: isMobile ? 'Total' : 'Total Pending',
          value: totalPending.toString(),
          icon: Icons.hourglass_empty,
          color: AdminTheme.primaryOrange,
          isMobile: isMobile,
        ),
        _buildMetricCard(
          title: isMobile ? 'Drivers' : 'Pending Drivers',
          value: pendingDrivers.toString(),
          icon: Icons.directions_car_outlined,
          color: Colors.blue.shade600,
          isMobile: isMobile,
        ),
        _buildMetricCard(
          title: isMobile ? 'Vendors' : 'Pending Vendors',
          value: pendingVendors.toString(),
          icon: Icons.storefront_outlined,
          color: AdminTheme.successGreen,
          isMobile: isMobile,
        ),
      ];

      return Row(
        children: cards
            .asMap()
            .entries
            .map((entry) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: entry.key == cards.length - 1 ? 0 : (isMobile ? 8 : 16),
                    ),
                    child: entry.value,
                  ),
                ))
            .toList(),
      );
    });
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 16,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: AdminTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 6 : 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: isMobile ? 18 : 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 16 : 20,
              fontWeight: FontWeight.w800,
              color: AdminTheme.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 9 : 11,
              fontWeight: FontWeight.w600,
              color: AdminTheme.textLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Tab Views ──────────────────────────────────────────────────────────────

  Widget _buildDriversTabView(
    List<Application> apps,
    int pending,
    int approved,
    int rejected,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Driver Segment Control
        Container(
          decoration: BoxDecoration(
            color: AdminTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AdminTheme.borderColor),
          ),
          child: Row(
            children: [
              _buildSegmentButton(
                  l10n.pendingTab(pending), 0, true),
              _buildSegmentButton(
                  l10n.approvedTab(approved), 1, true),
              _buildSegmentButton(
                  l10n.rejectedTab(rejected), 2, true),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Driver Search Bar
        _buildSearchBar(
          query: _driverSearchQuery,
          onChanged: (val) => setState(() => _driverSearchQuery = val),
          placeholder: l10n.searchByNameEmailPhone,
        ),
        const SizedBox(height: 16),

        // Apps List
        Expanded(
          child: apps.isEmpty
              ? _buildEmptyState(_selectedDriverSegment, l10n)
              : ListView.builder(
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    return _buildApplicationCard(apps[index], l10n);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildVendorsTabView(
    List<Application> apps,
    int pending,
    int approved,
    int rejected,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCategoryChip(
                label: l10n.allCategoriesFilter,
                selected: _selectedVendorType == null,
                onTap: () => setState(() => _selectedVendorType = null),
              ),
              const SizedBox(width: 8),
              for (final type in VendorType.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildCategoryChip(
                    label: type.label,
                    selected: _selectedVendorType == type,
                    onTap: () => setState(() => _selectedVendorType = type),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Vendor Segment Control
        Container(
          decoration: BoxDecoration(
            color: AdminTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AdminTheme.borderColor),
          ),
          child: Row(
            children: [
              _buildSegmentButton(
                  l10n.pendingTab(pending), 0, false),
              _buildSegmentButton(
                  l10n.approvedTab(approved), 1, false),
              _buildSegmentButton(
                  l10n.rejectedTab(rejected), 2, false),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Vendor Search Bar
        _buildSearchBar(
          query: _vendorSearchQuery,
          onChanged: (val) => setState(() => _vendorSearchQuery = val),
          placeholder: l10n.searchByNameEmailPhone,
        ),
        const SizedBox(height: 16),

        // Apps List
        Expanded(
          child: apps.isEmpty
              ? _buildEmptyState(_selectedVendorSegment, l10n)
              : ListView.builder(
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    return _buildApplicationCard(apps[index], l10n);
                  },
                ),
        ),
      ],
    );
  }

  // ── View Helper Widgets ────────────────────────────────────────────────────

  Widget _buildSegmentButton(String label, int index, bool isDriver) {
    final isSelected = isDriver ? _selectedDriverSegment == index : _selectedVendorSegment == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isDriver) {
              _selectedDriverSegment = index;
            } else {
              _selectedVendorSegment = index;
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AdminTheme.primaryOrange : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? AdminTheme.white : AdminTheme.textMedium,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : AdminTheme.textMedium,
        ),
      ),
      selected: selected,
      selectedColor: AdminTheme.primaryOrange,
      backgroundColor: AdminTheme.surfaceWhite,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected ? Colors.transparent : AdminTheme.borderColor,
        ),
      ),
      onSelected: (_) => onTap(),
    );
  }

  Widget _buildSearchBar({
    required String query,
    required ValueChanged<String> onChanged,
    required String placeholder,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AdminTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.borderColor),
      ),
      child: TextField(
        onChanged: onChanged,
        controller: TextEditingController.fromValue(
          TextEditingValue(
            text: query,
            selection: TextSelection.collapsed(offset: query.length),
          ),
        ),
        decoration: InputDecoration(
          hintText: placeholder,
          prefixIcon: Icon(Icons.search, color: AdminTheme.textLight, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintStyle: TextStyle(color: AdminTheme.textLight, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildEmptyState(int selectedSegment, AppLocalizations l10n) {
    final labels = ['pending', 'approved', 'rejected'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined,
                size: 48, color: Colors.grey.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              l10n.noTypeApplications(labels[selectedSegment]),
              style: TextStyle(color: AdminTheme.textLight, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationCard(Application app, AppLocalizations l10n) {
    final name = app.applicationType == ApplicationType.driver
        ? (app.formData['personalInfo']?['name'] as String? ?? 'Unknown Driver')
        : (app.formData['businessInfo']?['restaurantName'] as String? ??
            l10n.unknownRestaurantLabel);
    final email = app.applicationType == ApplicationType.driver
        ? (app.formData['personalInfo']?['email'] as String? ?? '—')
        : (app.formData['contactInfo']?['email'] as String? ?? '—');
    final submitted = _formatDate(app.submittedAt);

    // Icon resolution
    IconData iconData = Icons.store;
    if (app.applicationType == ApplicationType.driver) {
      iconData = Icons.directions_car_outlined;
    } else {
      final vtStr = app.formData['vendorType'] as String? ?? 'restaurant';
      final type = VendorType.values.firstWhere(
        (e) => e.name == vtStr,
        orElse: () => VendorType.restaurant,
      );
      switch (type) {
        case VendorType.restaurant:
          iconData = Icons.restaurant;
        case VendorType.supermarket:
          iconData = Icons.local_grocery_store;
        case VendorType.pharmacy:
          iconData = Icons.local_pharmacy;
        case VendorType.bookstore:
          iconData = Icons.menu_book;
        case VendorType.homeFurnishing:
          iconData = Icons.chair;
        case VendorType.meatAndProteins:
          iconData = Icons.restaurant_menu;
        case VendorType.clothes:
          iconData = Icons.checkroom;
        case VendorType.buyAndSell:
          iconData = Icons.swap_horiz;
        case VendorType.electronics:
          iconData = Icons.devices;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AdminTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon Badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AdminTheme.primaryOrange, AdminTheme.accentOrange],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(iconData, color: AdminTheme.white, size: 24),
              ),
            ),
            const SizedBox(width: 12),

            // Metadata Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AdminTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: TextStyle(fontSize: 12, color: AdminTheme.textLight),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 12, color: AdminTheme.textLight),
                      const SizedBox(width: 4),
                      Text(
                        submitted,
                        style: TextStyle(
                            fontSize: 11, color: AdminTheme.textLight),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Status badge
            _buildStatusBadge(app.status, l10n),
            const SizedBox(width: 8),

            // View details button
            IconButton(
              onPressed: () => _navigateToDetail(context, app),
              icon: Icon(Icons.arrow_forward_ios,
                  size: 16, color: AdminTheme.textLight),
              tooltip: l10n.viewDetails,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ReviewStatus status, AppLocalizations l10n) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case ReviewStatus.pending:
      case ReviewStatus.underReview:
        bgColor = AdminTheme.warningAmber.withValues(alpha: 0.1);
        textColor = AdminTheme.warningAmber;
        label = l10n.pending;
      case ReviewStatus.approved:
        bgColor = AdminTheme.successGreen.withValues(alpha: 0.1);
        textColor = AdminTheme.successGreen;
        label = l10n.approvedLabel;
      case ReviewStatus.rejected:
        bgColor = AdminTheme.errorRed.withValues(alpha: 0.1);
        textColor = AdminTheme.errorRed;
        label = l10n.rejectedLabel;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, Application app) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<AdminApplicationCubit>(),
          child: AdminApplicationDetailView(applicationId: app.id),
        ),
      ),
    );
  }

  // ── Helper Filtering Methods ───────────────────────────────────────────────

  List<Application> _filterDriverBySearch(List<Application> apps) {
    if (_driverSearchQuery.isEmpty) return apps;
    final q = _driverSearchQuery.toLowerCase();
    return apps.where((a) {
      final name =
          (a.formData['personalInfo']?['name'] as String? ?? '').toLowerCase();
      final email =
          (a.formData['personalInfo']?['email'] as String? ?? '').toLowerCase();
      final phone =
          (a.formData['personalInfo']?['phone'] as String? ?? '').toLowerCase();
      return name.contains(q) || email.contains(q) || phone.contains(q);
    }).toList();
  }

  List<Application> _filterVendorBySearch(List<Application> apps) {
    if (_vendorSearchQuery.isEmpty) return apps;
    final q = _vendorSearchQuery.toLowerCase();
    return apps.where((a) {
      final name =
          (a.formData['businessInfo']?['restaurantName'] as String? ?? '')
              .toLowerCase();
      final email =
          (a.formData['contactInfo']?['email'] as String? ?? '').toLowerCase();
      final phone =
          (a.formData['contactInfo']?['phone'] as String? ?? '').toLowerCase();
      return name.contains(q) || email.contains(q) || phone.contains(q);
    }).toList();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
