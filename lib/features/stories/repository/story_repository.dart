import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:z_speed/core/services/media_upload_service.dart';
import 'package:z_speed/features/stories/model/story.dart';
import 'package:z_speed/core/enums/user_enums.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:z_speed/features/stories/utils/thumbnail_generator.dart' as web_thumb;

import 'package:z_speed/core/services/media_compression_service.dart';
import 'package:video_compress/video_compress.dart' show VideoQuality;

/// Repository handling data persistence and uploads for the Stories feature.
@lazySingleton
class StoryRepository {
  final FirebaseFirestore _firestore;
  final MediaUploadService _uploadService;
  final MediaCompressionService _compressionService;

  StoryRepository({
    FirebaseFirestore? firestore,
    MediaUploadService? uploadService,
    MediaCompressionService? compressionService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _uploadService = uploadService ?? MediaUploadService(),
        _compressionService = compressionService ?? MediaCompressionService();

  /// Stream of all active (approved & non-expired) stories from all vendors.
  /// Expired or unapproved stories are automatically filtered out without needing compound Firestore indexes.
  Stream<List<Story>> streamActiveStories() {
    return _firestore
        .collection('stories')
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      final stories = snapshot.docs
          .map((doc) => Story.fromMap(doc.data(), doc.id))
          .where((story) =>
              story.status == StoryStatus.approved &&
              story.expiresAt.isAfter(now))
          .toList();
      // Sort in-memory by approval date / creation date descending
      stories.sort((a, b) {
        final dateA = a.approvedAt ?? a.createdAt;
        final dateB = b.approvedAt ?? b.createdAt;
        return dateB.compareTo(dateA);
      });
      return stories;
    });
  }

  /// Stream of stories for a specific vendor (including pending, approved, rejected).
  Stream<List<Story>> streamVendorStories(String vendorId) {
    return _firestore
        .collection('stories')
        .where('vendorId', isEqualTo: vendorId)
        .snapshots()
        .map((snapshot) {
      final stories = snapshot.docs
          .map((doc) => Story.fromMap(doc.data(), doc.id))
          .toList();
      stories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return stories;
    });
  }

  /// Stream of all pending stories for Admin approval moderation.
  /// Includes stories where status is 'pending' or missing/null for full backward compatibility.
  Stream<List<Story>> streamPendingStories() {
    return _firestore
        .collection('stories')
        .snapshots()
        .map((snapshot) {
      final stories = snapshot.docs
          .map((doc) => Story.fromMap(doc.data(), doc.id))
          .where((story) => story.status == StoryStatus.pending)
          .toList();
      stories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return stories;
    });
  }

  /// Stream of all stories (all statuses) for Admin management.
  Stream<List<Story>> streamAllStories() {
    return _firestore
        .collection('stories')
        .snapshots()
        .map((snapshot) {
      final stories = snapshot.docs
          .map((doc) => Story.fromMap(doc.data(), doc.id))
          .toList();
      stories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return stories;
    });
  }

  /// Approves a pending story. Sets approvedAt to now and starts the 24-hour expiration clock!
  Future<void> approveStory(String storyId) async {
    log('StoryRepository: Approving story ID: $storyId');
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(hours: 24));
    
    await _firestore.collection('stories').doc(storyId).update({
      'status': 'approved',
      'approvedAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'rejectionReason': FieldValue.delete(),
    });
  }

  /// Rejects a pending story with an optional reason.
  Future<void> rejectStory(String storyId, {String? reason}) async {
    log('StoryRepository: Rejecting story ID: $storyId with reason: $reason');
    await _firestore.collection('stories').doc(storyId).update({
      'status': 'rejected',
      if (reason != null && reason.isNotEmpty) 'rejectionReason': reason,
    });
  }

  /// Uploads a story media file to Firebase Storage and creates a document in Firestore.
  /// New stories default to status 'pending' awaiting admin approval.
  Future<String> createStory({
    required String vendorId,
    required String vendorName,
    required String vendorLogoUrl,
    required VendorType vendorType,
    required XFile imageFile,
    String? caption,
    String? menuItemId,
  }) async {
    log('StoryRepository: Preparing story upload for vendor $vendorId ($vendorName)');

    final nameLower = imageFile.name.toLowerCase();
    final isVideo = nameLower.endsWith('.mp4') ||
                    nameLower.endsWith('.mov') ||
                    nameLower.endsWith('.avi') ||
                    nameLower.endsWith('.m4v');

    XFile fileToUpload = imageFile;
    String? thumbnailUrl;

    // Apply native video compression if it is a video
    if (isVideo) {
      log('StoryRepository: Media is a video. Compressing before upload...');
      try {
        final compressedMedia = await _compressionService.compressVideo(
          imageFile.path,
          quality: VideoQuality.MediumQuality,
        );
        if (compressedMedia != null && compressedMedia.path != null) {
          fileToUpload = XFile(compressedMedia.path!);
          log('StoryRepository: Video compressed successfully. New size: ${compressedMedia.filesize} bytes');
        }
      } catch (e) {
        log('StoryRepository: Video compression failed, falling back to original: $e');
      }

      // Generate and upload thumbnail
      try {
        if (kIsWeb) {
          log('StoryRepository: Generating web video thumbnail...');
          final webBytes = await web_thumb.generateVideoThumbnail(imageFile.path);
          if (webBytes != null) {
            final thumbFile = XFile.fromData(
              webBytes,
              mimeType: 'image/jpeg',
              name: 'thumbnail_${DateTime.now().millisecondsSinceEpoch}.jpg',
            );
            final thumbUpload = await _uploadService.uploadXFile(
              thumbFile,
              'stories/$vendorId/thumbnails',
            );
            thumbnailUrl = thumbUpload.url;
            log('StoryRepository: Web video thumbnail uploaded: $thumbnailUrl');
          }
        } else {
          log('StoryRepository: Generating native video thumbnail...');
          final thumbnailPath = await _compressionService.getThumbnailPath(imageFile.path);
          if (thumbnailPath != null) {
            final thumbUpload = await _uploadService.uploadXFile(
              XFile(thumbnailPath),
              'stories/$vendorId/thumbnails',
            );
            thumbnailUrl = thumbUpload.url;
            log('StoryRepository: Native video thumbnail uploaded: $thumbnailUrl');
          }
        }
      } catch (e) {
        log('StoryRepository: Video thumbnail generation/upload failed: $e');
      }
    }
    
    // 1. Upload file using the secure MediaUploadService
    final uploadResult = await _uploadService.uploadXFile(
      fileToUpload,
      'stories/$vendorId',
    );

    // 2. Create story document with pending status (expiresAt placeholder 7 days)
    final docRef = _firestore.collection('stories').doc();
    final now = DateTime.now();
    final placeholderExpiresAt = now.add(const Duration(days: 7));

    final story = Story(
      id: docRef.id,
      vendorId: vendorId,
      vendorName: vendorName,
      vendorLogoUrl: vendorLogoUrl,
      vendorType: vendorType,
      mediaUrl: uploadResult.url,
      mediaType: isVideo ? 'video' : 'image',
      thumbnailUrl: thumbnailUrl,
      caption: caption,
      menuItemId: menuItemId,
      createdAt: now,
      expiresAt: placeholderExpiresAt,
      viewedBy: const [],
      status: StoryStatus.pending,
    );

    await docRef.set(story.toMap());
    log('StoryRepository: Story created successfully with ID: ${docRef.id} in pending status');
    return docRef.id;
  }

  /// Deletes a story from Firestore and its media file from Firebase Storage.
  Future<void> deleteStory(String storyId, String mediaUrl) async {
    log('StoryRepository: Deleting story ID: $storyId');
    
    // 1. Delete document in Firestore
    await _firestore.collection('stories').doc(storyId).delete();

    // 2. Extract storage path from the public download URL and delete file
    try {
      final uri = Uri.parse(mediaUrl);
      final pathSegs = uri.pathSegments;
      final oIndex = pathSegs.indexOf('o');
      
      if (oIndex != -1 && oIndex + 1 < pathSegs.length) {
        final storagePath = Uri.decodeComponent(pathSegs[oIndex + 1]);
        log('StoryRepository: Extracted storage path for deletion: $storagePath');
        await _uploadService.deleteFile(storagePath);
      }
    } catch (e) {
      log('StoryRepository: Error deleting story media from storage: $e');
    }
  }

  /// Appends the current user's UID to the viewedBy array of a story.
  Future<void> markStoryAsViewed(String storyId, String userId) async {
    try {
      await _firestore.collection('stories').doc(storyId).update({
        'viewedBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      log('StoryRepository: Error marking story as viewed: $e');
    }
  }
}
