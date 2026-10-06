import 'package:z_speed/l10n/app_localizations.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/features/restaurant_owner/widgets/restaurant_form_styles.dart';
import 'package:z_speed/features/restaurant_owner/widgets/restaurant_form_widgets.dart';

/// Step 5: Branding — Logo & Cover Image
///
/// Two image pickers with preview thumbnails.
class BrandingStep extends StatelessWidget {
  final XFile? logoImage;
  final XFile? coverImage;
  final VoidCallback onPickLogo;
  final VoidCallback onPickCover;
  final GlobalKey<FormState> formKey;
  final VendorType vendorType;

  const BrandingStep({
    super.key,
    required this.logoImage,
    required this.coverImage,
    required this.onPickLogo,
    required this.onPickCover,
    required this.formKey,
    this.vendorType = VendorType.restaurant,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(RestaurantFormStyles.horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RestaurantFormSectionHeader(
              title: AppLocalizations.of(context)!.vendorBrandingTitle(vendorType.getLocalizedLabel(AppLocalizations.of(context)!)),
              subtitle: AppLocalizations.of(context)!.uploadLogoCover,
              icon: Icons.brush_outlined,
            ),

            // Logo
            Text(AppLocalizations.of(context)!.vendorLogoLabel(vendorType.getLocalizedLabel(AppLocalizations.of(context)!)),
                style: RestaurantFormStyles.sectionTitle),
            const SizedBox(height: 4),
            Text(AppLocalizations.of(context)!.squareImageRecommended,
                style: RestaurantFormStyles.sectionSubtitle),
            const SizedBox(height: 12),
            Center(
              child: _ImagePickerCard(
                file: logoImage,
                placeholder: AppLocalizations.of(context)!.tapToUploadLogo,
                icon: Icons.add_a_photo_outlined,
                width: 160,
                height: 160,
                onTap: onPickLogo,
              ),
            ),
            const SizedBox(height: RestaurantFormStyles.sectionSpacing),

            // Cover Image
            Text(AppLocalizations.of(context)!.coverPhoto,
                style: RestaurantFormStyles.sectionTitle),
            const SizedBox(height: 4),
            Text(AppLocalizations.of(context)!.wideImageRecommended,
                style: RestaurantFormStyles.sectionSubtitle),
            const SizedBox(height: 12),
            _ImagePickerCard(
              file: coverImage,
              placeholder: AppLocalizations.of(context)!.tapToUploadCoverImage,
              icon: Icons.panorama_outlined,
              width: double.infinity,
              height: 180,
              onTap: onPickCover,
            ),

            if (logoImage == null || coverImage == null)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 12),
                child: Text(
                  AppLocalizations.of(context)!.imagesRequiredToProceed,
                  style: TextStyle(
                    color: RestaurantFormStyles.errorColor,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Image Picker Card ────────────────────────────────────────────────────────

class _ImagePickerCard extends StatelessWidget {
  final XFile? file;
  final String placeholder;
  final IconData icon;
  final double? width;
  final double height;
  final VoidCallback onTap;

  const _ImagePickerCard({
    required this.file,
    required this.placeholder,
    required this.icon,
    this.width,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RestaurantFormStyles.cardRadius),
        child: Ink(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: RestaurantFormStyles.uploadBg,
            borderRadius: BorderRadius.circular(RestaurantFormStyles.cardRadius),
            border: Border.all(
              color: file != null
                  ? RestaurantFormStyles.successColor
                  : RestaurantFormStyles.borderColor,
              width: file != null ? 2 : 1,
            ),
          ),
          child: file != null
              ? FutureBuilder<Uint8List>(
                  future: file!.readAsBytes(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(snapshot.data!, fit: BoxFit.cover),
                        PositionedDirectional(
                          bottom: 0,
                          start: 0,
                          end: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 8),
                            color: Colors.black54,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.edit,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  AppLocalizations.of(context)!.tapToChange,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon,
                        size: 36, color: RestaurantFormStyles.primaryColor),
                    const SizedBox(height: 8),
                    Text(
                      placeholder,
                      style: TextStyle(
                        color: RestaurantFormStyles.labelColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
