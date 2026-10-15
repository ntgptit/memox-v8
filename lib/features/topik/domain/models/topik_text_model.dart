/// A text the content gives in Vietnamese and English; both are always
/// present and non-empty (BR-TOPIK-006).
final class TopikText {
  const TopikText({required this.vi, required this.en});

  final String vi;
  final String en;
}
