import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/features/search/presentation/controllers/search_screen_controller.dart';
import 'package:memox/features/search/presentation/widgets/sections/search_body_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

/// Screen 04: the whole library — deck names, card faces, tag names — from
/// the Library header, at any level (UC-SEARCH-001). Navigation arrives as
/// callbacks.
class LibrarySearchScreen extends ConsumerStatefulWidget {
  const LibrarySearchScreen({
    super.key,
    required this.onOpenDeck,
    required this.onOpenCard,
    this.initialQuery = '',
  });

  final ValueChanged<String> onOpenDeck;
  final ValueChanged<String> onOpenCard;

  /// A term searched on arrival, such as a tag's name from screen 05 (FE-B2
  /// spec D11). Blank opens the search idle.
  final String initialQuery;

  @override
  ConsumerState<LibrarySearchScreen> createState() =>
      _LibrarySearchScreenState();
}

class _LibrarySearchScreenState extends ConsumerState<LibrarySearchScreen> {
  late final _query = TextEditingController(text: widget.initialQuery);

  @override
  void initState() {
    super.initState();
    // A term given on arrival is searched; the field itself takes focus
    // (step 1: the person came here to type).
    if (widget.initialQuery.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _search(widget.initialQuery);
    });
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _search(String term) =>
      ref.read(searchScreenControllerProvider.notifier).search(term);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxAppShell(
      appBar: MxAppBar(
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
        isTitleField: true,
        titleWidget: MxSearchField(
          // The field names the route, as the SDK AppBar names any title
          // (DEV-393): TalkBack announces the search on arrival.
          isRouteName: true,
          controller: _query,
          isAutofocused: true,
          hintText: l10n.searchFieldHint,
          clearLabel: l10n.searchClear,
          onChanged: _search,
        ),
      ),
      body: SearchBodyWidget(
        onOpenDeck: widget.onOpenDeck,
        onOpenCard: widget.onOpenCard,
      ),
    );
  }
}
