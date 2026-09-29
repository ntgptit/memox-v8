/// Where a warning or an error stands (ADR-018 §6). The names are the codes
/// of `app_log.status`. Other levels have none.
enum LogStatus {
  open,
  fixed;

  /// The status stored as [code], or null for a level with none.
  static LogStatus? parse(String? code) {
    for (final status in values) {
      if (status.name == code) return status;
    }
    return null;
  }
}
