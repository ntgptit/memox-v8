import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// Plain copy for every reason a tag write is refused (spec §5).
extension TagRejectionMessage on AppLocalizations {
  String tagRejection(TagRejection reason) => switch (reason) {
    TagRejection.blankName => tagRejectionBlankName,
    TagRejection.nameTooLong => tagRejectionNameTooLong,
    TagRejection.controlCharacter => tagRejectionControlCharacter,
    TagRejection.tooManyTags => tagRejectionTooManyTags,
    TagRejection.notFound => tagRejectionNotFound,
  };
}
