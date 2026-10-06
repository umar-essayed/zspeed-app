import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/constants/app_constants.dart';
import 'package:z_speed/core/utils/app_version_helper.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/features/support_chat/cubit/support_chat_cubit.dart';
import 'package:z_speed/features/support_chat/view/support_chat_screen.dart';

/// Extracted informational dialogs from SettingsPage:
/// delivery area, support / FAQ, privacy policy, terms of service, about.
///
/// Each dialog is exposed as a static method so the thin shell can call
/// e.g. `SettingsInfoDialogs.showDeliveryArea(context: ..., showSnackBar: ...)`.
class SettingsInfoDialogs {
  SettingsInfoDialogs._();

  // ════════════════════════════════════════════════════════════════
  // ABOUT DIALOG
  // ════════════════════════════════════════════════════════════════

  static void showAbout({required BuildContext context}) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/icon.png',
                width: 72,
                height: 72,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.delivery_dining,
                  size: 64,
                  color: Color(0xFFF35535),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppVersionHelper.appName.isNotEmpty ? AppVersionHelper.appName : 'Z Speed',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF35535).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                AppVersionHelper.displayVersion,
                style: const TextStyle(
                  color: Color(0xFFF35535),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isAr
                  ? 'تطبيق زاد سبيد لتوصيل الطلبات بسرعة وسهولة.'
                  : 'Fast Delivery, Delivered. Experience seamless ordering and lightning fast delivery.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '© ${DateTime.now().year} Z Speed. All rights reserved.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              isAr ? 'إغلاق' : 'Close',
              style: const TextStyle(color: Color(0xFFF35535)),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // DELIVERY AREA
  // ════════════════════════════════════════════════════════════════

  static void showDeliveryArea({
    required BuildContext context,
    required void Function(String message, {Color color}) showSnackBar,
  }) {
    String selectedArea = "New Administrative Capital";
    final List<String> areas = [
      "New Administrative Capital",
      "Cairo",
      "Giza",
      "Alexandria",
      "Sharm El Sheikh",
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              "Select Delivery Area",
              style: TextStyle(color: Colors.black),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: RadioGroup<String>(
                // ignore: deprecated_member_use
                groupValue: selectedArea,
                // ignore: deprecated_member_use
                onChanged: (value) {
                  setState(() => selectedArea = value!);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...areas.map((area) => RadioListTile(
                          title: Text(
                            area,
                            style: const TextStyle(color: Colors.black),
                          ),
                          value: area,
                          activeColor: const Color(0xFFF35535),
                        )),
                    const SizedBox(height: 16),
                    const Text(
                      "Note: Delivery fees may vary by area",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.black54),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  showSnackBar("Delivery area set to $selectedArea");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF35535),
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  "Save",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // SUPPORT / FAQ
  // ════════════════════════════════════════════════════════════════

  static void showSupport({
    required BuildContext context,
    required void Function(String message, {Color color}) showSnackBar,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        actionsPadding: const EdgeInsets.fromLTRB(0, 0, 8, 8),
        title: const Text(
          "Support & Contact",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildContactOption(
              icon: Icons.email,
              title: "Email",
              subtitle: AppConstants.supportEmail,
              onTap: () => showSnackBar("Email app opened"),
            ),
            _buildContactOption(
              icon: Icons.phone,
              title: "Phone",
              subtitle: AppConstants.supportPhone,
              onTap: () => showSnackBar("Dialing support..."),
            ),
            _buildContactOption(
              icon: Icons.chat,
              title: "Live Chat",
              subtitle: "Available 24/7",
              onTap: () {
                Navigator.pop(context); // Close the dialog
                
                final authCubit = context.read<AuthCubit>();
                final user = authCubit.state.user;
                if (user == null) {
                  final isAr = Localizations.localeOf(context).languageCode == 'ar';
                  showSnackBar(
                    isAr ? 'يرجى تسجيل الدخول لبدء دردشة الدعم.' : 'Please sign in to start a support chat.',
                    color: Colors.red,
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider<SupportChatCubit>(
                      create: (_) => SupportChatCubit(),
                      child: const SupportChatScreen(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            const Divider(color: Colors.grey, height: 1),
            const SizedBox(height: 12),
            const Text(
              "Frequently Asked Questions",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            ...[
              "How to cancel a ride?",
              "How to apply promo code?",
              "How to rate a driver?"
            ].map((question) => ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(
                    question,
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                  ),
                  trailing:
                      const Icon(Icons.chevron_right, color: Color(0xFFF35535), size: 20),
                  onTap: () =>
                      _showFAQDetails(context: context, question: question),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Close",
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  static void _showFAQDetails({
    required BuildContext context,
    required String question,
  }) {
    String answer = "";

    switch (question) {
      case "How to cancel a ride?":
        answer =
            "To cancel a ride:\n\n1. Go to 'My Rides' in the app\n2. Select the active ride\n3. Tap 'Cancel Ride'\n4. Confirm cancellation\n\nNote: Free cancellation within 5 minutes of booking.";
        break;
      case "How to apply promo code?":
        answer =
            "To apply a promo code:\n\n1. During checkout, tap 'Add Promo Code'\n2. Enter your promo code\n3. Tap 'Apply'\n4. Discount will be automatically applied\n\nNote: Promo codes are one-time use only.";
        break;
      case "How to rate a driver?":
        answer =
            "To rate a driver:\n\n1. After ride completion, you'll see a rating screen\n2. Select stars (1-5)\n3. Add optional feedback\n4. Tap 'Submit Rating'\n\nNote: Ratings are anonymous and help improve service quality.";
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          question,
          style: const TextStyle(color: Colors.black, fontSize: 16),
        ),
        content: Text(
          answer,
          style: const TextStyle(color: Colors.black54, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Close",
              style: TextStyle(color: Color(0xFFF35535)),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      color: Colors.white,
      child: ListTile(
        visualDensity: VisualDensity.compact,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: Icon(icon, color: const Color(0xFFF35535), size: 24),
        title: Text(
          title,
          style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFFF35535), size: 18),
        onTap: onTap,
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // PRIVACY POLICY
  // ════════════════════════════════════════════════════════════════

  static void showPrivacy({required BuildContext context}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          "Privacy Policy",
          style: TextStyle(color: Colors.black),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Effective Date: January 2024",
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const SizedBox(height: 16),
              const Text(
                "We collect the following information:",
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 8),
              ...[
                "Personal details (name, email, phone)",
                "Location data for ride matching",
                "Payment information",
                "Ride history and preferences"
              ].map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: Colors.green.shade600, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(
                          item,
                          style: const TextStyle(color: Colors.black),
                        )),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
              const Text(
                "Your data is secure with us. We use industry-standard encryption and never share your data without consent.",
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Close",
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // TERMS OF SERVICE
  // ════════════════════════════════════════════════════════════════

  static void showTerms({
    required BuildContext context,
    required void Function(String message, {Color color}) showSnackBar,
  }) {
    bool agreed = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              "Terms of Service",
              style: TextStyle(color: Colors.black),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  _buildTermItem(
                    "Age Requirement",
                    "You must be at least 18 years old to use our services.",
                  ),
                  _buildTermItem(
                    "Service Area",
                    "Currently available only in selected Egyptian cities.",
                  ),
                  _buildTermItem(
                    "Payment Terms",
                    "All payments must be completed before or during the ride.",
                  ),
                  _buildTermItem(
                    "Cancellation Policy",
                    "Free cancellation within 5 minutes of booking.",
                  ),
                  _buildTermItem(
                    "Safety Guidelines",
                    "Both drivers and riders must follow safety protocols.",
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text(
                      "I agree to the Terms of Service",
                      style: TextStyle(color: Colors.black),
                    ),
                    value: agreed,
                    // ignore: deprecated_member_use
                    onChanged: (value) {
                      setState(() => agreed = value ?? false);
                    },
                    activeColor: const Color(0xFFF35535),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: !agreed
                    ? null
                    : () {
                        Navigator.pop(context);
                        showSnackBar("Terms accepted successfully!",
                            color: Colors.green);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF35535),
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  "Accept & Continue",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Widget _buildTermItem(String title, String description) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
          const Divider(height: 16, color: Colors.grey),
        ],
      ),
    );
  }
}
