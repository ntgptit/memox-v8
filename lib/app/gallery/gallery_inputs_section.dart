import 'package:flutter/material.dart';
import 'package:memox/app/gallery/gallery_section.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';
import 'package:memox/shared/widgets/mx_stepper.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

/// Group C: fields, messages and selection controls, live where they have
/// state so the gallery can be poked at.
class GalleryInputsSection extends StatefulWidget {
  const GalleryInputsSection({super.key});

  @override
  State<GalleryInputsSection> createState() => _GalleryInputsSectionState();
}

class _GalleryInputsSectionState extends State<GalleryInputsSection> {
  static const int _minCards = 1;
  static const int _maxCards = 200;

  final _search = TextEditingController();
  var _isReminderOn = true;
  var _scheduler = 0;
  var _theme = 2;
  var _cards = 20;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GallerySection(
    title: 'C · Inputs & selection',
    children: [
      MxSearchField(
        controller: _search,
        hintText: 'Search decks and cards',
        clearLabel: 'Clear search',
      ),
      MxSearchField.trigger(hintText: 'Search decks', onTap: () {}),
      MxAppBar(
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: 'Back',
          onPressed: () {},
        ),
        titleWidget: MxSearchField(
          controller: _search,
          hintText: 'Search decks',
          clearLabel: 'Clear search',
        ),
      ),
      const MxTextField(hintText: 'Deck name'),
      const MxTextField(hintText: 'Deck name', errorText: 'Name is required'),
      const MxTextField(hintText: 'Back of the card', isMultiline: true),
      const MxFieldMessage(
        message: 'Ten tags at most on one card',
        tone: MxFieldMessageTone.warning,
      ),
      Row(
        children: [
          MxToggle(
            isOn: _isReminderOn,
            onChanged: (value) => setState(() => _isReminderOn = value),
            semanticLabel: 'Daily reminder',
          ),
          const MxSelectionCheckbox(isChecked: false),
          const MxSelectionCheckbox(isChecked: true),
        ],
      ),
      Column(
        children: [
          MxOptionRow(
            title: 'Eight box',
            description: 'Cards climb eight boxes, each a longer interval.',
            isSelected: _scheduler == 0,
            onSelected: () => setState(() => _scheduler = 0),
          ),
          MxOptionRow(
            title: 'SM-2',
            description: 'Intervals from four answers and an ease factor.',
            isSelected: _scheduler == 1,
            onSelected: () => setState(() => _scheduler = 1),
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
        selected: _theme,
        onSelected: (value) => setState(() => _theme = value),
      ),
      MxStepper(
        value: _cards,
        decrementLabel: 'Fewer cards',
        incrementLabel: 'More cards',
        onDecrement: _cards > _minCards ? () => setState(() => _cards--) : null,
        onIncrement: _cards < _maxCards ? () => setState(() => _cards++) : null,
      ),
    ],
  );
}
