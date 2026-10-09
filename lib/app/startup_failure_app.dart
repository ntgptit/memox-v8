import 'package:flutter/material.dart';
import 'package:memox/app/app_bootstrap.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';

/// The recovery screen when the database did not open (DEV-195): the app's
/// theme and language, one error state with Retry, and Send report. It says
/// first that nothing was deleted, names the upgrade step that stopped when
/// it was one, and never touches the file itself.
class StartupFailureApp extends StatelessWidget {
  const StartupFailureApp({
    super.key,
    required this.failure,
    required this.onRetry,
    required this.onSendReport,
    this.isRetrying = false,
    this.isReportQueued = false,
  });

  final StartupDatabaseUnavailable failure;
  final VoidCallback onRetry;
  final VoidCallback onSendReport;

  /// Retry holds a spinner while the start runs again.
  final bool isRetrying;

  /// Send report was tapped: the button gives way to the confirmation.
  final bool isReportQueued;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    theme: buildLightTheme(),
    darkTheme: buildDarkTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: _StartupFailureScreen(
      failure: failure,
      onRetry: onRetry,
      onSendReport: onSendReport,
      isRetrying: isRetrying,
      isReportQueued: isReportQueued,
    ),
  );
}

class _StartupFailureScreen extends StatelessWidget {
  const _StartupFailureScreen({
    required this.failure,
    required this.onRetry,
    required this.onSendReport,
    required this.isRetrying,
    required this.isReportQueued,
  });

  final StartupDatabaseUnavailable failure;
  final VoidCallback onRetry;
  final VoidCallback onSendReport;
  final bool isRetrying;
  final bool isReportQueued;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final migration = failure.migration;
    final body = migration == null
        ? l10n.startupDatabaseErrorBody
        : '${l10n.startupDatabaseMigrationHint(migration.$1, migration.$2)}\n'
              '${l10n.startupDatabaseErrorBody}';
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.section),
          children: [
            MxErrorState(
              title: l10n.startupDatabaseErrorTitle,
              body: body,
              retryLabel: l10n.commonRetry,
              onRetry: onRetry,
              isRetrying: isRetrying,
            ),
            const SizedBox(height: AppSpacing.gutter),
            if (isReportQueued)
              Text(
                l10n.startupReportQueued,
                style: context.textStyles.emptyBody,
                textAlign: TextAlign.center,
              )
            else
              MxButton(
                label: l10n.startupSendReport,
                tone: MxButtonTone.secondary,
                isBlock: true,
                onPressed: onSendReport,
              ),
          ],
        ),
      ),
    );
  }
}
