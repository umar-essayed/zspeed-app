import 'package:z_speed/l10n/app_localizations.dart';
// lib/pages/help_support_screen.dart
import 'package:flutter/material.dart';
import 'package:z_speed/core/constants/app_constants.dart';
import 'package:z_speed/features/help_support/widgets/help_support_actions.dart';
import 'package:z_speed/features/help_support/widgets/help_support_tiles.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.helpSupport),
        backgroundColor: const Color(0xFFF35535),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // ---- Contact Support ----
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _sectionDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.contactSupport,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(AppLocalizations.of(context)!.getInTouchWith,
                      style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 20),
                  ContactOptionTile(
                      icon: Icons.chat,
                      title: AppLocalizations.of(context)!.liveChat,
                      subtitle:
                          AppLocalizations.of(context)!.chatWithSupportAgents,
                      onTap: () => HelpSupportActions.openLiveChat(context)),
                  ContactOptionTile(
                      icon: Icons.email,
                      title: AppLocalizations.of(context)!.emailUs,
                      subtitle: AppConstants.supportEmail,
                      onTap: () => HelpSupportActions.sendEmail()),
                  ContactOptionTile(
                      icon: Icons.phone,
                      title: AppLocalizations.of(context)!.callUs,
                      subtitle: AppConstants.supportPhone,
                      onTap: () => HelpSupportActions.makePhoneCall()),
                  ContactOptionTile(
                      icon: Icons.help_outline,
                      title: AppLocalizations.of(context)!.faq,
                      subtitle: AppLocalizations.of(context)!
                          .frequentlyAskedQuestions,
                      onTap: () => HelpSupportActions.openFAQ(context)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ---- Resources ----
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _sectionDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.resources,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  ResourceCardTile(
                      icon: Icons.book,
                      title: AppLocalizations.of(context)!.userGuide,
                      description:
                          AppLocalizations.of(context)!.learnHowToUseApp,
                      onTap: () => HelpSupportActions.openUserGuide(context)),
                  ResourceCardTile(
                      icon: Icons.video_library,
                      title: AppLocalizations.of(context)!.videoTutorials,
                      description:
                          AppLocalizations.of(context)!.watchStepByStepGuides,
                      onTap: () =>
                          HelpSupportActions.openVideoTutorials(context)),
                  ResourceCardTile(
                      icon: Icons.description,
                      title: AppLocalizations.of(context)!.documentation,
                      description:
                          AppLocalizations.of(context)!.technicalDocumentation,
                      onTap: () =>
                          HelpSupportActions.openDocumentation(context)),
                  ResourceCardTile(
                      icon: Icons.newspaper,
                      title: AppLocalizations.of(context)!.blogAndUpdates,
                      description:
                          AppLocalizations.of(context)!.latestNewsAndUpdates,
                      onTap: () => HelpSupportActions.openBlog(context)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ---- Report Problem ----
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _sectionDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.reportAProblem,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(AppLocalizations.of(context)!.foundABugOr,
                      style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 20),
                  TextField(
                    decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.subject,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8))),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context)!.describeYourIssue,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        alignLabelWithHint: true),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      IconButton(
                          icon: const Icon(Icons.attach_file,
                              color: Color(0xFFF35535)),
                          onPressed: () =>
                              HelpSupportActions.attachFile(context)),
                      Text(AppLocalizations.of(context)!
                          .attachScreenshotsIfNeeded),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => HelpSupportActions.submitIssue(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF35535),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(AppLocalizations.of(context)!.submitReport),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ---- App Info ----
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _sectionDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.appInformation,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  InfoItemRow(
                      label: AppLocalizations.of(context)!.appVersion,
                      value: AppConstants.appVersion),
                  InfoItemRow(
                      label: AppLocalizations.of(context)!.buildNumber,
                      value: AppConstants.buildNumber),
                  InfoItemRow(
                      label: AppLocalizations.of(context)!.lastUpdated,
                      value: AppConstants.lastUpdated),
                  InfoItemRow(
                      label: AppLocalizations.of(context)!.developerLabel,
                      value: AppConstants.developer),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      TextButton(
                          onPressed: () =>
                              HelpSupportActions.openTerms(context),
                          child: Text(
                              AppLocalizations.of(context)!.termsOfService)),
                      TextButton(
                          onPressed: () =>
                              HelpSupportActions.openPrivacyPolicy(context),
                          child: Text(
                              AppLocalizations.of(context)!.privacyPolicy)),
                      TextButton(
                          onPressed: () =>
                              HelpSupportActions.checkForUpdates(context),
                          child: Text(
                              AppLocalizations.of(context)!.checkForUpdates)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// Shared section box decoration.
  BoxDecoration _sectionDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4)),
      ],
    );
  }
}
