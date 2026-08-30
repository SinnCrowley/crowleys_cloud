// Copyright (C) 2026 Sinn Crowley
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

import 'package:crowleys_cloud/l10n/generated/app_localizations.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations_cs.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations_pl.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations_ru.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations_uk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final slavicLocales = <Locale, Type>{
    const Locale('pl'): AppLocalizationsPl,
    const Locale('uk'): AppLocalizationsUk,
    const Locale('cs'): AppLocalizationsCs,
    const Locale('ru'): AppLocalizationsRu,
  };

  group('Slavic Locales Initialization and Instance Verification', () {
    test('AppLocalizations.supportedLocales contains all 4 Slavic locales', () {
      expect(
        AppLocalizations.supportedLocales,
        containsAll([
          const Locale('pl'),
          const Locale('uk'),
          const Locale('cs'),
          const Locale('ru'),
        ]),
      );
    });

    for (final entry in slavicLocales.entries) {
      final locale = entry.key;
      final expectedType = entry.value;

      test(
        'lookupAppLocalizations for ${locale.languageCode} returns $expectedType',
        () {
          final l10n = lookupAppLocalizations(locale);
          expect(l10n.runtimeType, expectedType);
          expect(l10n.localeName, locale.languageCode);
        },
      );
    }
  });

  group('Slavic Locales Exhaustive Parameterized Methods Stress Harness', () {
    const stringTestCases = <String>[
      'StandardName',
      '',
      '   ',
      'Special !@#\$%^&*()_+-=[]{}|;\':",.<>/?',
      'Unicode_🚀_Тест_Zażółć_gęślą_jaźń_Příliš_žluťoučký_kůň',
      'Very Long String Name That Exceeds Normal Length Constraints In Cloud File Systems 1234567890',
      'Path/With/Forward/Slashes/file.tar.gz',
      'Path\\With\\Backslashes\\file.dat',
      '{"jsonKey": "jsonValue", "status": 200}',
    ];

    const intTestCases = <int>[
      0,
      1,
      2,
      3,
      4,
      5,
      11,
      12,
      14,
      21,
      22,
      25,
      100,
      101,
      102,
      105,
      -1,
      999999,
    ];

    for (final entry in slavicLocales.entries) {
      final locale = entry.key;
      final lang = locale.languageCode;

      group('Locale [$lang] - All 106 Parameterized Methods Interpolation', () {
        late AppLocalizations l10n;

        setUp(() {
          l10n = lookupAppLocalizations(locale);
        });

        test('Single-String parameter methods format without exceptions', () {
          for (final s in stringTestCases) {
            // errorWithMessage
            final res1 = l10n.errorWithMessage(s);
            expect(res1, isNotEmpty);
            expect(res1, contains(s));

            // switchServerBody
            final res2 = l10n.switchServerBody(s);
            expect(res2, isNotEmpty);
            expect(res2, contains(s));

            // signInToAccess
            final res3 = l10n.signInToAccess(s);
            expect(res3, isNotEmpty);
            expect(res3, contains(s));

            // unableToConnectTo
            final res4 = l10n.unableToConnectTo(s);
            expect(res4, isNotEmpty);
            expect(res4, contains(s));

            // updateAvailableTitle
            final res5 = l10n.updateAvailableTitle(s);
            expect(res5, isNotEmpty);
            expect(res5, contains(s));

            // updateVersionSubtitle
            final res6 = l10n.updateVersionSubtitle(s);
            expect(res6, isNotEmpty);
            expect(res6, contains(s));

            // updateCurrentVersion
            final res7 = l10n.updateCurrentVersion(s);
            expect(res7, isNotEmpty);
            expect(res7, contains(s));

            // updateNewVersion
            final res8 = l10n.updateNewVersion(s);
            expect(res8, isNotEmpty);
            expect(res8, contains(s));

            // failedToCopySharedLink
            final res9 = l10n.failedToCopySharedLink(s);
            expect(res9, isNotEmpty);
            expect(res9, contains(s));

            // failedToCreateShare
            final res10 = l10n.failedToCreateShare(s);
            expect(res10, isNotEmpty);
            expect(res10, contains(s));

            // failedToCreateFolder
            final res11 = l10n.failedToCreateFolder(s);
            expect(res11, isNotEmpty);
            expect(res11, contains(s));

            // renameFailed
            final res12 = l10n.renameFailed(s);
            expect(res12, isNotEmpty);
            expect(res12, contains(s));

            // moveTo
            final res13 = l10n.moveTo(s);
            expect(res13, isNotEmpty);
            expect(res13, contains(s));

            // moveFailed
            final res14 = l10n.moveFailed(s);
            expect(res14, isNotEmpty);
            expect(res14, contains(s));

            // copyFailed
            final res15 = l10n.copyFailed(s);
            expect(res15, isNotEmpty);
            expect(res15, contains(s));

            // deletePermanentlyBody
            final res16 = l10n.deletePermanentlyBody(s);
            expect(res16, isNotEmpty);
            expect(res16, contains(s));

            // deleteFileBody
            final res17 = l10n.deleteFileBody(s);
            expect(res17, isNotEmpty);
            expect(res17, contains(s));

            // deleteServerFileBody
            final res18 = l10n.deleteServerFileBody(s);
            expect(res18, isNotEmpty);
            expect(res18, contains(s));

            // failedToMoveToTrash
            final res19 = l10n.failedToMoveToTrash(s);
            expect(res19, isNotEmpty);
            expect(res19, contains(s));

            // failedToDelete
            final res20 = l10n.failedToDelete(s);
            expect(res20, isNotEmpty);
            expect(res20, contains(s));

            // failedToDeleteItem
            final res21 = l10n.failedToDeleteItem(s);
            expect(res21, isNotEmpty);
            expect(res21, contains(s));

            // deletedFilename
            final res22 = l10n.deletedFilename(s);
            expect(res22, isNotEmpty);
            expect(res22, contains(s));

            // fileDownloadFailed
            final res23 = l10n.fileDownloadFailed(s);
            expect(res23, isNotEmpty);
            expect(res23, contains(s));

            // downloadComplete
            final res24 = l10n.downloadComplete(s);
            expect(res24, isNotEmpty);
            expect(res24, contains(s));

            // downloadFailed
            final res25 = l10n.downloadFailed(s);
            expect(res25, isNotEmpty);
            expect(res25, contains(s));

            // uploadComplete
            final res26 = l10n.uploadComplete(s);
            expect(res26, isNotEmpty);
            expect(res26, contains(s));

            // uploadFailed
            final res27 = l10n.uploadFailed(s);
            expect(res27, isNotEmpty);
            expect(res27, contains(s));

            // failedToCopyLink
            final res28 = l10n.failedToCopyLink(s);
            expect(res28, isNotEmpty);
            expect(res28, contains(s));

            // pleaseSignInToServer
            final res29 = l10n.pleaseSignInToServer(s);
            expect(res29, isNotEmpty);
            expect(res29, contains(s));

            // connectedToServer
            final res30 = l10n.connectedToServer(s);
            expect(res30, isNotEmpty);
            expect(res30, contains(s));

            // connectionFailed
            final res31 = l10n.connectionFailed(s);
            expect(res31, isNotEmpty);
            expect(res31, contains(s));

            // failedToConnect
            final res32 = l10n.failedToConnect(s);
            expect(res32, isNotEmpty);
            expect(res32, contains(s));

            // authFailed
            final res33 = l10n.authFailed(s);
            expect(res33, isNotEmpty);
            expect(res33, contains(s));

            // biometricLoginFailed
            final res34 = l10n.biometricLoginFailed(s);
            expect(res34, isNotEmpty);
            expect(res34, contains(s));

            // failedToSaveServer
            final res35 = l10n.failedToSaveServer(s);
            expect(res35, isNotEmpty);
            expect(res35, contains(s));

            // loginFailed
            final res36 = l10n.loginFailed(s);
            expect(res36, isNotEmpty);
            expect(res36, contains(s));

            // registrationFailed
            final res37 = l10n.registrationFailed(s);
            expect(res37, isNotEmpty);
            expect(res37, contains(s));

            // changePasswordSubtitle
            final res38 = l10n.changePasswordSubtitle(s);
            expect(res38, isNotEmpty);
            expect(res38, contains(s));

            // deleteAccountBody
            final res39 = l10n.deleteAccountBody(s);
            expect(res39, isNotEmpty);
            expect(res39, contains(s));

            // passwordChangeFailed
            final res40 = l10n.passwordChangeFailed(s);
            expect(res40, isNotEmpty);
            expect(res40, contains(s));

            // accountDeletionFailed
            final res41 = l10n.accountDeletionFailed(s);
            expect(res41, isNotEmpty);
            expect(res41, contains(s));

            // versionLabel
            final res42 = l10n.versionLabel(s);
            expect(res42, isNotEmpty);
            expect(res42, contains(s));

            // appIsUpToDate
            final res43 = l10n.appIsUpToDate(s);
            expect(res43, isNotEmpty);
            expect(res43, contains(s));

            // selectColor
            final res44 = l10n.selectColor(s);
            expect(res44, isNotEmpty);
            expect(res44, contains(s));

            // lastRunAt
            final res45 = l10n.lastRunAt(s);
            expect(res45, isNotEmpty);
            expect(res45, contains(s));

            // conflictSizeLabel
            final res46 = l10n.conflictSizeLabel(s);
            expect(res46, isNotEmpty);
            expect(res46, contains(s));

            // conflictDateLabel
            final res47 = l10n.conflictDateLabel(s);
            expect(res47, isNotEmpty);
            expect(res47, contains(s));

            // conflictDeletedLabel
            final res48 = l10n.conflictDeletedLabel(s);
            expect(res48, isNotEmpty);
            expect(res48, contains(s));

            // errorReadingFile
            final res49 = l10n.errorReadingFile(s);
            expect(res49, isNotEmpty);
            expect(res49, contains(s));

            // syncNotificationSyncingWith
            final res50 = l10n.syncNotificationSyncingWith(s);
            expect(res50, isNotEmpty);
            expect(res50, contains(s));

            // syncNotificationPausedTitle
            final res51 = l10n.syncNotificationPausedTitle(s);
            expect(res51, isNotEmpty);
            expect(res51, contains(s));

            // syncNotificationFailedTitle
            final res52 = l10n.syncNotificationFailedTitle(s);
            expect(res52, isNotEmpty);
            expect(res52, contains(s));

            // syncNotificationCompleteTitle
            final res53 = l10n.syncNotificationCompleteTitle(s);
            expect(res53, isNotEmpty);
            expect(res53, contains(s));

            // syncStatusConnectionLost
            final res54 = l10n.syncStatusConnectionLost(s);
            expect(res54, isNotEmpty);
            expect(res54, contains(s));

            // syncResultServerUnreachableWithServer
            final res55 = l10n.syncResultServerUnreachableWithServer(s);
            expect(res55, isNotEmpty);
            expect(res55, contains(s));

            // cannotMoveFolderIntoItself
            final res56 = l10n.cannotMoveFolderIntoItself(s);
            expect(res56, isNotEmpty);
            expect(res56, contains(s));

            // uploadLocalPathEmpty
            final res57 = l10n.uploadLocalPathEmpty(s);
            expect(res57, isNotEmpty);
            expect(res57, contains(s));

            // uploadErrorLocalPathEmpty
            final res58 = l10n.uploadErrorLocalPathEmpty(s);
            expect(res58, isNotEmpty);
            expect(res58, contains(s));
          }
        });

        test('Single-Integer parameter methods format without exceptions', () {
          for (final n in intTestCases) {
            final nStr = n.toString();

            // deleteNItemsTitle
            final res1 = l10n.deleteNItemsTitle(n);
            expect(res1, isNotEmpty);
            expect(res1, contains(nStr));

            // deleteFilesBody
            final res2 = l10n.deleteFilesBody(n);
            expect(res2, isNotEmpty);
            expect(res2, contains(nStr));

            // unshareItemsBody
            final res3 = l10n.unshareItemsBody(n);
            expect(res3, isNotEmpty);
            expect(res3, contains(nStr));

            // movedNItemsToTrash
            final res4 = l10n.movedNItemsToTrash(n);
            expect(res4, isNotEmpty);
            expect(res4, contains(nStr));

            // deletedNItems
            final res5 = l10n.deletedNItems(n);
            expect(res5, isNotEmpty);
            expect(res5, contains(nStr));

            // uploadedNItems
            final res6 = l10n.uploadedNItems(n);
            expect(res6, isNotEmpty);
            expect(res6, contains(nStr));

            // nSelected
            final res7 = l10n.nSelected(n);
            expect(res7, isNotEmpty);
            expect(res7, contains(nStr));

            // nCategoriesSelected
            final res8 = l10n.nCategoriesSelected(n);
            expect(res8, isNotEmpty);
            expect(res8, contains(nStr));

            // nFolders
            final res9 = l10n.nFolders(n);
            expect(res9, isNotEmpty);
            expect(res9, contains(nStr));

            // syncFreqEveryNHours
            final res10 = l10n.syncFreqEveryNHours(n);
            expect(res10, isNotEmpty);
            expect(res10, contains(nStr));

            // syncFreqEveryNMin
            final res11 = l10n.syncFreqEveryNMin(n);
            expect(res11, isNotEmpty);
            expect(res11, contains(nStr));

            // restoreItemsBody
            final res12 = l10n.restoreItemsBody(n);
            expect(res12, isNotEmpty);
            expect(res12, contains(nStr));

            // permanentlyDeleteBody
            final res13 = l10n.permanentlyDeleteBody(n);
            expect(res13, isNotEmpty);
            expect(res13, contains(nStr));

            // trashRetentionInfo
            final res14 = l10n.trashRetentionInfo(n);
            expect(res14, isNotEmpty);
            expect(res14, contains(nStr));

            // conflictApplyToRemaining
            final res15 = l10n.conflictApplyToRemaining(n);
            expect(res15, isNotEmpty);
            expect(res15, contains(nStr));

            // storageStatsNItems
            final res16 = l10n.storageStatsNItems(n);
            expect(res16, isNotEmpty);
            expect(res16, contains(nStr));

            // userFallback
            final res17 = l10n.userFallback(n);
            expect(res17, isNotEmpty);
            expect(res17, contains(nStr));

            // createdNShareLinks
            final res18 = l10n.createdNShareLinks(n);
            expect(res18, isNotEmpty);
            expect(res18, contains(nStr));

            // sharedNItemsInServer
            final res19 = l10n.sharedNItemsInServer(n);
            expect(res19, isNotEmpty);
            expect(res19, contains(nStr));

            // movedNItems
            final res20 = l10n.movedNItems(n);
            expect(res20, isNotEmpty);
            expect(res20, contains(nStr));

            // failedToCreateFolderWithCode
            final res21 = l10n.failedToCreateFolderWithCode(n);
            expect(res21, isNotEmpty);
            expect(res21, contains(nStr));

            // uploadSummaryFailedCount
            final res22 = l10n.uploadSummaryFailedCount(n);
            expect(res22, isNotEmpty);
            expect(res22, contains(nStr));

            // uploadErrorFolderCreateHttp
            final res23 = l10n.uploadErrorFolderCreateHttp(n);
            expect(res23, isNotEmpty);
            expect(res23, contains(nStr));
          }
        });

        test('Multi-parameter methods format correctly across combinations', () {
          for (final s1 in ['fileA.png', 'folder_123', '🚀_doc.pdf']) {
            for (final s2 in [
              'fileB.png',
              'folder_456',
              'Network timeout (504)',
            ]) {
              // errorDeletingFile
              final r1 = l10n.errorDeletingFile(s1, s2);
              expect(r1, isNotEmpty);
              expect(r1, contains(s1));
              expect(r1, contains(s2));

              // failedToMoveItem
              final r2 = l10n.failedToMoveItem(s1, s2);
              expect(r2, isNotEmpty);
              expect(r2, contains(s1));
              expect(r2, contains(s2));

              // renamedOldToNew
              final r3 = l10n.renamedOldToNew(s1, s2);
              expect(r3, isNotEmpty);
              expect(r3, contains(s1));
              expect(r3, contains(s2));

              // renamedFileFromTo
              final r4 = l10n.renamedFileFromTo(s1, s2);
              expect(r4, isNotEmpty);
              expect(r4, contains(s1));
              expect(r4, contains(s2));

              // failedToRenameWithError
              final r5 = l10n.failedToRenameWithError(s1, s2);
              expect(r5, isNotEmpty);
              expect(r5, contains(s1));
              expect(r5, contains(s2));

              // failedToRenameFile
              final r6 = l10n.failedToRenameFile(s1, s2);
              expect(r6, isNotEmpty);
              expect(r6, contains(s1));
              expect(r6, contains(s2));
            }
          }

          // Mixed int + String methods
          for (final n in [1, 5, 20]) {
            for (final s in ['/storage/emulated/0', 'Disk write error']) {
              // downloadedNFilesToPath
              final r1 = l10n.downloadedNFilesToPath(n, s);
              expect(r1, isNotEmpty);
              expect(r1, contains(n.toString()));
              expect(r1, contains(s));

              // failedToRenameWithStatus
              final r2 = l10n.failedToRenameWithStatus(s, n);
              expect(r2, isNotEmpty);
              expect(r2, contains(s));
              expect(r2, contains(n.toString()));

              // failedToRenameFileWithCode
              final r3 = l10n.failedToRenameFileWithCode(s, n);
              expect(r3, isNotEmpty);
              expect(r3, contains(s));
              expect(r3, contains(n.toString()));
            }
          }

          // Multi-integer methods
          for (final n1 in [0, 3, 10]) {
            for (final n2 in [1, 5, 20]) {
              // syncResultSuccess
              final r1 = l10n.syncResultSuccess(n1, n2);
              expect(r1, isNotEmpty);
              expect(r1, contains(n1.toString()));
              expect(r1, contains(n2.toString()));

              // syncResultPartial
              final r2 = l10n.syncResultPartial(n1, n2);
              expect(r2, isNotEmpty);
              expect(r2, contains(n1.toString()));
              expect(r2, contains(n2.toString()));

              // conflictNofM
              final r3 = l10n.conflictNofM(n1, n2);
              expect(r3, isNotEmpty);
              expect(r3, contains(n1.toString()));
              expect(r3, contains(n2.toString()));

              // sharedNItemsWithFailures
              final r4 = l10n.sharedNItemsWithFailures(n1, n2);
              expect(r4, isNotEmpty);
              expect(r4, contains(n1.toString()));
              expect(r4, contains(n2.toString()));

              // sharedNItemsFailedM
              final r5 = l10n.sharedNItemsFailedM(n1, n2);
              expect(r5, isNotEmpty);
              expect(r5, contains(n1.toString()));
              expect(r5, contains(n2.toString()));

              // movedNItemsWithFailures
              final r6 = l10n.movedNItemsWithFailures(n1, n2);
              expect(r6, isNotEmpty);
              expect(r6, contains(n1.toString()));
              expect(r6, contains(n2.toString()));

              // movedNItemsFailedM
              final r7 = l10n.movedNItemsFailedM(n1, n2);
              expect(r7, isNotEmpty);
              expect(r7, contains(n1.toString()));
              expect(r7, contains(n2.toString()));

              // deletedNItemsFailedM
              final r8 = l10n.deletedNItemsFailedM(n1, n2);
              expect(r8, isNotEmpty);
              expect(r8, contains(n1.toString()));
              expect(r8, contains(n2.toString()));

              // uploadedNItemsWithFailures
              final r9 = l10n.uploadedNItemsWithFailures(n1, n2);
              expect(r9, isNotEmpty);
              expect(r9, contains(n1.toString()));
              expect(r9, contains(n2.toString()));

              // uploadedNItemsFailedM
              final r10 = l10n.uploadedNItemsFailedM(n1, n2);
              expect(r10, isNotEmpty);
              expect(r10, contains(n1.toString()));
              expect(r10, contains(n2.toString()));
            }
          }

          // Triple argument methods
          // downloadedNFilesFailedM(int downloaded, int failed, String detail)
          final d1 = l10n.downloadedNFilesFailedM(10, 2, 'Connection reset');
          expect(d1, isNotEmpty);
          expect(d1, contains('10'));
          expect(d1, contains('2'));
          expect(d1, contains('Connection reset'));

          // downloadedNFilesWithFailures(int count, int failed, String error)
          final d2 = l10n.downloadedNFilesWithFailures(8, 1, 'HTTP 404');
          expect(d2, isNotEmpty);
          expect(d2, contains('8'));
          expect(d2, contains('1'));
          expect(d2, contains('HTTP 404'));

          // syncStatusCalculatingChecksum(int current, int total, String filename)
          final s1 = l10n.syncStatusCalculatingChecksum(4, 10, 'video.mp4');
          expect(s1, isNotEmpty);
          expect(s1, contains('4'));
          expect(s1, contains('10'));
          expect(s1, contains('video.mp4'));

          // syncStatusSyncingFile(int current, int total, String filename)
          final s2 = l10n.syncStatusSyncingFile(5, 10, 'image.jpg');
          expect(s2, isNotEmpty);
          expect(s2, contains('5'));
          expect(s2, contains('10'));
          expect(s2, contains('image.jpg'));

          // transferSummaryFiles(int percent, int completed, int total)
          final t1 = l10n.transferSummaryFiles(75, 3, 4);
          expect(t1, isNotEmpty);
          expect(t1, contains('75%'));
          expect(t1, contains('3/4'));

          // transferSummaryProgress(int percent, int completed, int total)
          final t2 = l10n.transferSummaryProgress(100, 5, 5);
          expect(t2, isNotEmpty);
          expect(t2, contains('100%'));
          expect(t2, contains('5/5'));
        });

        test('No raw curly brace placeholder strings remain un-interpolated', () {
          // Check representative methods to ensure no "{var}" literals leak into outputs
          final testOutputs = <String>[
            l10n.errorWithMessage('err'),
            l10n.switchServerBody('srv'),
            l10n.updateAvailableTitle('1.0.0'),
            l10n.updateVersionSubtitle('1.0.0'),
            l10n.deleteNItemsTitle(5),
            l10n.deletePermanentlyBody('f.txt'),
            l10n.syncResultSuccess(2, 1),
            l10n.downloadedNFilesToPath(3, '/path'),
            l10n.renamedOldToNew('old', 'new'),
            l10n.transferSummaryFiles(50, 1, 2),
            l10n.userFallback(42),
            l10n.conflictNofM(1, 3),
            l10n.cannotMoveFolderIntoItself('sub'),
          ];

          final rawPlaceholderRegex = RegExp(r'\{[a-zA-Z0-9_]+\}');
          for (final out in testOutputs) {
            expect(
              rawPlaceholderRegex.hasMatch(out),
              isFalse,
              reason: 'Found un-interpolated placeholder in output: "$out"',
            );
          }
        });
      });
    }
  });

  group('Slavic Locales Widget Tree Integration Test', () {
    for (final entry in slavicLocales.entries) {
      final locale = entry.key;

      testWidgets(
        'Renders localized text inside widget tree for locale [${locale.languageCode}]',
        (tester) async {
          late AppLocalizations contextL10n;

          await tester.pumpWidget(
            wrapWithLocalization(
              Scaffold(
                body: Builder(
                  builder: (context) {
                    contextL10n = AppLocalizations.of(context)!;
                    return Column(
                      children: [
                        Text(contextL10n.appTitle),
                        Text(contextL10n.welcomeBack),
                        Text(contextL10n.navSettings),
                        Text(contextL10n.deleteNItemsTitle(3)),
                      ],
                    );
                  },
                ),
              ),
              locale: locale,
            ),
          );
          await tester.pumpAndSettle();

          expect(contextL10n.localeName, locale.languageCode);
          expect(find.text(contextL10n.appTitle), findsOneWidget);
          expect(find.text(contextL10n.welcomeBack), findsOneWidget);
          expect(find.text(contextL10n.navSettings), findsOneWidget);
          expect(find.text(contextL10n.deleteNItemsTitle(3)), findsOneWidget);
        },
      );
    }
  });
}
