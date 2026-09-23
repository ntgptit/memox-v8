import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const String _oflAsset = 'assets/fonts/OFL.txt';
const String _fontPackage = 'Plus Jakarta Sans';

var _isRegistered = false;

/// Puts the bundled font's SIL Open Font License on the licence page, as the
/// licence requires of anyone shipping the font. Safe to call more than once.
void registerFontLicense() {
  if (_isRegistered) return;
  _isRegistered = true;
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString(_oflAsset);
    yield LicenseEntryWithLineBreaks(const [_fontPackage], text);
  });
}
