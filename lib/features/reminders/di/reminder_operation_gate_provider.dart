import 'package:memox/features/reminders/data/datasources/reminder_operation_gate_data_source.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reminder_operation_gate_provider.g.dart';

/// One gate for the app's isolate: every reminder operation that reads,
/// schedules and saves goes through it (reminders spec §14, BE-B5b).
@Riverpod(keepAlive: true)
ReminderOperationGate reminderOperationGate(Ref ref) => ReminderOperationGate();
