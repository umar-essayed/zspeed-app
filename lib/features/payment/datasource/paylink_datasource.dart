import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:z_speed/features/payment/model/saved_card_model.dart';

@lazySingleton
class PaylinkDatasource {
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  static const String _defaultPublicToken =
      'Wj5AYgn24icZmEviRWfCGpmk8cXJd2q61srOrDSeGTqsqJefACAfXMD4S1Nu';
  static const String _defaultHashToken =
      'lFKevvwEVv707kg7ybOKEDGH4luF4ZVNOrGYISAkccyVF2HFtyctBoXOEs15';
  static const String _baseUrl = 'https://pay.getpayin.com';
  static const String _returnScheme = 'zspeed://payment-return';
  static const String _webhookUrl =
      'https://us-central1-zspeed.cloudfunctions.net/paylinkWebhook';

  PaylinkDatasource({
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
  })  : _functions = functions ?? FirebaseFunctions.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  String _buildSignature(List<String> values, String hashToken) {
    final concatenated = values.join();
    final hmac = Hmac(sha256, utf8.encode(hashToken));
    final digest = hmac.convert(utf8.encode(concatenated));
    return base64.encode(digest.bytes);
  }

  Map<String, dynamic> _extractData(dynamic decodedJson) {
    if (decodedJson is Map<String, dynamic>) {
      if (decodedJson['data'] is Map<String, dynamic>) {
        return decodedJson['data'] as Map<String, dynamic>;
      }
      return decodedJson;
    }
    return <String, dynamic>{};
  }

  Future<Map<String, String>> _getCredentials() async {
    try {
      final doc = await _firestore.collection('sys_settings').doc('secrets').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final pub = data['paylink-public-token'] as String?;
        final hash = data['paylink-hash-token'] as String?;
        if (pub != null && pub.isNotEmpty && hash != null && hash.isNotEmpty) {
          return {'publicToken': pub, 'hashToken': hash};
        }
      }
    } catch (_) {}
    return {'publicToken': _defaultPublicToken, 'hashToken': _defaultHashToken};
  }

  /// Initialize a PayLink hosted checkout session for an Order or a Ride
  Future<Map<String, dynamic>> initCheckout({
    String? orderId,
    String? rideId,
  }) async {
    try {
      final callable = _functions.httpsCallable('paylinkInitCheckout');
      final response = await callable.call<Map<String, dynamic>>({
        if (orderId != null) 'orderId': orderId,
        if (rideId != null) 'rideId': rideId,
      });
      return Map<String, dynamic>.from(response.data);
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'not-found' || e.code == 'unavailable') {
        return _directInitCheckout(orderId: orderId, rideId: rideId);
      }
      rethrow;
    } catch (_) {
      return _directInitCheckout(orderId: orderId, rideId: rideId);
    }
  }

  Future<Map<String, dynamic>> _directInitCheckout({
    String? orderId,
    String? rideId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final creds = await _getCredentials();
    final publicToken = creds['publicToken']!;
    final hashToken = creds['hashToken']!;

    double amount = 0;
    String orderTitle = 'Z-SPEED Payment';
    DocumentReference? targetDocRef;

    if (orderId != null) {
      targetDocRef = _firestore.collection('orders').doc(orderId);
      final doc = await targetDocRef.get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        amount = (data['total'] as num?)?.toDouble() ?? 0.0;
        final shortId = orderId.length > 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase();
        orderTitle = 'Z-SPEED Order #$shortId';
      }
    } else if (rideId != null) {
      targetDocRef = _firestore.collection('rides').doc(rideId);
      final doc = await targetDocRef.get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        amount = (data['totalFare'] as num?)?.toDouble() ?? (data['estimatedFare'] as num?)?.toDouble() ?? 0.0;
        final shortId = rideId.length > 8 ? rideId.substring(0, 8).toUpperCase() : rideId.toUpperCase();
        orderTitle = 'Z-SPEED Ride #$shortId';
      }
    }

    if (amount <= 0) amount = 10.0;

    final customerName = user?.displayName ?? 'Valued Customer';
    final nameParts = customerName.trim().split(' ');
    final firstName = nameParts.first.isNotEmpty ? nameParts.first : 'Valued';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'Customer';
    final email = user?.email ?? 'customer_${user?.uid.substring(0, 6) ?? "guest"}@zspeed.app';
    final orderAmountStr = amount.toStringAsFixed(2);

    // Build signature according to INVOICE_CREATE spec
    final signedValues = [
      firstName,
      lastName,
      email,
      orderTitle,
      orderAmountStr,
      'Cairo',
      'Cairo',
      'EG',
      'EGP',
      _returnScheme,
      _webhookUrl,
    ];

    final signature = _buildSignature(signedValues, hashToken);

    final payload = {
      'token': publicToken,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'order_title': orderTitle,
      'order_amount': orderAmountStr,
      'address': 'Cairo',
      'city': 'Cairo',
      'country': 'EG',
      'currency': 'EGP',
      'redirection_url': _returnScheme,
      'webhook_url': _webhookUrl,
      'signature': signature,
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/api/v2/integration/init'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final resJson = jsonDecode(response.body);
      final data = _extractData(resJson);
      final checkoutUrl = (data['checkout_url'] ?? data['checkoutUrl'])?.toString() ?? '';
      final invoiceId = (data['invoice_id'] ?? data['invoiceId'] as num?)?.toInt() ?? 0;
      final expiresAt = (data['expires_at'] ?? data['expiresAt'])?.toString() ?? '';

      if (checkoutUrl.isEmpty) {
        String msg = 'PayLink returned empty checkout URL';
        if (resJson is Map && resJson['message'] != null) {
          msg = resJson['message'].toString();
        }
        throw Exception(msg);
      }

      if (targetDocRef != null) {
        await targetDocRef.update({
          'paymentInvoiceId': invoiceId,
          'paymentInvoiceUrl': checkoutUrl,
          'paymentState': 'pending_gateway',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return {
        'checkoutUrl': checkoutUrl,
        'invoiceId': invoiceId,
        'expiresAt': expiresAt,
      };
    } else {
      String errMsg = 'PayLink init error: ${response.statusCode} - ${response.body}';
      try {
        final errJson = jsonDecode(response.body);
        if (errJson is Map && errJson['message'] != null) {
          errMsg = errJson['message'].toString();
        }
      } catch (_) {}
      throw Exception(errMsg);
    }
  }

  /// Charge a vaulted Card Token for an Order or a Ride
  Future<Map<String, dynamic>> chargeSavedCard({
    required String cardId,
    String? orderId,
    String? rideId,
  }) async {
    try {
      final callable = _functions.httpsCallable('paylinkChargeSavedCard');
      final response = await callable.call<Map<String, dynamic>>({
        'cardId': cardId,
        if (orderId != null) 'orderId': orderId,
        if (rideId != null) 'rideId': rideId,
      });
      return Map<String, dynamic>.from(response.data);
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'not-found' || e.code == 'unavailable') {
        return _directChargeSavedCard(cardId: cardId, orderId: orderId, rideId: rideId);
      }
      rethrow;
    } catch (_) {
      return _directChargeSavedCard(cardId: cardId, orderId: orderId, rideId: rideId);
    }
  }

  Future<Map<String, dynamic>> _directChargeSavedCard({
    required String cardId,
    String? orderId,
    String? rideId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated.');

    final cardDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('savedCards')
        .doc(cardId)
        .get();

    if (!cardDoc.exists || cardDoc.data() == null) {
      throw Exception('Saved card not found.');
    }

    final cardData = cardDoc.data()!;
    final cardToken = cardData['cardToken'] as String;

    final creds = await _getCredentials();
    final publicToken = creds['publicToken']!;
    final hashToken = creds['hashToken']!;

    double amount = 0;
    String product = 'Z-SPEED Order';
    DocumentReference? targetDocRef;

    if (orderId != null) {
      targetDocRef = _firestore.collection('orders').doc(orderId);
      final doc = await targetDocRef.get();
      if (doc.exists && doc.data() != null) {
        amount = ((doc.data() as Map<String, dynamic>)['total'] as num?)?.toDouble() ?? 0.0;
        product = 'Order #${orderId.substring(0, 8).toUpperCase()}';
      }
    } else if (rideId != null) {
      targetDocRef = _firestore.collection('rides').doc(rideId);
      final doc = await targetDocRef.get();
      if (doc.exists && doc.data() != null) {
        amount = ((doc.data() as Map<String, dynamic>)['totalFare'] as num?)?.toDouble() ?? 0.0;
        product = 'Ride #${rideId.substring(0, 8).toUpperCase()}';
      }
    }

    if (amount <= 0) amount = 10.0;

    final nameParts = (user.displayName ?? 'Customer').trim().split(' ');
    final firstName = nameParts.first.isNotEmpty ? nameParts.first : 'Valued';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'Customer';
    final priceStr = amount.toStringAsFixed(2);
    final refNum = (orderId ?? rideId ?? 'ref_${DateTime.now().millisecondsSinceEpoch}').substring(0, 16);

    // CARD_CHARGE fields
    final signedValues = [
      cardToken,
      'merchant',
      firstName,
      lastName,
      user.email ?? 'customer@zspeed.app',
      'EGP',
      priceStr,
      product,
      refNum,
      'EG',
      'Cairo',
      'Cairo',
    ];

    final signature = _buildSignature(signedValues, hashToken);

    final payload = {
      'token': publicToken,
      'card_token': cardToken,
      'initiator': 'merchant',
      'first_name': firstName,
      'last_name': lastName,
      'email': user.email ?? 'customer@zspeed.app',
      'currency': 'EGP',
      'price': priceStr,
      'product': product,
      'reference_number': refNum,
      'country': 'EG',
      'address': 'Cairo',
      'city': 'Cairo',
      'signature': signature,
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/api/v2/integration/tokens/charge'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final resJson = jsonDecode(response.body);
      final data = _extractData(resJson);
      final invoiceId = (data['invoice_id'] ?? data['invoiceId'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch;
      final paidStatus = (data['paid_status'] ?? data['paidStatus'] ?? 'paid')
          .toString()
          .toUpperCase();

      if (paidStatus != 'PAID') {
        final reason = (data['message'] ?? data['reason_code'] ?? paidStatus).toString();
        throw Exception('Payment not approved: $reason');
      }

      if (targetDocRef != null) {
        await targetDocRef.update({
          'paymentStatus': 'completed',
          'paymentState': 'paid',
          'status': 'pending',
          'paymentInvoiceId': invoiceId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return {
        'success': true,
        'invoiceId': invoiceId,
        'paidStatus': paidStatus,
      };
    } else {
      String errMsg = 'PayLink card charge error: ${response.statusCode}';
      try {
        final errJson = jsonDecode(response.body);
        if (errJson is Map && errJson['message'] != null) {
          errMsg = errJson['message'].toString();
        }
      } catch (_) {}
      throw Exception(errMsg);
    }
  }

  /// Securely tokenize and save a card
  Future<Map<String, dynamic>> saveCard({
    required String firstName,
    required String lastName,
    required String cardNumber,
    required String cardExpiryMonth,
    required String cardExpiryYear,
    String? cardCvv,
    bool setAsDefault = false,
  }) async {
    try {
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
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'not-found' || e.code == 'unavailable') {
        return _directSaveCard(
          firstName: firstName,
          lastName: lastName,
          cardNumber: cardNumber,
          cardExpiryMonth: cardExpiryMonth,
          cardExpiryYear: cardExpiryYear,
          cardCvv: cardCvv,
          setAsDefault: setAsDefault,
        );
      }
      rethrow;
    } catch (_) {
      return _directSaveCard(
        firstName: firstName,
        lastName: lastName,
        cardNumber: cardNumber,
        cardExpiryMonth: cardExpiryMonth,
        cardExpiryYear: cardExpiryYear,
        cardCvv: cardCvv,
        setAsDefault: setAsDefault,
      );
    }
  }

  Future<Map<String, dynamic>> _directSaveCard({
    required String firstName,
    required String lastName,
    required String cardNumber,
    required String cardExpiryMonth,
    required String cardExpiryYear,
    String? cardCvv,
    bool setAsDefault = false,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in.');

    final creds = await _getCredentials();
    final publicToken = creds['publicToken']!;
    final hashToken = creds['hashToken']!;

    final cleanCard = cardNumber.replaceAll(RegExp(r'\D'), '');
    String last4 = cleanCard.length >= 4 ? cleanCard.substring(cleanCard.length - 4) : cleanCard;
    final expMonth = cardExpiryMonth.padLeft(2, '0');
    final expYear = cardExpiryYear.length == 2 ? '20$cardExpiryYear' : cardExpiryYear;

    String brand = 'Card';
    if (cleanCard.startsWith('4')) {
      brand = 'Visa';
    } else if (cleanCard.startsWith(RegExp(r'5[1-5]')) || cleanCard.startsWith(RegExp(r'2[2-7]'))) {
      brand = 'MasterCard';
    } else if (cleanCard.startsWith('5078') || cleanCard.startsWith('6378')) {
      brand = 'Meeza';
    }

    final email = user.email ?? 'customer_${user.uid.substring(0, 6)}@zspeed.app';

    // Build signature according to CARD_TOKENIZE
    final signedValues = [
      firstName,
      lastName,
      email,
      cleanCard,
      expMonth,
      expYear,
      if (cardCvv != null && cardCvv.isNotEmpty) cardCvv,
      'EG',
      'Cairo',
      'Cairo',
    ];

    final signature = _buildSignature(signedValues, hashToken);

    final payload = {
      'token': publicToken,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'card_number': cleanCard,
      'card_expiry_month': expMonth,
      'card_expiry_year': expYear,
      if (cardCvv != null && cardCvv.isNotEmpty) 'card_cvv': cardCvv,
      'country': 'EG',
      'address': 'Cairo',
      'city': 'Cairo',
      'signature': signature,
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/api/v2/integration/tokens/card'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final resJson = jsonDecode(response.body);
      final data = _extractData(resJson);

      final token = (data['token'] ??
              data['card_token'] ??
              (resJson is Map ? resJson['token'] : null))
          ?.toString();

      if (token == null || token.isEmpty) {
        String msg = 'Card tokenization failed: Token not found in response';
        if (resJson is Map && resJson['message'] != null) {
          msg = resJson['message'].toString();
        }
        throw Exception(msg);
      }

      if (data['card'] is Map<String, dynamic>) {
        final c = data['card'] as Map<String, dynamic>;
        if (c['brand'] != null && c['brand'].toString().isNotEmpty) {
          brand = c['brand'].toString();
        }
        if (c['last4'] != null && c['last4'].toString().isNotEmpty) {
          last4 = c['last4'].toString();
        }
      }

      final savedCardsCol = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('savedCards');

      if (setAsDefault) {
        final existing = await savedCardsCol.where('isDefault', isEqualTo: true).get();
        for (final doc in existing.docs) {
          await doc.reference.update({'isDefault': false});
        }
      }

      final docRef = savedCardsCol.doc();

      await docRef.set({
        'id': docRef.id,
        'cardToken': token,
        'last4': last4,
        'brand': brand,
        'expMonth': int.tryParse(expMonth) ?? 12,
        'expYear': int.tryParse(expYear) ?? 2030,
        'holderName': '$firstName $lastName'.trim(),
        'isDefault': setAsDefault,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'cardId': docRef.id,
        'cardToken': token,
        'last4': last4,
        'brand': brand,
      };
    } else {
      String errMsg = 'Card tokenization failed: ${response.statusCode}';
      try {
        final errJson = jsonDecode(response.body);
        if (errJson is Map && errJson['message'] != null) {
          errMsg = errJson['message'].toString();
        }
      } catch (_) {}
      throw Exception(errMsg);
    }
  }

  /// Delete a saved card and revoke its token
  Future<void> deleteCard(String cardId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('savedCards')
          .doc(cardId)
          .delete();
    }
    try {
      final callable = _functions.httpsCallable('paylinkDeleteCard');
      await callable.call({'cardId': cardId});
    } catch (_) {}
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
