import 'dart:ui';

import 'generated/app_localizations.dart';

/// Resolves the best supported locale for code that runs without a BuildContext.
AppLocalizations platformAppLocalizations() {
  final locale = PlatformDispatcher.instance.locale;
  if (AppLocalizations.supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  )) {
    return lookupAppLocalizations(Locale(locale.languageCode));
  }
  return lookupAppLocalizations(const Locale('en'));
}
