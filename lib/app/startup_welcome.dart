import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/app/startup_settings.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/presentation/providers/is_welcome_seen_use_case_provider.dart';
import 'package:memox/features/account/presentation/providers/welcome_due_provider.dart';

/// Account UI spec U1: Welcome shows once on every device of a build that
/// can sign in (plan ruling 3), decided before the first frame so nothing
/// flashes. A failed or slow read shows nothing; the next launch asks
/// again.
Future<void> showWelcomeIfDue(ProviderContainer container) async {
  if (container.read(accountCoordinatorProvider) == null) return;
  final bool isSeen;
  try {
    isSeen = await container
        .read(isWelcomeSeenUseCaseProvider)()
        .timeout(startupSettingsLimit);
  } on Failure {
    return;
  } on TimeoutException {
    return;
  }
  if (!isSeen) container.read(welcomeDueProvider.notifier).show();
}
