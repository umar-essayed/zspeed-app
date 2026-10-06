import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:z_speed/core/injection.dart';
import 'package:z_speed/core/utils/app_version_helper.dart';
import 'package:z_speed/features/review/datasource/review_firebase_datasource.dart';
import 'package:z_speed/features/review/model/review.dart';
import 'package:z_speed/features/settings/widgets/settings_info_dialogs.dart';
import 'package:z_speed/l10n/app_localizations.dart';

/// Promotions management page for restaurants.
///
/// MVP: placeholder with "Coming Soon" UI.
/// Future: Create/manage promo codes, discounts, special offers.
class RestaurantPromotionsPage extends StatelessWidget {
  const RestaurantPromotionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ComingSoonPage(
      icon: Icons.local_offer,
      title: AppLocalizations.of(context)!.promotions,
      subtitle: AppLocalizations.of(context)!.promotionsSubtitle,
      features: [
        _FeatureItem(
          icon: Icons.discount_outlined,
          title: AppLocalizations.of(context)!.discountCodes,
          description: AppLocalizations.of(context)!.discountCodesDescription,
        ),
        _FeatureItem(
          icon: Icons.celebration_outlined,
          title: AppLocalizations.of(context)!.specialOffers,
          description: AppLocalizations.of(context)!.specialOffersDescription,
        ),
        _FeatureItem(
          icon: Icons.schedule_outlined,
          title: AppLocalizations.of(context)!.scheduledPromotions,
          description:
              AppLocalizations.of(context)!.scheduledPromotionsDescription,
        ),
        _FeatureItem(
          icon: Icons.bar_chart,
          title: AppLocalizations.of(context)!.performanceTracking,
          description:
              AppLocalizations.of(context)!.performanceTrackingDescription,
        ),
      ],
    );
  }
}

/// Reviews management page for restaurants.
///
/// MVP: placeholder with "Coming Soon" UI.
/// Future: View customer reviews, reply, filter by rating.
/// Reviews management page for restaurants.
///
/// Real-time dashboard for restaurant owners to view customer ratings,
/// feedback breakdown, and customer review comments.
class RestaurantReviewsPage extends StatelessWidget {
  final String restaurantId;

  const RestaurantReviewsPage({
    super.key,
    this.restaurantId = '',
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFFF35535);

    if (restaurantId.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                l.noReviewsYet,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.reviewsTitle),
        elevation: 0,
      ),
      body: StreamBuilder<List<Review>>(
        stream: getIt<ReviewFirebaseDatasource>().streamReviews(restaurantId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  '${l.failedSubmitReview}\n(${snapshot.error})',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final reviews = snapshot.data ?? [];

          if (reviews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.rate_review_outlined,
                      size: 64,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.noReviewsYet,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      l.reviewsSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Calculate statistics
          final totalReviews = reviews.length;
          final averageRating = reviews.fold<double>(
                  0.0, (sum, r) => sum + r.rating) /
              totalReviews;

          // Star breakdown (1 to 5)
          final breakdown = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
          for (final r in reviews) {
            final star = r.rating.round().clamp(1, 5);
            breakdown[star] = (breakdown[star] ?? 0) + 1;
          }

          final dateFormat = DateFormat.yMMMd();

          return CustomScrollView(
            slivers: [
              // Summary Header Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    averageRating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFFC107),
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: List.generate(5, (i) {
                                      final star = i + 1;
                                      return Icon(
                                        star <= averageRating.round()
                                            ? Icons.star_rounded
                                            : Icons.star_outline_rounded,
                                        color: const Color(0xFFFFC107),
                                        size: 20,
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l.reviewsCount(totalReviews),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  children: List.generate(5, (index) {
                                    final star = 5 - index;
                                    final count = breakdown[star] ?? 0;
                                    final pct = totalReviews > 0
                                        ? count / totalReviews
                                        : 0.0;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 2),
                                      child: Row(
                                        children: [
                                          Text(
                                            '$star',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.star_rounded,
                                            size: 14,
                                            color: Color(0xFFFFC107),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: pct,
                                                minHeight: 6,
                                                backgroundColor: isDark
                                                    ? Colors.grey.shade800
                                                    : Colors.grey.shade200,
                                                valueColor:
                                                    const AlwaysStoppedAnimation<
                                                        Color>(
                                                  Color(0xFFFFC107),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            width: 24,
                                            child: Text(
                                              '$count',
                                              textAlign: TextAlign.end,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark
                                                    ? Colors.grey.shade400
                                                    : Colors.grey.shade600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Title for reviews list
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Text(
                    l.customerFeedback,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // List of review cards
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final review = reviews[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2C2C2E)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: isDark
                                ? Colors.white10
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: primaryColor.withValues(alpha: 0.1),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    size: 20,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Row(
                                            children: List.generate(5, (i) {
                                              final star = i + 1;
                                              return Icon(
                                                star <= review.rating
                                                    ? Icons.star_rounded
                                                    : Icons.star_outline_rounded,
                                                color: const Color(0xFFFFC107),
                                                size: 16,
                                              );
                                            }),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            review.rating.toStringAsFixed(1),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  dateFormat.format(review.createdAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                            if (review.comment != null &&
                                review.comment!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                review.comment!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.grey.shade200
                                      : Colors.black87,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                    childCount: reviews.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Support page for restaurant owners.
class RestaurantSupportPage extends StatelessWidget {
  const RestaurantSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF35535);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [orange, orange.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.support_agent, size: 40, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)!.howCanWeHelp,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.supportTeamAssist,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Contact options
          Text(
            AppLocalizations.of(context)!.contactUs,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 12),

          _ContactCard(
            icon: Icons.email_outlined,
            title: AppLocalizations.of(context)!.emailSupport,
            subtitle: 'support@zspeed.app',
            color: const Color(0xFF2196F3),
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _ContactCard(
            icon: Icons.phone_outlined,
            title: AppLocalizations.of(context)!.phoneSupport,
            subtitle: '+20 100 000 0000',
            color: const Color(0xFF4CAF50),
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _ContactCard(
            icon: Icons.chat_outlined,
            title: AppLocalizations.of(context)!.liveChat,
            subtitle: AppLocalizations.of(context)!.liveChatAvailability,
            color: orange,
            onTap: () {},
          ),

          const SizedBox(height: 28),

          // FAQ
          Text(
            AppLocalizations.of(context)!.faq,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 12),

          _FaqItem(
            question: AppLocalizations.of(context)!.faqQuestion1,
            answer: AppLocalizations.of(context)!.faqAnswer1,
          ),
          _FaqItem(
            question: AppLocalizations.of(context)!.faqQuestion2,
            answer: AppLocalizations.of(context)!.faqAnswer2,
          ),
          _FaqItem(
            question: AppLocalizations.of(context)!.faqQuestion3,
            answer: AppLocalizations.of(context)!.faqAnswer3,
          ),
          _FaqItem(
            question: AppLocalizations.of(context)!.faqQuestion4,
            answer: AppLocalizations.of(context)!.faqAnswer4,
          ),
          _FaqItem(
            question: AppLocalizations.of(context)!.faqQuestion5,
            answer: AppLocalizations.of(context)!.faqAnswer5,
          ),
        ],
      ),
    );
  }
}

/// About page for the restaurant app.
class RestaurantAboutPage extends StatelessWidget {
  const RestaurantAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF35535);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Logo
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: orange.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.delivery_dining,
              size: 48,
              color: orange,
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Z Speed',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          Text(
            AppLocalizations.of(context)!.restaurantDashboard,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF718096),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              AppVersionHelper.displayVersion,
              style: const TextStyle(
                color: orange,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Info cards
          _AboutCard(
            icon: Icons.business,
            title: AppLocalizations.of(context)!.aboutZSpeed,
            content: AppLocalizations.of(context)!.aboutZSpeedDescription,
          ),
          const SizedBox(height: 12),

          // Links
          _AboutLinkTile(
            icon: Icons.description_outlined,
            title: AppLocalizations.of(context)!.termsOfService,
            onTap: () => SettingsInfoDialogs.showTerms(
              context: context,
              showSnackBar: (message, {Color? color}) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: color,
                  ),
                );
              },
            ),
          ),
          _AboutLinkTile(
            icon: Icons.privacy_tip_outlined,
            title: AppLocalizations.of(context)!.privacyPolicy,
            onTap: () => SettingsInfoDialogs.showPrivacy(context: context),
          ),
          _AboutLinkTile(
            icon: Icons.article_outlined,
            title: AppLocalizations.of(context)!.openSourceLicenses,
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'Z Speed',
                applicationVersion: AppVersionHelper.fullVersion,
                applicationIcon: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.delivery_dining,
                      size: 32, color: orange),
                ),
              );
            },
          ),

          const SizedBox(height: 32),
          Text(
            AppLocalizations.of(context)!.copyright,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shared "Coming Soon" template
// ═══════════════════════════════════════════════════════════════════════════════

class _ComingSoonPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<_FeatureItem> features;

  const _ComingSoonPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF35535);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: orange),
          ),
          const SizedBox(height: 20),

          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF718096),
            ),
          ),
          const SizedBox(height: 12),

          // Coming soon badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.construction,
                    size: 16, color: Color(0xFFF57F17)),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context)!.comingSoon,
                  style: const TextStyle(
                    color: Color(0xFFF57F17),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Feature list
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              AppLocalizations.of(context)!.whatsPlanned,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(height: 16),

          ...features.map((f) => Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: orange.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(f.icon, size: 20, color: orange),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              f.description,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF718096),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// Support page helpers
// ═══════════════════════════════════════════════════════════════════════════════

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 10),
                Text(
                  widget.answer,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF718096),
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// About page helpers
// ═══════════════════════════════════════════════════════════════════════════════

class _AboutCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _AboutCard({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFFF35535)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF718096),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutLinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _AboutLinkTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF718096), size: 22),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2D3748),
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }
}
