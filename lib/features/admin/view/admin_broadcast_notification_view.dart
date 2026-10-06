import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/features/admin/model/admin_theme.dart';
import 'package:z_speed/features/admin/cubit/admin_broadcast_cubit.dart';
import 'package:z_speed/features/admin/cubit/admin_broadcast_state.dart';
import 'package:z_speed/components/map_location_picker.dart';
import 'package:latlong2/latlong.dart';

class AdminBroadcastNotificationView extends StatefulWidget {
  const AdminBroadcastNotificationView({super.key});

  @override
  State<AdminBroadcastNotificationView> createState() =>
      _AdminBroadcastNotificationViewState();
}

class _AdminBroadcastNotificationViewState
    extends State<AdminBroadcastNotificationView> {
  final _formKey = GlobalKey<FormState>();

  // Configuration Controllers & State
  String _selectedAudience = 'all'; // all, customer, driver, vendor, admin
  bool _enableAreaFilter = false;
  final _areaController = TextEditingController();

  bool _enableRadiusFilter = false;
  double _radiusKm = 10.0;
  final _latController = TextEditingController(text: '30.0444');
  final _lngController = TextEditingController(text: '31.2357');

  final _titleEnController = TextEditingController();
  final _bodyEnController = TextEditingController();
  final _titleArController = TextEditingController();
  final _bodyArController = TextEditingController();
  final _imageUrlController = TextEditingController();

  String _targetScreen =
      'none'; // none, promo_code, vendor, category, custom_url
  final _promoCodeController = TextEditingController();
  final _entityIdController = TextEditingController();
  final _targetUserIdController = TextEditingController();

  bool _sendPush = true;
  bool _storeInApp = true;
  String _priority = 'high'; // high, normal
  String _sound = 'default'; // default, alert, silent

  @override
  void dispose() {
    _areaController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _titleEnController.dispose();
    _bodyEnController.dispose();
    _titleArController.dispose();
    _bodyArController.dispose();
    _imageUrlController.dispose();
    _promoCodeController.dispose();
    _entityIdController.dispose();
    _targetUserIdController.dispose();
    super.dispose();
  }

  void _applyTemplate(String type) {
    setState(() {
      if (type == 'promo') {
        _titleEnController.text = 'Special Discount Code Available! 🎁';
        _bodyEnController.text =
            'Use code SAVE20 at checkout for 20% off your next order!';
        _titleArController.text = 'خصم خاص متاح الآن! 🎁';
        _bodyArController.text =
            'استخدم كود الخصم SAVE20 عند الدفع للحصول على خصم 20%! ';
        _targetScreen = 'promo_code';
        _promoCodeController.text = 'SAVE20';
      } else if (type == 'update') {
        _titleEnController.text = 'App Update & Maintenance Notice 🛠️';
        _bodyEnController.text =
            'We are improving ZSpeed! Expect smooth performance and new features.';
        _titleArController.text = 'إشعار تحديث وتحسين الخدمات 🛠️';
        _bodyArController.text =
            'نقوم بتطوير تطبيق ZSpeed لتقديم أفضل تجربة وأسرع خدمة لك!';
        _targetScreen = 'none';
      } else if (type == 'sale') {
        _titleEnController.text = 'Flash Sale - Limited Time Only! 🔥';
        _bodyEnController.text =
            'Don\'t miss out on special deals from top vendors near you!';
        _titleArController.text = 'عروض وخصومات خاطفة لفترة محدودة! 🔥';
        _bodyArController.text =
            'لا تفوت أقوى العروض والتخفيضات من أحدث المطاعم والمتاجر بالقرب منك!';
        _targetScreen = 'category';
      } else if (type == 'area') {
        _enableAreaFilter = true;
        _areaController.text = 'Cairo';
        _titleEnController.text = 'Special Offer for Cairo Residents! 📍';
        _bodyEnController.text =
            'Enjoy free delivery on select restaurants in your area today!';
        _titleArController.text = 'عرض خاص وسريع لسكان القاهرة! 📍';
        _bodyArController.text =
            'استمتع بتوصيل مجاني على مجموعة مختارة من المطاعم والمتاجر اليوم!';
      }
    });
  }

  Future<void> _pickLocationFromMap() async {
    final double? currentLat = double.tryParse(_latController.text);
    final double? currentLng = double.tryParse(_lngController.text);

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          showRadiusPicker: true,
          initialRadiusKm: _radiusKm,
          initialLocation: (currentLat != null && currentLng != null)
              ? LatLng(currentLat, currentLng)
              : null,
          initialAddress: _areaController.text.isNotEmpty
              ? _areaController.text
              : null,
        ),
      ),
    );

    if (result != null) {
      final double? lat = result['lat'] as double?;
      final double? lng = result['lng'] as double?;
      final double? rad = (result['radiusKm'] as num?)?.toDouble();
      final String? address = result['address'] as String?;

      setState(() {
        _enableAreaFilter = true;
        _enableRadiusFilter = true;
        if (rad != null && rad > 0) {
          _radiusKm = rad;
        }
        if (lat != null && lng != null) {
          _latController.text = lat.toStringAsFixed(6);
          _lngController.text = lng.toStringAsFixed(6);
        }
        if (address != null && address.isNotEmpty) {
          _areaController.text = address;
        }
      });
    }
  }

  void _submitBroadcast() {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.campaign, color: AdminTheme.primaryOrange, size: 28),
            const SizedBox(width: 10),
            Expanded(child: Text(l10n.confirmBroadcastTitle)),
          ],
        ),
        content: Text(l10n.confirmBroadcastBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              MaterialLocalizations.of(context).cancelButtonLabel,
              style: TextStyle(color: AdminTheme.textMedium),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.primaryOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.send_rounded, size: 18),
            label: Text(l10n.sendBroadcastButton),
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<AdminBroadcastCubit>().sendBroadcast(
                targetAudience: _selectedAudience,
                targetUserId: _selectedAudience == 'specific_user'
                    ? _targetUserIdController.text.trim()
                    : null,
                targetArea: _enableAreaFilter
                    ? _areaController.text.trim()
                    : null,
                centerLat: _enableRadiusFilter
                    ? double.tryParse(_latController.text)
                    : null,
                centerLng: _enableRadiusFilter
                    ? double.tryParse(_lngController.text)
                    : null,
                radiusKm: _enableRadiusFilter ? _radiusKm : null,
                title: _titleEnController.text.trim(),
                body: _bodyEnController.text.trim(),
                titleAr: _titleArController.text.trim(),
                bodyAr: _bodyArController.text.trim(),
                imageUrl: _imageUrlController.text.trim(),
                targetScreen: _targetScreen,
                promoCode: _promoCodeController.text.trim(),
                targetEntityId: _entityIdController.text.trim(),
                sendPush: _sendPush,
                storeInApp: _storeInApp,
                priority: _priority,
                sound: _sound,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return BlocConsumer<AdminBroadcastCubit, AdminBroadcastState>(
      listener: (context, state) {
        if (state is AdminBroadcastSuccess) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AdminTheme.successGreen,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(l10n.broadcastSuccessTitle)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.people, color: AdminTheme.infoBlue),
                    title: Text(
                      l10n.targetedUsersCount(
                        state.targetedUsersCount.toString(),
                      ),
                    ),
                  ),
                  ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.notifications_active,
                      color: AdminTheme.primaryOrange,
                    ),
                    title: Text(
                      l10n.pushDeliveredCount(state.pushSentCount.toString()),
                    ),
                  ),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.inbox, color: Colors.teal),
                    title: Text(
                      l10n.inAppSavedCount(state.inAppStoredCount.toString()),
                    ),
                  ),
                  if (state.pushFailedCount > 0)
                    ListTile(
                      dense: true,
                      leading: Icon(Icons.error, color: AdminTheme.errorRed),
                      title: Text(
                        l10n.pushFailedCount(state.pushFailedCount.toString()),
                      ),
                    ),
                ],
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.primaryOrange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.read<AdminBroadcastCubit>().reset();
                  },
                  child: Text(MaterialLocalizations.of(context).okButtonLabel),
                ),
              ],
            ),
          );
        } else if (state is AdminBroadcastFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.errorMessage}'),
              backgroundColor: AdminTheme.errorRed,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AdminBroadcastLoading;
        final isAr = Localizations.localeOf(context).languageCode == 'ar';

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 650;

            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 14.0 : 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Banner Card with Z_Speed Brand Gradient
                    Container(
                      padding: EdgeInsets.all(isMobile ? 16 : 22),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AdminTheme.primaryOrange,
                            AdminTheme.primaryDark,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AdminTheme.primaryOrange.withValues(
                              alpha: 0.25,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.campaign_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.broadcastTabTitle,
                                  style:
                                      (isMobile
                                              ? theme.textTheme.titleLarge
                                              : theme.textTheme.headlineSmall)
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.broadcastTabSubtitle,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Quick Templates Header
                    Text(
                      l10n.presetTemplates,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AdminTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildTemplateChip(
                            icon: Icons.local_offer_rounded,
                            label: l10n.templatePromoCode,
                            onTap: () => _applyTemplate('promo'),
                          ),
                          const SizedBox(width: 8),
                          _buildTemplateChip(
                            icon: Icons.build_circle_rounded,
                            label: l10n.templateSystemUpdate,
                            onTap: () => _applyTemplate('update'),
                          ),
                          const SizedBox(width: 8),
                          _buildTemplateChip(
                            icon: Icons.flash_on_rounded,
                            label: l10n.templateFlashSale,
                            onTap: () => _applyTemplate('sale'),
                          ),
                          const SizedBox(width: 8),
                          _buildTemplateChip(
                            icon: Icons.location_on_rounded,
                            label: l10n.templateAreaAlert,
                            onTap: () => _applyTemplate('area'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Section 1: Target Audience (Responsive Wrap instead of SegmentedButton)
                    _buildCardSection(
                      title: l10n.targetAudienceLabel,
                      icon: Icons.groups_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildAudienceChip(
                                value: 'all',
                                label: l10n.targetAllUsers,
                                icon: Icons.public,
                              ),
                              _buildAudienceChip(
                                value: 'customer',
                                label: l10n.targetCustomers,
                                icon: Icons.person_outline,
                              ),
                              _buildAudienceChip(
                                value: 'driver',
                                label: l10n.targetDrivers,
                                icon: Icons.directions_car_outlined,
                              ),
                              _buildAudienceChip(
                                value: 'vendor',
                                label: l10n.targetVendors,
                                icon: Icons.store_outlined,
                              ),
                              _buildAudienceChip(
                                value: 'admin',
                                label: l10n.targetAdmins,
                                icon: Icons.shield_outlined,
                              ),
                              _buildAudienceChip(
                                value: 'specific_user',
                                label: l10n.audienceSpecificUser,
                                icon: Icons.person_search_rounded,
                              ),
                            ],
                          ),
                          if (_selectedAudience == 'specific_user') ...[
                            const SizedBox(height: 14),
                            _UserSearchDropdownInput(
                              selectedUserId: _targetUserIdController.text,
                              onChanged: (user) {
                                setState(() {
                                  _targetUserIdController.text = user?.id ?? '';
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Section 2: Location & Area Filter
                    _buildCardSection(
                      title: l10n.locationAreaLabel,
                      icon: Icons.map_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              l10n.specificArea,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              _enableAreaFilter
                                  ? (isAr
                                        ? 'تم تفعيل التغطية الجغرافية المستهدفة'
                                        : 'Targeted geo-radius coverage enabled')
                                  : l10n.allLocations,
                              style: TextStyle(
                                color: _enableAreaFilter
                                    ? AdminTheme.primaryOrange
                                    : AdminTheme.textMedium,
                                fontSize: 13,
                              ),
                            ),
                            activeThumbColor: AdminTheme.primaryOrange,
                            value: _enableAreaFilter,
                            onChanged: (val) {
                              setState(() {
                                _enableAreaFilter = val;
                                _enableRadiusFilter = val;
                              });
                            },
                          ),
                          if (_enableAreaFilter) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AdminTheme.primaryOrange.withValues(
                                  alpha: 0.04,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AdminTheme.primaryOrange.withValues(
                                    alpha: 0.2,
                                  ),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AdminTheme.primaryOrange
                                              .withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.location_on_rounded,
                                          color: AdminTheme.primaryOrange,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _areaController.text.isNotEmpty
                                                  ? _areaController.text
                                                  : (isAr
                                                        ? 'لم يتم تحديد موقع بعد'
                                                        : 'No Location Selected Yet'),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AdminTheme.textDark,
                                                fontSize: 16,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '(${double.tryParse(_latController.text)?.toStringAsFixed(4) ?? '30.0444'}, ${double.tryParse(_lngController.text)?.toStringAsFixed(4) ?? '31.2357'})',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AdminTheme.textMedium,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AdminTheme.primaryOrange,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          isAr
                                              ? '${_radiusKm.toStringAsFixed(0)} كم'
                                              : '${_radiusKm.toStringAsFixed(0)} km',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AdminTheme.primaryOrange,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      icon: const Icon(
                                        Icons.map_rounded,
                                        size: 20,
                                      ),
                                      label: Text(
                                        l10n.selectTargetAreaMap,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      onPressed: _pickLocationFromMap,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Section 3: Notification Content (Bilingual)
                    _buildCardSection(
                      title: l10n.notificationContent,
                      icon: Icons.article_outlined,
                      child: Column(
                        children: [
                          _buildResponsiveRow(
                            isMobile: isMobile,
                            first: TextFormField(
                              controller: _titleEnController,
                              validator: (val) => val == null || val.isEmpty
                                  ? 'English title is required'
                                  : null,
                              decoration: InputDecoration(
                                labelText: l10n.notificationTitleEn,
                                prefixIcon: const Icon(Icons.language),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            second: TextFormField(
                              controller: _titleArController,
                              textDirection: TextDirection.rtl,
                              decoration: InputDecoration(
                                labelText: l10n.notificationTitleAr,
                                prefixIcon: const Icon(Icons.translate),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildResponsiveRow(
                            isMobile: isMobile,
                            first: TextFormField(
                              controller: _bodyEnController,
                              maxLines: 3,
                              validator: (val) => val == null || val.isEmpty
                                  ? 'English message body is required'
                                  : null,
                              decoration: InputDecoration(
                                labelText: l10n.notificationBodyEn,
                                alignLabelWithHint: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            second: TextFormField(
                              controller: _bodyArController,
                              maxLines: 3,
                              textDirection: TextDirection.rtl,
                              decoration: InputDecoration(
                                labelText: l10n.notificationBodyAr,
                                alignLabelWithHint: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _imageUrlController,
                            decoration: InputDecoration(
                              labelText: l10n.imageUrlLabel,
                              prefixIcon: const Icon(Icons.image_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Section 4: Target Screen & Payload
                    _buildCardSection(
                      title: l10n.targetScreenLabel,
                      icon: Icons.touch_app_outlined,
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _targetScreen,
                            decoration: InputDecoration(
                              labelText: l10n.targetScreenLabel,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'none',
                                child: Text(l10n.screenNone),
                              ),
                              DropdownMenuItem(
                                value: 'promo_code',
                                child: Text(l10n.screenPromo),
                              ),
                              DropdownMenuItem(
                                value: 'vendor',
                                child: Text(l10n.screenVendor),
                              ),
                              DropdownMenuItem(
                                value: 'category',
                                child: Text(l10n.screenCategory),
                              ),
                              DropdownMenuItem(
                                value: 'custom_url',
                                child: Text(l10n.screenCustomUrl),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _targetScreen = val;
                                });
                              }
                            },
                          ),
                          if (_targetScreen == 'promo_code') ...[
                            const SizedBox(height: 16),
                            _PromoCodeSearchDropdownInput(
                              selectedCode: _promoCodeController.text,
                              onChanged: (code) {
                                setState(() {
                                  _promoCodeController.text = code ?? '';
                                });
                              },
                            ),
                          ],
                          if (_targetScreen == 'vendor') ...[
                            const SizedBox(height: 16),
                            _VendorSearchDropdownInput(
                              selectedVendorId: _entityIdController.text,
                              onChanged: (vendor) {
                                setState(() {
                                  _entityIdController.text = vendor?.id ?? '';
                                });
                              },
                            ),
                          ] else if (_targetScreen == 'category' ||
                              _targetScreen == 'custom_url') ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _entityIdController,
                              decoration: InputDecoration(
                                labelText: _targetScreen == 'category'
                                    ? 'Category Name / ID'
                                    : l10n.targetEntityIdLabel,
                                prefixIcon: const Icon(Icons.link),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Section 5: Delivery & Priority Settings
                    _buildCardSection(
                      title: l10n.deliveryConfigLabel,
                      icon: Icons.tune_outlined,
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              l10n.sendFcmPush,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            activeThumbColor: AdminTheme.primaryOrange,
                            value: _sendPush,
                            onChanged: (val) => setState(() => _sendPush = val),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              l10n.storeInAppInbox,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            activeThumbColor: AdminTheme.primaryOrange,
                            value: _storeInApp,
                            onChanged: (val) =>
                                setState(() => _storeInApp = val),
                          ),
                          const SizedBox(height: 12),
                          _buildResponsiveRow(
                            isMobile: isMobile,
                            first: DropdownButtonFormField<String>(
                              initialValue: _priority,
                              decoration: InputDecoration(
                                labelText: l10n.priorityLabel,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'high',
                                  child: Text(l10n.priorityHigh),
                                ),
                                DropdownMenuItem(
                                  value: 'normal',
                                  child: Text(l10n.priorityNormal),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _priority = val);
                                }
                              },
                            ),
                            second: DropdownButtonFormField<String>(
                              initialValue: _sound,
                              decoration: InputDecoration(
                                labelText: l10n.soundLabel,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'default',
                                  child: Text(l10n.soundDefault),
                                ),
                                DropdownMenuItem(
                                  value: 'alert',
                                  child: Text(l10n.soundAlert),
                                ),
                                DropdownMenuItem(
                                  value: 'silent',
                                  child: Text(l10n.soundSilent),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _sound = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Lockscreen Live Preview
                    Text(
                      l10n.previewHeader,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AdminTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AdminTheme.primaryOrange.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AdminTheme.primaryOrange,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_active_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAr
                                      ? (_titleArController.text.isNotEmpty
                                          ? _titleArController.text
                                          : (_titleEnController.text.isNotEmpty
                                              ? _titleEnController.text
                                              : 'معاينة عنوان الإشعار'))
                                      : (_titleEnController.text.isNotEmpty
                                          ? _titleEnController.text
                                          : (_titleArController.text.isNotEmpty
                                              ? _titleArController.text
                                              : 'Notification Title Preview')),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  isAr
                                      ? (_bodyArController.text.isNotEmpty
                                          ? _bodyArController.text
                                          : (_bodyEnController.text.isNotEmpty
                                              ? _bodyEnController.text
                                              : 'معاينة محتوى الإشعار ستظهر هنا...'))
                                      : (_bodyEnController.text.isNotEmpty
                                          ? _bodyEnController.text
                                          : (_bodyArController.text.isNotEmpty
                                              ? _bodyArController.text
                                              : 'Notification body content preview will appear here...')),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminTheme.primaryOrange,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(
                          isLoading ? 'Sending...' : l10n.sendBroadcastButton,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: isLoading ? null : _submitBroadcast,
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAudienceChip({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedAudience == value;
    return ChoiceChip(
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? Colors.white : AdminTheme.primaryOrange,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AdminTheme.textDark,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: AdminTheme.primaryOrange,
      backgroundColor: AdminTheme.contentBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AdminTheme.primaryOrange : AdminTheme.borderColor,
        ),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedAudience = value;
          });
        }
      },
    );
  }

  Widget _buildTemplateChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AdminTheme.primaryOrange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AdminTheme.primaryOrange.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AdminTheme.primaryOrange),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: AdminTheme.primaryOrange,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveRow({
    required bool isMobile,
    required Widget first,
    required Widget second,
  }) {
    if (isMobile) {
      return Column(children: [first, const SizedBox(height: 16), second]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: 16),
        Expanded(child: second),
      ],
    );
  }

  Widget _buildCardSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: AdminTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AdminTheme.primaryOrange, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AdminTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ── User Search Dropdown Input ─────────────────────────────────────────────

class _UserOption {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String type;

  const _UserOption({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.type,
  });

  factory _UserOption.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return _UserOption(
      id: doc.id,
      name: (data['name'] as String?) ??
          (data['displayName'] as String?) ??
          'User',
      email: (data['email'] as String?) ?? '',
      phone:
          (data['phone'] as String?) ?? (data['phoneNumber'] as String?) ?? '',
      type: (data['type'] as String?) ?? 'user',
    );
  }
}

class _UserSearchDropdownInput extends StatelessWidget {
  const _UserSearchDropdownInput({
    required this.selectedUserId,
    required this.onChanged,
  });

  final String selectedUserId;
  final ValueChanged<_UserOption?> onChanged;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedUserId.trim().isNotEmpty;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        final users = (snapshot.data?.docs ?? [])
            .map((doc) => _UserOption.fromFirestore(doc))
            .toList();

        final selectedUser = hasSelection
            ? users.firstWhere(
                (u) => u.id == selectedUserId,
                orElse: () => _UserOption(
                  id: selectedUserId,
                  name: 'UID: $selectedUserId',
                  email: '',
                  phone: '',
                  type: 'user',
                ),
              )
            : null;

        return InkWell(
          onTap: () => _showSearchModal(context, users),
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Target Specific User *',
              hintText: 'Search and select target user...',
              prefixIcon: Icon(
                Icons.person_pin_rounded,
                color: AdminTheme.primaryOrange,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasSelection)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      tooltip: 'Clear selection',
                      onPressed: () => onChanged(null),
                    ),
                  const Icon(Icons.arrow_drop_down),
                  const SizedBox(width: 8),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              hasSelection
                  ? '${selectedUser?.name} (${selectedUser?.email.isNotEmpty == true ? selectedUser!.email : selectedUser?.id})'
                  : 'Tap to search & select user by name, email, phone or UID...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: hasSelection ? FontWeight.w600 : FontWeight.w400,
                color: hasSelection ? AdminTheme.textDark : AdminTheme.textMedium,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }

  void _showSearchModal(BuildContext context, List<_UserOption> users) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _UserSearchDialog(
        users: users,
        selectedUserId: selectedUserId,
        onSelected: (user) {
          onChanged(user);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }
}

class _UserSearchDialog extends StatefulWidget {
  const _UserSearchDialog({
    required this.users,
    required this.selectedUserId,
    required this.onSelected,
  });

  final List<_UserOption> users;
  final String selectedUserId;
  final ValueChanged<_UserOption?> onSelected;

  @override
  State<_UserSearchDialog> createState() => _UserSearchDialogState();
}

class _UserSearchDialogState extends State<_UserSearchDialog> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.users.where((u) {
      if (_query.trim().isEmpty) return true;
      final q = _query.toLowerCase();
      return u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.phone.toLowerCase().contains(q) ||
          u.id.toLowerCase().contains(q);
    }).toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Select Target User',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 460,
        height: 480,
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search user by name, email, phone or UID...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No users found matching "$_query"',
                        style: TextStyle(color: AdminTheme.textMedium),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final u = filtered[i];
                        final isSelected = widget.selectedUserId == u.id;

                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          tileColor: isSelected
                              ? AdminTheme.primaryOrange.withValues(alpha: 0.1)
                              : null,
                          leading: CircleAvatar(
                            backgroundColor: AdminTheme.primaryOrange
                                .withValues(alpha: 0.1),
                            child: Icon(Icons.person,
                                color: AdminTheme.primaryOrange, size: 20),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  u.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  u.type.toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            u.email.isNotEmpty
                                ? u.email
                                : (u.phone.isNotEmpty
                                    ? u.phone
                                    : 'UID: ${u.id}'),
                            style: TextStyle(
                                fontSize: 11, color: AdminTheme.textMedium),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle,
                                  color: AdminTheme.primaryOrange, size: 20)
                              : null,
                          onTap: () => widget.onSelected(u),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

// ── Vendor Search Dropdown Input ───────────────────────────────────────────

class _VendorOptionBroadcast {
  final String id;
  final String name;
  final String? nameAr;
  final String? logoUrl;

  const _VendorOptionBroadcast({
    required this.id,
    required this.name,
    this.nameAr,
    this.logoUrl,
  });

  factory _VendorOptionBroadcast.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return _VendorOptionBroadcast(
      id: doc.id,
      name: (data['name'] as String?) ??
          (data['restaurantName'] as String?) ??
          doc.id,
      nameAr: data['nameAr'] as String?,
      logoUrl:
          (data['logoUrl'] as String?) ?? (data['coverImageUrl'] as String?),
    );
  }
}

class _VendorSearchDropdownInput extends StatelessWidget {
  const _VendorSearchDropdownInput({
    required this.selectedVendorId,
    required this.onChanged,
  });

  final String selectedVendorId;
  final ValueChanged<_VendorOptionBroadcast?> onChanged;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedVendorId.trim().isNotEmpty;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('vendors').snapshots(),
      builder: (context, snapshot) {
        final vendors = (snapshot.data?.docs ?? [])
            .map((doc) => _VendorOptionBroadcast.fromFirestore(doc))
            .toList();

        final selectedVendor = hasSelection
            ? vendors.firstWhere(
                (v) => v.id == selectedVendorId,
                orElse: () => _VendorOptionBroadcast(
                  id: selectedVendorId,
                  name: 'Vendor ID: $selectedVendorId',
                ),
              )
            : null;

        return InkWell(
          onTap: () => _showSearchModal(context, vendors),
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Target Vendor / Restaurant *',
              hintText: 'Search & select a vendor...',
              prefixIcon: Icon(
                Icons.storefront_outlined,
                color: AdminTheme.primaryOrange,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasSelection)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      tooltip: 'Clear vendor',
                      onPressed: () => onChanged(null),
                    ),
                  const Icon(Icons.arrow_drop_down),
                  const SizedBox(width: 8),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              hasSelection
                  ? '${selectedVendor?.name} (ID: ${selectedVendor?.id})'
                  : 'Tap to search & select target vendor...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: hasSelection ? FontWeight.w600 : FontWeight.w400,
                color: hasSelection ? AdminTheme.textDark : AdminTheme.textMedium,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }

  void _showSearchModal(
      BuildContext context, List<_VendorOptionBroadcast> vendors) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _VendorSearchDialogBroadcast(
        vendors: vendors,
        selectedVendorId: selectedVendorId,
        onSelected: (vendor) {
          onChanged(vendor);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }
}

class _VendorSearchDialogBroadcast extends StatefulWidget {
  const _VendorSearchDialogBroadcast({
    required this.vendors,
    required this.selectedVendorId,
    required this.onSelected,
  });

  final List<_VendorOptionBroadcast> vendors;
  final String selectedVendorId;
  final ValueChanged<_VendorOptionBroadcast?> onSelected;

  @override
  State<_VendorSearchDialogBroadcast> createState() =>
      _VendorSearchDialogBroadcastState();
}

class _VendorSearchDialogBroadcastState
    extends State<_VendorSearchDialogBroadcast> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.vendors.where((v) {
      if (_query.trim().isEmpty) return true;
      final q = _query.toLowerCase();
      return v.name.toLowerCase().contains(q) ||
          (v.nameAr != null && v.nameAr!.toLowerCase().contains(q)) ||
          v.id.toLowerCase().contains(q);
    }).toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Select Target Vendor',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        height: 480,
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search by vendor name, Arabic name, or ID...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No vendors found matching "$_query"',
                        style: TextStyle(color: AdminTheme.textMedium),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final v = filtered[i];
                        final isSelected = widget.selectedVendorId == v.id;

                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          tileColor: isSelected
                              ? AdminTheme.primaryOrange.withValues(alpha: 0.1)
                              : null,
                          leading: CircleAvatar(
                            backgroundColor: AdminTheme.primaryOrange
                                .withValues(alpha: 0.1),
                            backgroundImage:
                                v.logoUrl != null && v.logoUrl!.isNotEmpty
                                    ? NetworkImage(v.logoUrl!)
                                    : null,
                            child: v.logoUrl == null || v.logoUrl!.isEmpty
                                ? Icon(Icons.storefront,
                                    color: AdminTheme.primaryOrange, size: 20)
                                : null,
                          ),
                          title: Text(
                            v.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          subtitle: Text(
                            'ID: ${v.id}${v.nameAr != null && v.nameAr!.isNotEmpty ? " • ${v.nameAr}" : ""}',
                            style: TextStyle(
                                fontSize: 11, color: AdminTheme.textMedium),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle,
                                  color: AdminTheme.primaryOrange, size: 20)
                              : null,
                          onTap: () => widget.onSelected(v),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

// ── Promo Code Search Dropdown Input ───────────────────────────────────────

class _PromoCodeOptionBroadcast {
  final String id;
  final String code;
  final String type;

  const _PromoCodeOptionBroadcast({
    required this.id,
    required this.code,
    required this.type,
  });

  factory _PromoCodeOptionBroadcast.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return _PromoCodeOptionBroadcast(
      id: doc.id,
      code: (data['code'] as String?) ?? doc.id,
      type: (data['type'] as String?) ?? 'percentage',
    );
  }
}

class _PromoCodeSearchDropdownInput extends StatelessWidget {
  const _PromoCodeSearchDropdownInput({
    required this.selectedCode,
    required this.onChanged,
  });

  final String selectedCode;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedCode.trim().isNotEmpty;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('promoCodes').snapshots(),
      builder: (context, snapshot) {
        final promos = (snapshot.data?.docs ?? [])
            .map((doc) => _PromoCodeOptionBroadcast.fromFirestore(doc))
            .toList();

        return InkWell(
          onTap: () => _showSearchModal(context, promos),
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Attached Promo Code',
              hintText: 'Search & select a promo code...',
              prefixIcon: Icon(
                Icons.confirmation_number,
                color: AdminTheme.primaryOrange,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasSelection)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      tooltip: 'Clear promo code',
                      onPressed: () => onChanged(null),
                    ),
                  const Icon(Icons.arrow_drop_down),
                  const SizedBox(width: 8),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              hasSelection
                  ? 'Promo Code: $selectedCode'
                  : 'Tap to search & select promo code...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: hasSelection ? FontWeight.w600 : FontWeight.w400,
                color: hasSelection ? AdminTheme.textDark : AdminTheme.textMedium,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }

  void _showSearchModal(
      BuildContext context, List<_PromoCodeOptionBroadcast> promos) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _PromoCodeSearchDialog(
        promos: promos,
        selectedCode: selectedCode,
        onSelected: (code) {
          onChanged(code);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }
}

class _PromoCodeSearchDialog extends StatefulWidget {
  const _PromoCodeSearchDialog({
    required this.promos,
    required this.selectedCode,
    required this.onSelected,
  });

  final List<_PromoCodeOptionBroadcast> promos;
  final String selectedCode;
  final ValueChanged<String?> onSelected;

  @override
  State<_PromoCodeSearchDialog> createState() => _PromoCodeSearchDialogState();
}

class _PromoCodeSearchDialogState extends State<_PromoCodeSearchDialog> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.promos.where((p) {
      if (_query.trim().isEmpty) return true;
      final q = _query.toLowerCase();
      return p.code.toLowerCase().contains(q) || p.type.toLowerCase().contains(q);
    }).toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Select Promo Code',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        height: 480,
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search promo code...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No promo codes match "$_query"',
                        style: TextStyle(color: AdminTheme.textMedium),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final p = filtered[i];
                        final isSelected = widget.selectedCode == p.code;

                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          tileColor: isSelected
                              ? AdminTheme.primaryOrange.withValues(alpha: 0.1)
                              : null,
                          leading: CircleAvatar(
                            backgroundColor: AdminTheme.primaryOrange
                                .withValues(alpha: 0.1),
                            child: Icon(Icons.local_offer,
                                color: AdminTheme.primaryOrange, size: 20),
                          ),
                          title: Text(
                            p.code,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            'Type: ${p.type}',
                            style: TextStyle(
                                fontSize: 11, color: AdminTheme.textMedium),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle,
                                  color: AdminTheme.primaryOrange, size: 20)
                              : null,
                          onTap: () => widget.onSelected(p.code),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
