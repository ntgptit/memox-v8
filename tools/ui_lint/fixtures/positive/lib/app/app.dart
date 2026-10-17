import 'package:flutter/material.dart' show MaterialApp, ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

Widget app(FThemeData theme) => MaterialApp(
  themeMode: ThemeMode.system,
  builder: (context, child) => FTheme(data: theme, child: child!),
);
