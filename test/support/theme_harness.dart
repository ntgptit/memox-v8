import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/app/app_theme_host.dart';
import 'package:memox/core/theme/app_theme.dart';

/// The `MaterialApp.builder` that puts [theme] over every route, as the app
/// does (`AppThemeHost`): FTheme, ForUI's own Material bridge and the
/// toaster.
TransitionBuilder mxThemeBuilder(FThemeData theme) =>
    (context, child) =>
        AppThemeHost(brightness: theme.colors.brightness, child: child!);

/// Pumps an empty app under [theme] and returns a context inside it, for the
/// `context.colors`-style getters.
Future<BuildContext> contextOf(WidgetTester tester, FThemeData theme) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MaterialApp(
      theme: materialHostTheme(theme),
      builder: mxThemeBuilder(theme),
      home: Builder(
        builder: (context) {
          captured = context;
          return const SizedBox();
        },
      ),
    ),
  );
  return captured;
}
