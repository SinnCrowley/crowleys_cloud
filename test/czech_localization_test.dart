import 'package:crowleys_cloud/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Czech is a supported locale with translated core interface labels', () {
    expect(AppLocalizations.supportedLocales, contains(const Locale('cs')));

    final l10n = lookupAppLocalizations(const Locale('cs'));
    expect(l10n.welcomeBack, 'Vítejte zpět');
    expect(l10n.upload, 'Nahrát');
    expect(l10n.download, 'Stáhnout');
    expect(l10n.navSettings, 'Nastavení');
    expect(l10n.deletePermanently, 'Trvale smazat');
  });
}
