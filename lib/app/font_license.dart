import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Each bundled family and the asset holding its SIL Open Font License.
const List<(String, String)> _fonts = [
  ('Be Vietnam Pro', 'assets/fonts/OFL.txt'),
  ('Noto Sans KR', 'assets/fonts/OFL-NotoSansKR.txt'),
];

var _isRegistered = false;

/// Puts the bundled fonts' SIL Open Font Licenses on the licence page, as
/// the licence requires of anyone shipping the fonts. Safe to call more than
/// once.
void registerFontLicense() {
  if (_isRegistered) return;
  _isRegistered = true;
  LicenseRegistry.addLicense(() async* {
    for (final (family, asset) in _fonts) {
      final text = await rootBundle.loadString(asset);
      yield LicenseEntryWithLineBreaks([family], text);
    }
  });
}
