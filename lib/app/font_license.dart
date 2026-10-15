import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Each bundled font with its SIL Open Font License asset.
const _fontLicenses = <(String package, String asset)>[
  ('Be Vietnam Pro', 'assets/fonts/OFL-BeVietnamPro.txt'),
  ('Noto Sans KR', 'assets/fonts/OFL-NotoSansKR.txt'),
];

var _isRegistered = false;

/// Puts the bundled fonts' SIL Open Font License on the licence page, as the
/// licence requires of anyone shipping the fonts. Safe to call more than once.
void registerFontLicense() {
  if (_isRegistered) return;
  _isRegistered = true;
  LicenseRegistry.addLicense(() async* {
    for (final (package, asset) in _fontLicenses) {
      final text = await rootBundle.loadString(asset);
      yield LicenseEntryWithLineBreaks([package], text);
    }
  });
}
