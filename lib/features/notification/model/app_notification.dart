import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:z_speed/core/enums/notification_enums.dart';

class AppNotification extends Equatable {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, String> data;
  final bool read;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data = const {},
    this.read = false,
    required this.createdAt,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    return AppNotification(
      id: id,
      userId: map['userId'] as String? ?? '',
      type: NotificationType.fromKey(map['type'] as String? ?? 'general'),
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      data: Map<String, String>.from(map['data'] as Map? ?? {}),
      read: map['read'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.key,
      'title': title,
      'body': body,
      'data': data,
      'read': read,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    Map<String, String>? data,
    bool? read,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, userId, type, title, body, data, read, createdAt];
}
