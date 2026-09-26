import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/deck/presentation/providers/deck_view_provider.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';

/// Which half of the Study Entry's deck context to draw.
enum DeckStudyHeaderPart { title, breadcrumb }

/// The deck a Study Entry is for: its name as the app bar's title, or its
/// path from the Library (screen 14). `app/` passes it to the study screen,
/// which may not read the deck feature (FE-A6 D16). Blank while loading and
/// once the deck is gone: the entry itself says so.
class DeckStudyHeaderWidget extends ConsumerWidget {
  const DeckStudyHeaderWidget({
    super.key,
    required this.deckId,
    required this.part,
  });

  final String deckId;
  final DeckStudyHeaderPart part;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = switch (ref.watch(deckViewProvider(deckId))) {
      AsyncData(value: Ok(:final value)) => value,
      _ => null,
    };
    if (view == null) return const SizedBox.shrink();
    return switch (part) {
      // The content bar's own title role (MxAppBar), as a header.
      DeckStudyHeaderPart.title => Semantics(
        header: true,
        child: Text(
          view.deck.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textStyles.contentTitle,
        ),
      ),
      DeckStudyHeaderPart.breadcrumb => MxBreadcrumb(
        segments: [
          MxBreadcrumbSegment(label: context.l10n.navLibrary),
          for (final entry in view.breadcrumb)
            MxBreadcrumbSegment(label: entry.name),
          MxBreadcrumbSegment(label: view.deck.name),
        ],
      ),
    };
  }
}
