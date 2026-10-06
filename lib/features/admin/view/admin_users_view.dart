import 'package:flutter/material.dart';
import 'package:z_speed/core/permissions/permission_service.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/features/admin/model/admin_models.dart';
import 'package:z_speed/features/admin/model/admin_theme.dart';
import 'package:z_speed/features/admin/view/admin_view_mappers.dart';
import 'package:z_speed/features/admin/cubit/admin_users_cubit.dart';
import 'package:z_speed/features/admin/cubit/admin_users_state.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/features/admin/view/admin_user_detail_view.dart';
import 'package:z_speed/features/admin/widgets/admin_dialogs.dart';
import 'package:z_speed/core/errors/failure_localization_ext.dart';
import 'package:z_speed/features/admin/view/admin_blacklist_view.dart';

/// User-management view for the admin panel.
///
/// Renders a responsive table (mobile cards / desktop rows) with user
/// avatars, role/status chips, and action buttons.
// ignore: unintended_html_in_doc_comment
/// Now uses Consumer<AdminUsersViewModel> to fetch live data from Firestore.
class AdminUsersView extends StatelessWidget {
  const AdminUsersView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminUsersCubit, AdminUsersState>(
      listenWhen: (prev, curr) => curr.actionError != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.actionError!),
            backgroundColor: AdminTheme.errorRed,
          ),
        );
      },
      builder: (context, state) {
        // Loading state
        if (state.isBusy) {
          return Center(
            child: CircularProgressIndicator(
              color: AdminTheme.primaryOrange,
            ),
          );
        }

        // Error state
        if (state.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AdminTheme.errorRed,
                ),
                const SizedBox(height: 16),
                Text(
                  state.failure?.getLocalizedMessage(context) ??
                      'An error occurred',
                  style: TextStyle(
                    color: AdminTheme.textDark,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.read<AdminUsersCubit>().loadUsers(),
                  icon: const Icon(Icons.refresh),
                  label: Text(AppLocalizations.of(context)!.retry),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.primaryOrange,
                    foregroundColor: AdminTheme.white,
                  ),
                ),
              ],
            ),
          );
        }

        // Success state - render users list
        final currentUserType = context.read<AdminUsersCubit>().currentUserType;
        return _UsersContent(
          users: state.filteredAdminUsers,
          currentUserType: currentUserType,
          onUpdateStatus: context.read<AdminUsersCubit>().updateStatus,
          onUpdateRole: context.read<AdminUsersCubit>().updateRole,
          onDeleteUser: context.read<AdminUsersCubit>().deleteUser,
          searchQuery: state.searchQuery,
          onSearchChanged: context.read<AdminUsersCubit>().setSearchQuery,
          selectedType: state.typeFilter,
          onTypeChanged: context.read<AdminUsersCubit>().setTypeFilter,
          selectedStatus: state.statusFilter,
          onStatusChanged: context.read<AdminUsersCubit>().setStatusFilter,
          hasMore: state.hasMore,
          isLoadingMore: state.isLoadingMore,
          onLoadMore: () =>
              context.read<AdminUsersCubit>().loadUsers(isLoadMore: true),
        );
      },
    );
  }
}

/// Internal widget to render the users list when data is loaded.
class _UsersContent extends StatelessWidget {
  const _UsersContent({
    required this.users,
    required this.currentUserType,
    required this.onUpdateStatus,
    required this.onUpdateRole,
    required this.onDeleteUser,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.selectedType,
    required this.onTypeChanged,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
  });

  final List<AdminUser> users;
  final UserType currentUserType;
  final Future<void> Function(String userId, UserStatus status) onUpdateStatus;
  final Future<void> Function(String userId, UserType role) onUpdateRole;
  final Future<void> Function(String userId) onDeleteUser;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final UserType? selectedType;
  final ValueChanged<UserType?> onTypeChanged;
  final UserStatus? selectedStatus;
  final ValueChanged<UserStatus?> onStatusChanged;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  String _localizeUserType(UserType type, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case UserType.superAdmin:
        return 'Super Admin';
      case UserType.admin:
        return l10n.userTypeAdmin;
      case UserType.vendor:
        return l10n.userTypeRestaurant;
      case UserType.customer:
        return l10n.userTypeCustomer;
      case UserType.driver:
        return l10n.userTypeDriver;
    }
  }

  String _localizeUserStatus(UserStatus status, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case UserStatus.active:
        return l10n.active;
      case UserStatus.inactive:
        return l10n.inactive;
      case UserStatus.suspended:
        return l10n.suspended;
      case UserStatus.pendingVerification:
        return l10n.pendingVerification;
      case UserStatus.banned:
        return l10n.banned;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                AppLocalizations.of(context)!.userManagement,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AdminTheme.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: AppLocalizations.of(context)!.refreshTooltip,
                  icon: Icon(Icons.refresh, color: AdminTheme.primaryOrange),
                  onPressed: () =>
                      context.read<AdminUsersCubit>().loadUsers(),
                ),
                if (context.read<AuthCubit>().state.user?.type == UserType.admin ||
                    context.read<AuthCubit>().state.user?.type == UserType.superAdmin) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => AdminBlacklistView.show(context),
                    icon: const Icon(Icons.block_rounded, size: 16, color: Colors.redAccent),
                    label: Text(
                      AppLocalizations.of(context)?.blacklistManagementTitle ?? 'Blacklist',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () =>
                        AdminDialogs.showComingSoon(context, 'Add User'),
                    icon: const Icon(Icons.person_add, size: 16),
                    label: Text(AppLocalizations.of(context)!.addUser),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.primaryOrange,
                      foregroundColor: AdminTheme.white,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Search & Filter Bar ────────────────────────────────────
        _SearchFilterBar(
          searchQuery: searchQuery,
          onSearchChanged: onSearchChanged,
          selectedType: selectedType,
          onTypeChanged: onTypeChanged,
          selectedStatus: selectedStatus,
          onStatusChanged: onStatusChanged,
        ),
        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: AdminTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AdminTheme.borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 15,
                offset: const Offset(0, 4),
                spreadRadius: -5,
              ),
            ],
          ),
          child: Column(
            children: [
              // Table Header - Responsive
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;

                  if (isMobile) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        AppLocalizations.of(context)!.usersList,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AdminTheme.textDark,
                        ),
                      ),
                    );
                  } else {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AdminTheme.backgroundWhite,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        border: BorderDirectional(
                            bottom: BorderSide(
                                color: AdminTheme.borderColor, width: 1)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              AppLocalizations.of(context)!.userColumnHeader,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AdminTheme.textDark,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.roleColumnHeader,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AdminTheme.textDark,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.statusColumnHeader,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AdminTheme.textDark,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.actionsColumnHeader,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AdminTheme.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
              // Table Rows
              ...users.map((user) {
                final statusColor = resolveAdminUserStatusColor(
                  status: user.status,
                  successGreen: AdminTheme.successGreen,
                  warningAmber: AdminTheme.warningAmber,
                  errorRed: AdminTheme.errorRed,
                );

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;

                    if (isMobile) {
                      return _buildMobileUserCard(user, statusColor, context);
                    } else {
                      return _buildDesktopUserRow(user, statusColor, context);
                    }
                  },
                );
              }),

              if (hasMore && users.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: isLoadingMore
                      ? const CircularProgressIndicator()
                      : TextButton(
                          onPressed: onLoadMore,
                          style: TextButton.styleFrom(
                            foregroundColor: AdminTheme.primaryOrange,
                          ),
                          child: Text(AppLocalizations.of(context)!.loadMore),
                        ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Mobile card layout ─────────────────────────────────────────────

  Widget _buildMobileUserCard(
      AdminUser user, Color statusColor, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AdminTheme.backgroundWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AdminTheme.borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Header (Avatar, Name, Email)
            Row(
              children: [
                _buildAvatar(user),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AdminTheme.textDark,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: AdminTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 2: Badges (Role, Status)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AdminTheme.textLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _localizeUserType(user.role, context).toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      color: AdminTheme.textMedium,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // Status Badge
                InkWell(
                  onTap: PermissionService.canEditUser(currentUserType, user.role)
                      ? () async {
                          final newStatus = await AdminDialogs.pickUserStatus(
                              context,
                              currentStatus: user.status);
                          if (newStatus != null && context.mounted) {
                            await onUpdateStatus(user.id, newStatus);
                          }
                        }
                      : null,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _localizeUserStatus(user.status, context).toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 0.5, color: Color(0xFFE5E5E5)),
            const SizedBox(height: 8),

            // Row 3: Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left Action Button (Change Role or View Details)
                if (PermissionService.canEditUser(currentUserType, user.role))
                  OutlinedButton.icon(
                    onPressed: () async {
                      final newRole = await AdminDialogs.pickUserRole(context,
                          currentRole: user.role);
                      if (newRole != null && context.mounted) {
                        await onUpdateRole(user.id, newRole);
                      }
                    },
                    icon: Icon(Icons.shield_outlined, size: 12, color: AdminTheme.primaryOrange),
                    label: Text(
                      'Change Role',
                      style: TextStyle(fontSize: 11, color: AdminTheme.primaryOrange, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AdminTheme.primaryOrange.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () {
                      final appUser = context
                          .read<AdminUsersCubit>()
                          .state
                          .users
                          .where((u) => u.id == user.id)
                          .firstOrNull;
                      if (appUser != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AdminUserDetailView(user: appUser),
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.visibility_outlined, size: 12, color: AdminTheme.primaryOrange),
                    label: Text(
                      AppLocalizations.of(context)!.viewDetails,
                      style: TextStyle(fontSize: 11, color: AdminTheme.primaryOrange, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AdminTheme.primaryOrange.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),

                // Right Action Icons
                Row(
                  children: [
                    if (PermissionService.canDeleteUser(currentUserType, user.role)) ...[
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: AdminTheme.errorRed, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () async {
                          final confirmed = await AdminDialogs.confirmDelete(
                              context,
                              itemType: 'User',
                              itemName: user.name);
                          if (confirmed && context.mounted) {
                            await onDeleteUser(user.id);
                          }
                        },
                      ),
                      const SizedBox(width: 14),
                    ],
                    _buildUserPopupMenu(user, context),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Desktop row layout ─────────────────────────────────────────────

  Widget _buildDesktopUserRow(
      AdminUser user, Color statusColor, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                _buildAvatar(user),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AdminTheme.textDark,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: AdminTheme.textLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Chip(
              label: Text(
                _localizeUserType(user.role, context),
                style: TextStyle(
                  fontSize: 10,
                  color: AdminTheme.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: AdminTheme.backgroundWhite,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: PermissionService.canEditUser(currentUserType, user.role)
                    ? () async {
                        final newStatus = await AdminDialogs.pickUserStatus(
                            context,
                            currentStatus: user.status);
                        if (newStatus != null && context.mounted) {
                          await onUpdateStatus(user.id, newStatus);
                        }
                      }
                    : null,
                borderRadius: BorderRadius.circular(4),
                child: Chip(
                  label: Text(
                    _localizeUserStatus(user.status, context),
                    style: TextStyle(
                      fontSize: 10,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: statusColor.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                if (PermissionService.canEditUser(currentUserType, user.role))
                  IconButton(
                    icon: Icon(Icons.edit,
                        size: 16, color: AdminTheme.primaryOrange),
                    onPressed: () async {
                      final newRole = await AdminDialogs.pickUserRole(context,
                          currentRole: user.role);
                      if (newRole != null && context.mounted) {
                        await onUpdateRole(user.id, newRole);
                      }
                    },
                  ),
                if (PermissionService.canDeleteUser(currentUserType, user.role))
                  IconButton(
                    icon:
                        Icon(Icons.delete, size: 16, color: AdminTheme.errorRed),
                    onPressed: () async {
                      final confirmed = await AdminDialogs.confirmDelete(
                          context,
                          itemType: 'User',
                          itemName: user.name);
                      if (confirmed && context.mounted) {
                        await onDeleteUser(user.id);
                      }
                    },
                  ),
                _buildUserPopupMenu(user, context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────

  Widget _buildAvatar(AdminUser user) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [AdminTheme.primaryOrange, AdminTheme.accentOrange],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          (user.name.length >= 2 ? user.name.substring(0, 2) : user.name)
              .toUpperCase(),
          style: TextStyle(
            color: AdminTheme.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildUserPopupMenu(AdminUser user, BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        switch (value) {
          case 'view':
            final appUser = context
                .read<AdminUsersCubit>()
                .state
                .users
                .where((u) => u.id == user.id)
                .firstOrNull;
            if (appUser != null && context.mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AdminUserDetailView(user: appUser),
                ),
              );
            }
          case 'change_status':
            final newStatus = await AdminDialogs.pickUserStatus(context,
                currentStatus: user.status);
            if (newStatus != null && context.mounted) {
              await onUpdateStatus(user.id, newStatus);
            }
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem(
            value: 'view',
            child: Row(
              children: [
                Icon(Icons.visibility, color: AdminTheme.infoBlue, size: 16),
                const SizedBox(width: 6),
                Text(AppLocalizations.of(context)!.viewDetails,
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          if (PermissionService.canEditUser(currentUserType, user.role))
            PopupMenuItem(
              value: 'change_status',
              child: Row(
                children: [
                  Icon(Icons.sync, color: AdminTheme.warningAmber, size: 16),
                  const SizedBox(width: 6),
                  Text(AppLocalizations.of(context)!.changeStatus,
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
        ];
      },
      child: Icon(Icons.more_vert, color: AdminTheme.textLight, size: 18),
    );
  }
}

// ── Search & Filter Bar ──────────────────────────────────────────────────────

class _SearchFilterBar extends StatelessWidget {
  const _SearchFilterBar({
    required this.searchQuery,
    required this.onSearchChanged,
    required this.selectedType,
    required this.onTypeChanged,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final UserType? selectedType;
  final ValueChanged<UserType?> onTypeChanged;
  final UserStatus? selectedStatus;
  final ValueChanged<UserStatus?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Search field
        SizedBox(
          width: isMobile ? double.infinity : 260,
          height: 40,
          child: TextField(
            // ignore: deprecated_member_use
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.searchUsers,
              hintStyle: TextStyle(color: AdminTheme.textLight, fontSize: 13),
              prefixIcon:
                  Icon(Icons.search, size: 18, color: AdminTheme.textLight),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear,
                          size: 16, color: AdminTheme.textLight),
                      onPressed: () => onSearchChanged(''),
                    )
                  : null,
              filled: true,
              fillColor: AdminTheme.surfaceWhite,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AdminTheme.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AdminTheme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: AdminTheme.primaryOrange, width: 1.5),
              ),
            ),
            style: TextStyle(fontSize: 13, color: AdminTheme.textDark),
          ),
        ),

        // Type filter dropdown
        _FilterDropdown<UserType>(
          value: selectedType,
          hint: AppLocalizations.of(context)!.allRoles,
          items: UserType.values.where((t) => t != UserType.admin).toList(),
          labelOf: (t) => t.name[0].toUpperCase() + t.name.substring(1),
          // ignore: deprecated_member_use
          onChanged: (v) => onTypeChanged(v),
        ),

        // Status filter dropdown
        _FilterDropdown<UserStatus>(
          value: selectedStatus,
          hint: AppLocalizations.of(context)!.allStatuses,
          items: UserStatus.values,
          labelOf: (s) => s.name[0].toUpperCase() + s.name.substring(1),
          // ignore: deprecated_member_use
          onChanged: (v) => onStatusChanged(v),
        ),
      ],
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    super.key,
    required this.value,
    required this.hint,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  final T? value;
  final String hint;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AdminTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminTheme.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint,
              style: TextStyle(fontSize: 13, color: AdminTheme.textLight)),
          icon: Icon(Icons.arrow_drop_down,
              color: AdminTheme.textLight, size: 18),
          style: TextStyle(fontSize: 13, color: AdminTheme.textDark),
          items: [
            DropdownMenuItem<T>(
                value: null,
                child: Text(AppLocalizations.of(context)!
                    .allCountParentheses(hint.toString()))),
            ...items.map((item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(labelOf(item)),
                )),
          ],
          // ignore: deprecated_member_use
          onChanged: onChanged,
        ),
      ),
    );
  }
}
