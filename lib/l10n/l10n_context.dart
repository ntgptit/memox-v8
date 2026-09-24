import 'package:flutter/widgets.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// The one way UI code reads its strings.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
