import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:z_speed/core/utils/phone_helper.dart';

class BlacklistItem {
  final String id;
  final String type; // 'phone', 'email', 'uid'
  final String value;
  final String? reason;
  final DateTime createdAt;

  BlacklistItem({
    required this.id,
    required this.type,
    required this.value,
    this.reason,
    required this.createdAt,
  });

  factory BlacklistItem.fromMap(Map<String, dynamic> map, String id) {
    return BlacklistItem(
      id: id,
      type: map['type'] as String? ?? 'phone',
      value: map['value'] as String? ?? '',
      reason: map['reason'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'value': value,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

@lazySingleton
class SettingsDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<bool> watchMaintenanceMode() {
    return _firestore
        .collection('sys_settings')
        .doc('app_settings')
        .snapshots()
        .map((doc) => doc.data()?['maintenanceMode'] as bool? ?? false);
  }

  Stream<bool> watchAllowNewSignups() {
    return _firestore
        .collection('sys_settings')
        .doc('app_settings')
        .snapshots()
        .map((doc) => doc.data()?['allowNewSignups'] as bool? ?? true);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchAppSettings() {
    return _firestore
        .collection('sys_settings')
        .doc('app_settings')
        .snapshots();
  }

  Future<Map<String, dynamic>> getSettings() async {
    final doc =
        await _firestore.collection('sys_settings').doc('app_settings').get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    } else {
      // Default fallback
      return {
        'deliveryFeeRate': 0.10,
        'platformCommission': 0.15,
        'maintenanceMode': false,
        'allowNewSignups': true,
        'signupDisabledMessage': '',
        'maintenanceMessage': '',
      };
    }
  }

  Future<void> updateSettings(Map<String, dynamic> data) async {
    await _firestore
        .collection('sys_settings')
        .doc('app_settings')
        .set(data, SetOptions(merge: true));
  }

  // ── Blacklist / Blocked List Management ────────────────────────────────────

  Future<List<BlacklistItem>> getBlacklist() async {
    final snap = await _firestore
        .collection('blacklists')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs
        .map((d) => BlacklistItem.fromMap(d.data(), d.id))
        .toList();
  }

  Stream<List<BlacklistItem>> streamBlacklist() {
    return _firestore
        .collection('blacklists')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => BlacklistItem.fromMap(d.data(), d.id)).toList());
  }

  Future<bool> isBlacklisted({
    String? phone,
    String? email,
    String? uid,
  }) async {
    try {
      if (phone != null && phone.isNotEmpty) {
        final normalized = PhoneHelper.normalizePhone(phone);
        final phoneSnap = await _firestore
            .collection('blacklists')
            .where('value', whereIn: [phone, normalized])
            .limit(1)
            .get();
        if (phoneSnap.docs.isNotEmpty) return true;
      }

      if (email != null && email.isNotEmpty) {
        final normalizedEmail = email.trim().toLowerCase();
        final emailSnap = await _firestore
            .collection('blacklists')
            .where('value', isEqualTo: normalizedEmail)
            .limit(1)
            .get();
        if (emailSnap.docs.isNotEmpty) return true;
      }

      if (uid != null && uid.isNotEmpty) {
        final uidSnap = await _firestore
            .collection('blacklists')
            .where('value', isEqualTo: uid.trim())
            .limit(1)
            .get();
        if (uidSnap.docs.isNotEmpty) return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> addToBlacklist({
    required String type,
    required String value,
    String? reason,
  }) async {
    String cleanVal = value.trim();
    if (type == 'phone') {
      cleanVal = PhoneHelper.normalizePhone(cleanVal);
    } else if (type == 'email') {
      cleanVal = cleanVal.toLowerCase();
    }

    final docId =
        '${type}_${cleanVal.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')}';
    await _firestore.collection('blacklists').doc(docId).set({
      'type': type,
      'value': cleanVal,
      'reason': reason?.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFromBlacklist(String docId) async {
    await _firestore.collection('blacklists').doc(docId).delete();
  }
}
