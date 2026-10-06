import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:z_speed/features/admin/model/application_model.dart';

void main() {
  group('Application.fromMap', () {
    test('parses legacy vendor applicationType and preserves restaurant semantics', () {
      final app = Application.fromMap(
        {
          'userId': 'user-1',
          'applicationType': 'vendor',
          'status': 'pending',
          'submittedAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
          'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
        },
        'app-1',
      );

      expect(app.applicationType, ApplicationType.vendor);
      expect(app.typeDisplayName, 'Restaurant');
      expect(app.status, ReviewStatus.pending);
    });
  });
}
