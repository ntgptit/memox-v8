import 'dart:typed_data';

import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';

/// A finished export file, held in memory until the share sheet takes it
/// (BR-TRANSFER-014).
final class ExportArtifact {
  const ExportArtifact({
    required this.bytes,
    required this.fileName,
    required this.format,
  });

  final Uint8List bytes;
  final String fileName;
  final TransferFormat format;
}

/// How a share ended. Dismissing the share sheet is a cancel, never an
/// error (BR-TRANSFER-014).
enum ExportShareResult { shared, dismissed }

/// BR-TRANSFER-013: the deck's name without path separators, control
/// characters or characters a file system refuses, its white space runs
/// joined by one `-`, then the local date and the format's extension. A name
/// that sanitizes to nothing becomes `cards`.
String exportFileName({
  required String deckName,
  required DateTime date,
  required TransferFormat format,
}) {
  const fallback = 'cards';
  final sanitized = deckName
      .replaceAll(RegExp(r'[\\/:*?"<>|\u0000-\u001F\u007F-\u009F]'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), '-');
  final name = sanitized.isEmpty ? fallback : sanitized;
  final day = [
    date.year.toString().padLeft(4, '0'),
    date.month.toString().padLeft(2, '0'),
    date.day.toString().padLeft(2, '0'),
  ].join('-');
  return '$name-$day.${format.extension}';
}
