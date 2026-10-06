import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/features/pharmacy_chat/cubit/pharmacy_chat_cubit.dart';
import 'package:z_speed/features/pharmacy_chat/cubit/pharmacy_chat_state.dart';
import 'package:z_speed/features/pharmacy_chat/view/pharmacy_chat_screen.dart';

class PrescriptionUploadBottomSheet extends StatefulWidget {
  final String pharmacyId;
  final String pharmacyName;

  const PrescriptionUploadBottomSheet({
    super.key,
    required this.pharmacyId,
    required this.pharmacyName,
  });

  static Future<void> show(
    BuildContext context, {
    required String pharmacyId,
    required String pharmacyName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider(
        create: (_) => PharmacyChatCubit(),
        child: PrescriptionUploadBottomSheet(
          pharmacyId: pharmacyId,
          pharmacyName: pharmacyName,
        ),
      ),
    );
  }

  @override
  State<PrescriptionUploadBottomSheet> createState() =>
      _PrescriptionUploadBottomSheetState();
}

class _PrescriptionUploadBottomSheetState
    extends State<PrescriptionUploadBottomSheet> {
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final img = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (img != null) {
        setState(() {
          _selectedImage = img;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  void _uploadPrescription() async {
    if (_selectedImage == null) return;

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final authState = context.read<AuthCubit>().state;
    final user = authState.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(isAr
                ? 'يرجى تسجيل الدخول لرفع الروشتة.'
                : 'Please log in to upload a prescription.')),
      );
      return;
    }

    final cubit = context.read<PharmacyChatCubit>();
    final result = await cubit.uploadPrescriptionAndStartChat(
      customerId: user.id,
      customerName: user.name.isNotEmpty ? user.name : 'Customer',
      customerPhone: user.phone ?? '',
      pharmacyId: widget.pharmacyId,
      pharmacyName: widget.pharmacyName,
      xFile: _selectedImage!,
    );

    if (result != null && mounted) {
      final requestId = result['requestId']!;
      final chatId = result['chatId']!;
      Navigator.pop(context); // Close sheet

      // Navigate to Live Chat Screen!
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => PharmacyChatCubit(),
            child: PharmacyChatScreen(
              chatId: chatId,
              requestId: requestId,
              pharmacyName: widget.pharmacyName,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const emeraldGreen = Color(0xFF10B981);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return BlocConsumer<PharmacyChatCubit, PharmacyChatState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
      builder: (context, state) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 20,
            right: 20,
            top: 10,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top handle
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  isAr ? 'رفع الروشتة الطبية' : 'Upload Prescription (روشتة)',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: emeraldGreen,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isAr
                      ? 'سيقوم الصيدلي بمراجعتها وبدء محادثة مباشرة معك'
                      : 'The pharmacist will review it and start a live chat with you',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                if (_selectedImage == null)
                  Row(
                    children: [
                      Expanded(
                        child: _OptionCard(
                          icon: Icons.camera_alt_rounded,
                          title: 'Take Photo',
                          titleAr: 'التقاط صورة',
                          color: emeraldGreen,
                          onTap: () => _pickImage(ImageSource.camera),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _OptionCard(
                          icon: Icons.photo_library_rounded,
                          title: 'Upload Gallery',
                          titleAr: 'معرض الصور',
                          color: Colors.orangeAccent,
                          onTap: () => _pickImage(ImageSource.gallery),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      // Preview selected image
                      Stack(
                        children: [
                          Container(
                            height: 220,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              image: DecorationImage(
                                image: kIsWeb
                                    ? NetworkImage(_selectedImage!.path)
                                    : FileImage(io.File(_selectedImage!.path))
                                        as ImageProvider,
                                fit: BoxFit.cover,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                          ),
                          // Premium badge
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: emeraldGreen,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: emeraldGreen.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded,
                                      color: Colors.white, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    isAr ? 'جاهزة للإرسال' : 'Ready to Send',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Premium close button
                          Positioned(
                            top: 12,
                            right: 12,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedImage = null),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(Icons.close,
                                    color: Colors.grey.shade800, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Upload / Progress button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: state.isUploadingPrescription
                              ? null
                              : _uploadPrescription,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: emeraldGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                            shadowColor: emeraldGreen.withValues(alpha: 0.4),
                          ),
                          child: state.isUploadingPrescription
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      isAr
                                          ? 'جاري إرسال الروشتة...'
                                          : 'Uploading Prescription...',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  isAr
                                      ? 'إرسال إلى الصيدلية'
                                      : 'Send to Pharmacy',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String titleAr;
  final Color color;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.titleAr,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                titleAr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
