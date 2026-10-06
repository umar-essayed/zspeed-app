import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/features/admin/cubit/admin_stories_cubit.dart';
import 'package:z_speed/features/admin/cubit/admin_stories_state.dart';
import 'package:z_speed/features/admin/model/admin_theme.dart';
import 'package:z_speed/features/stories/model/story.dart';
import 'package:intl/intl.dart';

class AdminStoriesView extends StatefulWidget {
  const AdminStoriesView({super.key});

  @override
  State<AdminStoriesView> createState() => _AdminStoriesViewState();
}

class _AdminStoriesViewState extends State<AdminStoriesView> {
  int _selectedFilterIndex = 0; // 0: Pending, 1: Approved, 2: Rejected, 3: All

  @override
  void initState() {
    super.initState();
    context.read<AdminStoriesCubit>().watchPendingStories();
  }

  void _showRejectDialog(BuildContext context, String storyId) {
    final reasonController = TextEditingController();
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(isArabic ? 'رفض القصة' : 'Reject Story'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic
                  ? 'يرجى تقديم سبب الرفض (اختياري):'
                  : 'Provide a reason for rejection (optional):',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: isArabic ? 'سبب الرفض...' : 'Rejection reason...',
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final reason = reasonController.text.trim();
              context.read<AdminStoriesCubit>().rejectStory(storyId, reason: reason);
              Navigator.pop(dialogCtx);
            },
            child: Text(isArabic ? 'تأكيد الرفض' : 'Confirm Reject'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Story story) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(isArabic ? 'حذف القصة؟' : 'Delete Story?'),
        content: Text(
          isArabic
              ? 'هل أنت متأكد من حذف هذه القصة نهائياً من النظام؟'
              : 'Are you sure you want to permanently delete this story?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              context.read<AdminStoriesCubit>().deleteStory(story.id, story.mediaUrl);
              Navigator.pop(dialogCtx);
            },
            child: Text(isArabic ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return BlocConsumer<AdminStoriesCubit, AdminStoriesState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: AdminTheme.errorRed,
            ),
          );
        }
        if (state.actionSuccessMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionSuccessMessage!),
              backgroundColor: AdminTheme.successGreen,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Story> currentStories;
        switch (_selectedFilterIndex) {
          case 0:
            currentStories = state.pendingStories;
            break;
          case 1:
            currentStories = state.approvedStories;
            break;
          case 2:
            currentStories = state.rejectedStories;
            break;
          case 3:
          default:
            currentStories = state.allStories;
            break;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isBounded = constraints.hasBoundedHeight;

            final Widget gridWidget = currentStories.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_awesome_motion_outlined,
                            size: 72,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isArabic ? 'لا توجد قصص في هذا التبويب' : 'No stories in this view',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isArabic
                                ? 'ستظهر قصص العارضين هنا فور إضافتها أو تغيير حالتها'
                                : 'Vendor stories will appear here when added or updated.',
                            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: !isBounded,
                    physics: isBounded ? null : const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 320,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.70,
                    ),
                    itemCount: currentStories.length,
                    itemBuilder: (context, index) {
                      final story = currentStories[index];
                      return _AdminStoryCard(
                        story: story,
                        isArabic: isArabic,
                        onApprove: () =>
                            context.read<AdminStoriesCubit>().approveStory(story.id),
                        onReject: () => _showRejectDialog(context, story.id),
                        onDelete: () => _showDeleteDialog(context, story),
                      );
                    },
                  );

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: isBounded ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  // Header
                  Text(
                    isArabic ? 'اعتماد وإدارة القصص' : 'Story Approvals & Moderation',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AdminTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isArabic
                        ? 'راجع واعتمد قصص العارضين أو قم بإدارتها.'
                        : 'Review and approve vendor stories to display to customers for 24 hours.',
                    style: TextStyle(fontSize: 13, color: AdminTheme.textLight),
                  ),
                  const SizedBox(height: 16),

                  // Filter Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          index: 0,
                          label: isArabic
                              ? 'قيد الانتظار (${state.pendingStories.length})'
                              : 'Pending (${state.pendingStories.length})',
                          badgeColor: AdminTheme.warningAmber,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          index: 1,
                          label: isArabic
                              ? 'المقبولة (${state.approvedStories.length})'
                              : 'Approved (${state.approvedStories.length})',
                          badgeColor: AdminTheme.successGreen,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          index: 2,
                          label: isArabic
                              ? 'المرفوضة (${state.rejectedStories.length})'
                              : 'Rejected (${state.rejectedStories.length})',
                          badgeColor: AdminTheme.errorRed,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          index: 3,
                          label: isArabic
                              ? 'الكل (${state.allStories.length})'
                              : 'All (${state.allStories.length})',
                          badgeColor: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Body Content
                  if (isBounded) Expanded(child: gridWidget) else gridWidget,
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip({
    required int index,
    required String label,
    required Color badgeColor,
  }) {
    final isSelected = _selectedFilterIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilterIndex = index;
          });
        }
      },
      selectedColor: badgeColor.withValues(alpha: 0.2),
      checkmarkColor: badgeColor,
      labelStyle: TextStyle(
        color: isSelected ? badgeColor : AdminTheme.textDark,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? badgeColor : AdminTheme.borderColor,
      ),
    );
  }
}

class _AdminStoryCard extends StatelessWidget {
  final Story story;
  final bool isArabic;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDelete;

  const _AdminStoryCard({
    required this.story,
    required this.isArabic,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(story.createdAt);

    Color statusColor;
    String statusText;

    switch (story.status) {
      case StoryStatus.approved:
        statusColor = AdminTheme.successGreen;
        statusText = isArabic ? 'مقبول' : 'Approved';
        break;
      case StoryStatus.rejected:
        statusColor = AdminTheme.errorRed;
        statusText = isArabic ? 'مرفوض' : 'Rejected';
        break;
      case StoryStatus.pending:
        statusColor = AdminTheme.warningAmber;
        statusText = isArabic ? 'معلق' : 'Pending';
        break;
    }

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Vendor Info Bar
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: story.vendorLogoUrl.isNotEmpty
                      ? CachedNetworkImageProvider(story.vendorLogoUrl)
                      : null,
                  child: story.vendorLogoUrl.isEmpty
                      ? const Icon(Icons.store, size: 16, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    story.vendorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: isArabic ? 'حذف' : 'Delete',
                ),
              ],
            ),
          ),

          // Media Preview
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                story.mediaType == 'video' && story.thumbnailUrl == null
                    ? Container(
                        color: Colors.black87,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_circle_fill, size: 40, color: Colors.white70),
                              SizedBox(height: 4),
                              Text('Video Story', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: story.thumbnailUrl ?? story.mediaUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.error_outline),
                        ),
                      ),
                if (story.caption != null && story.caption!.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.black.withValues(alpha: 0.65),
                      child: Text(
                        story.caption!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Details & Actions Footer
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formattedDate,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Text(
                      story.mediaType.toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ],
                ),
                if (story.rejectionReason != null && story.rejectionReason!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${isArabic ? 'السبب' : 'Reason'}: ${story.rejectionReason}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: Colors.redAccent),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (story.status != StoryStatus.rejected)
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AdminTheme.errorRed,
                            side: BorderSide(color: AdminTheme.errorRed),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: onReject,
                          icon: const Icon(Icons.close, size: 16),
                          label: Text(isArabic ? 'رفض' : 'Reject', style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                    if (story.status != StoryStatus.rejected && story.status != StoryStatus.approved)
                      const SizedBox(width: 8),
                    if (story.status != StoryStatus.approved)
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminTheme.successGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: onApprove,
                          icon: const Icon(Icons.check, size: 16),
                          label: Text(isArabic ? 'موافقة' : 'Approve', style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

