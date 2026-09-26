import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';

/// CSV and TSV through the `csv` package, the strict UTF-8 reading
/// BR-TRANSFER-006 asks for, and the delimiter a CSV file or pasted text
/// uses (spec D9). The only file that imports `csv`.
final class DelimitedTextDataSource {
  const DelimitedTextDataSource();

  static const comma = ',';
  static const semicolon = ';';
  static const tab = '\t';
  static const _byteOrderMark = [0xEF, 0xBB, 0xBF];
  static const _nul = '\u0000';

  /// The text of [bytes] read as UTF-8, a leading BOM dropped. Throws
  /// [FormatException] for anything that is not UTF-8, and for a NUL, which
  /// UTF-8 text never holds but UTF-16 without a BOM does.
  String decodeUtf8(Uint8List bytes) {
    final hasByteOrderMark =
        bytes.length >= _byteOrderMark.length &&
        bytes[0] == _byteOrderMark[0] &&
        bytes[1] == _byteOrderMark[1] &&
        bytes[2] == _byteOrderMark[2];
    final text = utf8.decode(
      hasByteOrderMark ? bytes.sublist(_byteOrderMark.length) : bytes,
    );
    if (text.contains(_nul)) throw const FormatException('not UTF-8');
    return text;
  }

  /// Pasted text is tab-separated when its first record that holds text has
  /// a tab outside quotes; else it reads as a CSV file (UC-TRANSFER-001 A1).
  String delimiterOfPasted(String text) {
    final records = _recordDelimiters(text);
    if (records.isNotEmpty && records.first.tabs > 0) return tab;
    return _csvDelimiterOf(records);
  }

  /// The delimiter of a CSV file (UC-TRANSFER-001 step 3, spec D9): the one
  /// of `;` and `,` that each of its first [_sniffedRecords] records that
  /// hold text holds as often, at least once, outside quotes; when both or
  /// neither do, `;` if the first of them holds `;` and no `,`, else `,`.
  String delimiterOfCsv(String text) =>
      _csvDelimiterOf(_recordDelimiters(text));

  /// Every row, blank ones kept so row numbers match the source.
  List<List<String>> parse(String text, String delimiter) {
    final withoutByteOrderMark = text.startsWith('﻿')
        ? text.substring(1)
        : text;
    final rows = Csv(
      fieldDelimiter: delimiter,
      autoDetect: false,
      skipEmptyLines: false,
    ).decode(withoutByteOrderMark);
    return [
      for (final row in rows) [for (final cell in row) '$cell'],
    ];
  }

  /// UTF-8 with a BOM, CRLF line ends, fields quoted when needed
  /// (BR-TRANSFER-012).
  Uint8List encode(List<List<String>> rows, String delimiter) =>
      utf8.encode(Csv(fieldDelimiter: delimiter, addBom: true).encode(rows));
}

/// How many records a CSV file's delimiter is judged on (spec D9).
const _sniffedRecords = 20;
const _quote = '"';
const _lineFeed = '\n';
const _carriageReturn = '\r';

typedef _Delimiters = ({int commas, int semicolons, int tabs});

String _csvDelimiterOf(List<_Delimiters> records) {
  if (records.isEmpty) return DelimitedTextDataSource.comma;
  final isSemicolonSteady = _isSteady([
    for (final record in records) record.semicolons,
  ]);
  final isCommaSteady = _isSteady([
    for (final record in records) record.commas,
  ]);
  if (isSemicolonSteady && !isCommaSteady) {
    return DelimitedTextDataSource.semicolon;
  }
  if (isCommaSteady && !isSemicolonSteady) return DelimitedTextDataSource.comma;
  final first = records.first;
  if (first.semicolons > 0 && first.commas == 0) {
    return DelimitedTextDataSource.semicolon;
  }
  return DelimitedTextDataSource.comma;
}

/// Every count is the same, and at least one.
bool _isSteady(List<int> counts) =>
    counts.first > 0 && counts.every((count) => count == counts.first);

/// The delimiters outside quotes of each of the first [_sniffedRecords]
/// records that hold a character other than whitespace. A quote opens a
/// quoted field only where a field starts.
List<_Delimiters> _recordDelimiters(String text) {
  final records = <_Delimiters>[];
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
    isFieldStart =
        char == DelimitedTextDataSource.comma ||
        char == DelimitedTextDataSource.semicolon ||
        char == DelimitedTextDataSource.tab;
    switch (char) {
      case DelimitedTextDataSource.comma:
        commas++;
      case DelimitedTextDataSource.semicolon:
        semicolons++;
      case DelimitedTextDataSource.tab:
        tabs++;
      default:
        if (char.trim().isNotEmpty) hasText = true;
    }
  }
  if (records.length < _sniffedRecords) endRecord();
  return records;
}
