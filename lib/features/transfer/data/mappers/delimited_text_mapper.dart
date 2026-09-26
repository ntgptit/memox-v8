import 'dart:convert';
import 'dart:typed_data';

import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/import_sheet_model.dart';
import 'package:memox/features/transfer/domain/models/import_source_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';

const _comma = ',';
const _semicolon = ';';
const _tab = '\t';
const _quote = '"';
const _carriageReturn = '\r';
const _lineFeed = '\n';
const _utf8Bom = [0xEF, 0xBB, 0xBF];
const _utf16LittleEndianBom = [0xFF, 0xFE];
const _utf16BigEndianBom = [0xFE, 0xFF];

/// [source] read as one sheet (transfer spec §5): a file by its extension
/// and as strict UTF-8, pasted text as it is. Pure, so it can run on
/// another isolate.
Outcome<ImportDocument, TransferRejection> readDelimited(ImportSource source) {
  switch (source) {
    case PastedText(:final text):
      final body = text.startsWith('\uFEFF') ? text.substring(1) : text;
      return _records(body, _delimiterOf(body, isTabAllowed: true));
    case ImportFile(:final name, :final bytes):
      final format = TransferFormat.ofFileName(name);
      if (format == null) {
        return const Rejected(TransferRejection.unsupportedFormat);
      }
      final text = _decodeUtf8(bytes);
      if (text == null) return const Rejected(TransferRejection.notUtf8);
      return _records(text, switch (format) {
        TransferFormat.csv => _delimiterOf(text, isTabAllowed: false),
        TransferFormat.tsv => _tab,
      });
  }
}

/// [bytes] as strict UTF-8 after an optional UTF-8 BOM; null when they are
/// not UTF-8: a UTF-16 or UTF-32 BOM, a malformed sequence, or a U+0000,
/// which UTF-16 without a BOM leaves (transfer spec D4). Nothing guesses
/// another encoding (BR-TRANSFER-006).
String? _decodeUtf8(Uint8List bytes) {
  if (_startsWith(bytes, _utf16LittleEndianBom) ||
      _startsWith(bytes, _utf16BigEndianBom)) {
    return null;
  }
  final body = _startsWith(bytes, _utf8Bom)
      ? Uint8List.sublistView(bytes, _utf8Bom.length)
      : bytes;
  final String text;
  try {
    text = utf8.decode(body);
  } on FormatException {
    // The error quotes the bytes, the person's own content: it stays here
    // (BR-TRANSFER-006), and the reason is what the caller needs.
    return null;
  }
  return text.contains('\u0000') ? null : text;
}

bool _startsWith(Uint8List bytes, List<int> prefix) {
  if (bytes.length < prefix.length) return false;
  for (var index = 0; index < prefix.length; index++) {
    if (bytes[index] != prefix[index]) return false;
  }
  return true;
}

/// The delimiter of a CSV file or of pasted text (transfer spec §5.2), from
/// the first record that holds anything but whitespace, counting only what
/// lies outside quotes: a tab when [isTabAllowed] and the record holds one;
/// `;` when it holds `;` and no `,`; `,` otherwise.
String _delimiterOf(String text, {required bool isTabAllowed}) {
  final (:commas, :semicolons, :tabs) = _firstRecordDelimiters(text);
  if (isTabAllowed && tabs > 0) return _tab;
  if (semicolons > 0 && commas == 0) return _semicolon;
  return _comma;
}

({int commas, int semicolons, int tabs}) _firstRecordDelimiters(String text) {
  var commas = 0;
  var semicolons = 0;
  var tabs = 0;
  var hasText = false;
  var isQuoted = false;
  var isFieldStart = true;
  var index = 0;
  while (index < text.length) {
    final char = text[index];
    index++;
    if (isQuoted) {
      if (char != _quote) continue;
      if (index < text.length && text[index] == _quote) {
        index++;
        continue;
      }
      isQuoted = false;
      continue;
    }
    if (char == _carriageReturn || char == _lineFeed) {
      if (hasText) break;
      commas = 0;
      semicolons = 0;
      tabs = 0;
      isFieldStart = true;
      continue;
    }
    if (char == _quote && isFieldStart) {
      isQuoted = true;
      hasText = true;
      isFieldStart = false;
      continue;
    }
    isFieldStart = char == _comma || char == _semicolon || char == _tab;
    switch (char) {
      case _comma:
        commas++;
      case _semicolon:
        semicolons++;
      case _tab:
        tabs++;
      default:
        if (char.trim().isNotEmpty) hasText = true;
    }
  }
  return (commas: commas, semicolons: semicolons, tabs: tabs);
}

/// The records of [text], split by [delimiter] (RFC 4180, with the
/// leniencies of transfer spec §5.3), numbered from 1; `unreadable` when a
/// quoted field never closes.
Outcome<ImportDocument, TransferRejection> _records(
  String text,
  String delimiter,
) {
  final rows = <ImportRow>[];
  var cells = <String>[];
  final cell = StringBuffer();
  var isQuoted = false;
  var isFieldStart = true;
  var isRecordOpen = false;

  void endField() {
    cells.add(cell.toString());
    cell.clear();
    isFieldStart = true;
  }

  void endRecord() {
    endField();
    rows.add(ImportRow(number: rows.length + 1, cells: cells));
    cells = [];
    isRecordOpen = false;
  }

  var index = 0;
  while (index < text.length) {
    final char = text[index];
    index++;
    isRecordOpen = true;
    if (isQuoted) {
      if (char != _quote) {
        cell.write(char);
        continue;
      }
      if (index < text.length && text[index] == _quote) {
        cell.write(_quote);
        index++;
        continue;
      }
      isQuoted = false;
      continue;
    }
    if (char == _quote && isFieldStart) {
      isQuoted = true;
      isFieldStart = false;
      continue;
    }
    if (char == delimiter) {
      endField();
      continue;
    }
    if (char == _carriageReturn || char == _lineFeed) {
      final isCrLf =
          char == _carriageReturn &&
          index < text.length &&
          text[index] == _lineFeed;
      if (isCrLf) index++;
      endRecord();
      continue;
    }
    isFieldStart = false;
    cell.write(char);
  }
  if (isQuoted) return const Rejected(TransferRejection.unreadable);
  if (isRecordOpen) endRecord();
  return Ok(ImportDocument([ImportSheet(rows: rows)]));
}
