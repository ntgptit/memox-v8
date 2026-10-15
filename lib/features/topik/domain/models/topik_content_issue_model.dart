/// The rule a content problem breaks, one per row of spec 2026-10-15 §4.2.
enum TopikContentRule {
  /// The JSON is not the shape the schema describes.
  shape,
  identity,
  metadata,
  numbering,
  points,
  options,
  groups,
  audio,
  questionType,
  languages,
  assets,

  /// Two packs share one test id.
  duplicate,
}

/// An error rejects the test (BR-TOPIK-008); a warning is reported only.
enum TopikIssueSeverity { error, warning }

/// One problem found in a content pack. [detail] is English and is read by
/// the content author and the log, never shown in the app (BR-CORE-005).
final class TopikContentIssue {
  const TopikContentIssue({
    required this.rule,
    required this.severity,
    required this.testId,
    required this.detail,
  });

  const TopikContentIssue.error(this.rule, this.testId, this.detail)
    : severity = TopikIssueSeverity.error;

  const TopikContentIssue.warning(this.rule, this.testId, this.detail)
    : severity = TopikIssueSeverity.warning;

  final TopikContentRule rule;
  final TopikIssueSeverity severity;

  /// The test the problem belongs to, or the file path when no id was read.
  final String testId;
  final String detail;

  bool get isError => severity == TopikIssueSeverity.error;

  @override
  String toString() => '${severity.name} $testId [${rule.name}] $detail';
}
