import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';

/// CSV and TSV through the `csv` package, and the strict UTF-8 reading
/// BR-TRANSFER-006 asks for. The only file that imports `csv`.
final class DelimitedTextDataSource {
  const DelimitedTextDataSource();

  static const comma = ',';
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

  /// Pasted text is tab-separated when its first line has a tab, else
  /// comma-separated (UC-TRANSFER-001 A1).
  String delimiterOfPasted(String text) {
    final firstLineEnd = text.indexOf('\n');
    final firstLine = firstLineEnd < 0 ? text : text.substring(0, firstLineEnd);
    return firstLine.contains(tab) ? tab : comma;
  }

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
