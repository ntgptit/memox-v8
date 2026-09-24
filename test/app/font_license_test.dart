import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/font_license.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the Plus Jakarta Sans OFL notice is on the licence page', () async {
    registerFontLicense();

    final entries = await LicenseRegistry.licenses.toList();
    final font = entries.where((e) => e.packages.contains('Plus Jakarta Sans'));
    expect(font, isNotEmpty);
    expect(
      font.first.paragraphs.map((p) => p.text).join(' '),
      contains('SIL Open Font License'),
    );
  });
}
