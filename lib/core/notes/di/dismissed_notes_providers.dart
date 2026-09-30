import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/notes/dismissed_note_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dismissed_notes_providers.g.dart';

@Riverpod(keepAlive: true)
DismissedNoteStore dismissedNoteStore(Ref ref) =>
    DismissedNoteStore(ref.watch(databaseProvider));

/// The note keys dismissed on this device.
@Riverpod(keepAlive: true)
Stream<Set<String>> dismissedNotes(Ref ref) =>
    ref.watch(dismissedNoteStoreProvider).watchDismissed();
