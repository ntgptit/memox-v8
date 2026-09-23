import 'package:flutter/material.dart';

/// The handoff's Lucide glyph names mapped once, by meaning, to the built-in
/// Material Icons (spec §2). One concept, one glyph. A navigation destination
/// has an outlined resting glyph and a filled selected one.
abstract final class AppIcons {
  static const IconData add = Icons.add; // plus
  static const IconData back = Icons.arrow_back; // arrow-left
  static const IconData close = Icons.close; // x
  static const IconData more = Icons.more_vert; // more-vertical
  static const IconData search = Icons.search; // search
  static const IconData chevronRight = Icons.chevron_right; // chevron-right
  static const IconData check = Icons.check; // check
  static const IconData delete = Icons.delete_outline; // trash-2
  static const IconData retry = Icons.refresh; // refresh-cw
  static const IconData play = Icons.play_arrow; // play
  static const IconData inbox = Icons.inbox_outlined; // inbox
  static const IconData tag = Icons.sell_outlined; // tag

  // Debug gallery.
  static const IconData gallery = Icons.widgets_outlined;
  static const IconData themeMode = Icons.contrast;
  static const IconData textScale = Icons.format_size;

  // Top-level destinations (bottom nav): layers · play · bar-chart-3 · settings.
  static const IconData library = Icons.layers_outlined;
  static const IconData librarySelected = Icons.layers;
  static const IconData study = Icons.play_circle_outline;
  static const IconData studySelected = Icons.play_circle;
  static const IconData progress = Icons.bar_chart_outlined;
  static const IconData progressSelected = Icons.bar_chart;
  static const IconData settings = Icons.settings_outlined;
  static const IconData settingsSelected = Icons.settings;
}
