import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/font_license.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/logging/di/logging_providers.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/account/presentation/widgets/sections/account_layer_host_widget.dart';
import 'package:memox/features/reminders/data/datasources/reminder_plugins_data_source.dart';
import 'package:memox/features/reminders/di/reminder_plugins_data_source_provider.dart';
import 'package:memox/features/reminders/presentation/providers/reconcile_reminder_provider.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/features/study/presentation/providers/abandon_stale_sessions_use_case_provider.dart';
import 'package:memox/features/trash/presentation/providers/purge_expired_trash_use_case_provider.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// The composition root: themes, localization and the router, the start-up
/// close of an earlier day's open study session (FE-A6 D9), and the Trash's
/// auto-purge at start and on every resume (FE-B1 D5), and the daily
/// reminder's start-up Reconcile and tap route (BE-B5b), and the account
/// transition layer (account UI spec U4). The theme and the language follow
/// the `app_settings` row (BR-SETTINGS-005, BR-SETTINGS-006).
class MemoxApp extends ConsumerStatefulWidget {
  const MemoxApp({
    super.key,
    this.hasGallery = kDebugMode,
    this.initialSettings,
  });

  /// Registers the debug-only component gallery.
  final bool hasGallery;

  /// The row `main()` read before the first frame (FE-A3 D5); null follows
  /// the platform until the stream answers.
  final AppSettingsEntity? initialSettings;

  @override
  ConsumerState<MemoxApp> createState() => _MemoxAppState();
}

class _MemoxAppState extends ConsumerState<MemoxApp> {
  // Owned here, not at top level, so each app instance starts at its initial
  // location and a disposed app releases its router.
  late final GoRouter _router = buildAppRouter(hasGallery: widget.hasGallery);

  /// A resume after a day away purges what expired meanwhile (UC-TRASH-001
  /// A4); a resume and a pause are logged (ADR-018).
  late final AppLifecycleListener _lifecycle;

  /// Taps on the daily reminder while the app runs (BR-REMINDER-008).
  StreamSubscription<String?>? _reminderTaps;

  @override
  void initState() {
    super.initState();
    // Android 15 draws edge-to-edge regardless; earlier versions opt in here.
    // Every inset is read from MediaQuery.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    registerFontLicense();
    // A session left open on an earlier day closes as interrupted before
    // anything could offer it (BR-STUDY-072). Unawaited: the entry already
    // offers no earlier day's session, so no frame waits for it.
    unawaited(_closeStaleSessions());
    unawaited(_purgeExpiredTrash());
    _lifecycle = AppLifecycleListener(
      onResume: () {
        appLogger.info('lifecycle.resume', category: LogCategory.lifecycle);
        unawaited(_purgeExpiredTrash());
        // The local offset may have changed while the app slept
        // (BR-REMINDER-009); Reconcile schedules from the offset now.
        unawaited(_reconcileReminder());
        // The logs of the last session go up while the app is in front
        // (ADR-018 §3).
        unawaited(ref.read(logSchedulerProvider)?.syncNow());
      },
      onPause: () {
        appLogger.info('lifecycle.pause', category: LogCategory.lifecycle);
        // What is still queued reaches the buffer before the app may die.
        unawaited(appLogger.flush());
      },
    );
    _followReminderTaps();
    unawaited(_reconcileReminder());
  }

  /// A tap on the reminder opens Study Home, whether the app was running or
  /// the tap launched it (BR-REMINDER-008). No plugins, no taps: Web and
  /// every platform but Android.
  void _followReminderTaps() {
    final plugins = ref.read(reminderPluginsDataSourceProvider);
    if (plugins == null) return;
    _reminderTaps = plugins.taps.listen(_openFromReminder);
    unawaited(_openFromLaunch(plugins));
  }

  /// A plugin that cannot say what launched the app leaves it where it
  /// opens; the reminder's taps and schedule do not depend on it.
  Future<void> _openFromLaunch(ReminderPluginsDataSource plugins) async {
    final String? payload;
    try {
      payload = await plugins.launchPayload();
    } on Object {
      return;
    }
    _openFromReminder(payload);
  }

  void _openFromReminder(String? payload) {
    if (payload != reminderTapPayload || !mounted) return;
    _router.go(AppRoutes.study);
  }

  /// UC-REMINDER-001 step 6: the pending alarm follows the stored reminder
  /// again, through the gate. A refusal changes nothing the person sees; the
  /// next start tries again.
  Future<void> _reconcileReminder() async {
    try {
      await ref.read(reconcileReminderProvider)();
    } on Failure {
      // The stored reminder could not be read; the next start retries.
    }
  }

  /// BR-TRASH-009: what is past 30 days leaves for good. A failed purge
  /// keeps it for the next start, resume or visit to the Trash.
  Future<void> _purgeExpiredTrash() async {
    try {
      await ref.read(purgeExpiredTrashUseCaseProvider)();
    } on Failure {
      // Nothing to say: the entries stay in the Trash until the next try.
    }
  }

  Future<void> _closeStaleSessions() async {
    try {
      await ref.read(abandonStaleSessionsUseCaseProvider)();
    } on Failure {
      // A failed sweep leaves the sessions open; the next start retries.
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    unawaited(_reminderTaps?.cancel());
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only the theme and the locale follow the row: the router stays, so a
    // change keeps the stack and the scroll position (BR-SETTINGS-005).
    final settings =
        ref.watch(appSettingsProvider).value ?? widget.initialSettings;
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: _themeMode(settings?.theme),
      locale: _locale(settings?.language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _router,
      // Account UI spec U4: the transition layer sits above the router,
      // with the router's Back dispatcher to take priority over.
      builder: (context, child) => AccountLayerHostWidget(
        backButtons: _router.backButtonDispatcher,
        child: child!,
      ),
    );
  }
}

/// `system` follows the platform's brightness as it changes.
ThemeMode _themeMode(ThemeChoice? theme) => switch (theme) {
  ThemeChoice.light => ThemeMode.light,
  ThemeChoice.dark => ThemeMode.dark,
  ThemeChoice.system || null => ThemeMode.system,
};

/// `system` is no locale: Flutter resolves the platform's on the supported
/// locales and falls back to English, the first (BR-SETTINGS-006).
Locale? _locale(LanguageChoice? language) => switch (language) {
  LanguageChoice.en => const Locale('en'),
  LanguageChoice.vi => const Locale('vi'),
  LanguageChoice.system || null => null,
};
