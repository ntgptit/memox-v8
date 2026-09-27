import 'package:memox/core/text/unicode_form.dart';

/// The stored form of a text a person typed: trimmed, then NFC (BE-C5).
/// Every write of user text goes through it, so the store holds one form.
String storedText(String raw) => nfc(raw.trim());

/// [storedText] for an optional field: absent or blank is stored as null.
String? storedTextOrNull(String? raw) {
  if (raw == null) return null;
  final stored = storedText(raw);
  return stored.isEmpty ? null : stored;
}
