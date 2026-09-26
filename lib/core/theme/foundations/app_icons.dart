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
  static const IconData chevronDown = Icons.keyboard_arrow_down; // chevron-down
  static const IconData sort = Icons.swap_vert; // arrow-up-down
  static const IconData filters = Icons.tune; // sliders-horizontal
  static const IconData filter = Icons.filter_list; // filter
  static const IconData alert = Icons.error_outline; // alert-circle
  static const IconData remove = Icons.remove; // minus
  static const IconData info = Icons.info_outline; // info
  static const IconData folder = Icons.folder_outlined; // folder
  static const IconData edit = Icons.edit_outlined; // pencil
  static const IconData reminder = Icons.notifications_none; // bell
  static const IconData offline = Icons.cloud_off_outlined; // cloud-off
  static const IconData reorder = Icons.reorder; // list-ordered
  static const IconData dragHandle = Icons.drag_handle; // grip-horizontal
  static const IconData scheduler =
      Icons.event_repeat_outlined; // calendar-clock
  static const IconData flag = Icons.outlined_flag; // flag
  static const IconData flagged = Icons.flag; // flag (filled)
  static const IconData details = Icons.auto_awesome_outlined; // sparkles
  static const IconData example = Icons.chat_bubble_outline; // message-square
  static const IconData hint = Icons.lightbulb_outline; // lightbulb
  static const IconData pronunciation = Icons.text_fields; // type
  static const IconData clock = Icons.schedule; // clock
  static const IconData searchOff = Icons.search_off; // search-x
  static const IconData history = Icons.history; // history
  static const IconData pause = Icons.pause_circle_outline; // pause-circle
  static const IconData swipe =
      Icons.keyboard_double_arrow_right; // chevrons-right
  static const IconData learned = Icons.check_circle_outline; // check-circle-2
  static const IconData repeat = Icons.repeat; // repeat
  static const IconData lapses = Icons.replay; // rotate-ccw
  static const IconData resetProgress = Icons.replay; // rotate-ccw
  static const IconData restore = Icons.replay; // rotate-ccw
  static const IconData lock = Icons.lock_outline; // lock
  static const IconData lockOpen = Icons.lock_open_outlined; // lock-open
  static const IconData timeout = Icons.timer_off_outlined; // timer-off
  static const IconData calendar = Icons.event; // calendar

  // Debug gallery.
  static const IconData gallery = Icons.widgets_outlined;
  static const IconData themeMode = Icons.contrast;
  static const IconData theme = Icons.palette_outlined;
  static const IconData shuffle = Icons.shuffle; // shuffle
  static const IconData language = Icons.language; // globe
  static const IconData resetOptions =
      Icons.settings_backup_restore; // rotate-ccw
  static const IconData safe = Icons.verified_user_outlined; // shield-check
  static const IconData textScale = Icons.format_size;

  // Top-level destinations (bottom nav): layers · play · bar-chart-3 · settings.
  static const IconData starterDecks = Icons.auto_awesome_outlined; // sparkles
  static const IconData upcoming = Icons.upcoming_outlined; // calendar-plus
  static const IconData dueNow = Icons.bolt_outlined; // zap
  static const IconData cardDeck = Icons.copy_all_outlined; // copy
  // Card import (kit 11).
  static const IconData fileUp = Icons.upload_file_outlined; // file-up
  static const IconData clipboard = Icons.content_paste; // clipboard
  static const IconData fileText = Icons.description_outlined; // file-text
  static const IconData folderOpen = Icons.folder_open_outlined; // folder-open
  static const IconData arrowRight = Icons.arrow_forward; // arrow-right
  static const IconData preview = Icons.visibility_outlined; // eye
  static const IconData download = Icons.download; // download
  // Card export (kit 12).
  static const IconData share = Icons.share_outlined; // share-2
  static const IconData fileDown = Icons.file_download_outlined; // file-down
  static const IconData library = Icons.layers_outlined;
  static const IconData librarySelected = Icons.layers;
  static const IconData study = Icons.play_circle_outline;
  static const IconData studySelected = Icons.play_circle;
  static const IconData progress = Icons.bar_chart_outlined;
  static const IconData progressSelected = Icons.bar_chart;
  static const IconData settings = Icons.settings_outlined;
  static const IconData settingsSelected = Icons.settings;
}
