import 'package:flutter/material.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/presentation/widgets/items/card_removable_tag_chip_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_rejection_message_widget.dart';
import 'package:memox/features/tags/domain/entities/tag_entity.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// The card's tags (kit 08/09): "Tags · optional · n / 10", removable chips,
/// and Add tag, which opens an inline input. Done adds the tag and keeps the
/// input open for the next one; an empty Done closes it. A name already
/// there, however spelled, adds nothing (BR-TAG-001). At the limit the
/// button gives way to a warning (ruling P4a-L8).
class CardTagEditorWidget extends StatefulWidget {
  const CardTagEditorWidget({
    super.key,
    required this.tags,
    required this.onChanged,
    this.onPendingChanged,
  });

  final List<String> tags;
  final ValueChanged<List<String>> onChanged;

  /// Whether a name is typed but not added yet, so leaving would lose it.
  final ValueChanged<bool>? onPendingChanged;

  @override
  State<CardTagEditorWidget> createState() => _CardTagEditorWidgetState();
}

class _CardTagEditorWidgetState extends State<CardTagEditorWidget> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  var _isAdding = false;
  var _isPending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _input.addListener(_reportPending);
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _reportPending() {
    final isPending = _input.text.trim().isNotEmpty;
    if (isPending == _isPending) return;
    _isPending = isPending;
    widget.onPendingChanged?.call(isPending);
  }

  void _open() {
    setState(() => _isAdding = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _add(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _isAdding = false;
        _error = null;
      });
      return;
    }
    final folded = TagEntity.fold(trimmed);
    if (widget.tags.any((tag) => TagEntity.fold(tag) == folded)) {
      _input.clear();
      _focus.requestFocus();
      return;
    }
    final next = [...widget.tags, trimmed];
    if (CardDraft.checkTagNames(next) case Rejected(:final reason)) {
      setState(() => _error = context.l10n.cardRejection(reason));
      return;
    }
    setState(() => _error = null);
    _input.clear();
    widget.onChanged(next);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final isFull = widget.tags.length >= TagEntity.maxPerCard;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.control,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.micro),
            child: Row(
              spacing: AppSpacing.micro,
              children: [
                const Icon(AppIcons.tag, size: AppIconSize.inline),
                Text(
                  l10n.cardTags.toUpperCase(),
                  semanticsLabel: l10n.cardTags,
                  style: styles.overline,
                ),
                Flexible(
                  child: Text(
                    l10n.cardTagsMeta(widget.tags.length, TagEntity.maxPerCard),
                    style: styles.rowDescription,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: AppSpacing.micro,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final tag in widget.tags)
                CardRemovableTagChipWidget(
                  name: tag,
                  onRemove: () =>
                      widget.onChanged([...widget.tags]..remove(tag)),
                ),
              if (!isFull && !_isAdding)
                MxButton(
                  label: l10n.cardAddTag,
                  icon: AppIcons.add,
                  size: MxButtonSize.chip,
                  tone: MxButtonTone.outline,
                  onPressed: _open,
                ),
            ],
          ),
          if (_isAdding && !isFull)
            MxTextField(
              controller: _input,
              focusNode: _focus,
              label: l10n.cardTagHint,
              hintText: l10n.cardTagHint,
              errorText: _error,
              textInputAction: TextInputAction.done,
              onSubmitted: _add,
            ),
          if (isFull)
            MxFieldMessage(
              message: l10n.cardTagLimit,
              tone: MxFieldMessageTone.warning,
            ),
        ],
      ),
    );
  }
}
