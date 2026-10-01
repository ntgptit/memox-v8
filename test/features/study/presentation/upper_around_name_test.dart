import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/presentation/states/upper_around_name_state.dart';

void main() {
  test('upper-cases the app words and keeps the name as typed (critique '
      '2026-09-30 part 2, P4)', () {
    expect(
      upperAroundName((name) => 'Review session · $name', 'Nhà hàng'),
      'REVIEW SESSION · Nhà hàng',
    );
    expect(
      upperAroundName((name) => '$name · review · round 1', 'TOPIK I · từ'),
      'TOPIK I · từ · REVIEW · ROUND 1',
    );
    expect(
      upperAroundName((name) => 'Phiên ôn tập · $name', 'nhà hàng'),
      'PHIÊN ÔN TẬP · nhà hàng',
    );
  });
}
