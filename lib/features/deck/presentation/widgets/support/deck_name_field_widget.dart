import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_rejection_message_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// The deck-name field of the create and rename dialogs (BR-DECK-020;
/// owner 2026-10-21): the count from the 26th character, and a name over
/// the limit said as it is typed, so the confirm can lock before a tap.
/// [submitted] is the reason the last write returned (a blank name is said
/// only then). Nothing is cut: a paste stays whole.
class DeckNameFieldWidget extends StatelessWidget {
  const DeckNameFieldWidget({
    super.key,
    required this.controller,
    required this.submitted,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final DeckRejection? submitted;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Whether [name], as typed, breaks the length rule of BR-DECK-020.
  static bool isTooLong(String name) => switch (DeckEntity.checkName(name)) {
    Rejected(reason: DeckRejection.nameTooLong) => true,
    _ => false,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = controller.text;
    final length = DeckEntity.nameLength(name);
    var reason = submitted;
    if (isTooLong(name)) reason = DeckRejection.nameTooLong;
    return MxTextField(
      controller: controller,
      label: l10n.deckNameHint,
      counter: length > DeckEntity.recommendedNameLength
          ? l10n.deckNameLength(length, DeckEntity.maxNameLength)
          : null,
      errorText: switch (reason) {
        null => null,
        final reason => l10n.deckRejection(reason),
      },
      textInputAction: TextInputAction.done,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}
