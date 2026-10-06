import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/features/stories/cubit/customer_stories_cubit.dart';
import 'package:z_speed/features/stories/cubit/customer_stories_state.dart';
import 'package:z_speed/features/stories/view/story_viewer_screen.dart';

class StoryCircleList extends StatelessWidget {
  final VendorType? vendorTypeFilter;

  const StoryCircleList({
    super.key,
    this.vendorTypeFilter,
  });

  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xFFF35535);

    return BlocBuilder<CustomerStoriesCubit, CustomerStoriesState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const _StoriesSkeleton();
        }

        final allGroups = state.groupedStories;
        
        // Filter groups by vendor type if a filter is specified
        final filteredGroups = vendorTypeFilter == null
            ? allGroups
            : allGroups.where((group) {
                return group.isNotEmpty && group.first.vendorType == vendorTypeFilter;
              }).toList();

        if (filteredGroups.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 105,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredGroups.length,
            itemBuilder: (context, index) {
              final group = filteredGroups[index];
              final firstStory = group.first;
              
              // Check if any story in this group is unseen
              final hasUnseen = group.any((s) => !state.seenStoryIds.contains(s.id));

              return Padding(
                padding: const EdgeInsets.only(right: 14),
                child: GestureDetector(
                  onTap: () {
                    // Open Story Viewer Screen
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<CustomerStoriesCubit>(),
                          child: StoryViewerScreen(
                            storyGroups: filteredGroups,
                            initialGroupIndex: index,
                          ),
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      // Story Circle Avatar
                      Container(
                        width: 70,
                        height: 70,
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: hasUnseen
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFFFFA726), // Orange
                                    Color(0xFFF35535), // Z-Speed Orange
                                    Color(0xFFE91E63), // Pink
                                    Color(0xFF9C27B0), // Purple
                                  ],
                                  begin: Alignment.bottomLeft,
                                  end: Alignment.topRight,
                                )
                              : null,
                          color: hasUnseen ? null : Colors.grey[300],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: CachedNetworkImage(
                              imageUrl: firstStory.thumbnailUrl ?? firstStory.mediaUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(orangeColor),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[100],
                                child: Icon(
                                  firstStory.mediaType == 'video'
                                      ? Icons.play_circle_fill
                                      : Icons.image,
                                  color: Colors.grey,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Vendor Name text
                      SizedBox(
                        width: 72,
                        child: Text(
                          firstStory.vendorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: hasUnseen ? FontWeight.bold : FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _StoriesSkeleton extends StatelessWidget {
  const _StoriesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 105,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Column(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.grey[200]!,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 50,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.grey[200]!,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
