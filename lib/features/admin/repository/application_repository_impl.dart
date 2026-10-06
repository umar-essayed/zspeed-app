import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:z_speed/core/core.dart';
import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/features/admin/model/application_model.dart';
import 'package:z_speed/features/admin/repository/application_repository.dart';
import 'package:injectable/injectable.dart' hide Order;

/// Firestore-backed implementation of [ApplicationRepository].
///
/// Collection: `applications`
/// Also updates the `users` collection when an application is approved/rejected.
@LazySingleton(as: ApplicationRepository)
class ApplicationRepositoryImpl implements ApplicationRepository {
  final FirebaseFirestore _firestore;

  ApplicationRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('applications');

  // ── Submit ─────────────────────────────────────────────────────────────────

  @override
  Future<Result<String>> submitApplication({
    required String userId,
    required ApplicationType type,
    required Map<String, dynamic> formData,
    required List<String> documentUrls,
  }) async {
    try {
      final now = DateTime.now();
      final application = Application(
        id: '', // Firestore will assign
        userId: userId,
        applicationType: type,
        status: ReviewStatus.pending,
        formData: formData,
        documentUrls: documentUrls,
        submittedAt: now,
        createdAt: now,
      );

      final docRef = await _collection.add(application.toMap());

      // Dual-write copies to the collections expected by the NestJS backend / Admin panel
      if (type == ApplicationType.driver) {
        final personalInfo =
            Map<String, dynamic>.from(formData['personalInfo'] ?? {});
        final vehicleInfo =
            Map<String, dynamic>.from(formData['vehicleInfo'] ?? {});

        final documentsMap = {
          'nationalIdUrl': documentUrls.isNotEmpty ? documentUrls[0] : null,
          'driverLicenseUrl': documentUrls.length > 1 ? documentUrls[1] : null,
          'registrationDocUrl':
              documentUrls.length > 2 ? documentUrls[2] : null,
          'insuranceDocUrl': documentUrls.length > 3 ? documentUrls[3] : null,
          'policeClearanceUrl':
              documentUrls.length > 4 ? documentUrls[4] : null,
          'facePhotoUrl': documentUrls.length > 5 ? documentUrls[5] : null,
          'vehiclePhotoUrl': documentUrls.length > 6 ? documentUrls[6] : null,
        };

        final driverAppData = {
          'userId': userId,
          'name': personalInfo['name'] ?? '',
          'email': personalInfo['email'] ?? '',
          'phone': personalInfo['phone'] ?? '',
          'status': 'pending',
          'nationalId': personalInfo['nationalId'] ?? '',
          'dateOfBirth': personalInfo['dob'] ?? '',
          'personal': {
            'name': personalInfo['name'] ?? '',
            'email': personalInfo['email'] ?? '',
            'phone': personalInfo['phone'] ?? '',
            'city': personalInfo['city'] ?? '',
            'dob': personalInfo['dob'] ?? '',
            'dateOfBirth': personalInfo['dob'] ?? '',
            'nationalId': personalInfo['nationalId'] ?? '',
            'driverCategory': personalInfo['driverCategory'] ?? 'delivery',
          },
          'vehicle': {
            'type': vehicleInfo['type'] ?? '',
            'make': vehicleInfo['make'] ?? '',
            'model': vehicleInfo['model'] ?? '',
            'year': vehicleInfo['year'] ?? '',
            'color': vehicleInfo['color'] ?? '',
            'plateNumber': vehicleInfo['plateNumber'] ?? '',
          },
          'documents': documentsMap,
          'documentUrls': documentUrls,
          'createdAt': Timestamp.fromDate(now),
          'submittedAt': Timestamp.fromDate(now),
        };

        await _firestore
            .collection('driver_applications')
            .doc(docRef.id)
            .set(driverAppData);
      } else if (type == ApplicationType.restaurant) {
        final biz = Map<String, dynamic>.from(formData['businessInfo'] ?? {});
        final contact =
            Map<String, dynamic>.from(formData['contactInfo'] ?? {});

        final vendorAppData = {
          'userId': userId,
          'name': biz['restaurantName'] ?? '',
          'businessName': biz['restaurantName'] ?? '',
          'businessNameAr': biz['nameAr'] ?? '',
          'address': contact['address'] ?? '',
          'city': contact['city'] ?? '',
          'vendorType': formData['vendorType'] ?? 'RESTAURANT',
          'status': 'pending',
          'phone': contact['restaurantPhone'] ?? contact['ownerPhone'] ?? '',
          'documentUrls': documentUrls,
          'createdAt': Timestamp.fromDate(now),
          'submittedAt': Timestamp.fromDate(now),
        };

        await _firestore
            .collection('vendor_applications')
            .doc(docRef.id)
            .set(vendorAppData);
      }

      // Also update user's applicationStatus
      await _firestore.collection('users').doc(userId).update({
        'applicationStatus': 'pending',
        'appliedAt': Timestamp.fromDate(now),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      log('ApplicationRepo: submitted ${type.name} application ${docRef.id} for user $userId');
      return Success(docRef.id);
    } catch (e, st) {
      return Err(
          NetworkFailure('Failed to submit application: $e', stackTrace: st));
    }
  }

  // ── Query ──────────────────────────────────────────────────────────────────

  @override
  Future<Result<List<Application>>> getApplications({
    ApplicationType? type,
    ReviewStatus? status,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _collection;

      if (type != null) {
        query = query.where('applicationType', isEqualTo: type.name);
      }
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      query = query.orderBy('submittedAt', descending: true);

      final snapshot = await query.get();
      final applications = snapshot.docs
          .map((doc) => Application.fromMap(doc.data(), doc.id))
          .toList();

      return Success(applications);
    } catch (e, st) {
      return Err(
          NetworkFailure('Failed to fetch applications: $e', stackTrace: st));
    }
  }

  @override
  Future<Result<Application>> getApplicationById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists || doc.data() == null) {
        return Err(NetworkFailure('Application not found'));
      }
      return Success(Application.fromMap(doc.data()!, doc.id));
    } catch (e, st) {
      return Err(
          NetworkFailure('Failed to fetch application: $e', stackTrace: st));
    }
  }

  @override
  Future<Result<List<Application>>> getApplicationsByUserId(
      String userId) async {
    try {
      final snapshot = await _collection
          .where('userId', isEqualTo: userId)
          .orderBy('submittedAt', descending: true)
          .get();

      final applications = snapshot.docs
          .map((doc) => Application.fromMap(doc.data(), doc.id))
          .toList();

      return Success(applications);
    } catch (e, st) {
      return Err(NetworkFailure('Failed to fetch user applications: $e',
          stackTrace: st));
    }
  }

  // ── Review Actions ─────────────────────────────────────────────────────────

  @override
  Future<Result<void>> approveApplication({
    required String applicationId,
    required String reviewerId,
  }) async {
    try {
      final now = DateTime.now();
      final batch = _firestore.batch();

      // Update application
      batch.update(_collection.doc(applicationId), {
        'status': ReviewStatus.approved.name,
        'reviewedAt': Timestamp.fromDate(now),
        'reviewedBy': reviewerId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get the application to find the user
      final appDoc = await _collection.doc(applicationId).get();
      if (appDoc.exists && appDoc.data() != null) {
        final data = appDoc.data()!;
        final userId = data['userId'] as String?;
        final appType = data['applicationType'] as String?;

        if (appType != null) {
          final targetCollection =
              (appType == 'restaurant' || appType == 'vendor') ? 'vendor_applications' : 'driver_applications';
          batch.update(_firestore.collection(targetCollection).doc(applicationId), {
            'status': 'approved',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        if (userId != null) {
          final formData = Map<String, dynamic>.from(data['formData'] ?? {});
          final personalInfo =
              Map<String, dynamic>.from(formData['personalInfo'] ?? {});
          final isTransport = personalInfo['driverCategory'] == 'transport';

          // Update user status
          batch.update(_firestore.collection('users').doc(userId), {
            'type': (appType == 'restaurant' || appType == 'vendor')
                ? UserType.vendor.name
                : UserType.driver.name,
            'applicationStatus': 'approved',
            'approvedAt': Timestamp.fromDate(now),
            'status': 'active',
            'canTransport': isTransport,
            'canDeliver': !isTransport,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          if (appType == 'restaurant' || appType == 'vendor') {
            // Create vendor document from application form data
            final formData = Map<String, dynamic>.from(data['formData'] ?? {});
            final biz =
                Map<String, dynamic>.from(formData['businessInfo'] ?? {});
            final contact =
                Map<String, dynamic>.from(formData['contactInfo'] ?? {});
            final location =
                Map<String, dynamic>.from(formData['locationInfo'] ?? {});
            final branding =
                Map<String, dynamic>.from(formData['branding'] ?? {});
            final vendorDocRef = _firestore.collection('vendors').doc(userId);
            batch.set(vendorDocRef, {
              'ownerId': userId,
              'vendorType': formData['vendorType'] ?? 'restaurant',
              'name': biz['restaurantName'] ?? '',
              'nameAr': biz['nameAr'] ?? '',
              'description': biz['description'] ?? '',
              'logoUrl': branding['logoUrl'] ?? '',
              'coverImageUrl': branding['coverUrl'] ?? '',
              'phone':
                  contact['restaurantPhone'] ?? contact['ownerPhone'] ?? '',
              'address': contact['address'] ?? location['address'] ?? '',
              'city': contact['city'] ?? location['city'] ?? '',
              'cuisineTypes': biz['cuisines'] ?? [],
              'rating': 0.0,
              'ratingCount': 0,
              'isOpen': false,
              'isActive': true,
              'deliveryFee': 0.0,
              'minimumOrder': 0.0,
              'deliveryTimeMin': 30,
              'deliveryTimeMax': 60,
              'deliveryRadiusKm': 10.0,
              'latitude': (location['latitude'] as num?)?.toDouble() ?? 0.0,
              'longitude': (location['longitude'] as num?)?.toDouble() ?? 0.0,
              'workingHours': location['operatingHours'] ?? {},
              'documentUrls': data['documentUrls'] ?? [],
              'createdAt': Timestamp.fromDate(now),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } else {
            final formData = Map<String, dynamic>.from(data['formData'] ?? {});
            final vehicleInfo =
                Map<String, dynamic>.from(formData['vehicleInfo'] ?? {});
            final personalInfo =
                Map<String, dynamic>.from(formData['personalInfo'] ?? {});

            batch.set(_firestore.collection('driverProfiles').doc(userId), {
              'userId': userId,
              'name': personalInfo['name'] ?? '',
              'status': 'offline',
              'vehicleType': vehicleInfo['type'] ?? '',
              'vehicleMake': vehicleInfo['make'] ?? '',
              'vehicleModel': vehicleInfo['model'] ?? '',
              'licensePlate': vehicleInfo['plateNumber'] ?? '',
              'licenseNumber': '',
              'phoneNumber': personalInfo['phone'] ?? '',
              'rating': 0.0,
              'ratingCount': 0,
              'totalTrips': 0,
              'totalEarnings': 0.0,
              'acceptanceRate': 1.0,
              'totalAccepted': 0,
              'totalRejected': 0,
              'walletBalance': 0.0,
              'payoutFrequency': 'weekly',
              'minimumPayout': 100.0,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }

      await batch.commit();
      log('ApplicationRepo: approved application $applicationId by $reviewerId');
      return Success(null);
    } catch (e, st) {
      return Err(
          NetworkFailure('Failed to approve application: $e', stackTrace: st));
    }
  }

  @override
  Future<Result<void>> rejectApplication({
    required String applicationId,
    required String reviewerId,
    required String reason,
  }) async {
    try {
      final now = DateTime.now();
      final batch = _firestore.batch();

      // Update application
      batch.update(_collection.doc(applicationId), {
        'status': ReviewStatus.rejected.name,
        'reviewedAt': Timestamp.fromDate(now),
        'reviewedBy': reviewerId,
        'rejectionReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get the application to find the user
      final appDoc = await _collection.doc(applicationId).get();
      if (appDoc.exists && appDoc.data() != null) {
        final data = appDoc.data()!;
        final userId = data['userId'] as String?;
        final appType = data['applicationType'] as String?;

        if (appType != null) {
          final targetCollection =
              (appType == 'restaurant' || appType == 'vendor') ? 'vendor_applications' : 'driver_applications';
          batch.update(_firestore.collection(targetCollection).doc(applicationId), {
            'status': 'rejected',
            'rejectionReason': reason,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        if (userId != null) {
          batch.update(_firestore.collection('users').doc(userId), {
            'applicationStatus': 'rejected',
            'rejectionReason': reason,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
      log('ApplicationRepo: rejected application $applicationId by $reviewerId');
      return Success(null);
    } catch (e, st) {
      return Err(
          NetworkFailure('Failed to reject application: $e', stackTrace: st));
    }
  }

  // ── Section-Level Review Actions ───────────────────────────────────────────

  @override
  Future<Result<void>> approveSection({
    required String applicationId,
    required String sectionKey,
    required String reviewerId,
  }) async {
    try {
      await _collection.doc(applicationId).update({
        'sectionStatuses.$sectionKey': 'approved',
        'sectionReasons.$sectionKey': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      log('ApplicationRepo: approved section $sectionKey of $applicationId');
      return Success(null);
    } catch (e, st) {
      return Err(
          NetworkFailure('Failed to approve section: $e', stackTrace: st));
    }
  }

  @override
  Future<Result<void>> rejectSection({
    required String applicationId,
    required String sectionKey,
    required String reviewerId,
    required String reason,
  }) async {
    try {
      await _collection.doc(applicationId).update({
        'sectionStatuses.$sectionKey': 'rejected',
        'sectionReasons.$sectionKey': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      log('ApplicationRepo: rejected section $sectionKey of $applicationId');
      return Success(null);
    } catch (e, st) {
      return Err(
          NetworkFailure('Failed to reject section: $e', stackTrace: st));
    }
  }

  // ── User-Side Section Update ───────────────────────────────────────────────

  @override
  Future<Result<void>> updateApplicationSection({
    required String applicationId,
    required String sectionKey,
    required Map<String, dynamic> sectionData,
  }) async {
    try {
      final batch = _firestore.batch();
      final docRef = _collection.doc(applicationId);

      // Update the section within formData and reset its status to pending
      batch.update(docRef, {
        'formData.$sectionKey': sectionData,
        'sectionStatuses.$sectionKey': 'pending',
        'sectionReasons.$sectionKey': FieldValue.delete(),
        'status': ReviewStatus.pending.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also update the user's applicationStatus back to pending
      final appDoc = await docRef.get();
      if (appDoc.exists && appDoc.data() != null) {
        final userId = appDoc.data()!['userId'] as String?;
        if (userId != null) {
          batch.update(_firestore.collection('users').doc(userId), {
            'applicationStatus': 'pending',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
      log('ApplicationRepo: updated section $sectionKey of $applicationId — reset to pending');
      return Success(null);
    } catch (e, st) {
      return Err(
          NetworkFailure('Failed to update section: $e', stackTrace: st));
    }
  }

  @override
  Future<Result<void>> updateApplicationDocuments({
    required String applicationId,
    required List<String> documentUrls,
  }) async {
    try {
      final batch = _firestore.batch();
      final docRef = _collection.doc(applicationId);

      // Update the documentUrls and reset status to pending
      batch.update(docRef, {
        'documentUrls': documentUrls,
        'status': ReviewStatus.pending.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also update the user's applicationStatus back to pending
      final appDoc = await docRef.get();
      if (appDoc.exists && appDoc.data() != null) {
        final userId = appDoc.data()!['userId'] as String?;
        if (userId != null) {
          batch.update(_firestore.collection('users').doc(userId), {
            'applicationStatus': 'pending',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
      log('ApplicationRepo: updated documents of $applicationId — reset to pending');
      return Success(null);
    } catch (e, st) {
      return Err(
          NetworkFailure('Failed to update documents: $e', stackTrace: st));
    }
  }
}
