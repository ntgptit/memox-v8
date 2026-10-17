import 'package:flutter/widgets.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/app/gallery/gallery_section.dart';
import 'package:memox/shared/widgets/mx_choice_tile.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';
import 'package:memox/shared/widgets/mx_slider.dart';
import 'package:memox/shared/widgets/mx_stepper.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_divided_column.dart';
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
  static const double _seekLength = 100;

  final _search = TextEditingController();
  var _isReminderOn = true;
  var _scheduler = 0;
  var _theme = 2;
  var _cards = 20;
  var _seekPosition = 40.0;
  var _choice = 1;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GallerySection(
    title: context.l10n.galleryCInputsSelection,
    children: [
      MxSearchField(
        controller: _search,
        hintText: context.l10n.gallerySearchDecksAndCards,
        clearLabel: context.l10n.galleryClearSearch,
      ),
      MxSearchField.trigger(
        hintText: context.l10n.gallerySearchDecks,
        onTap: () {},
      ),
      MxAppBar(
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: context.l10n.commonBack,
          onPressed: () {},
        ),
        isTitleField: true,
        titleWidget: MxSearchField(
          controller: _search,
          hintText: context.l10n.gallerySearchDecks,
          clearLabel: context.l10n.galleryClearSearch,
        ),
      ),
      MxTextField(hintText: context.l10n.galleryDeckName),
      MxTextField(
        hintText: context.l10n.galleryDeckName,
        errorText: context.l10n.galleryNameIsRequired,
      ),
      MxTextField(
        hintText: context.l10n.galleryAnExampleSentence,
        variant: MxTextFieldVariant.detail,
      ),
      MxTextField(
        hintText: context.l10n.galleryTheTerm,
        variant: MxTextFieldVariant.term,
      ),
      const MxTextField(variant: MxTextFieldVariant.code),
      MxFieldMessage(
        message: context.l10n.galleryTenTagsAtMostOn,
        tone: MxFieldMessageTone.warning,
      ),
      Row(
        children: [
          MxToggle(
            isOn: _isReminderOn,
            onChanged: (value) => setState(() => _isReminderOn = value),
            semanticLabel: context.l10n.galleryDailyReminder,
          ),
          const MxSelectionCheckbox(isChecked: false),
          const MxSelectionCheckbox(isChecked: true),
        ],
      ),
      MxSlider(
        value: _seekPosition,
        max: _seekLength,
        onChanged: (value) => setState(() => _seekPosition = value),
        semanticLabel: context.l10n.gallerySeekBar,
      ),
      for (final (index, label) in [
        context.l10n.galleryChoiceIdle,
        context.l10n.galleryChoiceSelected,
      ].indexed)
        MxChoiceTile(
          tone: index == _choice ? MxChoiceTone.selected : MxChoiceTone.idle,
          isSelected: index == _choice,
          semanticsLabel: label,
          padding: EdgeInsets.symmetric(
            horizontal: context.dimens.space16,
            vertical: context.dimens.space12,
          ),
          onTap: () => setState(() => _choice = index),
          builder: (foreground) => Text(
            label,
            style: context.texts.content.copyWith(color: foreground),
          ),
        ),
      MxDividedColumn(
        children: [
          MxOptionRow(
            title: context.l10n.galleryEightBox,
            description: context.l10n.galleryCardsClimbEightBoxesEach,
            isSelected: _scheduler == 0,
            onSelected: () => setState(() => _scheduler = 0),
          ),
          MxOptionRow(
            title: context.l10n.gallerySm2,
            description: context.l10n.galleryIntervalsFromFourAnswersAnd,
            isSelected: _scheduler == 1,
            onSelected: () => setState(() => _scheduler = 1),
          ),
        ],
      ),
      MxSegmentedTray(
        segments: [
          MxSegment(value: 0, label: context.l10n.galleryLight),
          MxSegment(value: 1, label: context.l10n.galleryDark),
          MxSegment(value: 2, label: context.l10n.gallerySystem),
        ],
        selected: _theme,
        onSelected: (value) => setState(() => _theme = value),
      ),
      MxStepper(
        value: _cards,
        decrementLabel: context.l10n.galleryFewerCards,
        incrementLabel: context.l10n.galleryMoreCards,
        onDecrement: _cards > _minCards ? () => setState(() => _cards--) : null,
        onIncrement: _cards < _maxCards ? () => setState(() => _cards++) : null,
        valueLabel: context.l10n.galleryCardsPerSession,
        editHint: context.l10n.commonEdit,
        onValueSubmitted: (text) => setState(
          () => _cards = (int.tryParse(text) ?? _cards).clamp(
            _minCards,
            _maxCards,
          ),
        ),
      ),
    ],
  );
}
