import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/components/map_location_picker.dart';
import 'package:z_speed/features/restaurant/model/restaurant.dart';
import 'package:z_speed/features/restaurant/repository/restaurant_menu_repository_impl.dart';
import 'package:z_speed/features/restaurant_owner/view/restaurant_settings_dialogs.dart';
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_profile_cubit.dart';
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_profile_state.dart';
import 'package:z_speed/features/restaurant_owner/screens/delivery_fee_settings_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:z_speed/core/utils/image_utils.dart';
import 'package:intl/intl.dart';

/// Full restaurant profile page showing ALL data from the signup process.
/// Allows editing via tap-to-edit fields and logo/cover image upload.
class RestaurantProfilePage extends StatelessWidget {
  const RestaurantProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ownerId = FirebaseAuth.instance.currentUser?.uid;
    if (ownerId == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.notAuthenticatedTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.pleaseLogInToViewProfile,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return BlocProvider<RestaurantProfileCubit>(
      create: (_) => RestaurantProfileCubit(
        repository: RestaurantMenuRepositoryImpl(),
        ownerId: ownerId,
      ),
      child: const _ProfileContent(),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RestaurantProfileCubit, RestaurantProfileState>(
      builder: (context, state) {
        if (state.isLoading && state.restaurant == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.error != null && state.restaurant == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(state.error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: context.read<RestaurantProfileCubit>().init,
                  child: Text(AppLocalizations.of(context)!.retry),
                ),
              ],
            ),
          );
        }

        if (!state.hasRestaurant) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF35535).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.store_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.noRestaurantProfileYet,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.createRestaurantFromDashboard,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    icon: const Icon(Icons.restaurant),
                    label: Text(AppLocalizations.of(context)!.goToDashboard),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF35535),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return _ProfileBody(
          cubit: context.read<RestaurantProfileCubit>(),
          state: state,
        );
      },
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final RestaurantProfileCubit cubit;
  final RestaurantProfileState state;
  const _ProfileBody({required this.cubit, required this.state});

  void _showSuccess(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = state.restaurant!;

    return RefreshIndicator(
      onRefresh: () => cubit.init(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Hero header with cover + logo ──
          _CoverAndLogo(restaurant: r, cubit: cubit, state: state),
          const SizedBox(height: 20),

          // ── Open/Closed toggle ──
          _StatusToggle(restaurant: r, cubit: cubit),
          const SizedBox(height: 20),

          // ── Business Information ──
          _SectionCard(
            title: AppLocalizations.of(context)!.businessInformation,
            icon: Icons.business,
            children: [
              _EditableField(
                label: AppLocalizations.of(context)!.restaurantName,
                value: r.name,
                icon: Icons.restaurant,
                onEdit: () => _editField(
                  context,
                  AppLocalizations.of(context)!.restaurantName,
                  r.name,
                  (v) => cubit.updateField('name', v),
                ),
              ),
              if (r.nameAr != null && r.nameAr!.isNotEmpty)
                _EditableField(
                  label: AppLocalizations.of(context)!.arabicName,
                  value: r.nameAr!,
                  icon: Icons.translate,
                  onEdit: () => _editField(
                    context,
                    AppLocalizations.of(context)!.arabicName,
                    r.nameAr!,
                    (v) => cubit.updateField('nameAr', v),
                  ),
                ),
              _EditableField(
                label: AppLocalizations.of(context)!.description,
                value: r.description.isEmpty
                    ? AppLocalizations.of(context)!.notSet
                    : r.description,
                icon: Icons.description,
                onEdit: () => _editField(
                  context,
                  AppLocalizations.of(context)!.description,
                  r.description,
                  (v) => cubit.updateField('description', v),
                ),
              ),
              _EditableField(
                label: AppLocalizations.of(context)!.cuisineTypes,
                value: r.cuisineTypes.isEmpty
                    ? AppLocalizations.of(context)!.notSet
                    : r.cuisineTypes.join(', '),
                icon: Icons.local_dining,
                onEdit: () => _editCuisines(context),
              ),
              _EditableField(
                label: AppLocalizations.of(context)!.phone,
                value: r.phone.isEmpty
                    ? AppLocalizations.of(context)!.notSet
                    : r.phone,
                icon: Icons.phone,
                onEdit: () => _editField(
                  context,
                  AppLocalizations.of(context)!.phone,
                  r.phone,
                  (v) => cubit.updateField('phone', v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Location ──
          _SectionCard(
            title: AppLocalizations.of(context)!.location,
            icon: Icons.location_on,
            children: [
              _EditableField(
                label: AppLocalizations.of(context)!.address,
                value: r.address.isEmpty
                    ? AppLocalizations.of(context)!.notSet
                    : r.address,
                icon: Icons.map,
                onEdit: () => _editField(
                  context,
                  AppLocalizations.of(context)!.address,
                  r.address,
                  (v) => cubit.updateField('address', v),
                ),
              ),
              _LocationField(
                label: AppLocalizations.of(context)!.coordinates,
                value: r.latitude != 0 && r.longitude != 0
                    ? '${r.latitude.toStringAsFixed(5)}, ${r.longitude.toStringAsFixed(5)}'
                    : AppLocalizations.of(context)!.notSet,
                icon: Icons.gps_fixed,
                isSaving: state.isSaving,
                onUpdate: () => cubit.updateLocation(context),
                onPickOnMap: () async {
                  final result = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapLocationPicker(
                        initialLocation: r.latitude != 0 && r.longitude != 0
                            ? null
                            : null,
                      ),
                    ),
                  );
                  if (result != null) {
                    final lat = result['lat'] as double;
                    final lng = result['lng'] as double;
                    final address = result['address'] as String;
                    await cubit.updateLocationFromMap(
                      lat,
                      lng,
                      address: address,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(
                              context,
                            )!.locationUpdatedFromMap,
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Delivery Settings ──
          _SectionCard(
            title: AppLocalizations.of(context)!.deliverySettings,
            icon: Icons.delivery_dining,
            onEdit: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(
                      title: Text(AppLocalizations.of(context)!.deliverySettings),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                    ),
                    body: DeliveryFeeSettingsScreen(
                      restaurant: r,
                      onSave: (updatedRestaurant) async {
                        await cubit.updateFields({
                          'deliveryFee': updatedRestaurant.deliveryFee,
                          'deliveryFeeMode': updatedRestaurant.deliveryFeeMode.name,
                          'deliveryFeeSubMode': updatedRestaurant.deliveryFeeSubMode?.name,
                          'deliveryFeeFormula': updatedRestaurant.deliveryFeeFormula,
                          'deliveryFeeTiers': updatedRestaurant.deliveryFeeTiers,
                          'deliveryRadiusKm': updatedRestaurant.deliveryRadiusKm,
                        });
                      },
                    ),
                  ),
                ),
              );
            },
            children: [
              _InfoField(
                label: AppLocalizations.of(context)!.deliveryFee,
                value: AppLocalizations.of(
                  context,
                )!.currencyEgp(r.deliveryFee.toStringAsFixed(2)),
                icon: Icons.attach_money,
              ),
              _InfoField(
                label: AppLocalizations.of(context)!.deliveryTime,
                value: AppLocalizations.of(
                  context,
                )!.deliveryTimeRange(r.deliveryTimeMin, r.deliveryTimeMax),
                icon: Icons.timer,
              ),
              _InfoField(
                label: AppLocalizations.of(context)!.minimumOrder,
                value: AppLocalizations.of(
                  context,
                )!.currencyEgp(r.minimumOrder.toStringAsFixed(2)),
                icon: Icons.shopping_bag,
              ),
              _InfoField(
                label: AppLocalizations.of(context)!.deliveryRadiusLabel,
                value: AppLocalizations.of(
                  context,
                )!.deliveryRadius(r.deliveryRadiusKm.toStringAsFixed(1)),
                icon: Icons.radar,
              ),
              _InfoField(
                label: AppLocalizations.of(context)!.feeMode,
                value: r.deliveryFeeMode.name.toUpperCase(),
                icon: Icons.tune,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Operating Hours ──
          _OperatingHoursCard(restaurant: r, cubit: cubit),
          const SizedBox(height: 16),

          // ── Ratings & Stats ──
          _SectionCard(
            title: AppLocalizations.of(context)!.ratingsAndStats,
            icon: Icons.star,
            children: [
              _InfoField(
                label: AppLocalizations.of(context)!.rating,
                value: r.rating > 0
                    ? '${r.rating.toStringAsFixed(1)} / 5.0'
                    : AppLocalizations.of(context)!.noRatingsYet,
                icon: Icons.star_rate,
              ),
              _InfoField(
                label: AppLocalizations.of(context)!.totalReviews,
                value: r.ratingCount.toString(),
                icon: Icons.rate_review,
              ),
              _InfoField(
                label: AppLocalizations.of(context)!.memberSince,
                value: DateFormat.yMMMd(
                  Localizations.localeOf(context).toString(),
                ).format(r.createdAt),
                icon: Icons.calendar_today,
              ),
              _InfoField(
                label: AppLocalizations.of(context)!.lastUpdated,
                value: DateFormat.yMMMd(
                  Localizations.localeOf(context).toString(),
                ).add_Hm().format(r.updatedAt),
                icon: Icons.update,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Branding Images ──
          _BrandingCard(restaurant: r, cubit: cubit, state: state),
          const SizedBox(height: 32),

          // ── Documents Section ──
          if (r.documentUrls.isNotEmpty) ...[
            _DocumentsSection(documentUrls: r.documentUrls),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  void _editField(
    BuildContext context,
    String label,
    String current,
    Future<void> Function(String) onSave,
  ) {
    showVendorEditDialog(
      context: context,
      label: label,
      currentValue: current,
      onSave: (newVal) async {
        try {
          await onSave(newVal);
          if (context.mounted) {
            _showSuccess(context, AppLocalizations.of(context)!.updated(label));
          }
        } catch (e) {
          if (context.mounted) {
            _showError(
              context,
              AppLocalizations.of(context)!.failedWithMessage(e.toString()),
            );
          }
        }
      },
      showSuccess: (msg) => _showSuccess(context, msg),
    );
  }

  void _editCuisines(BuildContext context) {
    if (state.isLoadingCuisines) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.loadingCuisines)),
      );
      return;
    }

    showCuisineTypesEditDialog(
      context: context,
      currentCuisines: state.restaurant!.cuisineTypes,
      availableCuisines: state.availableCuisines,
      onSave: (newVal) => cubit.updateField('cuisineTypes', newVal),
      showSuccess: (msg) => _showSuccess(context, msg),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Cover image + logo hero header
// ═══════════════════════════════════════════════════════════════════════════════

class _CoverAndLogo extends StatelessWidget {
  final Restaurant restaurant;
  final RestaurantProfileCubit cubit;
  final RestaurantProfileState state;
  const _CoverAndLogo({
    required this.restaurant,
    required this.cubit,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Cover image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey[300]),
                child: state.isUploadingCover
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: Color(0xFFF35535),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context)!.uploadingCover,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : restaurant.coverImageUrl.isNotEmpty
                    ? Image.network(
                        restaurant.coverImageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 160,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                        progress.expectedTotalBytes!
                                  : null,
                              color: const Color(0xFFF35535),
                            ),
                          );
                        },
                        errorBuilder: (_, _, _) => Center(
                          child: Icon(
                            Icons.image,
                            size: 48,
                            color: Colors.grey[500],
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.image,
                          size: 48,
                          color: Colors.grey[500],
                        ),
                      ),
              ),
            ),
          ),
          // Cover edit button
          PositionedDirectional(
            end: 12,
            top: 12,
            child: _CircleButton(
              icon: Icons.camera_alt,
              onTap: () => _uploadCover(context),
            ),
          ),
          // Logo overlay
          PositionedDirectional(
            top: 116, // (160 - 44) to center/overlap correctly
            start: 20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: state.isUploadingLogo
                  ? const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFF35535),
                        ),
                      ),
                    )
                  : restaurant.logoUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Image.network(
                        restaurant.logoUrl,
                        fit: BoxFit.cover,
                        width: 80,
                        height: 80,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFF35535),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, _, _) => Icon(
                          Icons.restaurant,
                          size: 36,
                          color: Colors.grey[400],
                        ),
                      ),
                    )
                  : Icon(Icons.restaurant, size: 36, color: Colors.grey[400]),
            ),
          ),
          // Logo edit button
          PositionedDirectional(
            top: 168,
            start: 72,
            child: _CircleButton(
              icon: Icons.edit,
              size: 28,
              iconSize: 14,
              onTap: () => _uploadLogo(context),
            ),
          ),
          // Name + address to the right of logo
          PositionedDirectional(
            top: 170,
            start: 110,
            end: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  restaurant.address,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _uploadCover(BuildContext context) async {
    final image = await ImageUtils.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await cubit.uploadCoverImage(image);
    }
  }

  void _uploadLogo(BuildContext context) async {
    final image = await ImageUtils.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await cubit.uploadLogo(image);
    }
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.size = 36,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFF35535),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Status toggle (open / closed)
// ═══════════════════════════════════════════════════════════════════════════════

class _StatusToggle extends StatelessWidget {
  final Restaurant restaurant;
  final RestaurantProfileCubit cubit;
  const _StatusToggle({required this.restaurant, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          restaurant.isOpen ? Icons.storefront : Icons.store,
          color: restaurant.isOpen ? const Color(0xFF4CAF50) : Colors.grey,
          size: 28,
        ),
        title: Text(
          restaurant.isOpen
              ? AppLocalizations.of(context)!.currentlyOpen
              : AppLocalizations.of(context)!.currentlyClosed,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: restaurant.isOpen
                ? const Color(0xFF4CAF50)
                : Colors.grey[700],
          ),
        ),
        subtitle: Text(
          restaurant.isOpen
              ? AppLocalizations.of(context)!.customersCanOrderFromRestaurant
              : AppLocalizations.of(context)!.restaurantNotAcceptingOrders,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: Switch(
          value: restaurant.isOpen,
          activeThumbColor: const Color(0xFF4CAF50),
          onChanged: (_) => cubit.toggleOpen(),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Section card container
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final VoidCallback? onEdit;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFFF35535), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    color: const Color(0xFFF35535),
                    onPressed: onEdit,
                  ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Editable field & read-only field
// ═══════════════════════════════════════════════════════════════════════════════

class _LocationField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isSaving;
  final VoidCallback onUpdate;
  final VoidCallback onPickOnMap;

  const _LocationField({
    required this.label,
    required this.value,
    required this.icon,
    required this.isSaving,
    required this.onUpdate,
    required this.onPickOnMap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[500]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: isSaving ? null : onUpdate,
                  icon: isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location, size: 14),
                  label: Text(
                    isSaving
                        ? AppLocalizations.of(context)!.wait
                        : AppLocalizations.of(context)!.gps,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF35535),
                    side: const BorderSide(color: Color(0xFFF35535)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  onPressed: isSaving ? null : onPickOnMap,
                  icon: const Icon(Icons.map_outlined, size: 14),
                  label: Text(AppLocalizations.of(context)!.map),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF35535),
                    side: const BorderSide(color: Color(0xFFF35535)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                    visualDensity: VisualDensity.compact,
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

class _EditableField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onEdit;

  const _EditableField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey[500]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.edit, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[500]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Operating hours card
// ═══════════════════════════════════════════════════════════════════════════════

class _OperatingHoursCard extends StatelessWidget {
  final Restaurant restaurant;
  final RestaurantProfileCubit cubit;
  const _OperatingHoursCard({required this.restaurant, required this.cubit});

  static const _dayOrderRaw = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String _localDay(BuildContext context, String day) {
    final l10n = AppLocalizations.of(context)!;
    switch (day) {
      case 'Monday':
        return l10n.monday;
      case 'Tuesday':
        return l10n.tuesday;
      case 'Wednesday':
        return l10n.wednesday;
      case 'Thursday':
        return l10n.thursday;
      case 'Friday':
        return l10n.friday;
      case 'Saturday':
        return l10n.saturday;
      case 'Sunday':
        return l10n.sunday;
      default:
        return day;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hours = restaurant.workingHours;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: Color(0xFFF35535), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.operatingHours,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  color: const Color(0xFFF35535),
                  tooltip: AppLocalizations.of(context)!.editOperatingHours,
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _OperatingHoursEditSheet(
                      restaurant: restaurant,
                      cubit: cubit,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (hours.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context)!.noHoursSet,
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              )
            else
              ..._dayOrderRaw.where((d) => hours.containsKey(d)).map((day) {
                final wh = hours[day]!;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          _localDay(context, day),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          wh.isClosed
                              ? AppLocalizations.of(context)!.statusClosed
                              : AppLocalizations.of(
                                  context,
                                )!.timeRange(wh.open, wh.close),
                          style: TextStyle(
                            fontSize: 14,
                            color: wh.isClosed
                                ? Colors.red[400]
                                : Colors.grey[700],
                          ),
                        ),
                      ),
                      if (!wh.isClosed)
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green[400],
                        )
                      else
                        Icon(Icons.cancel, size: 16, color: Colors.red[300]),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Branding card (logo + cover image preview)
// ═══════════════════════════════════════════════════════════════════════════════

class _BrandingCard extends StatelessWidget {
  final Restaurant restaurant;
  final RestaurantProfileCubit cubit;
  final RestaurantProfileState state;
  const _BrandingCard({
    required this.restaurant,
    required this.cubit,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.palette, color: Color(0xFFF35535), size: 22),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.branding,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Logo
            _ImageTile(
              label: AppLocalizations.of(context)!.restaurantLogo,
              imageUrl: restaurant.logoUrl,
              placeholder: Icons.restaurant,
              isUploading: state.isUploadingLogo,
              onUpload: () async {
                final img = await ImageUtils.pickImage(
                  source: ImageSource.gallery,
                );
                if (img != null) await cubit.uploadLogo(img);
              },
            ),
            const SizedBox(height: 12),
            // Cover
            _ImageTile(
              label: AppLocalizations.of(context)!.coverImage,
              imageUrl: restaurant.coverImageUrl,
              placeholder: Icons.image,
              aspectRatio: 16 / 9,
              isUploading: state.isUploadingCover,
              onUpload: () async {
                final img = await ImageUtils.pickImage(
                  source: ImageSource.gallery,
                );
                if (img != null) await cubit.uploadCoverImage(img);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  final String label;
  final String imageUrl;
  final IconData placeholder;
  final double aspectRatio;
  final bool isUploading;
  final VoidCallback onUpload;

  const _ImageTile({
    required this.label,
    required this.imageUrl,
    required this.placeholder,
    this.aspectRatio = 1,
    this.isUploading = false,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isUploading ? null : onUpload,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: aspectRatio > 1 ? 100 : 60,
              height: 60,
              color: Colors.grey[200],
              child: isUploading
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFF35535),
                        ),
                      ),
                    )
                  : imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFF35535),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, _, _) =>
                          Icon(placeholder, color: Colors.grey[400]),
                    )
                  : Icon(placeholder, color: Colors.grey[400]),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  isUploading
                      ? AppLocalizations.of(context)!.uploading
                      : imageUrl.isNotEmpty
                      ? AppLocalizations.of(context)!.tapToChange
                      : AppLocalizations.of(context)!.tapToUpload,
                  style: TextStyle(
                    fontSize: 12,
                    color: isUploading
                        ? const Color(0xFFF35535)
                        : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          isUploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFF35535),
                  ),
                )
              : Icon(Icons.upload, size: 20, color: Colors.grey[400]),
        ],
      ),
    );
  }
}

class _DocumentsSection extends StatelessWidget {
  final List<String> documentUrls;
  const _DocumentsSection({required this.documentUrls});

  static const _docLabels = [
    'Commercial Registration',
    'Business License',
    'Health Certificate',
    'Tax Registration',
  ];

  static const _docIcons = [
    Icons.business_outlined,
    Icons.verified_outlined,
    Icons.health_and_safety_outlined,
    Icons.receipt_long_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    if (documentUrls.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      title: AppLocalizations.of(context)!.uploadedDocuments,
      icon: Icons.description_outlined,
      children: [
        for (var i = 0; i < documentUrls.length; i++)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _showDocumentViewer(
                context,
                documentUrls[i],
                i < _docLabels.length ? _docLabels[i] : 'Document ${i + 1}',
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Icon(
                      i < _docIcons.length
                          ? _docIcons[i]
                          : Icons.insert_drive_file_outlined,
                      size: 20,
                      color: const Color(0xFF1976D2),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        i < _docLabels.length
                            ? _docLabels[i]
                            : 'Document ${i + 1}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.check_circle,
                      size: 18,
                      color: Colors.green[400],
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.open_in_new, size: 16, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showDocumentViewer(BuildContext context, String url, String label) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 20,
                    color: Color(0xFF2D3748),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            // Image
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                child: InteractiveViewer(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return SizedBox(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.broken_image_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Failed to load document',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Operating Hours Edit Sheet
// ═══════════════════════════════════════════════════════════════════════════════

class _OperatingHoursEditSheet extends StatefulWidget {
  final Restaurant restaurant;
  final RestaurantProfileCubit cubit;
  const _OperatingHoursEditSheet({
    required this.restaurant,
    required this.cubit,
  });

  @override
  State<_OperatingHoursEditSheet> createState() =>
      _OperatingHoursEditSheetState();
}

class _OperatingHoursEditSheetState extends State<_OperatingHoursEditSheet> {
  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  late Map<String, WorkingHours> _hours;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _hours = {
      for (final d in _days)
        d:
            widget.restaurant.workingHours[d] ??
            const WorkingHours(open: '09:00', close: '22:00'),
    };
  }

  String _localDay(String day) {
    final l10n = AppLocalizations.of(context)!;
    switch (day) {
      case 'Monday':
        return l10n.monday;
      case 'Tuesday':
        return l10n.tuesday;
      case 'Wednesday':
        return l10n.wednesday;
      case 'Thursday':
        return l10n.thursday;
      case 'Friday':
        return l10n.friday;
      case 'Saturday':
        return l10n.saturday;
      case 'Sunday':
        return l10n.sunday;
      default:
        return day;
    }
  }

  Future<void> _pickTime(String day, bool isOpen) async {
    final current = isOpen ? _hours[day]!.open : _hours[day]!.close;
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts[1]) ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null && mounted) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        final wh = _hours[day]!;
        _hours[day] = WorkingHours(
          open: isOpen ? formatted : wh.open,
          close: isOpen ? wh.close : formatted,
          isClosed: wh.isClosed,
        );
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final payload = _hours.map((k, v) => MapEntry(k, v.toMap()));
    await widget.cubit.updateWorkingHours(payload);
    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.operatingHoursSaved),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: 20 + bottomPadding,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.schedule, color: Color(0xFFF35535)),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.editOperatingHours,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...(_days.map((day) {
              final wh = _hours[day]!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(
                        _localDay(day),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: wh.isClosed ? null : () => _pickTime(day, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: wh.isClosed
                                ? Colors.grey[100]
                                : const Color(0xFFFFF3F0),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: wh.isClosed
                                  ? Colors.grey[300]!
                                  : const Color(
                                      0xFFF35535,
                                    ).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            wh.isClosed ? '—' : wh.open,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: wh.isClosed
                                  ? Colors.grey[400]
                                  : const Color(0xFFF35535),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '–',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: wh.isClosed ? null : () => _pickTime(day, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: wh.isClosed
                                ? Colors.grey[100]
                                : const Color(0xFFFFF3F0),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: wh.isClosed
                                  ? Colors.grey[300]!
                                  : const Color(
                                      0xFFF35535,
                                    ).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            wh.isClosed ? '—' : wh.close,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: wh.isClosed
                                  ? Colors.grey[400]
                                  : const Color(0xFFF35535),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.statusClosed,
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[500],
                          ),
                        ),
                        Transform.scale(
                          scale: 0.75,
                          child: Switch(
                            value: wh.isClosed,
                            activeThumbColor: Colors.red[400],
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onChanged: (val) => setState(() {
                              _hours[day] = WorkingHours(
                                open: wh.open,
                                close: wh.close,
                                isClosed: val,
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            })),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF35535),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context)!.save,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
