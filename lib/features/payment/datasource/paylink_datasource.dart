import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:z_speed/features/payment/model/saved_card_model.dart';

@lazySingleton
class PaylinkDatasource {
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  PaylinkDatasource({
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
  })  : _functions = functions ?? FirebaseFunctions.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Initialize a PayLink hosted checkout session for an Order or a Ride
  Future<Map<String, dynamic>> initCheckout({
    String? orderId,
    String? rideId,
  }) async {
    final callable = _functions.httpsCallable('paylinkInitCheckout');
    final response = await callable.call<Map<String, dynamic>>({
      if (orderId != null) 'orderId': orderId,
      if (rideId != null) 'rideId': rideId,
    });
    return Map<String, dynamic>.from(response.data);
  }

  /// Charge a vaulted Card Token for an Order or a Ride
  Future<Map<String, dynamic>> chargeSavedCard({
    required String cardId,
    String? orderId,
    String? rideId,
  }) async {
    final callable = _functions.httpsCallable('paylinkChargeSavedCard');
    final response = await callable.call<Map<String, dynamic>>({
      'cardId': cardId,
      if (orderId != null) 'orderId': orderId,
      if (rideId != null) 'rideId': rideId,
    });
    return Map<String, dynamic>.from(response.data);
  }

  /// Securely tokenize and save a card server-side
  Future<Map<String, dynamic>> saveCard({
    required String firstName,
    required String lastName,
    required String cardNumber,
    required String cardExpiryMonth,
    required String cardExpiryYear,
    String? cardCvv,
    bool setAsDefault = false,
  }) async {
    final callable = _functions.httpsCallable('paylinkSaveCard');
    final response = await callable.call<Map<String, dynamic>>({
      'firstName': firstName,
      'lastName': lastName,
      'cardNumber': cardNumber,
      'cardExpiryMonth': cardExpiryMonth,
      'cardExpiryYear': cardExpiryYear,
      if (cardCvv != null) 'cardCvv': cardCvv,
      'setAsDefault': setAsDefault,
    });
    return Map<String, dynamic>.from(response.data);
  }

  /// Delete a saved card and revoke its token
  Future<void> deleteCard(String cardId) async {
    final callable = _functions.httpsCallable('paylinkDeleteCard');
    await callable.call({
      'cardId': cardId,
    });
  }

  /// Stream saved cards for current user
  Stream<List<SavedCardModel>> streamSavedCards(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('savedCards')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SavedCardModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
