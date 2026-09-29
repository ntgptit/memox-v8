import 'package:collection/collection.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/domain/models/log_window_model.dart';

/// What the Server tab asks the server for (monitoring spec §3.2). The
/// default is the admin's main job: open warnings and errors.
///
/// An empty set restricts nothing. A change is a `with…` call, so every
/// rule about how two choices interact lives here.
final class LogFilter {
  const LogFilter({
    this.levels = defaultLevels,
    this.statuses = defaultStatuses,
    this.categories = const {},
    this.window = LogWindow.all,
    this.deviceId,
    this.userId,
    this.search = '',
  });

  static const Set<LogLevel> defaultLevels = {LogLevel.warning, LogLevel.error};
  static const Set<LogStatus> defaultStatuses = {LogStatus.open};

  final Set<LogLevel> levels;
  final Set<LogStatus> statuses;
  final Set<LogCategory> categories;
  final LogWindow window;

  /// One device id, or null for every device.
  final String? deviceId;

  /// One user id (a uuid), or null for every user.
  final String? userId;

  /// Matched against `event` and `message`, as typed.
  final String search;

  /// The filter the screen opens with: nothing changed by the admin.
  bool get isDefault => this == const LogFilter();

  /// A debug or info row has no status, so a status filter would hide it:
  /// choosing one of those levels, or none (every level), clears the status
  /// filter (the admin can set it again after).
  LogFilter withLevels(Set<LogLevel> next) {
    final hasStatusless =
        next.isEmpty ||
        next.contains(LogLevel.debug) ||
        next.contains(LogLevel.info);
    return _copy(levels: next, statuses: hasStatusless ? const {} : statuses);
  }

  LogFilter withStatuses(Set<LogStatus> next) => _copy(statuses: next);

  LogFilter withCategories(Set<LogCategory> next) => _copy(categories: next);

  LogFilter withWindow(LogWindow next) => _copy(window: next);

  /// A blank id is no device.
  LogFilter withDevice(String? id) => LogFilter(
    levels: levels,
    statuses: statuses,
    categories: categories,
    window: window,
    deviceId: _idOrNull(id),
    userId: userId,
    search: search,
  );

  /// A blank id is no user.
  LogFilter withUser(String? id) => LogFilter(
    levels: levels,
    statuses: statuses,
    categories: categories,
    window: window,
    deviceId: deviceId,
    userId: _idOrNull(id),
    search: search,
  );

  LogFilter withSearch(String text) => _copy(search: text.trim());

  LogFilter _copy({
    Set<LogLevel>? levels,
    Set<LogStatus>? statuses,
    Set<LogCategory>? categories,
    LogWindow? window,
    String? search,
  }) => LogFilter(
    levels: levels ?? this.levels,
    statuses: statuses ?? this.statuses,
    categories: categories ?? this.categories,
    window: window ?? this.window,
    deviceId: deviceId,
    userId: userId,
    search: search ?? this.search,
  );

  static String? _idOrNull(String? id) {
    final trimmed = id?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  @override
  bool operator ==(Object other) =>
      other is LogFilter &&
      const SetEquality<LogLevel>().equals(other.levels, levels) &&
      const SetEquality<LogStatus>().equals(other.statuses, statuses) &&
      const SetEquality<LogCategory>().equals(other.categories, categories) &&
      other.window == window &&
      other.deviceId == deviceId &&
      other.userId == userId &&
      other.search == search;

  @override
  int get hashCode => Object.hash(
    const SetEquality<LogLevel>().hash(levels),
    const SetEquality<LogStatus>().hash(statuses),
    const SetEquality<LogCategory>().hash(categories),
    window,
    deviceId,
    userId,
    search,
  );
}
