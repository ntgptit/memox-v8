import 'package:memox/core/text/unicode_form.dart';

/// The folded form of a text: trimmed, NFC, lowercased, then NFC again,
/// since lowercasing can leave a string outside NFC. schema.md defines
/// `front_folded`, `back_folded` and `tags.name_folded` this way, and every
/// search term, name sort and fill answer folds the same way so they
/// compare alike (BE-C5). Written in Dart because SQLite's `lower()` and
/// `NOCASE` fold ASCII only, and SQLite has no NFC.
String foldText(String text) => nfc(nfc(text.trim()).toLowerCase());
