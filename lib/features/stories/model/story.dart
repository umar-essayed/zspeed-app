import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:z_speed/core/enums/user_enums.dart';

enum StoryStatus {
  pending,
  approved,
  rejected;

  String get key {
    switch (this) {
      case StoryStatus.approved:
        return 'approved';
      case StoryStatus.rejected:
        return 'rejected';
      case StoryStatus.pending:
        return 'pending';
    }
  }

  static StoryStatus fromKey(String? key) {
    switch (key) {
      case 'approved':
        return StoryStatus.approved;
      case 'rejected':
        return StoryStatus.rejected;
      case 'pending':
      default:
        return StoryStatus.pending;
    }
  }
}

/// Represents a short-lived visual story posted by a vendor.
class Story extends Equatable {
  final String id;
  final String vendorId;
  final String vendorName;
  final String vendorLogoUrl;
  final VendorType vendorType;
  final String mediaUrl;
  final String mediaType; // 'image' | 'video'
  final String? thumbnailUrl;
  final String? caption;
  final String? menuItemId; // Optional link to a specific menu item
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> viewedBy; // User UIDs who saw this story
  final StoryStatus status;
  final DateTime? approvedAt;
  final String? rejectionReason;

  const Story({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.vendorLogoUrl,
    required this.vendorType,
    required this.mediaUrl,
    this.mediaType = 'image',
    this.thumbnailUrl,
    this.caption,
    this.menuItemId,
    required this.createdAt,
    required this.expiresAt,
    this.viewedBy = const [],
    this.status = StoryStatus.pending,
    this.approvedAt,
    this.rejectionReason,
  });

  factory Story.fromMap(Map<String, dynamic> map, String docId) {
    return Story(
      id: docId,
      vendorId: map['vendorId'] as String? ?? '',
      vendorName: map['vendorName'] as String? ?? '',
      vendorLogoUrl: map['vendorLogoUrl'] as String? ?? '',
      vendorType: VendorTypeX.fromKey(map['vendorType'] as String? ?? 'restaurant'),
      mediaUrl: map['mediaUrl'] as String? ?? '',
      mediaType: map['mediaType'] as String? ?? 'image',
      thumbnailUrl: map['thumbnailUrl'] as String?,
      caption: map['caption'] as String?,
      menuItemId: map['menuItemId'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(hours: 24)),
      viewedBy: List<String>.from(map['viewedBy'] ?? []),
      status: StoryStatusX.fromKey(map['status'] as String?),
      approvedAt: (map['approvedAt'] as Timestamp?)?.toDate(),
      rejectionReason: map['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vendorId': vendorId,
      'vendorName': vendorName,
      'vendorLogoUrl': vendorLogoUrl,
      'vendorType': vendorType.key,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (caption != null) 'caption': caption,
      if (menuItemId != null) 'menuItemId': menuItemId,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'viewedBy': viewedBy,
      'status': status.key,
      if (approvedAt != null) 'approvedAt': Timestamp.fromDate(approvedAt!),
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    };
  }

  Story copyWith({
    String? id,
    String? vendorId,
    String? vendorName,
    String? vendorLogoUrl,
    VendorType? vendorType,
    String? mediaUrl,
    String? mediaType,
    String? thumbnailUrl,
    String? caption,
    String? menuItemId,
    DateTime? createdAt,
    DateTime? expiresAt,
    List<String>? viewedBy,
    StoryStatus? status,
    DateTime? approvedAt,
    String? rejectionReason,
  }) {
    return Story(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      vendorLogoUrl: vendorLogoUrl ?? this.vendorLogoUrl,
      vendorType: vendorType ?? this.vendorType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      menuItemId: menuItemId ?? this.menuItemId,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      viewedBy: viewedBy ?? this.viewedBy,
      status: status ?? this.status,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  @override
  List<Object?> get props => [
        id,
        vendorId,
        vendorName,
        vendorLogoUrl,
        vendorType,
        mediaUrl,
        mediaType,
        thumbnailUrl,
        caption,
        menuItemId,
        createdAt,
        expiresAt,
        viewedBy,
        status,
        approvedAt,
        rejectionReason,
      ];
}

extension StoryStatusX on StoryStatus {
  static StoryStatus fromKey(String? key) => StoryStatus.fromKey(key);
}

