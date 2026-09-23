/// The folded form of a text: trimmed, then lowercased. schema.md defines
/// `front_folded`, `back_folded` and `tags.name_folded` this way, and every
/// search term and name sort folds the same way so they compare alike.
/// Written in Dart because SQLite's `lower()` and `NOCASE` fold ASCII only.
String foldText(String text) => text.trim().toLowerCase();
