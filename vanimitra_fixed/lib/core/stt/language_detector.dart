// DEV 2 — per PDR Section 9.3
class LanguageDetector {
  static String detect(String text) {
    if (RegExp(r'[\u0900-\u097F]').hasMatch(text)) return 'hi';
    if (RegExp(r'[\u0B80-\u0BFF]').hasMatch(text)) return 'ta';
    return 'en';
  }
}
