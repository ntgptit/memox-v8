import 'package:flutter/material.dart';

/// The outlined edge [decoration] takes in [states]: the theme's one
/// state-resolved border, as the decorator resolves it for the field's state.
OutlineInputBorder edgeIn(
  InputDecoration decoration,
  Set<WidgetState> states,
) =>
    WidgetStateProperty.resolveAs<InputBorder?>(decoration.border, states)!
        as OutlineInputBorder;
