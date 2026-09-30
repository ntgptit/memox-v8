import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/domain/models/log_filter_model.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/domain/models/log_window_model.dart';

// Monitoring spec §3.2: the filter's defaults and how its choices interact.
void main() {
  test('the default is open warnings and errors, everything else open', () {
    const filter = LogFilter();

    expect(filter.levels, {LogLevel.warning, LogLevel.error});
    expect(filter.statuses, {LogStatus.open});
    expect(filter.categories, isEmpty);
    expect(filter.window, LogWindow.all);
    expect(filter.deviceId, isNull);
    expect(filter.userId, isNull);
    expect(filter.search, '');
    expect(filter.isDefault, isTrue);
  });

  test('two filters with the same choices are equal, in any set order', () {
    final a = const LogFilter().withCategories({
      LogCategory.db,
      LogCategory.sync,
    });
    final b = const LogFilter().withCategories({
      LogCategory.sync,
      LogCategory.db,
    });

    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a.isDefault, isFalse);
  });

  test('a level with no status clears the status filter', () {
    final filter = const LogFilter().withLevels({
      LogLevel.error,
      LogLevel.info,
    });

    expect(filter.statuses, isEmpty);
    expect(filter.levels, {LogLevel.error, LogLevel.info});
  });

  // Final review M4: no level chosen is every level, debug and info included.
  test('no level chosen clears the status filter too', () {
    final filter = const LogFilter().withLevels({});

    expect(filter.levels, isEmpty);
    expect(filter.statuses, isEmpty);
  });

  test('warning and error keep the status filter', () {
    final filter = const LogFilter().withLevels({LogLevel.error});

    expect(filter.statuses, {LogStatus.open});
  });

  test('a blank device or user is none, and an id is trimmed', () {
    expect(const LogFilter().withDevice('   ').deviceId, isNull);
    expect(const LogFilter().withUser('').userId, isNull);
    expect(const LogFilter().withDevice(' dev-1 ').deviceId, 'dev-1');
  });

  test('a search is trimmed', () {
    expect(const LogFilter().withSearch('  sync  ').search, 'sync');
  });

  test('a window reaches back from now, and all reaches without limit', () {
    final now = DateTime.utc(2026, 9, 29, 12);

    expect(LogWindow.hour.since(now), DateTime.utc(2026, 9, 29, 11));
    expect(LogWindow.day.since(now), DateTime.utc(2026, 9, 28, 12));
    expect(LogWindow.week.since(now), DateTime.utc(2026, 9, 22, 12));
    expect(LogWindow.month.since(now), DateTime.utc(2026, 8, 30, 12));
    expect(LogWindow.all.since(now), isNull);
  });

  test('a status is parsed from its stored code, or is none', () {
    expect(LogStatus.parse('open'), LogStatus.open);
    expect(LogStatus.parse('fixed'), LogStatus.fixed);
    expect(LogStatus.parse(null), isNull);
    expect(LogStatus.parse('wontfix'), isNull);
  });
}
