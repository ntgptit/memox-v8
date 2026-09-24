import 'package:memox/features/deck/domain/models/deck_path_model.dart';

/// A deck as a walk of its tree needs it: where it hangs, and whether the
/// walk hands it back ([isCandidate]) or only passes through it.
final class DeckTreeNode {
  const DeckTreeNode({
    required this.id,
    required this.name,
    required this.parentId,
    required this.siblingPosition,
    required this.isCandidate,
  });

  final String id;
  final String name;
  final String? parentId;
  final int siblingPosition;
  final bool isCandidate;
}

/// The candidates among [nodes] in tree order — roots first, each deck
/// followed by the decks below it, siblings in manual order
/// `(sibling_position, id)` — each built by [build] with its path from the
/// root. [nodes] hold every deck on the candidates' paths, so one query
/// serves every path instead of a query per deck.
List<T> candidatesInTreeOrder<T>(
  List<DeckTreeNode> nodes,
  T Function(DeckTreeNode node, List<DeckPathEntry> path) build,
) {
  final children = <String?, List<DeckTreeNode>>{};
  for (final node in nodes) {
    (children[node.parentId] ??= []).add(node);
  }
  for (final siblings in children.values) {
    siblings.sort((a, b) {
      final byPosition = a.siblingPosition.compareTo(b.siblingPosition);
      if (byPosition != 0) return byPosition;
      return a.id.compareTo(b.id);
    });
  }
  final found = <T>[];
  void visit(String? parentId, List<DeckPathEntry> path) {
    for (final node in children[parentId] ?? const <DeckTreeNode>[]) {
      if (node.isCandidate) found.add(build(node, path));
      visit(node.id, [...path, DeckPathEntry(id: node.id, name: node.name)]);
    }
  }

  visit(null, const []);
  return found;
}
