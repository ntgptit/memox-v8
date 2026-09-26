import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/font_license.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/study/presentation/providers/abandon_stale_sessions_use_case_provider.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// The composition root: themes, localization and the router, and the
/// start-up close of an earlier day's open study session (FE-A6 D9).
class MemoxApp extends ConsumerStatefulWidget {
  const MemoxApp({super.key, this.hasGallery = kDebugMode});

  /// Registers the debug-only component gallery.
  final bool hasGallery;

  @override
  ConsumerState<MemoxApp> createState() => _MemoxAppState();
}

class _MemoxAppState extends ConsumerState<MemoxApp> {
  // Owned here, not at top level, so each app instance starts at its initial
  // location and a disposed app releases its router.
  late final GoRouter _router = buildAppRouter(hasGallery: widget.hasGallery);

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
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    debugShowCheckedModeBanner: false,
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    theme: buildLightTheme(),
    darkTheme: buildDarkTheme(),
    // The system choice until the settings feature persists one
    // (BR-SETTINGS-005, BR-SETTINGS-006).
    themeMode: ThemeMode.system,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: _router,
  );
}
