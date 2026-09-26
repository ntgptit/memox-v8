import 'dart:typed_data';

/// Where an import reads its rows from (UC-TRANSFER-001 step 2).
sealed class ImportSource {
  const ImportSource();
}

/// A file the person picked, read in memory. Its [name] gives the format,
/// and is never logged or kept (BR-TRANSFER-006).
final class ImportFile extends ImportSource {
  const ImportFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

/// Rows the person pasted (UC-TRANSFER-001 A1).
final class PastedText extends ImportSource {
  const PastedText(this.text);

  final String text;
}
