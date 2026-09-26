import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';

/// How long the first frame waits for the stored theme and language.
const Duration startupSettingsLimit = Duration(seconds: 2);

/// FE-A3 D5: the `app_settings` row before the first frame, so the app
/// paints its stored theme and language from the start. Null when the read
/// fails or is slow: the app then follows the platform until the stream
/// answers, and the Settings screen shows the failure (E3).
Future<AppSettingsEntity?> readStartupSettings(
  ProviderContainer container,
) async {
  // A provider with no listener is paused; this one listens while it reads.
  final subscription = container.listen(appSettingsProvider.future, (_, _) {});
  try {
    return await subscription.read().timeout(startupSettingsLimit);
  } on Failure {
    return null;
  } on TimeoutException {
    return null;
  } finally {
    subscription.close();
  }
}
