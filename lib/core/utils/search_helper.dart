class SearchHelper {
  /// Normalizes Arabic and English text for accurate search matching.
  /// Standardizes Alif variants (أ, إ, آ, ٱ -> ا), Teh Marbuta (ة -> ه),
  /// Alif Maqsura (ى -> ي), Hamza variants, strips Tashkeel/diacritics and Tatweel,
  /// and converts English letters to lowercase.
  static String normalize(String text) {
    if (text.isEmpty) return '';

    String normalized = text.toLowerCase();

    // Remove Tashkeel (diacritics)
    normalized = normalized.replaceAll(RegExp(r'[\u064B-\u0652]'), '');

    // Remove Tatweel (Kashida)
    normalized = normalized.replaceAll('\u0640', '');

    // Normalize Alif variants (أ, إ, آ, ٱ -> ا)
    normalized = normalized.replaceAll(RegExp(r'[\u0622\u0623\u0625\u0671]'), 'ا');

    // Normalize Teh Marbuta -> Heh (ة -> ه)
    normalized = normalized.replaceAll('ة', 'ه');

    // Normalize Alif Maqsura & Farsi/Kurdish Yeh -> Standard Yeh (ى, ی -> ي)
    normalized = normalized.replaceAll(RegExp(r'[\u0649\u06CC]'), 'ي');

    // Normalize Waw with Hamza -> Waw (ؤ -> و)
    normalized = normalized.replaceAll('ؤ', 'و');

    // Normalize Yeh with Hamza -> Yeh (ئ -> ي)
    normalized = normalized.replaceAll('ئ', 'ي');

    // Normalize Persian/Kurdish Keheh -> Standard Kaf (ک -> ك)
    normalized = normalized.replaceAll('ک', 'ك');

    return normalized.trim();
  }

  /// Checks if [text] matches [normalizedQuery] after normalizing [text].
  /// [normalizedQuery] should already be normalized using [SearchHelper.normalize].
  static bool matches(String? text, String normalizedQuery) {
    if (text == null || text.isEmpty || normalizedQuery.isEmpty) return false;
    return normalize(text).contains(normalizedQuery);
  }
}
