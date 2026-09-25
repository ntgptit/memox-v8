import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/features/deck/presentation/states/deck_reorder_mode_state.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';

/// Ends reorder mode for its level (ruling P2-L3).
class DeckReorderDoneWidget extends ConsumerWidget {
  const DeckReorderDoneWidget({super.key, required this.parentId});

  final String? parentId;

  void _finish(WidgetRef ref) =>
      ref.read(deckReorderModeProvider(parentId).notifier).finish();

  @override
  Widget build(BuildContext context, WidgetRef ref) => MxButton(
    label: context.l10n.libraryReorderDone,
    size: MxButtonSize.compact,
    onPressed: () => _finish(ref),
  );
}
