import 'package:flutter/widgets.dart';
import 'package:memox/features/search/presentation/states/search_screen_state.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

/// The end of the results while another page follows: "Load more results",
/// busy while it reads; after a failure, a retry in its place and the rows
/// above kept (UC-SEARCH-001 A1, E2).
class SearchLoadMoreWidget extends StatelessWidget {
  const SearchLoadMoreWidget({
    super.key,
    required this.status,
    required this.onLoadMore,
    required this.onRetry,
  });

  final SearchMoreStatus status;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (status == SearchMoreStatus.failed) {
      return MxInlineBanner(
        tone: MxBannerTone.danger,
        message: l10n.searchLoadMoreFailed,
        actions: [
          MxButton(
            label: l10n.commonRetry,
            size: MxButtonSize.compact,
            onPressed: onRetry,
          ),
        ],
      );
    }
    return MxButton(
      label: l10n.searchLoadMore,
      onPressed: onLoadMore,
      tone: MxButtonTone.secondary,
      isBlock: true,
      isLoading: status == SearchMoreStatus.loading,
    );
  }
}
