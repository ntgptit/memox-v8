import 'package:flutter/material.dart' as sdk;
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

// The theme owner builds the themes and sets the barrier.
FThemeData light(FColors colors) => FThemeData(colors: colors, touch: true);

sdk.ThemeData host() => sdk.ThemeData(useMaterial3: true);

Widget barrier() => const ColoredBox(color: Color(0x33000000));

sdk.DialogThemeData dialogs() =>
    const sdk.DialogThemeData(barrierColor: Color(0x33000000));
