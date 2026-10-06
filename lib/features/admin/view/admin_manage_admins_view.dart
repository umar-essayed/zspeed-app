import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/features/admin/model/admin_models.dart';
import 'package:z_speed/features/admin/model/admin_theme.dart';
import 'package:z_speed/features/admin/view/admin_view_mappers.dart';
import 'package:z_speed/features/admin/cubit/admin_management_cubit.dart';
import 'package:z_speed/features/admin/cubit/admin_management_state.dart';
import 'package:z_speed/features/admin/widgets/admin_dialogs.dart';
import 'package:z_speed/core/errors/failure_localization_ext.dart';
import 'package:z_speed/l10n/app_localizations.dart';

/// Admin management view — only visible to super admins.
///
/// Displays a list of admin users and allows creating new admin accounts.
/// Follows the same UI pattern as [AdminUsersView].
class AdminManageAdminsView extends StatelessWidget {
  const AdminManageAdminsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminManagementCubit, AdminManagementState>(
      listener: (context, state) {
        if (state.createSuccess) {
          AdminDialogs.showSnack(context, AppLocalizations.of(context)!.adminCreatedSuccessfully);
        }
        if (state.createError != null) {
          AdminDialogs.showSnack(context, state.createError!);
        }
      },
      builder: (context, state) {
        if (state.isBusy) {
          return Center(
            child: CircularProgressIndicator(
              color: AdminTheme.primaryOrange,
            ),
          );
        }

        if (state.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AdminTheme.errorRed),
                const SizedBox(height: 16),
                Text(
                  state.failure?.getLocalizedMessage(context) ??
                      'An error occurred',
                  style: TextStyle(color: AdminTheme.textDark, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () =>
                      context.read<AdminManagementCubit>().loadAdmins(),
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

        return _AdminsContent(admins: state.admins);
      },
    );
  }
}

class _AdminsContent extends StatelessWidget {
  const _AdminsContent({required this.admins});

  final List<AdminUser> admins;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header with Add Admin button ──────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                AppLocalizations.of(context)!.adminManagement,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AdminTheme.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddAdminDialog(context),
              icon: const Icon(Icons.person_add, size: 16),
              label: Text(AppLocalizations.of(context)!.addAdmin),
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
        ),
        const SizedBox(height: 16),

        // ── Search bar ────────────────────────────────────────────────
        SizedBox(
          width: MediaQuery.of(context).size.width < 768
              ? double.infinity
              : 260,
          height: 40,
          child: TextField(
            onChanged:
                context.read<AdminManagementCubit>().setSearchQuery,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.searchAdmins,
              hintStyle:
                  TextStyle(color: AdminTheme.textLight, fontSize: 13),
              prefixIcon:
                  Icon(Icons.search, size: 18, color: AdminTheme.textLight),
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
        const SizedBox(height: 12),

        // ── Admins table / cards ──────────────────────────────────────
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
              // Table Header
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;

                  if (isMobile) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        AppLocalizations.of(context)!.adminsList,
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
                              color: AdminTheme.borderColor, width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(AppLocalizations.of(context)!.adminColumnHeader,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AdminTheme.textDark)),
                          ),
                          Expanded(
                            child: Text(AppLocalizations.of(context)!.roleColumnHeader,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AdminTheme.textDark)),
                          ),
                          Expanded(
                            child: Text(AppLocalizations.of(context)!.statusColumnHeader,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AdminTheme.textDark)),
                          ),
                          Expanded(
                            child: Text(AppLocalizations.of(context)!.joinedColumnHeader,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AdminTheme.textDark)),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),

              if (admins.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.noAdminUsersFound,
                      style: TextStyle(
                          color: AdminTheme.textLight, fontSize: 14),
                    ),
                  ),
                ),

              // Table Rows
              ...admins.map((admin) {
                final statusColor = resolveAdminUserStatusColor(
                  status: admin.status,
                  successGreen: AdminTheme.successGreen,
                  warningAmber: AdminTheme.warningAmber,
                  errorRed: AdminTheme.errorRed,
                );

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    if (isMobile) {
                      return _buildMobileCard(admin, statusColor);
                    } else {
                      return _buildDesktopRow(admin, statusColor);
                    }
                  },
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileCard(AdminUser admin, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: AdminTheme.backgroundWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AdminTheme.borderColor, width: 1),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildAvatar(admin),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(admin.name,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AdminTheme.textDark,
                              fontSize: 14)),
                      Text(admin.email,
                          style: TextStyle(
                              fontSize: 12, color: AdminTheme.textLight)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(
                    admin.role.toString().split('.').last,
                    style: TextStyle(
                        fontSize: 10,
                        color: AdminTheme.textDark,
                        fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: AdminTheme.backgroundWhite,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                Chip(
                  label: Text(
                    admin.status.toString().split('.').last,
                    style: TextStyle(
                        fontSize: 10,
                        color: statusColor,
                        fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: statusColor.withValues(alpha: 0.1),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopRow(AdminUser admin, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                _buildAvatar(admin),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(admin.name,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AdminTheme.textDark,
                              fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(admin.email,
                          style: TextStyle(
                              fontSize: 12, color: AdminTheme.textLight),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Chip(
              label: Text(
                admin.role.toString().split('.').last,
                style: TextStyle(
                    fontSize: 10,
                    color: AdminTheme.textDark,
                    fontWeight: FontWeight.w600),
              ),
              backgroundColor: AdminTheme.backgroundWhite,
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
          Expanded(
            child: Chip(
              label: Text(
                admin.status.toString().split('.').last,
                style: TextStyle(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.w600),
              ),
              backgroundColor: statusColor.withValues(alpha: 0.1),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
          Expanded(
            child: Text(
              admin.joinDate,
              style: TextStyle(fontSize: 12, color: AdminTheme.textLight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(AdminUser admin) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [Colors.deepPurple, Colors.deepPurple.shade300],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          (admin.name.length >= 2
                  ? admin.name.substring(0, 2)
                  : admin.name)
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

  void _showAddAdminDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    // Capture the cubit before entering the new dialog route context.
    final cubit = context.read<AdminManagementCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocProvider<AdminManagementCubit>.value(
          value: cubit,
          child: AlertDialog(
          backgroundColor: AdminTheme.surfaceWhite,
          title: Text(AppLocalizations.of(context)!.addNewAdmin,
              style: TextStyle(color: AdminTheme.textDark)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.fullName,
                    labelStyle: TextStyle(color: AdminTheme.textMedium),
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: AdminTheme.borderColor)),
                    focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: AdminTheme.primaryOrange)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.emailLabel,
                    labelStyle: TextStyle(color: AdminTheme.textMedium),
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: AdminTheme.borderColor)),
                    focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: AdminTheme.primaryOrange)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.password,
                    labelStyle: TextStyle(color: AdminTheme.textMedium),
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: AdminTheme.borderColor)),
                    focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: AdminTheme.primaryOrange)),
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(AppLocalizations.of(context)!.cancel,
                  style: TextStyle(color: AdminTheme.textLight)),
            ),
            BlocBuilder<AdminManagementCubit, AdminManagementState>(
              builder: (ctx, state) {
                return ElevatedButton(
                  onPressed: state.isCreating
                      ? null
                      : () {
                          final name = nameController.text.trim();
                          final email = emailController.text.trim();
                          final password = passwordController.text.trim();

                          if (name.isEmpty ||
                              email.isEmpty ||
                              password.isEmpty) {
                            AdminDialogs.showSnack(
                                context, AppLocalizations.of(context)!.pleaseFillAllFields);
                            return;
                          }
                          if (password.length < 6) {
                            AdminDialogs.showSnack(context,
                                AppLocalizations.of(context)!.passwordMinLength);
                            return;
                          }

                          context.read<AdminManagementCubit>().createAdmin(
                                name: name,
                                email: email,
                                password: password,
                              );
                          Navigator.pop(dialogContext);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.primaryOrange,
                    foregroundColor: AdminTheme.white,
                  ),
                  child: state.isCreating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(AppLocalizations.of(context)!.addAdmin),
                );
              },
            ),
          ],
        ),
        );
      },
    );
  }
}
