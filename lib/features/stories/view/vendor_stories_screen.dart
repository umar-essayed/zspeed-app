import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/injection.dart';
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_dashboard_cubit.dart';
import 'package:z_speed/features/stories/cubit/vendor_stories_cubit.dart';
import 'package:z_speed/features/stories/cubit/vendor_stories_state.dart';
import 'package:z_speed/features/stories/widgets/add_story_dialog.dart';
import 'package:z_speed/features/stories/model/story.dart';
import 'package:z_speed/core/enums/user_enums.dart';

class VendorStoriesScreen extends StatelessWidget {
  const VendorStoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final dashboardState = context.watch<RestaurantDashboardCubit>().state;
    final restaurant = dashboardState.restaurant;

    if (restaurant == null) {
      return Scaffold(
        body: Center(
          child: Text(
            locale == 'ar'
                ? 'لم يتم العثور على بيانات المتجر.'
                : 'Vendor data not found.',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return BlocProvider<VendorStoriesCubit>(
      create: (_) => getIt<VendorStoriesCubit>()..loadVendorStories(restaurant.id),
      child: _VendorStoriesView(
        restaurantId: restaurant.id,
        restaurantName: restaurant.name,
        restaurantLogoUrl: restaurant.logoUrl,
        restaurantVendorType: restaurant.vendorType,
      ),
    );
  }
}

class _VendorStoriesView extends StatelessWidget {
  final String restaurantId;
  final String restaurantName;
  final String restaurantLogoUrl;
  final VendorType restaurantVendorType;

  const _VendorStoriesView({
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantLogoUrl,
    required this.restaurantVendorType,
  });

  String _formatTimeRemaining(DateTime expiresAt, String locale) {
    final difference = expiresAt.difference(DateTime.now());
    if (difference.isNegative) {
      return locale == 'ar' ? 'منتهية' : 'Expired';
    }
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    if (hours > 0) {
      return locale == 'ar' ? 'تبقي $hours ساعة' : '$hours hrs left';
    } else {
      return locale == 'ar' ? 'تبقي $minutes دقيقة' : '$minutes mins left';
    }
  }

  void _showAddStoryDialog(BuildContext context, VendorStoriesState state) {
    final cubit = context.read<VendorStoriesCubit>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: cubit,
          child: BlocBuilder<VendorStoriesCubit, VendorStoriesState>(
            builder: (context, state) {
              return AddStoryDialog(
                restaurantId: restaurantId,
                isUploading: state.isUploading,
                onPost: (file, caption, menuItemId) async {
                  await cubit.addStory(
                    vendorId: restaurantId,
                    vendorName: restaurantName,
                    vendorLogoUrl: restaurantLogoUrl,
                    vendorType: restaurantVendorType,
                    imageFile: file,
                    caption: caption,
                    menuItemId: menuItemId,
                  );
                  if (context.mounted) {
                    final freshState = cubit.state;
                    if (freshState.error == null) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            Localizations.localeOf(context).languageCode == 'ar'
                                ? 'تم رفع القصة وهي في انتظار موافقة الإدارة!'
                                : 'Story submitted! Awaiting admin approval.',
                          ),
                          backgroundColor: const Color(0xFFF35535),
                        ),
                      );
                    }
                  }
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(Story story, String locale) {
    Color badgeColor;
    String text;

    switch (story.status) {
      case StoryStatus.approved:
        badgeColor = Colors.green;
        text = _formatTimeRemaining(story.expiresAt, locale);
        break;
      case StoryStatus.rejected:
        badgeColor = Colors.red;
        text = locale == 'ar' ? 'مرفوض' : 'Rejected';
        break;
      case StoryStatus.pending:
        badgeColor = Colors.orange;
        text = locale == 'ar' ? 'قيد المراجعة' : 'Pending Review';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isMobile = MediaQuery.of(context).size.width < 768;
    const orangeColor = Color(0xFFF35535);

    return BlocConsumer<VendorStoriesCubit, VendorStoriesState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          // Show AppBar only on non-mobile platforms (drawer/hub handles it on mobile)
          appBar: isMobile
              ? null
              : AppBar(
                  title: Text(locale == 'ar' ? 'إدارة القصص اليومية' : 'Manage Daily Stories'),
                  elevation: 0,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: orangeColor,
            onPressed: () => _showAddStoryDialog(context, state),
            child: const Icon(Icons.add_a_photo, color: Colors.white),
          ),
          body: state.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(orangeColor),
                  ),
                )
              : state.stories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            size: 72,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            locale == 'ar' ? 'لا توجد قصص حالياً' : 'No stories right now',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              locale == 'ar'
                                  ? 'انشر العروض اليومية، الأطباق الجديدة أو كواليس العمل لزيادة تفاعل عملائك! ستخضع قصصك لمراجعة الإدارة قبل النشر.'
                                  : 'Share daily promos or new dishes! Stories will be reviewed by admin before going live.',
                              style: const TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              locale == 'ar'
                                  ? 'قصص المتجر (${state.stories.length})'
                                  : 'Store Stories (${state.stories.length})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Expanded(
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 180,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.65,
                              ),
                              itemCount: state.stories.length,
                              itemBuilder: (context, index) {
                                final story = state.stories[index];
                                return Card(
                                  clipBehavior: Clip.antiAlias,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      // Image/Video
                                      story.mediaType == 'video' && story.thumbnailUrl == null
                                          ? Container(
                                              color: Colors.grey[900],
                                              child: const Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.video_library_outlined,
                                                      color: Colors.white70,
                                                      size: 36,
                                                    ),
                                                    SizedBox(height: 8),
                                                    Icon(
                                                      Icons.play_circle_fill,
                                                      color: Colors.white38,
                                                      size: 20,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                          : CachedNetworkImage(
                                              imageUrl: story.thumbnailUrl ?? story.mediaUrl,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Container(
                                                color: Colors.grey[200],
                                                child: const Center(
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation(orangeColor),
                                                  ),
                                                ),
                                              ),
                                              errorWidget: (context, url, error) => Container(
                                                color: Colors.grey[200],
                                                child: const Icon(Icons.error_outline),
                                              ),
                                            ),

                                      Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.black54,
                                              Colors.transparent,
                                              Colors.transparent,
                                              Colors.black87,
                                            ],
                                            stops: [0.0, 0.25, 0.75, 1.0],
                                          ),
                                        ),
                                      ),

                                      // Status badge (Top Left)
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        child: _buildStatusBadge(story, locale),
                                      ),

                                      // Delete button (Top Right)
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.white,
                                          ),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (dialogCtx) => AlertDialog(
                                                title: Text(locale == 'ar' ? 'حذف القصة؟' : 'Delete Story?'),
                                                content: Text(
                                                  locale == 'ar'
                                                      ? 'هل أنت متأكد من رغبتك في حذف هذه القصة؟ لا يمكن التراجع عن هذا الإجراء.'
                                                      : 'Are you sure you want to delete this story? This action cannot be undone.',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(dialogCtx),
                                                    child: Text(
                                                      locale == 'ar' ? 'إلغاء' : 'Cancel',
                                                      style: const TextStyle(color: Colors.grey),
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      context.read<VendorStoriesCubit>().deleteStory(
                                                            story.id,
                                                            story.mediaUrl,
                                                          );
                                                      Navigator.pop(dialogCtx);
                                                    },
                                                    child: Text(
                                                      locale == 'ar' ? 'حذف' : 'Delete',
                                                      style: const TextStyle(color: Colors.red),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),

                                      // Caption (Bottom)
                                      if (story.caption != null && story.caption!.isNotEmpty)
                                        Positioned(
                                          bottom: 8,
                                          left: 8,
                                          right: 8,
                                          child: Text(
                                            story.caption!,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
        );
      },
    );
  }
}
