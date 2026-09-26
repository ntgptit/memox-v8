import 'dart:convert';
import 'dart:typed_data';

import 'package:characters/characters.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';

/// Which cards an export takes (BR-TRANSFER-007): it follows from where the
/// person opened it, and the sheet never changes it.
sealed class ExportScope {
  const ExportScope();
}

/// Every active card of the deck itself, whatever the list shows.
final class ExportAllCards extends ExportScope {
  const ExportAllCards();
}

/// The cards the person selected, each once.
final class ExportSelectedCards extends ExportScope {
  const ExportSelectedCards(this.cardIds);

  final Set<String> cardIds;
}

/// The file an export made, for the private cache and the share sheet
/// (BR-TRANSFER-014; transfer spec D16).
final class ExportFile {
  const ExportFile({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
    required this.cardCount,
  });

  final String fileName;
  final String mimeType;
  final Uint8List bytes;
  final int cardCount;
}

/// The longest a file name's deck part may be: with the date and the
/// extension it stays within the 255 bytes a file system takes.
const exportNameMaxBytes = 200;

const _fallbackName = 'cards';

final _whitespace = RegExp(r'\s+');
final _invalid = RegExp(r'[<>:"/\\|?*\u0000-\u001F\u007F-\u009F]');
final _outerSpacesAndDots = RegExp(r'^[ .]+|[ .]+$');

/// The name of an export's file (BR-TRANSFER-013; transfer spec D15): the
/// deck's name without path separators, characters no file system takes
/// and control characters, its whitespace runs made one space, no space or
/// dot at either end, and cut to [exportNameMaxBytes] UTF-8 bytes on whole
/// characters, or `cards` when nothing is left; then a space, the day of
/// [now] as `yyyy-MM-dd`, and the format's extension.
String exportFileName({
  required String deckName,
  required DateTime now,
  required TransferFormat format,
}) {
  final cleaned = _strip(
    deckName.replaceAll(_whitespace, ' ').replaceAll(_invalid, ''),
  ).replaceAll(_whitespace, ' ');
  final name = _strip(_cutToBytes(cleaned, exportNameMaxBytes));
  final day = '${now.year}-${_twoDigits(now.month)}-${_twoDigits(now.day)}';
  return '${name.isEmpty ? _fallbackName : name} $day.${format.fileExtension}';
}

String _strip(String name) => name.replaceAll(_outerSpacesAndDots, '');

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String _cutToBytes(String text, int maxBytes) {
  final kept = StringBuffer();
  var bytes = 0;
  for (final character in text.characters) {
    bytes += utf8.encode(character).length;
    if (bytes > maxBytes) break;
    kept.write(character);
  }
  return kept.toString();
}
