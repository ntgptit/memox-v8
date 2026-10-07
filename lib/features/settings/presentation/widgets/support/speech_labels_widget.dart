import 'package:memox/core/speech/speech_language.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// [language] as the person reads it (study speech spec §4).
String speechLanguageName(AppLocalizations l10n, SpeechLanguage language) =>
    switch (language) {
      SpeechLanguage.enUs => l10n.speechLanguageEnUs,
      SpeechLanguage.enGb => l10n.speechLanguageEnGb,
      SpeechLanguage.viVn => l10n.speechLanguageViVn,
      SpeechLanguage.koKr => l10n.speechLanguageKoKr,
      SpeechLanguage.jaJp => l10n.speechLanguageJaJp,
      SpeechLanguage.zhCn => l10n.speechLanguageZhCn,
      SpeechLanguage.zhTw => l10n.speechLanguageZhTw,
      SpeechLanguage.frFr => l10n.speechLanguageFrFr,
      SpeechLanguage.deDe => l10n.speechLanguageDeDe,
      SpeechLanguage.esEs => l10n.speechLanguageEsEs,
    };
