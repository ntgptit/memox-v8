/// [email] for display: a zero-width space after the @, a place the line may
/// break that draws as nothing, so a long address wraps before its domain
/// rather than inside it (audit 2026-10-19, G5). The domain is what tells
/// accounts apart. Screen readers skip the space.
String wrappableEmail(String email) => email.replaceFirst('@', '@​');
