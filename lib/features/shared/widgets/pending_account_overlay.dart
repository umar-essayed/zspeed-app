import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:z_speed/features/auth/model/user_model.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/features/shared/view/application_profile_page.dart';

/// Wraps a dashboard screen and shows a minimal pending-account overlay
/// if the user's application is not yet approved.
///
/// When approved → shows the [child] dashboard normally.
/// When pending/underReview → shows profile icon + status badge only.
/// When rejected → shows rejection info + "Edit Application" link.
class PendingAccountOverlay extends StatefulWidget {
  final Widget child;

  const PendingAccountOverlay({super.key, required this.child});

  @override
  State<PendingAccountOverlay> createState() => _PendingAccountOverlayState();
}

class _PendingAccountOverlayState extends State<PendingAccountOverlay> {
  StreamSubscription? _userSubscription;
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    _subscribeToUserChanges();
  }

  @override
  void didUpdateWidget(covariant PendingAccountOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _subscribeToUserChanges();
  }

  void _subscribeToUserChanges() {
    final user = context.read<AuthCubit>().state.user;
    if (user == null || user.applicationStatus == ApplicationStatus.approved) {
      _userSubscription?.cancel();
      _userSubscription = null;
      _lastUserId = null;
      return;
    }

    if (user.id == _lastUserId) return;

    _userSubscription?.cancel();
    _lastUserId = user.id;

    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.id)
        .snapshots()
        .listen(
          (snapshot) {
            if (!mounted) return;
            if (snapshot.exists && snapshot.data() != null) {
              final data = snapshot.data()!;
              final statusStr = data['applicationStatus'] as String?;
              if (statusStr == 'approved') {
                // Trigger a refresh of AuthCubit to load full approved user status and capabilities
                context.read<AuthCubit>().checkAuthStatus();
              }
            }
          },
          onError: (e) {
            debugPrint(
              'PendingAccountOverlay: error listening to user changes: $e',
            );
          },
        );
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final user = authState.user;

    // No user or approved → show full dashboard
    if (user == null || user.applicationStatus == ApplicationStatus.approved) {
      return widget.child;
    }

    // null applicationStatus with non-customer type means form not submitted yet
    // Show the full dashboard for customers (they don't have applications)
    if (user.applicationStatus == null && user.type == UserType.customer) {
      return widget.child;
    }

    return _PendingScreen(user: user);
  }
}

class _PendingScreen extends StatefulWidget {
  final AppUser user;

  const _PendingScreen({required this.user});

  @override
  State<_PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends State<_PendingScreen> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    // Wait a brief moment to make the interaction feel substantial
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    await context.read<AuthCubit>().checkAuthStatus();

    if (!mounted) return;

    setState(() {
      _isRefreshing = false;
    });

    final freshUser = context.read<AuthCubit>().state.user;
    if (freshUser != null &&
        freshUser.applicationStatus == ApplicationStatus.approved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '🎉 تم تفعيل حسابك بنجاح! جاري الانتقال للوحة التحكم...',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⏳ الطلب ما زال قيد المراجعة. سيتم تنشيط الحساب فور موافقة الإدارة.',
          ),
          backgroundColor: Color(0xFFFF9800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final status = user.applicationStatus;
    final isRejected = status == ApplicationStatus.rejected;
    final isPending =
        status == ApplicationStatus.pending ||
        status == ApplicationStatus.underReview;

    final Color statusColor = isRejected
        ? const Color(0xFFD32F2F)
        : const Color(0xFFFF9800);

    final String statusText = isRejected
        ? AppLocalizations.of(context)!.applicationRejected
        : status == ApplicationStatus.underReview
        ? AppLocalizations.of(context)!.statusUnderReviewLabel
        : AppLocalizations.of(context)!.pendingReview;

    final String statusDescription = isRejected
        ? AppLocalizations.of(context)!.applicationRejectedDesc
        : AppLocalizations.of(context)!.applicationPendingDesc;

    final IconData statusIcon = isRejected
        ? Icons.cancel_outlined
        : Icons.hourglass_top_rounded;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.myAccount),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3748),
        elevation: 1,
        actions: [
          // AppBar refresh button
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF2D3748),
                      ),
                    ),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'تحديث الحالة',
            onPressed: _isRefreshing ? null : _handleRefresh,
          ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: AppLocalizations.of(context)!.logoutTooltip,
            onPressed: () {
              context.read<AuthCubit>().logout();
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Profile avatar
              CircleAvatar(
                radius: 56,
                backgroundColor: statusColor.withValues(alpha: 0.15),
                child:
                    user.profileImage != null && user.profileImage!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          user.profileImage!,
                          width: 112,
                          height: 112,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              Icon(Icons.person, size: 56, color: statusColor),
                        ),
                      )
                    : Icon(Icons.person, size: 56, color: statusColor),
              ),
              const SizedBox(height: 16),

              // User name
              Text(
                user.name.isNotEmpty ? user.name : user.email,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 4),

              // Role chip
              Chip(
                label: Text(
                  user.type.label,
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
                backgroundColor: const Color(0xFFF35535),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(height: 32),

              // Status icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, size: 44, color: statusColor),
              ),
              const SizedBox(height: 16),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  statusDescription,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ),

              // Rejection reason
              if (isRejected && user.rejectionReason != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3F3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFD32F2F).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.rejectionReasonLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD32F2F),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.rejectionReason!,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Edit Profile button (for rejected or pending)
              if (isPending || isRejected)
                Column(
                  children: [
                    SizedBox(
                      width: 220,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ApplicationProfilePage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text(
                          isRejected
                              ? AppLocalizations.of(context)!.editAndResubmit
                              : AppLocalizations.of(context)!.viewApplication,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFF35535),
                          side: const BorderSide(color: Color(0xFFF35535)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Manual Refresh Button
                    SizedBox(
                      width: 220,
                      child: ElevatedButton.icon(
                        onPressed: _isRefreshing ? null : _handleRefresh,
                        icon: _isRefreshing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text(
                          'تحديث حالة الحساب',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D3748),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 1,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
