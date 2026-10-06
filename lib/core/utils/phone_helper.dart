class PhoneHelper {
  /// Normalizes any input phone number format to the canonical Egyptian format: +201XXXXXXXXX.
  /// 
  /// Handles all cases:
  /// - "+201012345678" -> "+201012345678"
  /// - "+2001012345678" -> "+201012345678"
  /// - "201012345678" -> "+201012345678"
  /// - "2001012345678" -> "+201012345678"
  /// - "01012345678" -> "+201012345678"
  /// - "00201012345678" -> "+201012345678"
  /// - "002001012345678" -> "+201012345678"
  /// - "1012345678" -> "+201012345678"
  /// - Includes trimming spaces, dashes, parentheses.
  static String normalizePhone(String input) {
    // 1. Remove all spaces, hyphens, and other non-digit, non-plus characters
    String cleaned = input.replaceAll(RegExp(r'[^0-9+]'), '');

    // 2. Convert leading '0020' to '+20'
    if (cleaned.startsWith('0020')) {
      cleaned = '+20${cleaned.substring(4)}';
    }

    // 3. Normalize prefix
    if (cleaned.startsWith('+20')) {
      String rest = cleaned.substring(3);
      if (rest.startsWith('0')) {
        rest = rest.substring(1);
      }
      return '+20$rest';
    } else if (cleaned.startsWith('20')) {
      String rest = cleaned.substring(2);
      if (rest.startsWith('0')) {
        rest = rest.substring(1);
      }
      return '+20$rest';
    } else {
      // Local or partial format (e.g. 010... or 10...)
      if (cleaned.startsWith('0')) {
        cleaned = cleaned.substring(1);
      }
      return '+20$cleaned';
    }
  }

  /// Validates if the normalized phone is a valid Egyptian mobile number.
  /// Egyptian mobile numbers have 11 digits in local format (01XXXXXXXXX)
  /// which translates to 13 characters in E.164: +201XXXXXXXXX.
  static bool isValidEgyptianPhone(String normalized) {
    return RegExp(r'^\+201\d{9}$').hasMatch(normalized);
  }
}
