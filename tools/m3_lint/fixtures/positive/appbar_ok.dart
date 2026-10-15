import 'package:flutter/material.dart';

final theme = AppBarThemeData(
  iconTheme: const IconThemeData(),
  actionsIconTheme: const IconThemeData(),
  backgroundColor: WidgetStateColor.resolveWith(
    (states) => const Color(0xFFFFFFFF),
  ),
);
