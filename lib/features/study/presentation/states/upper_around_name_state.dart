/// A private-use code point no deck name contains: the template is
/// upper-cased with it in the name's place, then the name goes back as
/// typed (critique 2026-09-30 part 2, P4: never upper-case user data).
const String _namePlaceholder = '\u{F8FF}';

/// [build]'s sentence with the app's words upper-cased and [name] as typed.
String upperAroundName(String Function(String name) build, String name) =>
    build(_namePlaceholder).toUpperCase().replaceAll(_namePlaceholder, name);
