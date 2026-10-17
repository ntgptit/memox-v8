import 'package:flutter/widgets.dart';
import 'package:forui/assets.dart';

/// Every glyph the app draws, mapped once, by meaning, to ForUI's Lucide set
/// (ADR-025). One concept, one glyph. Lucide has no filled variants, so a
/// navigation destination's selected glyph is the resting one: the selected
/// state is carried by colour and the indicator, never by the glyph alone.
abstract final class AppIcons {
  static const IconData add = FLucideIcons.plus;
  static const IconData back = FLucideIcons.arrowLeft;
  static const IconData close = FLucideIcons.x;
  static const IconData more = FLucideIcons.ellipsisVertical;
  static const IconData search = FLucideIcons.search;
  static const IconData chevronRight = FLucideIcons.chevronRight;
  static const IconData check = FLucideIcons.check;
  static const IconData select = FLucideIcons.listChecks;
  static const IconData delete = FLucideIcons.trash2;
  static const IconData retry = FLucideIcons.refreshCw;
  static const IconData play = FLucideIcons.play;
  static const IconData inbox = FLucideIcons.inbox;
  static const IconData tag = FLucideIcons.tag;
  static const IconData chevronDown = FLucideIcons.chevronDown;
  static const IconData chevronUp = FLucideIcons.chevronUp;
  static const IconData sort = FLucideIcons.arrowUpDown;
  static const IconData filters = FLucideIcons.slidersHorizontal;
  static const IconData filter = FLucideIcons.funnel;
  static const IconData alert = FLucideIcons.circleAlert;
  static const IconData remove = FLucideIcons.minus;
  static const IconData info = FLucideIcons.info;
  static const IconData folder = FLucideIcons.folder;
  static const IconData edit = FLucideIcons.pencil;
  static const IconData reminder = FLucideIcons.bell;
  static const IconData reminderOff = FLucideIcons.bellOff;
  static const IconData offline = FLucideIcons.cloudOff;
  static const IconData sync = FLucideIcons.cloudSync;
  static const IconData reorder = FLucideIcons.listOrdered;
  static const IconData dragHandle = FLucideIcons.gripHorizontal;
  static const IconData scheduler = FLucideIcons.calendarClock;
  static const IconData flag = FLucideIcons.flag;
  // Lucide has no filled flag: the flagged state is the accent colour.
  static const IconData flagged = FLucideIcons.flag;
  static const IconData example = FLucideIcons.messageSquare;
  static const IconData hint = FLucideIcons.lightbulb;
  static const IconData pronunciation = FLucideIcons.type;
  static const IconData speak = FLucideIcons.volume2;
  static const IconData voice = FLucideIcons.speech;
  static const IconData clock = FLucideIcons.clock;
  static const IconData searchOff = FLucideIcons.searchX;
  static const IconData history = FLucideIcons.history;
  static const IconData pause = FLucideIcons.circlePause;
  static const IconData swipe = FLucideIcons.chevronsRight;
  static const IconData learned = FLucideIcons.circleCheck;
  static const IconData repeat = FLucideIcons.repeat;
  static const IconData lapses = FLucideIcons.rotateCcw;
  static const IconData resetProgress = FLucideIcons.rotateCcw;
  static const IconData restore = FLucideIcons.rotateCcw;
  static const IconData lock = FLucideIcons.lock;
  static const IconData lockOpen = FLucideIcons.lockOpen;
  static const IconData timeout = FLucideIcons.timerOff;
  static const IconData studyMode = FLucideIcons.layers;
  static const IconData calendar = FLucideIcons.calendar;
  // Monitoring (screen 28): one glyph per log level, so colour is never the
  // only cue; info and error are [info] and [alert].
  static const IconData levelDebug = FLucideIcons.bug;
  static const IconData levelWarning = FLucideIcons.triangleAlert;
  static const IconData copy = FLucideIcons.copy;
  static const IconData monitoring = FLucideIcons.activity;
  // Account (screens 23, 29).
  static const IconData account = FLucideIcons.user;
  static const IconData users = FLucideIcons.users;
  static const IconData switchAccount = FLucideIcons.arrowLeftRight;
  static const IconData signOut = FLucideIcons.logOut;
  static const IconData devices = FLucideIcons.smartphone;

  // Debug gallery.
  static const IconData gallery = FLucideIcons.layoutGrid;
  static const IconData themeMode = FLucideIcons.contrast;
  static const IconData theme = FLucideIcons.palette;
  static const IconData studyOptions = FLucideIcons.slidersHorizontal;
  static const IconData shuffle = FLucideIcons.shuffle;
  static const IconData language = FLucideIcons.globe;
  static const IconData resetOptions = FLucideIcons.rotateCcw;
  static const IconData safe = FLucideIcons.shieldCheck;
  static const IconData textScale = FLucideIcons.aLargeSmall;
  // Development fixtures (screen 03, BR-STARTER-010).
  static const IconData fixture = FLucideIcons.flaskConical;
  // A rename onto an existing tag merges the two (screen 05).
  static const IconData merge = FLucideIcons.gitMerge;

  static const IconData starterDecks = FLucideIcons.sparkles;
  static const IconData upcoming = FLucideIcons.calendarPlus;
  static const IconData dueNow = FLucideIcons.zap;
  // Workload terms (BR-STUDY-076: each count has its own glyph); Due today
  // is [dueNow].
  static const IconData overdue = FLucideIcons.history;
  static const IconData newCards = FLucideIcons.sparkles;
  static const IconData cardDeck = FLucideIcons.copy;
  // Card import (kit 11).
  static const IconData fileUp = FLucideIcons.fileUp;
  static const IconData clipboard = FLucideIcons.clipboard;
  static const IconData fileText = FLucideIcons.fileText;
  // TOPIK's sections (owner, Q-P6-3).
  static const IconData book = FLucideIcons.bookOpen;
  static const IconData headphones = FLucideIcons.headphones;
  static const IconData folderOpen = FLucideIcons.folderOpen;
  static const IconData arrowRight = FLucideIcons.arrowRight;
  static const IconData preview = FLucideIcons.eye;
  static const IconData download = FLucideIcons.download;
  // Card export (kit 12).
  static const IconData share = FLucideIcons.share2;
  static const IconData fileDown = FLucideIcons.fileDown;
  // Progress (kit 22).
  static const IconData streak = FLucideIcons.flame;

  // Top-level destinations: layers · play · bar chart · settings. The
  // selected glyph is the resting one (see the class comment).
  static const IconData library = FLucideIcons.layers;
  static const IconData librarySelected = FLucideIcons.layers;
  static const IconData study = FLucideIcons.circlePlay;
  static const IconData studySelected = FLucideIcons.circlePlay;
  static const IconData progress = FLucideIcons.chartColumn;
  static const IconData progressSelected = FLucideIcons.chartColumn;
  static const IconData settings = FLucideIcons.settings;
  static const IconData settingsSelected = FLucideIcons.settings;
}
