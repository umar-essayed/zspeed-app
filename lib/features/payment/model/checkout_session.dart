import 'package:equatable/equatable.dart';

class CheckoutSession extends Equatable {
  final String endpointUrl;
  final Map<String, String> signedFields;
  final DateTime expiresAt;

  const CheckoutSession({
    required this.endpointUrl,
    required this.signedFields,
    required this.expiresAt,
  });

  factory CheckoutSession.fromJson(Map<String, dynamic> json) {
    return CheckoutSession(
      endpointUrl: json['endpointUrl'] as String,
      signedFields: Map<String, String>.from(json['signedFields'] as Map),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'endpointUrl': endpointUrl,
      'signedFields': signedFields,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [endpointUrl, signedFields, expiresAt];
}