/// Why Monitoring refuses a read or a change (ADR-011 D6).
enum MonitoringRejection {
  /// The log is gone: cleaned up by the retention job, or sent from the
  /// device since the list was drawn.
  notFound,
}
