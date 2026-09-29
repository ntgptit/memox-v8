import 'package:memox/core/logging/log_entry.dart';

/// What the buffer keeps (spec §3). Every level by default (owner ruling
/// 2026-09-29); this is the one knob if the volume grows too much.
final class LogConfig {
  const LogConfig({this.persistMinLevel = LogLevel.debug});

  final LogLevel persistMinLevel;
}
