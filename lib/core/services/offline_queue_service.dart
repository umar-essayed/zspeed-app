import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:z_speed/core/models/offline_action.dart';
import 'package:uuid/uuid.dart';

@lazySingleton
class OfflineQueueService {
  static const String _queueKey = 'offline_actions_queue';
  final SharedPreferences _prefs;
  final Uuid _uuid = const Uuid();

  OfflineQueueService(this._prefs);

  List<OfflineAction> getQueue() {
    final queueString = _prefs.getString(_queueKey);
    if (queueString == null || queueString.isEmpty) return [];

    try {
      final List<dynamic> decodedList = json.decode(queueString);
      return decodedList.map((item) => OfflineAction.fromMap(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> enqueueAction({
    required String actionType,
    required String resourcePath,
    required Map<String, dynamic> payload,
  }) async {
    final action = OfflineAction(
      id: _uuid.v4(),
      actionType: actionType,
      resourcePath: resourcePath,
      payload: payload,
      timestamp: DateTime.now(),
    );

    final currentQueue = getQueue();
    currentQueue.add(action);

    await _saveQueue(currentQueue);
  }

  Future<void> removeAction(String actionId) async {
    final currentQueue = getQueue();
    currentQueue.removeWhere((item) => item.id == actionId);
    await _saveQueue(currentQueue);
  }

  Future<void> clearQueue() async {
    await _prefs.remove(_queueKey);
  }

  Future<void> _saveQueue(List<OfflineAction> queue) async {
    final encodedList = queue.map((a) => a.toJson()).toList();
    await _prefs.setString(_queueKey, json.encode(encodedList));
  }
}
