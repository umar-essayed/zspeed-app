import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:z_speed/core/injection.dart';
import 'package:z_speed/features/restaurant/model/menu_item.dart';
import 'package:z_speed/features/restaurant/repository/restaurant_menu_repository.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/core/services/media_compression_service.dart';

class AddStoryDialog extends StatefulWidget {
  final String restaurantId;
  final bool isUploading;
  final Function(XFile file, String? caption, String? menuItemId) onPost;

  const AddStoryDialog({
    super.key,
    required this.restaurantId,
    required this.isUploading,
    required this.onPost,
  });

  @override
  State<AddStoryDialog> createState() => _AddStoryDialogState();
}

class _AddStoryDialogState extends State<AddStoryDialog> {
  XFile? _selectedFile;
  String? _videoThumbnailPath;
  final _captionController = TextEditingController();
  String? _selectedMenuItemId;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    try {
      final XFile? media = await _picker.pickMedia(
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (media != null) {
        final nameLower = media.name.toLowerCase();
        final isVideo = nameLower.endsWith('.mp4') ||
                        nameLower.endsWith('.mov') ||
                        nameLower.endsWith('.avi') ||
                        nameLower.endsWith('.m4v');
        if (isVideo) {
          final thumbnail = await getIt<MediaCompressionService>().getThumbnailPath(media.path);
          setState(() {
            _selectedFile = media;
            _videoThumbnailPath = thumbnail;
          });
        } else {
          setState(() {
            _selectedFile = media;
            _videoThumbnailPath = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking media: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    const orangeColor = Color(0xFFF35535);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    locale == 'ar' ? 'إضافة قصة جديدة' : 'Add New Story',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: orangeColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.isUploading ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Image/Video Selector / Preview
              GestureDetector(
                onTap: widget.isUploading ? null : _pickMedia,
                child: Container(
                  height: 240,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _selectedFile != null
                      ? Builder(
                          builder: (context) {
                            final nameLower = _selectedFile!.name.toLowerCase();
                            final isVideo = nameLower.endsWith('.mp4') ||
                                            nameLower.endsWith('.mov') ||
                                            nameLower.endsWith('.avi') ||
                                            nameLower.endsWith('.m4v') ||
                                            (_selectedFile!.mimeType?.startsWith('video/') ?? false);

                            if (isVideo && _videoThumbnailPath == null) {
                              // Render placeholder card for videos on Web / when thumbnail is unavailable
                              return Container(
                                color: Colors.grey[900],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.video_library_outlined,
                                      color: Colors.white70,
                                      size: 56,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      locale == 'ar' ? 'تم اختيار فيديو' : 'Video Selected',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                      child: Text(
                                        _selectedFile!.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Icon(
                                      Icons.play_circle_fill,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ],
                                ),
                              );
                            }

                            // Otherwise, render image preview or video thumbnail
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                kIsWeb || _videoThumbnailPath != null
                                    ? Image.network(
                                        _videoThumbnailPath ?? _selectedFile!.path,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(_selectedFile!.path),
                                        fit: BoxFit.cover,
                                      ),
                                Container(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  child: Center(
                                    child: Icon(
                                      _videoThumbnailPath != null
                                          ? Icons.play_circle_outline
                                          : Icons.edit,
                                      color: Colors.white,
                                      size: 48,
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
                            const Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              locale == 'ar'
                                  ? 'اختر صورة أو فيديو من المعرض'
                                  : 'Select image or video from gallery',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '9:16 aspect ratio recommended',
                              style: TextStyle(color: Colors.grey, fontSize: 10),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Caption input
              TextField(
                controller: _captionController,
                enabled: !widget.isUploading,
                maxLength: 150,
                decoration: InputDecoration(
                  labelText: locale == 'ar' ? 'الوصف (اختياري)' : 'Caption (Optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: orangeColor),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Linked menu item dropdown
              StreamBuilder<List<MenuItem>>(
                stream: getIt<RestaurantMenuRepository>().streamAllItems(widget.restaurantId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final items = snapshot.data!;
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedMenuItemId,
                    disabledHint: Text(locale == 'ar' ? 'جاري التحميل...' : 'Loading items...'),
                    decoration: InputDecoration(
                      labelText: locale == 'ar' ? 'ربط بوجبة (اختياري)' : 'Link to a dish (Optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: orangeColor),
                      ),
                    ),
                    items: items.map((item) {
                      return DropdownMenuItem<String>(
                        value: item.id,
                        child: Text(
                          locale == 'ar' && item.nameAr != null && item.nameAr!.isNotEmpty
                              ? item.nameAr!
                              : item.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: widget.isUploading
                        ? null
                        : (val) {
                            setState(() {
                              _selectedMenuItemId = val;
                            });
                          },
                  );
                },
              ),
              const SizedBox(height: 24),

              // Action Buttons
              if (widget.isUploading)
                const Column(
                  children: [
                    CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(orangeColor)),
                    SizedBox(height: 12),
                    Text('Uploading story... Please wait', style: TextStyle(color: Colors.grey)),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          l10n.cancel,
                          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orangeColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _selectedFile == null
                            ? null
                            : () {
                                widget.onPost(
                                  _selectedFile!,
                                  _captionController.text.trim().isEmpty
                                      ? null
                                      : _captionController.text.trim(),
                                  _selectedMenuItemId,
                                );
                              },
                        child: Text(
                          locale == 'ar' ? 'نشر القصة' : 'Post Story',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
