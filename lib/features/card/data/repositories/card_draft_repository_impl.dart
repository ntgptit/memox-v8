import 'dart:convert';

import 'package:memox/core/database/app_database.dart' hide CardDraft;
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/data/datasources/card_draft_dao.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/repositories/card_draft_repository.dart';

/// `card_draft` through [CardDraftDao]. The optional fields and the flag are
/// one JSON object, the tag names a JSON array. The text is card content, so
/// nothing here logs it (ADR-002), and the DB tracer logs a `card_draft`
/// statement without its arguments.
final class CardDraftRepositoryImpl implements CardDraftRepository {
  CardDraftRepositoryImpl(AppDatabase db, {DateTime Function()? now})
    : _dao = CardDraftDao(db),
      _now = now ?? DateTime.now;

  /// A draft not written to for this long goes with the next save: the deck
  /// or the card it names may be gone for good, and its text should not stay
  /// on the phone forever.
  static const Duration expiry = Duration(days: 30);

  static const _example = 'example';
  static const _hint = 'hint';
  static const _pronunciation = 'pronunciation';
  static const _isFlagged = 'isFlagged';
  static const _base = 'baseUpdatedAt';

  final CardDraftDao _dao;
  final DateTime Function() _now;

  @override
  Future<CardDraft?> read(String key) => guardDatabase(() async {
    final row = await _dao.find(key);
    return row == null ? null : _draftOf(row);
  });

  @override
  Future<void> save(String key, CardDraft draft) => guardDatabase(() async {
    final at = _now().toUtc();
    await _dao.upsert(
      key: key,
      front: draft.front,
      back: draft.back,
      extras: jsonEncode({
        _example: draft.example,
        _hint: draft.hint,
        _pronunciation: draft.pronunciation,
        _isFlagged: draft.isFlagged,
        _base: draft.baseUpdatedAt?.toUtc().toIso8601String(),
      }),
      tags: jsonEncode(draft.tagNames),
      at: at,
    );
    try {
      await _dao.removeBefore(at.subtract(expiry));
    } on Object {
      // The draft is kept; a prune that fails goes with the next save, and
      // must not report this one as lost.
    }
  });

  @override
  Future<void> clear(String key) => guardDatabase(() => _dao.remove(key));

  static CardDraft? _draftOf(CardDraftRow row) {
    try {
      final extras = jsonDecode(row.extras) as Map<String, Object?>;
      final tags = jsonDecode(row.tags) as List<Object?>;
      return CardDraft(
        front: row.front,
        back: row.back,
        example: extras[_example] as String?,
        hint: extras[_hint] as String?,
        pronunciation: extras[_pronunciation] as String?,
        isFlagged: extras[_isFlagged] as bool? ?? false,
        tagNames: [for (final tag in tags) tag as String],
        baseUpdatedAt: DateTime.tryParse(extras[_base] as String? ?? ''),
      );
    } on FormatException {
      // A row nothing in this app wrote offers no draft; it never breaks the
      // editor.
      return null;
    } on TypeError {
      return null;
    }
  }
}
