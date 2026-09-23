@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';

import '../../support/golden_harness.dart';

void main() {
  testWidgets('MxCard and MxIconTile', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_card_icon_tile',
      const Column(
        spacing: 16,
        children: [
          MxCard(child: SizedBox(height: 56)),
          MxCard(isHero: true, child: SizedBox(height: 56)),
          Row(
            spacing: 12,
            children: [
              MxIconTile(icon: AppIcons.library),
              MxIconTile(icon: AppIcons.reminder, size: MxIconTileSize.medium),
              MxIconTile(icon: AppIcons.library, size: MxIconTileSize.large),
              MxIconTile(icon: AppIcons.folder, seed: Color(0xFF0E9F6E)),
            ],
          ),
        ],
      ),
    );
  });
}
