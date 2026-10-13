/// The languages the term can be read in (study speech spec §4, D5): a
/// fixed list, each with the BCP-47 tag `app_settings.tts_language` and
/// `deck.study_config`'s `tts_language` store. Adding one is a code change,
/// a schema migration (the CHECK) and two ARB lines.
enum SpeechLanguage {
  enUs('en-US'),
  enGb('en-GB'),
  viVn('vi-VN'),
  koKr('ko-KR'),
  jaJp('ja-JP'),
  zhCn('zh-CN'),
  zhTw('zh-TW'),
  frFr('fr-FR'),
  deDe('de-DE'),
  esEs('es-ES');

  const SpeechLanguage(this.tag);

  /// The BCP-47 tag the engine and the store use.
  final String tag;

  /// What a fresh install and a root without a language read in.
  static const SpeechLanguage defaultLanguage = enUs;

  /// The language [tag] names, or null for one not in the list.
  static SpeechLanguage? fromTag(String? tag) {
    for (final language in values) {
      if (language.tag == tag) return language;
    }
    return null;
  }
}
