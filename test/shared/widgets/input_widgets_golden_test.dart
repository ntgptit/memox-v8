@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';
import 'package:memox/shared/widgets/mx_stepper.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import '../../support/golden_harness.dart';

void main() {
  testWidgets('MxFilterChip and MxChipTrigger', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_chips',
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          MxFilterChip(
            label: 'All',
            count: 128,
            isSelected: true,
            onSelected: (_) {},
          ),
          MxFilterChip(
            label: 'Cards',
            count: 96,
            isSelected: false,
            onSelected: (_) {},
          ),
          MxFilterChip(
            label: 'Decks',
            icon: AppIcons.filter,
            isSelected: false,
            onSelected: (_) {},
          ),
          const MxFilterChip(
            label: 'Disabled',
            isSelected: false,
            onSelected: null,
          ),
          MxChipTrigger(label: 'Sort: Due', onPressed: () {}),
          MxChipTrigger(
            label: 'Filters',
            icon: AppIcons.filters,
            onPressed: () {},
          ),
        ],
      ),
    );
  });

  testWidgets('MxTextField states and MxFieldMessage tones', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_text_field',
      Column(
        spacing: 16,
        children: [
          const MxTextField(hintText: 'Deck name'),
          MxTextField(controller: TextEditingController(text: 'Japanese N5')),
          const MxTextField(
            hintText: 'Deck name',
            errorText: 'Name is required',
          ),
          const MxTextField(hintText: 'Back of the card', isMultiline: true),
          const MxTextField(hintText: 'Disabled', isEnabled: false),
          const MxFieldMessage(
            message: 'Ten tags at most on one card',
            tone: MxFieldMessageTone.warning,
          ),
        ],
      ),
    );
  });

  testWidgets('MxSearchField empty and filled', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_search_field',
      Column(
        spacing: 16,
        children: [
          MxSearchField(
            controller: TextEditingController(),
            hintText: 'Search decks and cards',
            clearLabel: 'Clear',
          ),
          MxSearchField(
            controller: TextEditingController(text: 'irregular verbs'),
            hintText: 'Search decks and cards',
            clearLabel: 'Clear',
          ),
        ],
      ),
    );
  });

  testWidgets('MxToggle and MxSelectionCheckbox', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_toggle_checkbox',
      Row(
        spacing: 8,
        children: [
          MxToggle(isOn: false, onChanged: (_) {}, semanticLabel: 'Off'),
          MxToggle(isOn: true, onChanged: (_) {}, semanticLabel: 'On'),
          const MxToggle(
            isOn: true,
            onChanged: null,
            semanticLabel: 'Disabled',
          ),
          const MxSelectionCheckbox(isChecked: false),
          const MxSelectionCheckbox(isChecked: true),
        ],
      ),
    );
  });
  testWidgets('MxOptionRow and MxSegmentedTray', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_option_tray',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Column(
            children: [
              MxOptionRow(
                title: 'Eight box',
                description: 'Cards climb eight boxes, each a longer interval.',
                isSelected: true,
                onSelected: () {},
              ),
              MxOptionRow(title: 'SM-2', isSelected: false, onSelected: () {}),
              const MxOptionRow(
                title: 'Disabled',
                isSelected: false,
                onSelected: null,
                hasDivider: false,
              ),
            ],
          ),
          MxSegmentedTray(
            segments: const [
              MxSegment(value: 0, label: 'Light'),
              MxSegment(value: 1, label: 'Dark'),
              MxSegment(value: 2, label: 'System'),
            ],
            selected: 2,
            onSelected: (_) {},
          ),
          MxSegmentedTray(
            segments: const [
              MxSegment(value: 7, label: '7 days'),
              MxSegment(value: 30, label: '30 days'),
            ],
            selected: 7,
            onSelected: (_) {},
            isWide: true,
          ),
        ],
      ),
    );
  });
  testWidgets('MxStepper default, invalid, busy, disabled', (tester) async {
    Widget stepper({
      int value = 20,
      bool isInvalid = false,
      bool isBusy = false,
      bool isEnabled = true,
    }) => MxStepper(
      value: value,
      decrementLabel: 'Fewer',
      incrementLabel: 'More',
      onDecrement: () {},
      onIncrement: () {},
      isInvalid: isInvalid,
      isBusy: isBusy,
      isEnabled: isEnabled,
    );
    await expectThemedGoldens(
      tester,
      'mx_stepper',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          stepper(),
          stepper(value: 250, isInvalid: true),
          stepper(isBusy: true),
          stepper(isEnabled: false),
        ],
      ),
    );
  });
}
