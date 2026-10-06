import 'dart:convert';

class OfflineAction {
  final String id;
  final String actionType;
  final String resourcePath;
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  OfflineAction({
    required this.id,
    required this.actionType,
    required this.resourcePath,
    required this.payload,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'actionType': actionType,
      'resourcePath': resourcePath,
      'payload': payload,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory OfflineAction.fromMap(Map<String, dynamic> map) {
    return OfflineAction(
      id: map['id'] ?? '',
      actionType: map['actionType'] ?? '',
      resourcePath: map['resourcePath'] ?? '',
      payload: Map<String, dynamic>.from(map['payload'] ?? {}),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
    );
  }

  String toJson() => json.encode(toMap());

  factory OfflineAction.fromJson(String source) =>
      OfflineAction.fromMap(json.decode(source));
}
