import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/card/domain/models/card_folded_pair_model.dart';
import 'package:memox/features/card/domain/models/card_import_target_model.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/import_sections_model.dart';
import 'package:memox/features/transfer/domain/models/source_table_model.dart';

/// The user's answer to a name clash (spec 2026-10-08 §4.3).
enum ImportSectionChoice { addToExisting, createNew }

/// What a preview read, before the user's choices: re-derived into an
/// [ImportPreview] each time a choice or the default name changes, without
/// reading again (spec 2026-10-08 U2–U6).
final class ImportPlan {
  const ImportPlan({
    required this.table,
    required this.mapping,
    required this.hasHeaderRow,
    required this.target,
    required this.sections,
  });

  final SourceTable table;
  final ColumnMapping mapping;
  final bool hasHeaderRow;
  final CardImportTarget target;

  /// Null for a flat source (BR-TRANSFER-015).
  final List<ImportSection>? sections;

  /// Whether this import writes into the target itself (§4.2).
  bool get isFlatIntoTarget => sections == null && target.canHoldCards;

  /// The sections as written, or one default section with every data row
  /// for a flat source into a deck that takes decks (§4.2).
  List<ImportSection> get _groupsToBe =>
      sections ??
      [
        ImportSection(
          name: '',
          isDefault: true,
          rowIndexes: [
            for (
              var index = hasHeaderRow ? 1 : 0;
              index < table.rows.length;
              index++
            )
              index,
          ],
        ),
      ];

  /// The groups with their destinations under [choices] (keyed by group
  /// index), the default deck named [defaultDeckName].
  ImportPreview preview({
    required String defaultDeckName,
    required Map<int, ImportSectionChoice> choices,
  }) {
    if (isFlatIntoTarget) {
      return buildImportPreview(
        table: table,
        mapping: mapping,
        hasHeaderRow: hasHeaderRow,
        existing: target.pairs,
      );
    }
    final toBe = _groupsToBe;
    final sectionKeys = {
      for (final section in toBe)
        if (!section.isDefault) foldText(section.name),
    };
    return ImportPreview.sectioned([
      for (final (index, section) in toBe.indexed)
        _group(
          section,
          name: section.isDefault ? defaultDeckName.trim() : section.name,
          choice: choices[index],
          isTakenInFile:
              section.isDefault &&
              sectionKeys.contains(foldText(defaultDeckName)),
        ),
    ]);
  }

  ImportGroup _group(
    ImportSection section, {
    required String name,
    required ImportSectionChoice? choice,
    required bool isTakenInFile,
  }) {
    final key = foldText(name);
    final child = target.children
        .where((candidate) => foldText(candidate.name) == key)
        .firstOrNull;
    final destination = _destinationOf(child, choice);
    final rows = classifyRows(
      table: table,
      rowIndexes: section.rowIndexes,
      mapping: mapping,
      existing: switch (destination) {
        IntoExistingDeck() || Undecided() => child!.pairs,
        _ => <CardFoldedPair>{},
      },
    );
    final nameCheck = DeckEntity.checkName(name);
    return ImportGroup(
      name: name,
      isDefault: section.isDefault,
      destination: destination,
      clash: child == null
          ? null
          : ImportClash(
              deckId: child.id,
              name: child.name,
              canHoldCards: child.canHoldCards,
            ),
      nameProblem: section.isDefault
          ? _problemOf(nameCheck, isTakenInFile: isTakenInFile)
          : null,
      rows: switch (nameCheck) {
        Rejected(:final reason) when !section.isDefault => _refused(
          rows,
          reason,
        ),
        _ => rows,
      },
    );
  }

  /// No clash or a clash with a deck of decks: a new deck (§4.3); a clash
  /// with a deck that takes cards: the user's choice, undecided until made.
  static ImportDestination _destinationOf(
    CardImportChild? child,
    ImportSectionChoice? choice,
  ) => switch ((child, choice)) {
    (null, _) => const IntoNewDeck(),
    (final clash?, _) when !clash.canHoldCards => const IntoNewDeck(),
    (final clash?, ImportSectionChoice.addToExisting) => IntoExistingDeck(
      clash.id,
    ),
    (_, ImportSectionChoice.createNew) => const IntoNewDeck(),
    (_, null) => const Undecided(),
  };

  /// A section's rows when its name is refused: every row that is not
  /// blank is invalid for the deck name (BR-TRANSFER-015).
  static List<ImportRow> _refused(List<ImportRow> rows, DeckRejection reason) =>
      [
        for (final row in rows)
          if (row.kind == ImportRowKind.blank)
            row
          else
            ImportRow(
              rowNumber: row.rowNumber,
              kind: ImportRowKind.invalid,
              draft: row.draft,
              deckNameReason: reason,
            ),
      ];

  static ImportNameProblem? _problemOf(
    Outcome<void, DeckRejection> check, {
    required bool isTakenInFile,
  }) => switch (check) {
    Rejected(reason: DeckRejection.blankName) => ImportNameProblem.blank,
    Rejected() => ImportNameProblem.tooLong,
    _ when isTakenInFile => ImportNameProblem.takenInFile,
    _ => null,
  };
}
