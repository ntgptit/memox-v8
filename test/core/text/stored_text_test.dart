import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/text/stored_text.dart';

// BE-C5: one stored form whatever form the text arrives in (local backend
// spec 2026-09-27 §4).
const _congNfc = 'công'; // công, precomposed
const _congNfd = 'công'; // c + o + combining circumflex + ng
const _babNfc = '밥'; // 밥, one syllable
const _babJamo = '밥'; // ㅂ ㅏ ㅂ as conjoining jamo

void main() {
  test('stored text is trimmed and in NFC, whatever form it arrives in', () {
    expect(storedText('  $_congNfd '), _congNfc);
    expect(storedText(_congNfc), _congNfc);
    expect(storedText(_babJamo), _babNfc);
  });

  test('a blank optional field is stored as null', () {
    expect(storedTextOrNull(null), isNull);
    expect(storedTextOrNull('  '), isNull);
    expect(storedTextOrNull(' $_congNfd'), _congNfc);
  });
}
