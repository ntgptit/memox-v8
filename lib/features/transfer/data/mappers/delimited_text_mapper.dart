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
const _recordEnd = '\r\n';
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

/// [records] as a CSV or TSV file (transfer spec D14): a UTF-8 BOM, then
/// each record and a CRLF; a cell is quoted, its quotes doubled, only when
/// it holds the delimiter, a quote, a CR or an LF, and is otherwise written
/// as it is (BR-TRANSFER-012).
Uint8List writeDelimited(List<List<String>> records, TransferFormat format) {
  final delimiter = switch (format) {
    TransferFormat.csv => _comma,
    TransferFormat.tsv => _tab,
  };
  final text = StringBuffer();
  for (final record in records) {
    text
      ..writeAll([
        for (final cell in record) _cellOf(cell, delimiter),
      ], delimiter)
      ..write(_recordEnd);
  }
  return Uint8List.fromList([..._utf8Bom, ...utf8.encode(text.toString())]);
}

String _cellOf(String cell, String delimiter) {
  final isQuoted =
      cell.contains(delimiter) ||
      cell.contains(_quote) ||
      cell.contains(_carriageReturn) ||
      cell.contains(_lineFeed);
  if (!isQuoted) return cell;
  return '$_quote${cell.replaceAll(_quote, '$_quote$_quote')}$_quote';
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

/// How many records a CSV file's delimiter is judged on (transfer spec D5).
const _sniffedRecords = 20;

/// The delimiter of a CSV file or of pasted text (transfer spec §5.2, D5),
/// from the first records that hold a character other than whitespace,
/// counting only what lies outside quotes: a tab when [isTabAllowed] and the
/// first record holds one; else the one of `;` and `,` that each of the
/// first [_sniffedRecords] records holds as often, at least once; else `;`
/// when the first record holds `;` and no `,`; `,` otherwise.
String _delimiterOf(String text, {required bool isTabAllowed}) {
  final records = _recordDelimiters(text);
  if (records.isEmpty) return _comma;
  final first = records.first;
  if (isTabAllowed && first.tabs > 0) return _tab;
  final isSemicolonSteady = _isSteady([
    for (final record in records) record.semicolons,
  ]);
  final isCommaSteady = _isSteady([
    for (final record in records) record.commas,
  ]);
  if (isSemicolonSteady && !isCommaSteady) return _semicolon;
  if (isCommaSteady && !isSemicolonSteady) return _comma;
  if (first.semicolons > 0 && first.commas == 0) return _semicolon;
  return _comma;
}

/// Every count is the same, and at least one.
bool _isSteady(List<int> counts) =>
    counts.first > 0 && counts.every((count) => count == counts.first);

/// The delimiters outside quotes of each of the first [_sniffedRecords]
/// records that hold a character other than whitespace.
List<({int commas, int semicolons, int tabs})> _recordDelimiters(String text) {
  final records = <({int commas, int semicolons, int tabs})>[];
  var commas = 0;
  var semicolons = 0;
  var tabs = 0;
  var hasText = false;
  var isQuoted = false;
  var isFieldStart = true;

  void endRecord() {
    if (hasText) {
      records.add((commas: commas, semicolons: semicolons, tabs: tabs));
    }
    commas = 0;
    semicolons = 0;
    tabs = 0;
    hasText = false;
    isFieldStart = true;
  }

  var index = 0;
  while (index < text.length && records.length < _sniffedRecords) {
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
      endRecord();
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
  if (records.length < _sniffedRecords) endRecord();
  return records;
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
