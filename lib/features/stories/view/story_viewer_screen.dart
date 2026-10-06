import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/features/customer/view/vendor_menu_page.dart';
import 'package:z_speed/features/stories/cubit/customer_stories_cubit.dart';
import 'package:z_speed/features/stories/model/story.dart';
import 'package:video_player/video_player.dart';
import 'dart:developer' show log;

class StoryViewerScreen extends StatefulWidget {
  final List<List<Story>> storyGroups;
  final int initialGroupIndex;

  const StoryViewerScreen({
    super.key,
    required this.storyGroups,
    required this.initialGroupIndex,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late PageController _vendorPageController;
  late int _currentGroupIndex;
  int _currentStoryIndex = 0;
  
  late AnimationController _progressController;
  bool _isPaused = false;
  VideoPlayerController? _videoPlayerController;
  bool _isVideoLoading = false;
  VoidCallback? _videoPositionListener;

  @override
  void initState() {
    super.initState();
    _currentGroupIndex = widget.initialGroupIndex;
    _vendorPageController = PageController(initialPage: widget.initialGroupIndex);
    
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // For video stories, completion is driven by the video position listener.
        // Only fire here for image stories.
        if (_videoPlayerController == null) {
          _onStoryComplete();
        }
      }
    });

    // Start playing the first story
    _startStory();
  }

  @override
  void dispose() {
    if (_videoPositionListener != null && _videoPlayerController != null) {
      _videoPlayerController!.removeListener(_videoPositionListener!);
    }
    _vendorPageController.dispose();
    _progressController.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  List<Story> get _currentGroupStories => widget.storyGroups[_currentGroupIndex];
  Story get _activeStory => _currentGroupStories[_currentStoryIndex];

  void _startStory() {
    // Remove any existing video position listener before disposing
    if (_videoPositionListener != null && _videoPlayerController != null) {
      _videoPlayerController!.removeListener(_videoPositionListener!);
      _videoPositionListener = null;
    }

    _progressController.reset();
    _videoPlayerController?.dispose();
    _videoPlayerController = null;

    final story = _activeStory;
    final isVideo = story.mediaType == 'video';

    if (isVideo) {
      setState(() {
        _isVideoLoading = true;
      });
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(story.mediaUrl))
        ..initialize().then((_) {
          if (!mounted) return;
          if (_activeStory.id == story.id) {
            setState(() {
              _isVideoLoading = false;
            });
            // Set duration so the progress bar knows the full length
            _progressController.duration = _videoPlayerController!.value.duration;

            if (!_isPaused) {
              _videoPlayerController!.play();
            }

            // Sync progress bar to real video position on every frame tick
            _videoPositionListener = () {
              final ctrl = _videoPlayerController;
              if (ctrl == null || !ctrl.value.isInitialized) return;
              final total = ctrl.value.duration.inMicroseconds;
              if (total <= 0) return;
              final pos = ctrl.value.position.inMicroseconds;
              final ratio = (pos / total).clamp(0.0, 1.0);

              // Drive the animation controller value directly – no AnimationController.forward()
              if (_progressController.value != ratio) {
                _progressController.value = ratio;
              }

              // When video finishes, advance to next story
              if (!ctrl.value.isPlaying && ctrl.value.position >= ctrl.value.duration - const Duration(milliseconds: 200)) {
                _videoPositionListener != null
                    ? ctrl.removeListener(_videoPositionListener!)
                    : null;
                _videoPositionListener = null;
                _onStoryComplete();
              }
            };
            _videoPlayerController!.addListener(_videoPositionListener!);
          }
        }).catchError((error) {
          log('StoryViewerScreen: Video initialization error: $error');
          if (mounted && _activeStory.id == story.id) {
            setState(() {
              _isVideoLoading = false;
            });
            // Fall back to a 5-second timer if video fails to load
            _progressController.duration = const Duration(seconds: 5);
            _progressController.forward();
          }
        });
    } else {
      setState(() {
        _isVideoLoading = false;
      });
      _progressController.duration = const Duration(seconds: 5);
      _progressController.forward();
    }

    // Mark story as viewed in database
    context.read<CustomerStoriesCubit>().markStoryAsSeen(story.id);
  }

  void _onStoryComplete() {
    if (_currentStoryIndex < _currentGroupStories.length - 1) {
      // Go to next story of same vendor
      setState(() {
        _currentStoryIndex++;
      });
      _startStory();
    } else {
      // Last story for this vendor, go to next vendor
      _navigateToNextVendor();
    }
  }

  void _navigateToNextVendor() {
    if (_currentGroupIndex < widget.storyGroups.length - 1) {
      _vendorPageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // No more vendors, close viewer
      Navigator.pop(context);
    }
  }

  void _navigateToPrevVendor() {
    if (_currentGroupIndex > 0) {
      _vendorPageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipToNext() {
    if (_currentStoryIndex < _currentGroupStories.length - 1) {
      setState(() {
        _currentStoryIndex++;
      });
      _startStory();
    } else {
      _navigateToNextVendor();
    }
  }

  void _skipToPrev() {
    if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
      });
      _startStory();
    } else {
      // Go to previous vendor's last story
      if (_currentGroupIndex > 0) {
        _navigateToPrevVendor();
      } else {
        // First story of first vendor, reset current story
        _startStory();
      }
    }
  }

  void _pause() {
    if (!_isPaused) {
      _progressController.stop();
      _videoPlayerController?.pause();
      setState(() {
        _isPaused = true;
      });
    }
  }

  void _resume() {
    if (_isPaused) {
      _progressController.forward();
      _videoPlayerController?.play();
      setState(() {
        _isPaused = false;
      });
    }
  }

  String _formatTimeAgo(DateTime createdAt, String locale) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) {
      return locale == 'ar' ? 'منذ ${diff.inMinutes} دقيقة' : '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return locale == 'ar' ? 'منذ ${diff.inHours} ساعة' : '${diff.inHours}h ago';
    } else {
      return locale == 'ar' ? 'يوم مضى' : '1 day ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    const orangeColor = Color(0xFFF35535);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          onVerticalDragUpdate: (details) {
            // Swipe down to close story viewer
            if (details.delta.dy > 8) {
              Navigator.pop(context);
            }
          },
          child: PageView.builder(
            controller: _vendorPageController,
            physics: const ClampingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentGroupIndex = index;
                _currentStoryIndex = 0;
              });
              _startStory();
            },
            itemCount: widget.storyGroups.length,
            itemBuilder: (context, groupIdx) {
              final group = widget.storyGroups[groupIdx];
              final story = group[groupIdx == _currentGroupIndex ? _currentStoryIndex : 0];

              return Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Story background (Video or Image)
                  if (story.mediaType == 'video')
                    _isVideoLoading || _videoPlayerController == null || !_videoPlayerController!.value.isInitialized
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(orangeColor),
                            ),
                          )
                        : Center(
                            child: FittedBox(
                              fit: BoxFit.contain,
                              clipBehavior: Clip.hardEdge,
                              child: SizedBox(
                                width: _videoPlayerController!.value.size.width,
                                height: _videoPlayerController!.value.size.height,
                                child: VideoPlayer(_videoPlayerController!),
                              ),
                            ),
                          )
                  else
                    CachedNetworkImage(
                      imageUrl: story.mediaUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(orangeColor),
                        ),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Text(
                          locale == 'ar' ? 'تعذر تحميل الصورة' : 'Failed to load image',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),

                  // Black overlays for gradient text legibility
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black87,
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black87,
                        ],
                        stops: [0.0, 0.15, 0.8, 1.0],
                      ),
                    ),
                  ),

                  // 2. Interactive touch areas for navigation
                  Row(
                    children: [
                      // Left tap to go back
                      Expanded(
                        child: GestureDetector(
                          onTap: _skipToPrev,
                          onLongPressStart: (_) => _pause(),
                          onLongPressEnd: (_) => _resume(),
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                      // Right tap to skip forward
                      Expanded(
                        child: GestureDetector(
                          onTap: _skipToNext,
                          onLongPressStart: (_) => _pause(),
                          onLongPressEnd: (_) => _resume(),
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                    ],
                  ),

                  // 3. UI overlays (Progress indicators, header, caption, buttons)
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Progress bars
                        Row(
                          children: List.generate(
                            group.length,
                            (index) {
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: SizedBox(
                                      height: 3,
                                      child: AnimatedBuilder(
                                        animation: _progressController,
                                        builder: (context, child) {
                                          return LinearProgressIndicator(
                                            value: index == _currentStoryIndex
                                                ? _progressController.value
                                                : (index < _currentStoryIndex ? 1.0 : 0.0),
                                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                            backgroundColor: Colors.white24,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Header (Vendor profile info)
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundImage: CachedNetworkImageProvider(story.vendorLogoUrl),
                              backgroundColor: Colors.grey[800],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    story.vendorName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _formatTimeAgo(story.createdAt, locale),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white, size: 28),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Caption Overlay (Bottom)
                  Positioned(
                    bottom: MediaQuery.of(context).padding.bottom + 80,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (story.caption != null && story.caption!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              story.caption!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                shadows: [
                                  Shadow(
                                    blurRadius: 4.0,
                                    color: Colors.black,
                                    offset: Offset(1.0, 1.0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Swipe-up / Button to Visit Store
                  Positioned(
                    bottom: MediaQuery.of(context).padding.bottom + 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orangeColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          onPressed: () {
                            _pause();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RestaurantMenuPage(
                                  restaurantId: story.vendorId,
                                ),
                              ),
                            ).then((_) => _resume());
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.store_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                locale == 'ar' ? 'زيارة المتجر والتسوق' : 'Visit Store & Shop',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          Icons.keyboard_arrow_up,
                          color: Colors.white.withValues(alpha: 0.6),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
