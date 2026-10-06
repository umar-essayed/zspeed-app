import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';

class SettingsPasswordDialog {
  SettingsPasswordDialog._();

  static void show({
    required BuildContext context,
    required void Function(String message, {Color color}) showSnackBar,
  }) {
    showDialog(
      context: context,
      builder: (_) => _ChangePasswordDialog(
        authCubit: context.read<AuthCubit>(),
        showSnackBar: showSnackBar,
      ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  final AuthCubit authCubit;
  final void Function(String message, {Color color}) showSnackBar;

  const _ChangePasswordDialog({
    required this.authCubit,
    required this.showSnackBar,
  });

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final error = await widget.authCubit.changePassword(
      currentPassword: _currentCtrl.text,
      newPassword: _newCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error == null) {
      widget.showSnackBar('Password changed successfully!');
      Navigator.pop(context);
    } else {
      widget.showSnackBar(error, color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title:
          const Text('Change Password', style: TextStyle(color: Colors.black)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField(
                controller: _currentCtrl,
                label: 'Current Password',
                icon: Icons.lock,
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Please enter current password'
                    : null,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _newCtrl,
                label: 'New Password',
                icon: Icons.lock_outline,
                validator: (v) => (v == null || v.length < 8)
                    ? 'Password must be at least 8 characters'
                    : null,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _confirmCtrl,
                label: 'Confirm New Password',
                icon: Icons.lock_reset,
                validator: (v) =>
                    v != _newCtrl.text ? 'Passwords do not match' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF35535),
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Text('Update Password',
                  style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.black),
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        prefixIcon: Icon(icon, color: const Color(0xFFF35535)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFF35535)),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      validator: validator,
    );
  }
}
