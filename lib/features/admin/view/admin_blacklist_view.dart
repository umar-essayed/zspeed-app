import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/core/injection.dart';
import 'package:z_speed/features/admin/datasource/settings_datasource.dart';
import 'package:z_speed/features/admin/model/admin_theme.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/l10n/app_localizations.dart';

/// Modal / Screen for managing blocked identifiers (phone, email, UID).
class AdminBlacklistView extends StatefulWidget {
  final bool isDialog;

  const AdminBlacklistView({super.key, this.isDialog = false});

  /// Open as a modal bottom sheet (on mobile) or dialog (on desktop/tablet).
  static Future<void> show(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 700;
    if (isDesktop) {
      return showDialog<void>(
        context: context,
        builder: (ctx) => const Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 40, vertical: 32),
          child: SizedBox(
            width: 680,
            height: 640,
            child: AdminBlacklistView(isDialog: true),
          ),
        ),
      );
    } else {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => const FractionallySizedBox(
          heightFactor: 0.85,
          child: AdminBlacklistView(isDialog: false),
        ),
      );
    }
  }

  @override
  State<AdminBlacklistView> createState() => _AdminBlacklistViewState();
}

class _AdminBlacklistViewState extends State<AdminBlacklistView> {
  String _searchQuery = '';
  final SettingsDatasource _datasource = getIt<SettingsDatasource>();

  void _showAddDialog(BuildContext context, UserType userType) {
    showDialog(
      context: context,
      builder: (dialogCtx) => _AddBlacklistDialog(
        userType: userType,
        onAdd: (type, value, reason) async {
          await _datasource.addToBlacklist(
            type: type,
            value: value,
            reason: reason,
          );
        },
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    BlacklistItem item,
    UserType userType,
  ) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n?.removeFromBlacklist ?? 'Remove from Blacklist',
          style:
              const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
        ),
        content: Text(
          l10n?.confirmRemoveBlacklist(item.value) ??
              'Are you sure you want to unblock ${item.value}?',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              l10n?.cancel ?? 'Cancel',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              try {
                await _datasource.removeFromBlacklist(item.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n?.removedFromBlacklistSuccess ??
                            'Removed from blacklist successfully',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to remove: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(
              l10n?.removeFromBlacklist ?? 'Remove',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = context.watch<AuthCubit>().state.user;
    final userType = user?.type ?? UserType.customer;
    final isSuperAdmin = userType == UserType.superAdmin;
    final isAdmin = userType == UserType.admin || isSuperAdmin;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : Colors.white,
        borderRadius: BorderRadius.circular(widget.isDialog ? 20 : 24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AdminTheme.errorRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.block_rounded,
                      color: AdminTheme.errorRed, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.blacklistManagementTitle ??
                            'Blacklist & Blocked Identifiers',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          color: isDark ? Colors.white : AdminTheme.textDark,
                        ),
                      ),
                      Text(
                        l10n?.blacklistSubtitle ??
                            'Manage blocked phones, emails, and user IDs',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'Cairo',
                          color: isDark ? Colors.white60 : AdminTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAdmin) ...[
                  ElevatedButton.icon(
                    onPressed: () => _showAddDialog(context, userType),
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(
                      l10n?.addToBlacklist ?? 'Add',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText:
                    '${l10n?.searchHint ?? 'Search'} (${l10n?.blockedIdentifiers ?? 'Blocked Identifiers'})...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white38 : Colors.grey[400],
                  fontFamily: 'Cairo',
                ),
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.06),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const Divider(height: 1),

          // Real-time List
          Expanded(
            child: StreamBuilder<List<BlacklistItem>>(
              stream: _datasource.streamBlacklist(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rawList = snapshot.data ?? [];
                final items = rawList.where((item) {
                  if (_searchQuery.trim().isEmpty) return true;
                  final q = _searchQuery.toLowerCase();
                  return item.value.toLowerCase().contains(q) ||
                      (item.reason?.toLowerCase().contains(q) ?? false) ||
                      item.type.toLowerCase().contains(q);
                }).toList();

                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 48,
                            color: isDark ? Colors.white24 : Colors.grey[300],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n?.blacklistEmpty ??
                                'No blocked identifiers found.',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white60 : Colors.grey[600],
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final item = items[idx];
                    IconData icon;
                    Color iconBg;
                    if (item.type == 'phone') {
                      icon = Icons.phone_android_rounded;
                      iconBg = Colors.blue;
                    } else if (item.type == 'email') {
                      icon = Icons.email_outlined;
                      iconBg = Colors.purple;
                    } else {
                      icon = Icons.person_outline_rounded;
                      iconBg = Colors.orange;
                    }

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: iconBg.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: iconBg, size: 20),
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.value,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Cairo',
                                color: isDark
                                    ? Colors.white
                                    : AdminTheme.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.grey.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.type.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: (item.reason != null &&
                              item.reason!.trim().isNotEmpty)
                          ? Text(
                              '${l10n?.blockReason ?? 'Reason'}: ${item.reason!}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white60
                                    : Colors.grey[600],
                                fontFamily: 'Cairo',
                              ),
                            )
                          : null,
                      trailing: isAdmin
                          ? IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              tooltip: l10n?.removeFromBlacklist ?? 'Remove',
                              onPressed: () => _confirmDelete(
                                context,
                                item,
                                userType,
                              ),
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AddBlacklistDialog extends StatefulWidget {
  final UserType userType;
  final Future<void> Function(String type, String value, String? reason) onAdd;

  const _AddBlacklistDialog({
    required this.userType,
    required this.onAdd,
  });

  @override
  State<_AddBlacklistDialog> createState() => _AddBlacklistDialogState();
}

class _AddBlacklistDialogState extends State<_AddBlacklistDialog> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'phone';
  final _valueCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _valueCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        l10n?.addToBlacklist ?? 'Add to Blacklist',
        style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n?.blockType ?? 'Type',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'phone',
                    child: Text(l10n?.phoneType ?? 'Phone Number'),
                  ),
                  DropdownMenuItem(
                    value: 'email',
                    child: Text(l10n?.emailType ?? 'Email Address'),
                  ),
                  DropdownMenuItem(
                    value: 'uid',
                    child: Text(l10n?.uidType ?? 'User ID (UID)'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _type = val);
                },
              ),
              const SizedBox(height: 14),
              Text(
                _type == 'phone'
                    ? (l10n?.phoneType ?? 'Phone Number')
                    : (_type == 'email'
                        ? (l10n?.emailType ?? 'Email Address')
                        : (l10n?.uidType ?? 'User ID')),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _valueCtrl,
                decoration: InputDecoration(
                  hintText: _type == 'phone'
                      ? '010XXXXXXXX / +2010XXXXXXXX'
                      : (_type == 'email' ? 'user@example.com' : 'UID...'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return l10n?.enterIdentifier ?? 'Please enter a value';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Text(
                l10n?.blockReason ?? 'Reason (Optional)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _reasonCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: l10n?.blockReasonHint ??
                      'e.g. Suspicious activity or policy violation',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n?.cancel ?? 'Cancel',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminTheme.primaryOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _saving
              ? null
              : () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    setState(() => _saving = true);
                    try {
                      await widget.onAdd(
                        _type,
                        _valueCtrl.text.trim(),
                        _reasonCtrl.text.trim().isEmpty
                            ? null
                            : _reasonCtrl.text.trim(),
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n?.addedToBlacklistSuccess ??
                                  'Added to blacklist successfully',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        setState(() => _saving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to add: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  l10n?.addToBlacklist ?? 'Add',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
        ),
      ],
    );
  }
}
