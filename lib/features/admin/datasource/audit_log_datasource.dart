import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:z_speed/features/auth/model/user_model.dart';

enum AuditAction { updateStatus, updateRole, deleteUser }

@lazySingleton
class AuditLogDatasource {
  final FirebaseFirestore _db;

  AuditLogDatasource({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  Future<void> log({
    required AppUser actor,
    required AuditAction action,
    required String targetUserId,
    required String targetUserName,
    required String targetUserEmail,
    required UserType targetUserRole,
    Map<String, dynamic> extra = const {},
  }) async {
    await _db.collection('auditLogs').add({
      'action': action.name,
      'actor': {
        'id': actor.id,
        'name': actor.name,
        'email': actor.email,
        'role': actor.type.name,
      },
      'target': {
        'id': targetUserId,
        'name': targetUserName,
        'email': targetUserEmail,
        'role': targetUserRole.name,
      },
      'extra': extra,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
