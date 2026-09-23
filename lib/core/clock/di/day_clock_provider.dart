import 'package:memox/core/clock/day_clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'day_clock_provider.g.dart';

@Riverpod(keepAlive: true)
DayClock dayClock(Ref ref) => const SystemDayClock();
