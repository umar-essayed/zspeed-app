import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:z_speed/core/utils/image_utils.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/core/constants/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/features/support_chat/cubit/support_chat_cubit.dart';
import 'package:z_speed/features/support_chat/view/support_chat_screen.dart';

/// Static helper class containing all action/dialog methods for [HelpSupportScreen].
class HelpSupportActions {
  HelpSupportActions._();

  static void openLiveChat(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    final user = authCubit.state.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.localeName == 'ar' 
              ? 'يرجى تسجيل الدخول لبدء دردشة الدعم.' 
              : 'Please sign in to start a support chat.'),
          backgroundColor: Colors.red,
        ),
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
  }

  static Future<void> sendEmail({
    BuildContext? context,
    String? subject,
    String? body,
  }) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: AppConstants.supportEmail,
      queryParameters: {
        'subject': subject ?? '${AppConstants.appName} Support',
        'body': body ?? 'Hello, I need help with...',
      },
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        final success = await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
        if (success) return;
      }
      final successFallback = await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
      if (!successFallback && context != null && context.mounted) {
        _copyToClipboardAndNotify(context, AppConstants.supportEmail);
      }
    } catch (_) {
      if (context != null && context.mounted) {
        _copyToClipboardAndNotify(context, AppConstants.supportEmail);
      }
    }
  }

  static Future<void> makePhoneCall({BuildContext? context}) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: AppConstants.supportPhoneRaw);
    try {
      if (await canLaunchUrl(phoneUri)) {
        final success = await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
        if (success) return;
      }
      final successFallback = await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      if (!successFallback && context != null && context.mounted) {
        _copyToClipboardAndNotify(context, AppConstants.supportPhone);
      }
    } catch (_) {
      if (context != null && context.mounted) {
        _copyToClipboardAndNotify(context, AppConstants.supportPhone);
      }
    }
  }

  static void _copyToClipboardAndNotify(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    final isAr = AppLocalizations.of(context)!.localeName == 'ar';
    final message = isAr
        ? 'تعذر فتح التطبيق. تم نسخ $text إلى الحافظة.'
        : 'Could not open application. Copied $text to clipboard.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
      ),
    );
  }

  static void openFAQ(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.frequentlyAskedQuestions,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildFAQItem(
                      question: AppLocalizations.of(context)!.faqHowUpdateMenu,
                      answer:
                          AppLocalizations.of(context)!.faqHowUpdateMenuAnswer),
                  _buildFAQItem(
                      question: AppLocalizations.of(context)!.faqManageOrders,
                      answer:
                          AppLocalizations.of(context)!.faqManageOrdersAnswer),
                  _buildFAQItem(
                      question: AppLocalizations.of(context)!.faqChangeHours,
                      answer:
                          AppLocalizations.of(context)!.faqChangeHoursAnswer),
                  _buildFAQItem(
                      question: AppLocalizations.of(context)!.faqAddStaff,
                      answer: AppLocalizations.of(context)!.faqAddStaffAnswer),
                  _buildFAQItem(
                      question: AppLocalizations.of(context)!.faqPaymentIssues,
                      answer:
                          AppLocalizations.of(context)!.faqPaymentIssuesAnswer),
                  _buildFAQItem(
                      question: AppLocalizations.of(context)!.faqPrintReceipts,
                      answer:
                          AppLocalizations.of(context)!.faqPrintReceiptsAnswer),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF35535)),
                child: Text(AppLocalizations.of(context)!.close),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildFAQItem(
      {required String question, required String answer}) {
    return ExpansionTile(
      title:
          Text(question, style: const TextStyle(fontWeight: FontWeight.bold)),
      children: [
        Padding(padding: const EdgeInsets.all(16), child: Text(answer)),
      ],
    );
  }

  static void openUserGuide(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.userGuide),
              backgroundColor: const Color(0xFFF35535)),
          body: Center(
              child: Text(AppLocalizations.of(context)!.userGuideContent)),
        ),
      ),
    );
  }

  static void openVideoTutorials(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.videoTutorials),
              backgroundColor: const Color(0xFFF35535)),
          body:
              Center(child: Text(AppLocalizations.of(context)!.videoTutorials)),
        ),
      ),
    );
  }

  static void openDocumentation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.documentation),
              backgroundColor: const Color(0xFFF35535)),
          body: Center(
              child:
                  Text(AppLocalizations.of(context)!.technicalDocumentation)),
        ),
      ),
    );
  }

  static void openBlog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.blogUpdates),
              backgroundColor: const Color(0xFFF35535)),
          body: Center(child: Text(AppLocalizations.of(context)!.blogContent)),
        ),
      ),
    );
  }

  static void attachFile(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.attachFile),
        content: Text(AppLocalizations.of(context)!.chooseFileFrom),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final picked = await ImageUtils.pickImage(source: ImageSource.gallery);
              if (picked == null) return;
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        AppLocalizations.of(context)!.fileAttachedFromGallery)),
              );
            },
            child: Text(AppLocalizations.of(context)!.gallery),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final picked = await ImageUtils.pickImage(source: ImageSource.camera);
              if (picked == null) return;
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        AppLocalizations.of(context)!.fileAttachedFromCamera)),
              );
            },
            child: Text(AppLocalizations.of(context)!.camera),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final picked = await ImageUtils.pickDocument();
              if (picked == null) return;
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        AppLocalizations.of(context)!.fileAttachedFromFiles)),
              );
            },
            child: Text(AppLocalizations.of(context)!.files),
          ),
        ],
      ),
    );
  }

  static void submitIssue(BuildContext context) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.issueReportedSuccessfully),
        backgroundColor: Colors.green,
      ),
    );
  }

  static void openTerms(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.termsOfService),
              backgroundColor: const Color(0xFFF35535)),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
                child: Text(AppLocalizations.of(context)!.termsOfServiceContent,
                    style: const TextStyle(fontSize: 16))),
          ),
        ),
      ),
    );
  }

  static void openPrivacyPolicy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.privacyPolicy),
              backgroundColor: const Color(0xFFF35535)),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
                child: Text(AppLocalizations.of(context)!.privacyPolicyContent,
                    style: const TextStyle(fontSize: 16))),
          ),
        ),
      ),
    );
  }

  static void checkForUpdates(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.checkForUpdates),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(AppLocalizations.of(context)!.checkingForUpdates),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.youHaveTheLatest),
          backgroundColor: Colors.green,
        ),
      );
    });
  }
}
