import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

/// Matches a [Color] whose A, R, G and B channels are each within one 8-bit
/// step of [argb]. For blended colours, where the last bit depends on how the
/// blend rounds; an exact role value is compared with `toARGB32()` instead.
Matcher isColorCloseTo(int argb) => _ColorCloseTo(argb);

final class _ColorCloseTo extends Matcher {
  const _ColorCloseTo(this._argb);

  final int _argb;

  static const int _tolerance = 1;
  static const List<int> _channelShifts = [24, 16, 8, 0];
  static const int _channelMask = 0xFF;

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! Color) return false;

    final actual = item.toARGB32();
    for (final shift in _channelShifts) {
      final actualChannel = (actual >> shift) & _channelMask;
      final expectedChannel = (_argb >> shift) & _channelMask;
      if ((actualChannel - expectedChannel).abs() > _tolerance) return false;
    }
    return true;
  }

  @override
  Description describe(Description description) => description.add(
    'a colour within $_tolerance per channel of '
    '0x${_argb.toRadixString(16).toUpperCase()}',
  );
}
