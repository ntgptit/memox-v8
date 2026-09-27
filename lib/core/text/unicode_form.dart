import 'package:unorm_dart/unorm_dart.dart' as unorm;

/// The one door to Unicode normalisation (BE-C5): text is stored and folded
/// in NFC, so a word typed precomposed and one typed decomposed (Vietnamese
/// marks, Hangul pasted as conjoining jamo) are the same string. No other
/// file imports `unorm_dart` (guard rule).
String nfc(String text) => unorm.nfc(text);
