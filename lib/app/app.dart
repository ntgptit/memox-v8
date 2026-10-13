import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/app_lifecycle_hooks.dart';
import 'package:memox/app/font_license.dart';
import 'package:memox/app/router/account_redirect.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/logging/di/logging_providers.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/account/presentation/providers/welcome_due_provider.dart';
import 'package:memox/features/account/presentation/widgets/sections/account_layer_host_widget.dart';
import 'package:memox/features/reminders/data/datasources/reminder_plugins_data_source.dart';
import 'package:memox/features/reminders/di/reminder_plugins_data_source_provider.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// The composition root: themes, localization and the router, the features'
/// lifecycle side effects at start and on every resume ([AppLifecycleHooks]),
/// the daily reminder's tap route (BE-B5b), and the account transition layer
/// (account UI spec U4). The theme and the language follow
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
  /// Runs the router's account rules again when their inputs change.
  final _accountRoutes = AccountRouteRefresh();

  // Owned here, not at top level, so each app instance starts at its initial
  // location and a disposed app releases its router.
  late final GoRouter _router = buildAppRouter(
    hasGallery: widget.hasGallery,
    refreshListenable: _accountRoutes,
    redirect: (context, state) => _accountTarget(state.uri),
  );

  String? _accountTarget(Uri location) => accountRedirect(
    location,
    isWelcomeDue: ref.read(welcomeDueProvider),
    // P3b plan ruling 4: the coordinator's own state, a frame ahead of
    // the provider's.
    account: ref.read(accountCoordinatorProvider)?.state ?? const LocalOnly(),
  );

  /// A refresh runs the redirect on the location under the pushed routes
  /// only, so a pushed screen 30 or 32 the account no longer allows stayed
  /// open (device check D6, F1 and F2): the top route is checked as well.
  void _leavePushedAccountRoute() {
    if (_router.routerDelegate.currentConfiguration.isEmpty) return;
    final target = _accountTarget(_router.state.uri);
    if (target == null) return;
    _router.go(target);
  }

  /// A resume after a day away purges what expired meanwhile (UC-TRASH-001
  /// A4); a resume and a pause are logged (ADR-018).
  late final AppLifecycleListener _lifecycle;

  /// Taps on the daily reminder while the app runs (BR-REMINDER-008).
  StreamSubscription<String?>? _reminderTaps;

  /// The features' lifecycle side effects (DEV-176), over this scope's
  /// container.
  late final _hooks = AppLifecycleHooks(
    ProviderScope.containerOf(context, listen: false),
  );

  @override
  void initState() {
    super.initState();
    // Android 15 draws edge-to-edge regardless; earlier versions opt in here.
    // Every inset is read from MediaQuery.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    registerFontLicense();
    // The features' start side effects, and the resume's below, in one
    // place (DEV-176). Unawaited: no frame waits for them.
    _hooks.onStart();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        appLogger.info('lifecycle.resume', category: LogCategory.lifecycle);
        _hooks.onResume();
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
    // Account UI spec §4: the welcome flag and the account drive the
    // redirect.
    ref
      ..listenManual(welcomeDueProvider, (_, _) => _accountRoutes.ping())
      ..listenManual(authStateProvider, (_, _) {
        _accountRoutes.ping();
        _leavePushedAccountRoute();
      });
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

  @override
  void dispose() {
    _lifecycle.dispose();
    unawaited(_reminderTaps?.cancel());
    _accountRoutes.dispose();
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
        dialogNavigator: _router.routerDelegate.navigatorKey,
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
