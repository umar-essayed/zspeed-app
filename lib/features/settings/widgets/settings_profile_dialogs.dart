import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:z_speed/core/services/media_upload_service.dart';
import 'package:z_speed/core/utils/image_utils.dart'; // ImageUtils.pickImage
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';

/// Extracted profile-editing dialogs from SettingsPage.
///
/// Usage:
///   SettingsProfileDialogs.showEditProfile(
///     context: context,
///     nameController: _nameController,
///     emailController: _emailController,
///     phoneController: _phoneController,
///     profileImageUrl: _profileImageUrl,
///     onProfileImageChanged: (url) => setState(() => _profileImageUrl = url),
///     onSaved: () => setState(() {}),
///     showSnackBar: _showSnackBar,
///   );
class SettingsProfileDialogs {
  SettingsProfileDialogs._();

  /// Shows the edit-profile dialog (name / email / phone + avatar).
  static void showEditProfile({
    required BuildContext context,
    required TextEditingController nameController,
    required TextEditingController emailController,
    required TextEditingController phoneController,
    required String profileImageUrl,
    required ValueChanged<String> onProfileImageChanged,
    required VoidCallback onSaved,
    required void Function(String message, {Color color}) showSnackBar,
  }) {
    final formKey = GlobalKey<FormState>();
    // Local state for image URL inside the dialog
    final String currentImageUrl = profileImageUrl;

    showDialog(
      context: context,
      builder: (dialogContext) => _EditProfileDialog(
        formKey: formKey,
        nameController: nameController,
        emailController: emailController,
        phoneController: phoneController,
        initialImageUrl: currentImageUrl,
        onProfileImageChanged: onProfileImageChanged,
        onSaved: onSaved,
        showSnackBar: showSnackBar,
        authCubit: context.read<AuthCubit>(),
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final String initialImageUrl;
  final ValueChanged<String> onProfileImageChanged;
  final VoidCallback onSaved;
  final void Function(String message, {Color color}) showSnackBar;
  final AuthCubit authCubit;

  const _EditProfileDialog({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.initialImageUrl,
    required this.onProfileImageChanged,
    required this.onSaved,
    required this.showSnackBar,
    required this.authCubit,
  });

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late String _imageUrl;
  bool _isUploading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.initialImageUrl;
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    final xFile = await ImageUtils.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (xFile == null) return;

    setState(() => _isUploading = true);
    try {
      final userId = widget.authCubit.currentUser?.id ?? 'unknown';
      final result = await MediaUploadService().uploadXFile(
        xFile,
        'profiles/$userId',
      );
      setState(() => _imageUrl = result.url);
      widget.onProfileImageChanged(result.url);
    } catch (e) {
      widget.showSnackBar('Failed to upload image: $e', color: Colors.red);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFF35535)),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload(ImageSource.camera);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: Color(0xFFF35535)),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!widget.formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final success = await widget.authCubit.updateProfile(
      name: widget.nameController.text,
      email: widget.emailController.text,
      phone: widget.phoneController.text,
      profileImage: _imageUrl.isNotEmpty ? _imageUrl : null,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      widget.onSaved();
      widget.showSnackBar('Profile updated successfully!');
      Navigator.pop(context);
    } else {
      widget.showSnackBar('Failed to save profile. Please try again.',
          color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      title: const Text('Edit Profile', style: TextStyle(color: Colors.black)),
      content: SingleChildScrollView(
        child: Form(
          key: widget.formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar with upload indicator
              GestureDetector(
                onTap: _isUploading ? null : _showPickerSheet,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor:
                          const Color(0xFFF35535).withValues(alpha: 0.1),
                      backgroundImage:
                          _imageUrl.isNotEmpty ? NetworkImage(_imageUrl) : null,
                      child: _imageUrl.isEmpty
                          ? const Icon(Icons.camera_alt,
                              size: 30, color: Color(0xFFF35535))
                          : null,
                    ),
                    if (_isUploading)
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                        ),
                        child: const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: widget.nameController,
                label: 'Full Name',
                icon: Icons.person,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: widget.emailController,
                label: 'Email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter your email';
                  if (!v.contains('@')) return 'Please enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: widget.phoneController,
                label: 'Phone Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Please enter your phone number'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              (_isSaving || _isUploading) ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
        ),
        ElevatedButton(
          onPressed: (_isSaving || _isUploading) ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF35535),
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  static Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.black),
      keyboardType: keyboardType,
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
