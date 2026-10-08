import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/transfer/domain/models/import_plan_model.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/presentation/widgets/support/import_labels_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// One destination of a sectioned import (spec 2026-10-08 U2–U4): its
/// name, New or Existing, the cards it receives, and, for a taken name, the
/// choice the user must make. The default deck's name is a field.
class ImportDeckRowWidget extends StatefulWidget {
  const ImportDeckRowWidget({
    super.key,
    required this.group,
    required this.willWrite,
    required this.onChoose,
    required this.onRename,
  });

  final ImportGroup group;
  final int willWrite;
  final ValueChanged<ImportSectionChoice> onChoose;
  final ValueChanged<String> onRename;

  @override
  State<ImportDeckRowWidget> createState() => _ImportDeckRowWidgetState();
}

class _ImportDeckRowWidgetState extends State<ImportDeckRowWidget> {
  /// A deck name of up to 200 characters stays within two lines.
  static const int _maxNameLines = 2;

  /// What a chosen clash does (C4); null while undecided.
  static String? _consequenceOf(ImportGroup group, AppLocalizations l10n) =>
      switch (group.destination) {
        IntoExistingDeck() => l10n.importDeckAddConsequence,
        IntoNewDeck() => l10n.importDeckCreateConsequence(group.name),
        _ => null,
      };

  /// Owns the default name's text, so a rebuild with the edited name does
  /// not move the caret.
  late final TextEditingController _name = TextEditingController(
    text: widget.group.name,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final group = widget.group;
    final clash = group.clash;
    final isExisting = group.destination is IntoExistingDeck;
    final isUndecided = group.destination is Undecided;
    final problem = group.nameProblem;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.grouped,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.control,
        children: [
          if (group.isDefault) ...[
            // MxTextField's label is for TalkBack; the caller shows its own
            // (critique 2026-10-08, F2).
            ExcludeSemantics(
              child: Text(
                l10n.importDeckNameLabel,
                style: styles.rowDescription,
              ),
            ),
            MxTextField(
              controller: _name,
              label: l10n.importDeckNameLabel,
              errorText: problem == null
                  ? null
                  : l10n.importNameProblem(problem),
              onChanged: widget.onRename,
            ),
          ] else
            Text(
              group.name,
              maxLines: _maxNameLines,
              overflow: TextOverflow.ellipsis,
              style: styles.contentTitle,
            ),
          Row(
            spacing: AppSpacing.control,
            children: [
              // Undecided is neither New nor Existing until the user
              // chooses (critique 2026-10-08, F1).
              if (!isUndecided)
                MxBadge(
                  label: isExisting
                      ? l10n.importDeckExisting
                      : l10n.importDeckNew,
                  tone: isExisting ? MxBadgeTone.neutral : MxBadgeTone.primary,
                ),
              Expanded(
                child: Text(
                  widget.willWrite == 0
                      ? l10n.importDeckNothing
                      : l10n.importDeckCards(widget.willWrite),
                  style: styles.rowDescription,
                ),
              ),
            ],
          ),
          if (clash != null && group.isChoosable) ...[
            // The facts the choice needs (critique 2026-10-08, C4).
            MxNote.hint(
              text: l10n.importDeckClashNote(clash.name, clash.cardCount),
            ),
            MxSegmentedTray<ImportSectionChoice>(
              segments: [
                MxSegment(
                  value: ImportSectionChoice.addToExisting,
                  label: l10n.importDeckAddToExisting,
                ),
                MxSegment(
                  value: ImportSectionChoice.createNew,
                  label: l10n.importDeckCreateNew,
                ),
              ],
              selected: switch (group.destination) {
                IntoExistingDeck() => ImportSectionChoice.addToExisting,
                Undecided() => null,
                _ => ImportSectionChoice.createNew,
              },
              onSelected: widget.onChoose,
            ),
            if (_consequenceOf(group, l10n) case final consequence?)
              Text(consequence, style: styles.rowDescription),
          ],
          if (clash != null && !clash.canHoldCards)
            MxNote.hint(text: l10n.importDeckHoldsDecksNote),
        ],
      ),
    );
  }
}
