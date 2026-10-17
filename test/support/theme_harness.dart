import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:memox/app/app_theme_host.dart';

/// The `MaterialApp.builder` that puts [theme] over every route, as the app
/// does (`AppThemeHost`): FTheme, ForUI's own Material bridge and the
/// toaster.
TransitionBuilder mxThemeBuilder(FThemeData theme) =>
    (context, child) =>
        AppThemeHost(brightness: theme.colors.brightness, child: child!);
