import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/starter_decks/domain/models/starter_template_model.dart';

/// The depth of the root a copy writes; the template's decks start below it.
const _rootDepth = 1;

/// The template a file's JSON describes (starter decks spec §5.1), or null
/// when it breaks a rule of spec D6: the library leaves such a template out
/// (UC-STARTER-001 E3), so every template it lists can be copied.
StarterTemplate? starterTemplateOf(Object? json) {
  if (json is! Map<String, Object?>) return null;
  final templateId = _textOf(json['templateId']);
  final version = json['version'];
  final locale = _textOf(json['locale']);
  final title = _textOf(json['title']);
  final contentSource = _textOf(json['contentSource']);
  final frontLanguage = _textOf(json['frontLanguage']);
  final backLanguage = _textOf(json['backLanguage']);
  final scheduler = _schedulerOf(json['defaultScheduler']);
  if (templateId == null || locale == null || title == null) return null;
  if (contentSource == null || frontLanguage == null) return null;
  if (backLanguage == null || scheduler == null) return null;
  if (version is! int || version < 1) return null;
  // The copy's root is named after the title, and a root holds decks only.
  if (!_isDeckName(title) || json.containsKey('cards')) return null;
  final decks = _decksOf(json['decks'], depth: _rootDepth + 1);
  if (decks == null) return null;
  return StarterTemplate(
    templateId: templateId,
    version: version,
    locale: locale,
    title: title,
    contentSource: contentSource,
    frontLanguage: frontLanguage,
    backLanguage: backLanguage,
    suggestedScheduler: scheduler,
    decks: decks,
  );
}

/// [value] when it is text with something in it.
String? _textOf(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return value;
}

SchedulerType? _schedulerOf(Object? code) {
  for (final type in SchedulerType.values) {
    if (type.code == code) return type;
  }
  return null;
}

bool _isDeckName(String name) => switch (DeckEntity.checkName(name)) {
  Ok() => true,
  Rejected() => false,
};

/// The decks of [value], a list with something in it, each at [depth].
List<StarterDeck>? _decksOf(Object? value, {required int depth}) {
  if (value is! List<Object?> || value.isEmpty) return null;
  if (depth > DeckEntity.maxDepth) return null;
  final decks = <StarterDeck>[];
  for (final item in value) {
    final deck = _deckOf(item, depth: depth);
    if (deck == null) return null;
    decks.add(deck);
  }
  return decks;
}

/// A deck holds sub-decks or cards: both or neither breaks spec D6.
StarterDeck? _deckOf(Object? json, {required int depth}) {
  if (json is! Map<String, Object?>) return null;
  final name = json['name'];
  if (name is! String || !_isDeckName(name)) return null;
  final hasDecks = json.containsKey('decks');
  if (hasDecks == json.containsKey('cards')) return null;
  if (!hasDecks) return _cardDeckOf(name, json['cards']);
  final decks = _decksOf(json['decks'], depth: depth + 1);
  if (decks == null) return null;
  return StarterDeck(name: name, decks: decks);
}

StarterDeck? _cardDeckOf(String name, Object? value) {
  if (value is! List<Object?> || value.isEmpty) return null;
  final cards = <StarterCard>[];
  for (final item in value) {
    final card = _cardOf(item);
    if (card == null) return null;
    cards.add(card);
  }
  return StarterDeck(name: name, cards: cards);
}

/// A card passes exactly what a card written by hand passes
/// (BR-CARD-001…BR-CARD-003).
StarterCard? _cardOf(Object? json) {
  if (json is! Map<String, Object?>) return null;
  final front = json['front'];
  final back = json['back'];
  final example = json['example'];
  final hint = json['hint'];
  final pronunciation = json['pronunciation'];
  if (front is! String || back is! String) return null;
  if (example is! String? || hint is! String?) return null;
  if (pronunciation is! String?) return null;
  final draft = CardDraft(
    front: front,
    back: back,
    example: example,
    hint: hint,
    pronunciation: pronunciation,
  );
  if (draft.check() case Rejected()) return null;
  return StarterCard(
    front: front,
    back: back,
    example: example,
    hint: hint,
    pronunciation: pronunciation,
  );
}
