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
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';

void main() {
  group('Exhaustive AppLocalizations Verification Harness', () {
    final enL10n = lookupAppLocalizations(const Locale('en'));
    final ruL10n = lookupAppLocalizations(const Locale('ru'));

    test('Supported locales list contains the priority languages', () {
      expect(
        AppLocalizations.supportedLocales,
        containsAll([const Locale('en'), const Locale('ru')]),
      );
      expect(
        AppLocalizations.supportedLocales.length,
        greaterThanOrEqualTo(12),
      );
    });

    test('Unsupported locale throws FlutterError on headless lookup', () {
      expect(
        () => lookupAppLocalizations(const Locale('xx')),
        throwsA(isA<FlutterError>()),
      );
      expect(
        () => lookupAppLocalizations(const Locale('yy')),
        throwsA(isA<FlutterError>()),
      );
    });

    testWidgets('Widget tree resolution works for English and Russian', (
      tester,
    ) async {
      late AppLocalizations enContextL10n;
      await tester.pumpWidget(
        wrapWithLocalization(
          Builder(
            builder: (context) {
              enContextL10n = AppLocalizations.of(context)!;
              return Text(enContextL10n.appTitle);
            },
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("Crowley's Cloud"), findsOneWidget);
      expect(enContextL10n.appTitle, "Crowley's Cloud");

      late AppLocalizations ruContextL10n;
      await tester.pumpWidget(
        wrapWithLocalization(
          Builder(
            builder: (context) {
              ruContextL10n = AppLocalizations.of(context)!;
              return Text(ruContextL10n.appTitle);
            },
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("Crowley's Cloud"), findsOneWidget);
      expect(ruContextL10n.welcomeBack, 'С возвращением');
    });

    test(
      'All 506 getters and methods return valid non-empty strings in EN and RU',
      () {
        // appTitle
        expect(enL10n.appTitle, isNotEmpty, reason: 'EN appTitle empty');
        expect(ruL10n.appTitle, isNotEmpty, reason: 'RU appTitle empty');
        // ok
        expect(enL10n.ok, isNotEmpty, reason: 'EN ok empty');
        expect(ruL10n.ok, isNotEmpty, reason: 'RU ok empty');
        // cancel
        expect(enL10n.cancel, isNotEmpty, reason: 'EN cancel empty');
        expect(ruL10n.cancel, isNotEmpty, reason: 'RU cancel empty');
        // save
        expect(enL10n.save, isNotEmpty, reason: 'EN save empty');
        expect(ruL10n.save, isNotEmpty, reason: 'RU save empty');
        // delete
        expect(enL10n.delete, isNotEmpty, reason: 'EN delete empty');
        expect(ruL10n.delete, isNotEmpty, reason: 'RU delete empty');
        // rename
        expect(enL10n.rename, isNotEmpty, reason: 'EN rename empty');
        expect(ruL10n.rename, isNotEmpty, reason: 'RU rename empty');
        // close
        expect(enL10n.close, isNotEmpty, reason: 'EN close empty');
        expect(ruL10n.close, isNotEmpty, reason: 'RU close empty');
        // retry
        expect(enL10n.retry, isNotEmpty, reason: 'EN retry empty');
        expect(ruL10n.retry, isNotEmpty, reason: 'RU retry empty');
        // loading
        expect(enL10n.loading, isNotEmpty, reason: 'EN loading empty');
        expect(ruL10n.loading, isNotEmpty, reason: 'RU loading empty');
        // confirm
        expect(enL10n.confirm, isNotEmpty, reason: 'EN confirm empty');
        expect(ruL10n.confirm, isNotEmpty, reason: 'RU confirm empty');
        // error
        expect(enL10n.error, isNotEmpty, reason: 'EN error empty');
        expect(ruL10n.error, isNotEmpty, reason: 'RU error empty');
        // errorWithMessage(String message)
        expect(
          enL10n.errorWithMessage('SampleText'),
          isNotEmpty,
          reason: 'EN errorWithMessage empty',
        );
        expect(
          ruL10n.errorWithMessage('SampleText'),
          isNotEmpty,
          reason: 'RU errorWithMessage empty',
        );
        // unknown
        expect(enL10n.unknown, isNotEmpty, reason: 'EN unknown empty');
        expect(ruL10n.unknown, isNotEmpty, reason: 'RU unknown empty');
        // upload
        expect(enL10n.upload, isNotEmpty, reason: 'EN upload empty');
        expect(ruL10n.upload, isNotEmpty, reason: 'RU upload empty');
        // download
        expect(enL10n.download, isNotEmpty, reason: 'EN download empty');
        expect(ruL10n.download, isNotEmpty, reason: 'RU download empty');
        // share
        expect(enL10n.share, isNotEmpty, reason: 'EN share empty');
        expect(ruL10n.share, isNotEmpty, reason: 'RU share empty');
        // copy
        expect(enL10n.copy, isNotEmpty, reason: 'EN copy empty');
        expect(ruL10n.copy, isNotEmpty, reason: 'RU copy empty');
        // move
        expect(enL10n.move, isNotEmpty, reason: 'EN move empty');
        expect(ruL10n.move, isNotEmpty, reason: 'RU move empty');
        // restore
        expect(enL10n.restore, isNotEmpty, reason: 'EN restore empty');
        expect(ruL10n.restore, isNotEmpty, reason: 'RU restore empty');
        // apply
        expect(enL10n.apply, isNotEmpty, reason: 'EN apply empty');
        expect(ruL10n.apply, isNotEmpty, reason: 'RU apply empty');
        // create
        expect(enL10n.create, isNotEmpty, reason: 'EN create empty');
        expect(ruL10n.create, isNotEmpty, reason: 'RU create empty');
        // clear
        expect(enL10n.clear, isNotEmpty, reason: 'EN clear empty');
        expect(ruL10n.clear, isNotEmpty, reason: 'RU clear empty');
        // add
        expect(enL10n.add, isNotEmpty, reason: 'EN add empty');
        expect(ruL10n.add, isNotEmpty, reason: 'RU add empty');
        // remove
        expect(enL10n.remove, isNotEmpty, reason: 'EN remove empty');
        expect(ruL10n.remove, isNotEmpty, reason: 'RU remove empty');
        // edit
        expect(enL10n.edit, isNotEmpty, reason: 'EN edit empty');
        expect(ruL10n.edit, isNotEmpty, reason: 'RU edit empty');
        // switchLabel
        expect(enL10n.switchLabel, isNotEmpty, reason: 'EN switchLabel empty');
        expect(ruL10n.switchLabel, isNotEmpty, reason: 'RU switchLabel empty');
        // search
        expect(enL10n.search, isNotEmpty, reason: 'EN search empty');
        expect(ruL10n.search, isNotEmpty, reason: 'RU search empty');
        // name
        expect(enL10n.name, isNotEmpty, reason: 'EN name empty');
        expect(ruL10n.name, isNotEmpty, reason: 'RU name empty');
        // date
        expect(enL10n.date, isNotEmpty, reason: 'EN date empty');
        expect(ruL10n.date, isNotEmpty, reason: 'RU date empty');
        // size
        expect(enL10n.size, isNotEmpty, reason: 'EN size empty');
        expect(ruL10n.size, isNotEmpty, reason: 'RU size empty');
        // type
        expect(enL10n.type, isNotEmpty, reason: 'EN type empty');
        expect(ruL10n.type, isNotEmpty, reason: 'RU type empty');
        // ascending
        expect(enL10n.ascending, isNotEmpty, reason: 'EN ascending empty');
        expect(ruL10n.ascending, isNotEmpty, reason: 'RU ascending empty');
        // descending
        expect(enL10n.descending, isNotEmpty, reason: 'EN descending empty');
        expect(ruL10n.descending, isNotEmpty, reason: 'RU descending empty');
        // allFiles
        expect(enL10n.allFiles, isNotEmpty, reason: 'EN allFiles empty');
        expect(ruL10n.allFiles, isNotEmpty, reason: 'RU allFiles empty');
        // categoryImages
        expect(
          enL10n.categoryImages,
          isNotEmpty,
          reason: 'EN categoryImages empty',
        );
        expect(
          ruL10n.categoryImages,
          isNotEmpty,
          reason: 'RU categoryImages empty',
        );
        // categoryPhotos
        expect(
          enL10n.categoryPhotos,
          isNotEmpty,
          reason: 'EN categoryPhotos empty',
        );
        expect(
          ruL10n.categoryPhotos,
          isNotEmpty,
          reason: 'RU categoryPhotos empty',
        );
        // categoryVideos
        expect(
          enL10n.categoryVideos,
          isNotEmpty,
          reason: 'EN categoryVideos empty',
        );
        expect(
          ruL10n.categoryVideos,
          isNotEmpty,
          reason: 'RU categoryVideos empty',
        );
        // categoryAudio
        expect(
          enL10n.categoryAudio,
          isNotEmpty,
          reason: 'EN categoryAudio empty',
        );
        expect(
          ruL10n.categoryAudio,
          isNotEmpty,
          reason: 'RU categoryAudio empty',
        );
        // categoryDocuments
        expect(
          enL10n.categoryDocuments,
          isNotEmpty,
          reason: 'EN categoryDocuments empty',
        );
        expect(
          ruL10n.categoryDocuments,
          isNotEmpty,
          reason: 'RU categoryDocuments empty',
        );
        // categoryArchives
        expect(
          enL10n.categoryArchives,
          isNotEmpty,
          reason: 'EN categoryArchives empty',
        );
        expect(
          ruL10n.categoryArchives,
          isNotEmpty,
          reason: 'RU categoryArchives empty',
        );
        // categoryShared
        expect(
          enL10n.categoryShared,
          isNotEmpty,
          reason: 'EN categoryShared empty',
        );
        expect(
          ruL10n.categoryShared,
          isNotEmpty,
          reason: 'RU categoryShared empty',
        );
        // categoryOther
        expect(
          enL10n.categoryOther,
          isNotEmpty,
          reason: 'EN categoryOther empty',
        );
        expect(
          ruL10n.categoryOther,
          isNotEmpty,
          reason: 'RU categoryOther empty',
        );
        // categoryOtherFiles
        expect(
          enL10n.categoryOtherFiles,
          isNotEmpty,
          reason: 'EN categoryOtherFiles empty',
        );
        expect(
          ruL10n.categoryOtherFiles,
          isNotEmpty,
          reason: 'RU categoryOtherFiles empty',
        );
        // noFilesFound
        expect(
          enL10n.noFilesFound,
          isNotEmpty,
          reason: 'EN noFilesFound empty',
        );
        expect(
          ruL10n.noFilesFound,
          isNotEmpty,
          reason: 'RU noFilesFound empty',
        );
        // noFilesInFolder
        expect(
          enL10n.noFilesInFolder,
          isNotEmpty,
          reason: 'EN noFilesInFolder empty',
        );
        expect(
          ruL10n.noFilesInFolder,
          isNotEmpty,
          reason: 'RU noFilesInFolder empty',
        );
        // thisActionCannotBeUndone
        expect(
          enL10n.thisActionCannotBeUndone,
          isNotEmpty,
          reason: 'EN thisActionCannotBeUndone empty',
        );
        expect(
          ruL10n.thisActionCannotBeUndone,
          isNotEmpty,
          reason: 'RU thisActionCannotBeUndone empty',
        );
        // passwordsDoNotMatch
        expect(
          enL10n.passwordsDoNotMatch,
          isNotEmpty,
          reason: 'EN passwordsDoNotMatch empty',
        );
        expect(
          ruL10n.passwordsDoNotMatch,
          isNotEmpty,
          reason: 'RU passwordsDoNotMatch empty',
        );
        // navLocalFiles
        expect(
          enL10n.navLocalFiles,
          isNotEmpty,
          reason: 'EN navLocalFiles empty',
        );
        expect(
          ruL10n.navLocalFiles,
          isNotEmpty,
          reason: 'RU navLocalFiles empty',
        );
        // navServerFiles
        expect(
          enL10n.navServerFiles,
          isNotEmpty,
          reason: 'EN navServerFiles empty',
        );
        expect(
          ruL10n.navServerFiles,
          isNotEmpty,
          reason: 'RU navServerFiles empty',
        );
        // navSettings
        expect(enL10n.navSettings, isNotEmpty, reason: 'EN navSettings empty');
        expect(ruL10n.navSettings, isNotEmpty, reason: 'RU navSettings empty');
        // navTrash
        expect(enL10n.navTrash, isNotEmpty, reason: 'EN navTrash empty');
        expect(ruL10n.navTrash, isNotEmpty, reason: 'RU navTrash empty');
        // navLocal
        expect(enL10n.navLocal, isNotEmpty, reason: 'EN navLocal empty');
        expect(ruL10n.navLocal, isNotEmpty, reason: 'RU navLocal empty');
        // navServer
        expect(enL10n.navServer, isNotEmpty, reason: 'EN navServer empty');
        expect(ruL10n.navServer, isNotEmpty, reason: 'RU navServer empty');
        // addServer
        expect(enL10n.addServer, isNotEmpty, reason: 'EN addServer empty');
        expect(ruL10n.addServer, isNotEmpty, reason: 'RU addServer empty');
        // noServersConfigured
        expect(
          enL10n.noServersConfigured,
          isNotEmpty,
          reason: 'EN noServersConfigured empty',
        );
        expect(
          ruL10n.noServersConfigured,
          isNotEmpty,
          reason: 'RU noServersConfigured empty',
        );
        // addAServerInSettings
        expect(
          enL10n.addAServerInSettings,
          isNotEmpty,
          reason: 'EN addAServerInSettings empty',
        );
        expect(
          ruL10n.addAServerInSettings,
          isNotEmpty,
          reason: 'RU addAServerInSettings empty',
        );
        // addFirstServerHint
        expect(
          enL10n.addFirstServerHint,
          isNotEmpty,
          reason: 'EN addFirstServerHint empty',
        );
        expect(
          ruL10n.addFirstServerHint,
          isNotEmpty,
          reason: 'RU addFirstServerHint empty',
        );
        // noServersConfiguredYet
        expect(
          enL10n.noServersConfiguredYet,
          isNotEmpty,
          reason: 'EN noServersConfiguredYet empty',
        );
        expect(
          ruL10n.noServersConfiguredYet,
          isNotEmpty,
          reason: 'RU noServersConfiguredYet empty',
        );
        // crowleysCloudSetup
        expect(
          enL10n.crowleysCloudSetup,
          isNotEmpty,
          reason: 'EN crowleysCloudSetup empty',
        );
        expect(
          ruL10n.crowleysCloudSetup,
          isNotEmpty,
          reason: 'RU crowleysCloudSetup empty',
        );
        // connect
        expect(enL10n.connect, isNotEmpty, reason: 'EN connect empty');
        expect(ruL10n.connect, isNotEmpty, reason: 'RU connect empty');
        // connecting
        expect(enL10n.connecting, isNotEmpty, reason: 'EN connecting empty');
        expect(ruL10n.connecting, isNotEmpty, reason: 'RU connecting empty');
        // connected
        expect(enL10n.connected, isNotEmpty, reason: 'EN connected empty');
        expect(ruL10n.connected, isNotEmpty, reason: 'RU connected empty');
        // disconnected
        expect(
          enL10n.disconnected,
          isNotEmpty,
          reason: 'EN disconnected empty',
        );
        expect(
          ruL10n.disconnected,
          isNotEmpty,
          reason: 'RU disconnected empty',
        );
        // switchServer
        expect(
          enL10n.switchServer,
          isNotEmpty,
          reason: 'EN switchServer empty',
        );
        expect(
          ruL10n.switchServer,
          isNotEmpty,
          reason: 'RU switchServer empty',
        );
        // chooseOtherServer
        expect(
          enL10n.chooseOtherServer,
          isNotEmpty,
          reason: 'EN chooseOtherServer empty',
        );
        expect(
          ruL10n.chooseOtherServer,
          isNotEmpty,
          reason: 'RU chooseOtherServer empty',
        );
        // switchServerTitle
        expect(
          enL10n.switchServerTitle,
          isNotEmpty,
          reason: 'EN switchServerTitle empty',
        );
        expect(
          ruL10n.switchServerTitle,
          isNotEmpty,
          reason: 'RU switchServerTitle empty',
        );
        // switchServerBody(String serverName)
        expect(
          enL10n.switchServerBody('document.pdf'),
          isNotEmpty,
          reason: 'EN switchServerBody empty',
        );
        expect(
          ruL10n.switchServerBody('document.pdf'),
          isNotEmpty,
          reason: 'RU switchServerBody empty',
        );
        // chooseServer
        expect(
          enL10n.chooseServer,
          isNotEmpty,
          reason: 'EN chooseServer empty',
        );
        expect(
          ruL10n.chooseServer,
          isNotEmpty,
          reason: 'RU chooseServer empty',
        );
        // authenticationRequired
        expect(
          enL10n.authenticationRequired,
          isNotEmpty,
          reason: 'EN authenticationRequired empty',
        );
        expect(
          ruL10n.authenticationRequired,
          isNotEmpty,
          reason: 'RU authenticationRequired empty',
        );
        // signInToAccess(String serverName)
        expect(
          enL10n.signInToAccess('document.pdf'),
          isNotEmpty,
          reason: 'EN signInToAccess empty',
        );
        expect(
          ruL10n.signInToAccess('document.pdf'),
          isNotEmpty,
          reason: 'RU signInToAccess empty',
        );
        // signInWithPassword
        expect(
          enL10n.signInWithPassword,
          isNotEmpty,
          reason: 'EN signInWithPassword empty',
        );
        expect(
          ruL10n.signInWithPassword,
          isNotEmpty,
          reason: 'RU signInWithPassword empty',
        );
        // useBiometrics
        expect(
          enL10n.useBiometrics,
          isNotEmpty,
          reason: 'EN useBiometrics empty',
        );
        expect(
          ruL10n.useBiometrics,
          isNotEmpty,
          reason: 'RU useBiometrics empty',
        );
        // openingSignIn
        expect(
          enL10n.openingSignIn,
          isNotEmpty,
          reason: 'EN openingSignIn empty',
        );
        expect(
          ruL10n.openingSignIn,
          isNotEmpty,
          reason: 'RU openingSignIn empty',
        );
        // serverConnectionFailed
        expect(
          enL10n.serverConnectionFailed,
          isNotEmpty,
          reason: 'EN serverConnectionFailed empty',
        );
        expect(
          ruL10n.serverConnectionFailed,
          isNotEmpty,
          reason: 'RU serverConnectionFailed empty',
        );
        // unableToConnectToServer
        expect(
          enL10n.unableToConnectToServer,
          isNotEmpty,
          reason: 'EN unableToConnectToServer empty',
        );
        expect(
          ruL10n.unableToConnectToServer,
          isNotEmpty,
          reason: 'RU unableToConnectToServer empty',
        );
        // unableToConnectTo(String serverName)
        expect(
          enL10n.unableToConnectTo('document.pdf'),
          isNotEmpty,
          reason: 'EN unableToConnectTo empty',
        );
        expect(
          ruL10n.unableToConnectTo('document.pdf'),
          isNotEmpty,
          reason: 'RU unableToConnectTo empty',
        );
        // searchHint
        expect(enL10n.searchHint, isNotEmpty, reason: 'EN searchHint empty');
        expect(ruL10n.searchHint, isNotEmpty, reason: 'RU searchHint empty');
        // searchFilesHint
        expect(
          enL10n.searchFilesHint,
          isNotEmpty,
          reason: 'EN searchFilesHint empty',
        );
        expect(
          ruL10n.searchFilesHint,
          isNotEmpty,
          reason: 'RU searchFilesHint empty',
        );
        // searchServerFilesHint
        expect(
          enL10n.searchServerFilesHint,
          isNotEmpty,
          reason: 'EN searchServerFilesHint empty',
        );
        expect(
          ruL10n.searchServerFilesHint,
          isNotEmpty,
          reason: 'RU searchServerFilesHint empty',
        );
        // searchTrashHint
        expect(
          enL10n.searchTrashHint,
          isNotEmpty,
          reason: 'EN searchTrashHint empty',
        );
        expect(
          ruL10n.searchTrashHint,
          isNotEmpty,
          reason: 'RU searchTrashHint empty',
        );
        // storagePermissionRequired
        expect(
          enL10n.storagePermissionRequired,
          isNotEmpty,
          reason: 'EN storagePermissionRequired empty',
        );
        expect(
          ruL10n.storagePermissionRequired,
          isNotEmpty,
          reason: 'RU storagePermissionRequired empty',
        );
        // grantPermission
        expect(
          enL10n.grantPermission,
          isNotEmpty,
          reason: 'EN grantPermission empty',
        );
        expect(
          ruL10n.grantPermission,
          isNotEmpty,
          reason: 'RU grantPermission empty',
        );
        // permissionDeniedOpenSettings
        expect(
          enL10n.permissionDeniedOpenSettings,
          isNotEmpty,
          reason: 'EN permissionDeniedOpenSettings empty',
        );
        expect(
          ruL10n.permissionDeniedOpenSettings,
          isNotEmpty,
          reason: 'RU permissionDeniedOpenSettings empty',
        );
        // manageStoragePermissionRequired
        expect(
          enL10n.manageStoragePermissionRequired,
          isNotEmpty,
          reason: 'EN manageStoragePermissionRequired empty',
        );
        expect(
          ruL10n.manageStoragePermissionRequired,
          isNotEmpty,
          reason: 'RU manageStoragePermissionRequired empty',
        );
        // storagePermissionsRequired
        expect(
          enL10n.storagePermissionsRequired,
          isNotEmpty,
          reason: 'EN storagePermissionsRequired empty',
        );
        expect(
          ruL10n.storagePermissionsRequired,
          isNotEmpty,
          reason: 'RU storagePermissionsRequired empty',
        );
        // updateAvailableTitle(String version)
        expect(
          enL10n.updateAvailableTitle('1.2.3'),
          isNotEmpty,
          reason: 'EN updateAvailableTitle empty',
        );
        expect(
          ruL10n.updateAvailableTitle('1.2.3'),
          isNotEmpty,
          reason: 'RU updateAvailableTitle empty',
        );
        // updateAvailableTapToSeeNew
        expect(
          enL10n.updateAvailableTapToSeeNew,
          isNotEmpty,
          reason: 'EN updateAvailableTapToSeeNew empty',
        );
        expect(
          ruL10n.updateAvailableTapToSeeNew,
          isNotEmpty,
          reason: 'RU updateAvailableTapToSeeNew empty',
        );
        // updateView
        expect(enL10n.updateView, isNotEmpty, reason: 'EN updateView empty');
        expect(ruL10n.updateView, isNotEmpty, reason: 'RU updateView empty');
        // updateAvailableDialogTitle
        expect(
          enL10n.updateAvailableDialogTitle,
          isNotEmpty,
          reason: 'EN updateAvailableDialogTitle empty',
        );
        expect(
          ruL10n.updateAvailableDialogTitle,
          isNotEmpty,
          reason: 'RU updateAvailableDialogTitle empty',
        );
        // updateVersionSubtitle(String version)
        expect(
          enL10n.updateVersionSubtitle('1.2.3'),
          isNotEmpty,
          reason: 'EN updateVersionSubtitle empty',
        );
        expect(
          ruL10n.updateVersionSubtitle('1.2.3'),
          isNotEmpty,
          reason: 'RU updateVersionSubtitle empty',
        );
        // updateCurrentVersion(String version)
        expect(
          enL10n.updateCurrentVersion('1.2.3'),
          isNotEmpty,
          reason: 'EN updateCurrentVersion empty',
        );
        expect(
          ruL10n.updateCurrentVersion('1.2.3'),
          isNotEmpty,
          reason: 'RU updateCurrentVersion empty',
        );
        // updateNewVersion(String version)
        expect(
          enL10n.updateNewVersion('1.2.3'),
          isNotEmpty,
          reason: 'EN updateNewVersion empty',
        );
        expect(
          ruL10n.updateNewVersion('1.2.3'),
          isNotEmpty,
          reason: 'RU updateNewVersion empty',
        );
        // updateWhatsNew
        expect(
          enL10n.updateWhatsNew,
          isNotEmpty,
          reason: 'EN updateWhatsNew empty',
        );
        expect(
          ruL10n.updateWhatsNew,
          isNotEmpty,
          reason: 'RU updateWhatsNew empty',
        );
        // updateGitHub
        expect(
          enL10n.updateGitHub,
          isNotEmpty,
          reason: 'EN updateGitHub empty',
        );
        expect(
          ruL10n.updateGitHub,
          isNotEmpty,
          reason: 'RU updateGitHub empty',
        );
        // updateNoReleaseNotes
        expect(
          enL10n.updateNoReleaseNotes,
          isNotEmpty,
          reason: 'EN updateNoReleaseNotes empty',
        );
        expect(
          ruL10n.updateNoReleaseNotes,
          isNotEmpty,
          reason: 'RU updateNoReleaseNotes empty',
        );
        // updateLater
        expect(enL10n.updateLater, isNotEmpty, reason: 'EN updateLater empty');
        expect(ruL10n.updateLater, isNotEmpty, reason: 'RU updateLater empty');
        // updateDownloadApk
        expect(
          enL10n.updateDownloadApk,
          isNotEmpty,
          reason: 'EN updateDownloadApk empty',
        );
        expect(
          ruL10n.updateDownloadApk,
          isNotEmpty,
          reason: 'RU updateDownloadApk empty',
        );
        // updateInstall
        expect(
          enL10n.updateInstall,
          isNotEmpty,
          reason: 'EN updateInstall empty',
        );
        expect(
          ruL10n.updateInstall,
          isNotEmpty,
          reason: 'RU updateInstall empty',
        );
        // shareLinkTitle
        expect(
          enL10n.shareLinkTitle,
          isNotEmpty,
          reason: 'EN shareLinkTitle empty',
        );
        expect(
          ruL10n.shareLinkTitle,
          isNotEmpty,
          reason: 'RU shareLinkTitle empty',
        );
        // shareViaLink
        expect(
          enL10n.shareViaLink,
          isNotEmpty,
          reason: 'EN shareViaLink empty',
        );
        expect(
          ruL10n.shareViaLink,
          isNotEmpty,
          reason: 'RU shareViaLink empty',
        );
        // shareInServer
        expect(
          enL10n.shareInServer,
          isNotEmpty,
          reason: 'EN shareInServer empty',
        );
        expect(
          ruL10n.shareInServer,
          isNotEmpty,
          reason: 'RU shareInServer empty',
        );
        // expiryDays
        expect(enL10n.expiryDays, isNotEmpty, reason: 'EN expiryDays empty');
        expect(ruL10n.expiryDays, isNotEmpty, reason: 'RU expiryDays empty');
        // expiryNever
        expect(enL10n.expiryNever, isNotEmpty, reason: 'EN expiryNever empty');
        expect(ruL10n.expiryNever, isNotEmpty, reason: 'RU expiryNever empty');
        // expiry1Day
        expect(enL10n.expiry1Day, isNotEmpty, reason: 'EN expiry1Day empty');
        expect(ruL10n.expiry1Day, isNotEmpty, reason: 'RU expiry1Day empty');
        // expiry7Days
        expect(enL10n.expiry7Days, isNotEmpty, reason: 'EN expiry7Days empty');
        expect(ruL10n.expiry7Days, isNotEmpty, reason: 'RU expiry7Days empty');
        // expiry30Days
        expect(
          enL10n.expiry30Days,
          isNotEmpty,
          reason: 'EN expiry30Days empty',
        );
        expect(
          ruL10n.expiry30Days,
          isNotEmpty,
          reason: 'RU expiry30Days empty',
        );
        // expiry90Days
        expect(
          enL10n.expiry90Days,
          isNotEmpty,
          reason: 'EN expiry90Days empty',
        );
        expect(
          ruL10n.expiry90Days,
          isNotEmpty,
          reason: 'RU expiry90Days empty',
        );
        // expiry180Days
        expect(
          enL10n.expiry180Days,
          isNotEmpty,
          reason: 'EN expiry180Days empty',
        );
        expect(
          ruL10n.expiry180Days,
          isNotEmpty,
          reason: 'RU expiry180Days empty',
        );
        // expiry365Days
        expect(
          enL10n.expiry365Days,
          isNotEmpty,
          reason: 'EN expiry365Days empty',
        );
        expect(
          ruL10n.expiry365Days,
          isNotEmpty,
          reason: 'RU expiry365Days empty',
        );
        // createLink
        expect(enL10n.createLink, isNotEmpty, reason: 'EN createLink empty');
        expect(ruL10n.createLink, isNotEmpty, reason: 'RU createLink empty');
        // sharedLinkCopied
        expect(
          enL10n.sharedLinkCopied,
          isNotEmpty,
          reason: 'EN sharedLinkCopied empty',
        );
        expect(
          ruL10n.sharedLinkCopied,
          isNotEmpty,
          reason: 'RU sharedLinkCopied empty',
        );
        // failedToCopySharedLink(String error)
        expect(
          enL10n.failedToCopySharedLink('Network timeout'),
          isNotEmpty,
          reason: 'EN failedToCopySharedLink empty',
        );
        expect(
          ruL10n.failedToCopySharedLink('Network timeout'),
          isNotEmpty,
          reason: 'RU failedToCopySharedLink empty',
        );
        // cannotShareThisFileType
        expect(
          enL10n.cannotShareThisFileType,
          isNotEmpty,
          reason: 'EN cannotShareThisFileType empty',
        );
        expect(
          ruL10n.cannotShareThisFileType,
          isNotEmpty,
          reason: 'RU cannotShareThisFileType empty',
        );
        // failedToCreateShare(String error)
        expect(
          enL10n.failedToCreateShare('Network timeout'),
          isNotEmpty,
          reason: 'EN failedToCreateShare empty',
        );
        expect(
          ruL10n.failedToCreateShare('Network timeout'),
          isNotEmpty,
          reason: 'RU failedToCreateShare empty',
        );
        // newFolderTitle
        expect(
          enL10n.newFolderTitle,
          isNotEmpty,
          reason: 'EN newFolderTitle empty',
        );
        expect(
          ruL10n.newFolderTitle,
          isNotEmpty,
          reason: 'RU newFolderTitle empty',
        );
        // newFolderHint
        expect(
          enL10n.newFolderHint,
          isNotEmpty,
          reason: 'EN newFolderHint empty',
        );
        expect(
          ruL10n.newFolderHint,
          isNotEmpty,
          reason: 'RU newFolderHint empty',
        );
        // newFolder
        expect(enL10n.newFolder, isNotEmpty, reason: 'EN newFolder empty');
        expect(ruL10n.newFolder, isNotEmpty, reason: 'RU newFolder empty');
        // folderCreated
        expect(
          enL10n.folderCreated,
          isNotEmpty,
          reason: 'EN folderCreated empty',
        );
        expect(
          ruL10n.folderCreated,
          isNotEmpty,
          reason: 'RU folderCreated empty',
        );
        // failedToCreateFolder(String error)
        expect(
          enL10n.failedToCreateFolder('Network timeout'),
          isNotEmpty,
          reason: 'EN failedToCreateFolder empty',
        );
        expect(
          ruL10n.failedToCreateFolder('Network timeout'),
          isNotEmpty,
          reason: 'RU failedToCreateFolder empty',
        );
        // creatingFolder
        expect(
          enL10n.creatingFolder,
          isNotEmpty,
          reason: 'EN creatingFolder empty',
        );
        expect(
          ruL10n.creatingFolder,
          isNotEmpty,
          reason: 'RU creatingFolder empty',
        );
        // renameDialogTitle
        expect(
          enL10n.renameDialogTitle,
          isNotEmpty,
          reason: 'EN renameDialogTitle empty',
        );
        expect(
          ruL10n.renameDialogTitle,
          isNotEmpty,
          reason: 'RU renameDialogTitle empty',
        );
        // renameHint
        expect(enL10n.renameHint, isNotEmpty, reason: 'EN renameHint empty');
        expect(ruL10n.renameHint, isNotEmpty, reason: 'RU renameHint empty');
        // enterNewName
        expect(
          enL10n.enterNewName,
          isNotEmpty,
          reason: 'EN enterNewName empty',
        );
        expect(
          ruL10n.enterNewName,
          isNotEmpty,
          reason: 'RU enterNewName empty',
        );
        // renamedSuccessfully
        expect(
          enL10n.renamedSuccessfully,
          isNotEmpty,
          reason: 'EN renamedSuccessfully empty',
        );
        expect(
          ruL10n.renamedSuccessfully,
          isNotEmpty,
          reason: 'RU renamedSuccessfully empty',
        );
        // renameFailed(String error)
        expect(
          enL10n.renameFailed('Network timeout'),
          isNotEmpty,
          reason: 'EN renameFailed empty',
        );
        expect(
          ruL10n.renameFailed('Network timeout'),
          isNotEmpty,
          reason: 'RU renameFailed empty',
        );
        // moveDialogTitle
        expect(
          enL10n.moveDialogTitle,
          isNotEmpty,
          reason: 'EN moveDialogTitle empty',
        );
        expect(
          ruL10n.moveDialogTitle,
          isNotEmpty,
          reason: 'RU moveDialogTitle empty',
        );
        // moveTo(String path)
        expect(
          enL10n.moveTo('/storage/emulated/0/Download'),
          isNotEmpty,
          reason: 'EN moveTo empty',
        );
        expect(
          ruL10n.moveTo('/storage/emulated/0/Download'),
          isNotEmpty,
          reason: 'RU moveTo empty',
        );
        // moveHere
        expect(enL10n.moveHere, isNotEmpty, reason: 'EN moveHere empty');
        expect(ruL10n.moveHere, isNotEmpty, reason: 'RU moveHere empty');
        // moveFailed(String error)
        expect(
          enL10n.moveFailed('Network timeout'),
          isNotEmpty,
          reason: 'EN moveFailed empty',
        );
        expect(
          ruL10n.moveFailed('Network timeout'),
          isNotEmpty,
          reason: 'RU moveFailed empty',
        );
        // movedToFolder
        expect(
          enL10n.movedToFolder,
          isNotEmpty,
          reason: 'EN movedToFolder empty',
        );
        expect(
          ruL10n.movedToFolder,
          isNotEmpty,
          reason: 'RU movedToFolder empty',
        );
        // copyFailed(String error)
        expect(
          enL10n.copyFailed('Network timeout'),
          isNotEmpty,
          reason: 'EN copyFailed empty',
        );
        expect(
          ruL10n.copyFailed('Network timeout'),
          isNotEmpty,
          reason: 'RU copyFailed empty',
        );
        // selectFolder
        expect(
          enL10n.selectFolder,
          isNotEmpty,
          reason: 'EN selectFolder empty',
        );
        expect(
          ruL10n.selectFolder,
          isNotEmpty,
          reason: 'RU selectFolder empty',
        );
        // useThisFolder
        expect(
          enL10n.useThisFolder,
          isNotEmpty,
          reason: 'EN useThisFolder empty',
        );
        expect(
          ruL10n.useThisFolder,
          isNotEmpty,
          reason: 'RU useThisFolder empty',
        );
        // storageRoot
        expect(enL10n.storageRoot, isNotEmpty, reason: 'EN storageRoot empty');
        expect(ruL10n.storageRoot, isNotEmpty, reason: 'RU storageRoot empty');
        // serverRoot
        expect(enL10n.serverRoot, isNotEmpty, reason: 'EN serverRoot empty');
        expect(ruL10n.serverRoot, isNotEmpty, reason: 'RU serverRoot empty');
        // deleteNItemsTitle(int count)
        expect(
          enL10n.deleteNItemsTitle(5),
          isNotEmpty,
          reason: 'EN deleteNItemsTitle empty',
        );
        expect(
          ruL10n.deleteNItemsTitle(5),
          isNotEmpty,
          reason: 'RU deleteNItemsTitle empty',
        );
        // deleteFilesTitle
        expect(
          enL10n.deleteFilesTitle,
          isNotEmpty,
          reason: 'EN deleteFilesTitle empty',
        );
        expect(
          ruL10n.deleteFilesTitle,
          isNotEmpty,
          reason: 'RU deleteFilesTitle empty',
        );
        // deleteFilesBody(int count)
        expect(
          enL10n.deleteFilesBody(5),
          isNotEmpty,
          reason: 'EN deleteFilesBody empty',
        );
        expect(
          ruL10n.deleteFilesBody(5),
          isNotEmpty,
          reason: 'RU deleteFilesBody empty',
        );
        // deletePermanently
        expect(
          enL10n.deletePermanently,
          isNotEmpty,
          reason: 'EN deletePermanently empty',
        );
        expect(
          ruL10n.deletePermanently,
          isNotEmpty,
          reason: 'RU deletePermanently empty',
        );
        // deletePermanentlyTitle
        expect(
          enL10n.deletePermanentlyTitle,
          isNotEmpty,
          reason: 'EN deletePermanentlyTitle empty',
        );
        expect(
          ruL10n.deletePermanentlyTitle,
          isNotEmpty,
          reason: 'RU deletePermanentlyTitle empty',
        );
        // deletePermanentlyBody(String filename)
        expect(
          enL10n.deletePermanentlyBody('document.pdf'),
          isNotEmpty,
          reason: 'EN deletePermanentlyBody empty',
        );
        expect(
          ruL10n.deletePermanentlyBody('document.pdf'),
          isNotEmpty,
          reason: 'RU deletePermanentlyBody empty',
        );
        // deleteFileTitle
        expect(
          enL10n.deleteFileTitle,
          isNotEmpty,
          reason: 'EN deleteFileTitle empty',
        );
        expect(
          ruL10n.deleteFileTitle,
          isNotEmpty,
          reason: 'RU deleteFileTitle empty',
        );
        // deleteFileBody(String filename)
        expect(
          enL10n.deleteFileBody('document.pdf'),
          isNotEmpty,
          reason: 'EN deleteFileBody empty',
        );
        expect(
          ruL10n.deleteFileBody('document.pdf'),
          isNotEmpty,
          reason: 'RU deleteFileBody empty',
        );
        // deleteServerFileTitle
        expect(
          enL10n.deleteServerFileTitle,
          isNotEmpty,
          reason: 'EN deleteServerFileTitle empty',
        );
        expect(
          ruL10n.deleteServerFileTitle,
          isNotEmpty,
          reason: 'RU deleteServerFileTitle empty',
        );
        // deleteServerFileBody(String filename)
        expect(
          enL10n.deleteServerFileBody('document.pdf'),
          isNotEmpty,
          reason: 'EN deleteServerFileBody empty',
        );
        expect(
          ruL10n.deleteServerFileBody('document.pdf'),
          isNotEmpty,
          reason: 'RU deleteServerFileBody empty',
        );
        // unshareItemsTitle
        expect(
          enL10n.unshareItemsTitle,
          isNotEmpty,
          reason: 'EN unshareItemsTitle empty',
        );
        expect(
          ruL10n.unshareItemsTitle,
          isNotEmpty,
          reason: 'RU unshareItemsTitle empty',
        );
        // unshareItemsBody(int count)
        expect(
          enL10n.unshareItemsBody(5),
          isNotEmpty,
          reason: 'EN unshareItemsBody empty',
        );
        expect(
          ruL10n.unshareItemsBody(5),
          isNotEmpty,
          reason: 'RU unshareItemsBody empty',
        );
        // unshare
        expect(enL10n.unshare, isNotEmpty, reason: 'EN unshare empty');
        expect(ruL10n.unshare, isNotEmpty, reason: 'RU unshare empty');
        // moveToTrash
        expect(enL10n.moveToTrash, isNotEmpty, reason: 'EN moveToTrash empty');
        expect(ruL10n.moveToTrash, isNotEmpty, reason: 'RU moveToTrash empty');
        // movedToTrash
        expect(
          enL10n.movedToTrash,
          isNotEmpty,
          reason: 'EN movedToTrash empty',
        );
        expect(
          ruL10n.movedToTrash,
          isNotEmpty,
          reason: 'RU movedToTrash empty',
        );
        // movedNItemsToTrash(int count)
        expect(
          enL10n.movedNItemsToTrash(5),
          isNotEmpty,
          reason: 'EN movedNItemsToTrash empty',
        );
        expect(
          ruL10n.movedNItemsToTrash(5),
          isNotEmpty,
          reason: 'RU movedNItemsToTrash empty',
        );
        // failedToMoveToTrash(String error)
        expect(
          enL10n.failedToMoveToTrash('Network timeout'),
          isNotEmpty,
          reason: 'EN failedToMoveToTrash empty',
        );
        expect(
          ruL10n.failedToMoveToTrash('Network timeout'),
          isNotEmpty,
          reason: 'RU failedToMoveToTrash empty',
        );
        // deletedNItems(int count)
        expect(
          enL10n.deletedNItems(5),
          isNotEmpty,
          reason: 'EN deletedNItems empty',
        );
        expect(
          ruL10n.deletedNItems(5),
          isNotEmpty,
          reason: 'RU deletedNItems empty',
        );
        // failedToDelete(String error)
        expect(
          enL10n.failedToDelete('Network timeout'),
          isNotEmpty,
          reason: 'EN failedToDelete empty',
        );
        expect(
          ruL10n.failedToDelete('Network timeout'),
          isNotEmpty,
          reason: 'RU failedToDelete empty',
        );
        // failedToDeleteItem(String error)
        expect(
          enL10n.failedToDeleteItem('Network timeout'),
          isNotEmpty,
          reason: 'EN failedToDeleteItem empty',
        );
        expect(
          ruL10n.failedToDeleteItem('Network timeout'),
          isNotEmpty,
          reason: 'RU failedToDeleteItem empty',
        );
        // deletedFilename(String filename)
        expect(
          enL10n.deletedFilename('document.pdf'),
          isNotEmpty,
          reason: 'EN deletedFilename empty',
        );
        expect(
          ruL10n.deletedFilename('document.pdf'),
          isNotEmpty,
          reason: 'RU deletedFilename empty',
        );
        // failedToOpenFile
        expect(
          enL10n.failedToOpenFile,
          isNotEmpty,
          reason: 'EN failedToOpenFile empty',
        );
        expect(
          ruL10n.failedToOpenFile,
          isNotEmpty,
          reason: 'RU failedToOpenFile empty',
        );
        // fileDownloadFailed(String error)
        expect(
          enL10n.fileDownloadFailed('Network timeout'),
          isNotEmpty,
          reason: 'EN fileDownloadFailed empty',
        );
        expect(
          ruL10n.fileDownloadFailed('Network timeout'),
          isNotEmpty,
          reason: 'RU fileDownloadFailed empty',
        );
        // downloading
        expect(enL10n.downloading, isNotEmpty, reason: 'EN downloading empty');
        expect(ruL10n.downloading, isNotEmpty, reason: 'RU downloading empty');
        // downloadingFile
        expect(
          enL10n.downloadingFile,
          isNotEmpty,
          reason: 'EN downloadingFile empty',
        );
        expect(
          ruL10n.downloadingFile,
          isNotEmpty,
          reason: 'RU downloadingFile empty',
        );
        // downloadComplete(String filename)
        expect(
          enL10n.downloadComplete('document.pdf'),
          isNotEmpty,
          reason: 'EN downloadComplete empty',
        );
        expect(
          ruL10n.downloadComplete('document.pdf'),
          isNotEmpty,
          reason: 'RU downloadComplete empty',
        );
        // downloadFailed(String error)
        expect(
          enL10n.downloadFailed('Network timeout'),
          isNotEmpty,
          reason: 'EN downloadFailed empty',
        );
        expect(
          ruL10n.downloadFailed('Network timeout'),
          isNotEmpty,
          reason: 'RU downloadFailed empty',
        );
        // failedToDownloadPreview
        expect(
          enL10n.failedToDownloadPreview,
          isNotEmpty,
          reason: 'EN failedToDownloadPreview empty',
        );
        expect(
          ruL10n.failedToDownloadPreview,
          isNotEmpty,
          reason: 'RU failedToDownloadPreview empty',
        );
        // uploadComplete(String filename)
        expect(
          enL10n.uploadComplete('document.pdf'),
          isNotEmpty,
          reason: 'EN uploadComplete empty',
        );
        expect(
          ruL10n.uploadComplete('document.pdf'),
          isNotEmpty,
          reason: 'RU uploadComplete empty',
        );
        // uploadFailed(String error)
        expect(
          enL10n.uploadFailed('Network timeout'),
          isNotEmpty,
          reason: 'EN uploadFailed empty',
        );
        expect(
          ruL10n.uploadFailed('Network timeout'),
          isNotEmpty,
          reason: 'RU uploadFailed empty',
        );
        // failedToPickFiles
        expect(
          enL10n.failedToPickFiles,
          isNotEmpty,
          reason: 'EN failedToPickFiles empty',
        );
        expect(
          ruL10n.failedToPickFiles,
          isNotEmpty,
          reason: 'RU failedToPickFiles empty',
        );
        // uploadedNItems(int count)
        expect(
          enL10n.uploadedNItems(5),
          isNotEmpty,
          reason: 'EN uploadedNItems empty',
        );
        expect(
          ruL10n.uploadedNItems(5),
          isNotEmpty,
          reason: 'RU uploadedNItems empty',
        );
        // copiedLinkToClipboard
        expect(
          enL10n.copiedLinkToClipboard,
          isNotEmpty,
          reason: 'EN copiedLinkToClipboard empty',
        );
        expect(
          ruL10n.copiedLinkToClipboard,
          isNotEmpty,
          reason: 'RU copiedLinkToClipboard empty',
        );
        // failedToCopyLink(String error)
        expect(
          enL10n.failedToCopyLink('Network timeout'),
          isNotEmpty,
          reason: 'EN failedToCopyLink empty',
        );
        expect(
          ruL10n.failedToCopyLink('Network timeout'),
          isNotEmpty,
          reason: 'RU failedToCopyLink empty',
        );
        // selectingAll
        expect(
          enL10n.selectingAll,
          isNotEmpty,
          reason: 'EN selectingAll empty',
        );
        expect(
          ruL10n.selectingAll,
          isNotEmpty,
          reason: 'RU selectingAll empty',
        );
        // allItemsSelected
        expect(
          enL10n.allItemsSelected,
          isNotEmpty,
          reason: 'EN allItemsSelected empty',
        );
        expect(
          ruL10n.allItemsSelected,
          isNotEmpty,
          reason: 'RU allItemsSelected empty',
        );
        // failedToLoadSearchResults
        expect(
          enL10n.failedToLoadSearchResults,
          isNotEmpty,
          reason: 'EN failedToLoadSearchResults empty',
        );
        expect(
          ruL10n.failedToLoadSearchResults,
          isNotEmpty,
          reason: 'RU failedToLoadSearchResults empty',
        );
        // shareNotSupportedForType
        expect(
          enL10n.shareNotSupportedForType,
          isNotEmpty,
          reason: 'EN shareNotSupportedForType empty',
        );
        expect(
          ruL10n.shareNotSupportedForType,
          isNotEmpty,
          reason: 'RU shareNotSupportedForType empty',
        );
        // nSelected(int count)
        expect(enL10n.nSelected(5), isNotEmpty, reason: 'EN nSelected empty');
        expect(ruL10n.nSelected(5), isNotEmpty, reason: 'RU nSelected empty');
        // noServerSelected
        expect(
          enL10n.noServerSelected,
          isNotEmpty,
          reason: 'EN noServerSelected empty',
        );
        expect(
          ruL10n.noServerSelected,
          isNotEmpty,
          reason: 'RU noServerSelected empty',
        );
        // pleaseConnectToServerFirst
        expect(
          enL10n.pleaseConnectToServerFirst,
          isNotEmpty,
          reason: 'EN pleaseConnectToServerFirst empty',
        );
        expect(
          ruL10n.pleaseConnectToServerFirst,
          isNotEmpty,
          reason: 'RU pleaseConnectToServerFirst empty',
        );
        // signInRequired
        expect(
          enL10n.signInRequired,
          isNotEmpty,
          reason: 'EN signInRequired empty',
        );
        expect(
          ruL10n.signInRequired,
          isNotEmpty,
          reason: 'RU signInRequired empty',
        );
        // pleaseSignInToServer(String serverName)
        expect(
          enL10n.pleaseSignInToServer('document.pdf'),
          isNotEmpty,
          reason: 'EN pleaseSignInToServer empty',
        );
        expect(
          ruL10n.pleaseSignInToServer('document.pdf'),
          isNotEmpty,
          reason: 'RU pleaseSignInToServer empty',
        );
        // connectingToServer
        expect(
          enL10n.connectingToServer,
          isNotEmpty,
          reason: 'EN connectingToServer empty',
        );
        expect(
          ruL10n.connectingToServer,
          isNotEmpty,
          reason: 'RU connectingToServer empty',
        );
        // connectedToServer(String serverName)
        expect(
          enL10n.connectedToServer('document.pdf'),
          isNotEmpty,
          reason: 'EN connectedToServer empty',
        );
        expect(
          ruL10n.connectedToServer('document.pdf'),
          isNotEmpty,
          reason: 'RU connectedToServer empty',
        );
        // connectionFailed(String error)
        expect(
          enL10n.connectionFailed('Network timeout'),
          isNotEmpty,
          reason: 'EN connectionFailed empty',
        );
        expect(
          ruL10n.connectionFailed('Network timeout'),
          isNotEmpty,
          reason: 'RU connectionFailed empty',
        );
        // failedToConnect(String error)
        expect(
          enL10n.failedToConnect('Network timeout'),
          isNotEmpty,
          reason: 'EN failedToConnect empty',
        );
        expect(
          ruL10n.failedToConnect('Network timeout'),
          isNotEmpty,
          reason: 'RU failedToConnect empty',
        );
        // authFailed(String error)
        expect(
          enL10n.authFailed('Network timeout'),
          isNotEmpty,
          reason: 'EN authFailed empty',
        );
        expect(
          ruL10n.authFailed('Network timeout'),
          isNotEmpty,
          reason: 'RU authFailed empty',
        );
        // authFailedGeneric
        expect(
          enL10n.authFailedGeneric,
          isNotEmpty,
          reason: 'EN authFailedGeneric empty',
        );
        expect(
          ruL10n.authFailedGeneric,
          isNotEmpty,
          reason: 'RU authFailedGeneric empty',
        );
        // biometricLoginFailed(String error)
        expect(
          enL10n.biometricLoginFailed('Network timeout'),
          isNotEmpty,
          reason: 'EN biometricLoginFailed empty',
        );
        expect(
          ruL10n.biometricLoginFailed('Network timeout'),
          isNotEmpty,
          reason: 'RU biometricLoginFailed empty',
        );
        // biometricLoginFailedGeneric
        expect(
          enL10n.biometricLoginFailedGeneric,
          isNotEmpty,
          reason: 'EN biometricLoginFailedGeneric empty',
        );
        expect(
          ruL10n.biometricLoginFailedGeneric,
          isNotEmpty,
          reason: 'RU biometricLoginFailedGeneric empty',
        );
        // noServerSessionToken
        expect(
          enL10n.noServerSessionToken,
          isNotEmpty,
          reason: 'EN noServerSessionToken empty',
        );
        expect(
          ruL10n.noServerSessionToken,
          isNotEmpty,
          reason: 'RU noServerSessionToken empty',
        );
        // failedToSaveServer(String error)
        expect(
          enL10n.failedToSaveServer('Network timeout'),
          isNotEmpty,
          reason: 'EN failedToSaveServer empty',
        );
        expect(
          ruL10n.failedToSaveServer('Network timeout'),
          isNotEmpty,
          reason: 'RU failedToSaveServer empty',
        );
        // addToFolder
        expect(enL10n.addToFolder, isNotEmpty, reason: 'EN addToFolder empty');
        expect(ruL10n.addToFolder, isNotEmpty, reason: 'RU addToFolder empty');
        // loginTabLabel
        expect(
          enL10n.loginTabLabel,
          isNotEmpty,
          reason: 'EN loginTabLabel empty',
        );
        expect(
          ruL10n.loginTabLabel,
          isNotEmpty,
          reason: 'RU loginTabLabel empty',
        );
        // registerTabLabel
        expect(
          enL10n.registerTabLabel,
          isNotEmpty,
          reason: 'EN registerTabLabel empty',
        );
        expect(
          ruL10n.registerTabLabel,
          isNotEmpty,
          reason: 'RU registerTabLabel empty',
        );
        // welcomeBack
        expect(enL10n.welcomeBack, isNotEmpty, reason: 'EN welcomeBack empty');
        expect(ruL10n.welcomeBack, isNotEmpty, reason: 'RU welcomeBack empty');
        // signInToContinue
        expect(
          enL10n.signInToContinue,
          isNotEmpty,
          reason: 'EN signInToContinue empty',
        );
        expect(
          ruL10n.signInToContinue,
          isNotEmpty,
          reason: 'RU signInToContinue empty',
        );
        // createAccount
        expect(
          enL10n.createAccount,
          isNotEmpty,
          reason: 'EN createAccount empty',
        );
        expect(
          ruL10n.createAccount,
          isNotEmpty,
          reason: 'RU createAccount empty',
        );
        // joinTheServer
        expect(
          enL10n.joinTheServer,
          isNotEmpty,
          reason: 'EN joinTheServer empty',
        );
        expect(
          ruL10n.joinTheServer,
          isNotEmpty,
          reason: 'RU joinTheServer empty',
        );
        // usernameLabel
        expect(
          enL10n.usernameLabel,
          isNotEmpty,
          reason: 'EN usernameLabel empty',
        );
        expect(
          ruL10n.usernameLabel,
          isNotEmpty,
          reason: 'RU usernameLabel empty',
        );
        // usernameHint
        expect(
          enL10n.usernameHint,
          isNotEmpty,
          reason: 'EN usernameHint empty',
        );
        expect(
          ruL10n.usernameHint,
          isNotEmpty,
          reason: 'RU usernameHint empty',
        );
        // passwordLabel
        expect(
          enL10n.passwordLabel,
          isNotEmpty,
          reason: 'EN passwordLabel empty',
        );
        expect(
          ruL10n.passwordLabel,
          isNotEmpty,
          reason: 'RU passwordLabel empty',
        );
        // passwordHint
        expect(
          enL10n.passwordHint,
          isNotEmpty,
          reason: 'EN passwordHint empty',
        );
        expect(
          ruL10n.passwordHint,
          isNotEmpty,
          reason: 'RU passwordHint empty',
        );
        // showPassword
        expect(
          enL10n.showPassword,
          isNotEmpty,
          reason: 'EN showPassword empty',
        );
        expect(
          ruL10n.showPassword,
          isNotEmpty,
          reason: 'RU showPassword empty',
        );
        // hidePassword
        expect(
          enL10n.hidePassword,
          isNotEmpty,
          reason: 'EN hidePassword empty',
        );
        expect(
          ruL10n.hidePassword,
          isNotEmpty,
          reason: 'RU hidePassword empty',
        );
        // confirmPassword
        expect(
          enL10n.confirmPassword,
          isNotEmpty,
          reason: 'EN confirmPassword empty',
        );
        expect(
          ruL10n.confirmPassword,
          isNotEmpty,
          reason: 'RU confirmPassword empty',
        );
        // logIn
        expect(enL10n.logIn, isNotEmpty, reason: 'EN logIn empty');
        expect(ruL10n.logIn, isNotEmpty, reason: 'RU logIn empty');
        // loggingIn
        expect(enL10n.loggingIn, isNotEmpty, reason: 'EN loggingIn empty');
        expect(ruL10n.loggingIn, isNotEmpty, reason: 'RU loggingIn empty');
        // registering
        expect(enL10n.registering, isNotEmpty, reason: 'EN registering empty');
        expect(ruL10n.registering, isNotEmpty, reason: 'RU registering empty');
        // forgotPassword
        expect(
          enL10n.forgotPassword,
          isNotEmpty,
          reason: 'EN forgotPassword empty',
        );
        expect(
          ruL10n.forgotPassword,
          isNotEmpty,
          reason: 'RU forgotPassword empty',
        );
        // doNotHaveAccount
        expect(
          enL10n.doNotHaveAccount,
          isNotEmpty,
          reason: 'EN doNotHaveAccount empty',
        );
        expect(
          ruL10n.doNotHaveAccount,
          isNotEmpty,
          reason: 'RU doNotHaveAccount empty',
        );
        // alreadyHaveAccount
        expect(
          enL10n.alreadyHaveAccount,
          isNotEmpty,
          reason: 'EN alreadyHaveAccount empty',
        );
        expect(
          ruL10n.alreadyHaveAccount,
          isNotEmpty,
          reason: 'RU alreadyHaveAccount empty',
        );
        // usernameCannotBeEmpty
        expect(
          enL10n.usernameCannotBeEmpty,
          isNotEmpty,
          reason: 'EN usernameCannotBeEmpty empty',
        );
        expect(
          ruL10n.usernameCannotBeEmpty,
          isNotEmpty,
          reason: 'RU usernameCannotBeEmpty empty',
        );
        // passwordCannotBeEmpty
        expect(
          enL10n.passwordCannotBeEmpty,
          isNotEmpty,
          reason: 'EN passwordCannotBeEmpty empty',
        );
        expect(
          ruL10n.passwordCannotBeEmpty,
          isNotEmpty,
          reason: 'RU passwordCannotBeEmpty empty',
        );
        // usernameInvalid
        expect(
          enL10n.usernameInvalid,
          isNotEmpty,
          reason: 'EN usernameInvalid empty',
        );
        expect(
          ruL10n.usernameInvalid,
          isNotEmpty,
          reason: 'RU usernameInvalid empty',
        );
        // passwordTooShort
        expect(
          enL10n.passwordTooShort,
          isNotEmpty,
          reason: 'EN passwordTooShort empty',
        );
        expect(
          ruL10n.passwordTooShort,
          isNotEmpty,
          reason: 'RU passwordTooShort empty',
        );
        // loginFailed(String error)
        expect(
          enL10n.loginFailed('Network timeout'),
          isNotEmpty,
          reason: 'EN loginFailed empty',
        );
        expect(
          ruL10n.loginFailed('Network timeout'),
          isNotEmpty,
          reason: 'RU loginFailed empty',
        );
        // registrationFailed(String error)
        expect(
          enL10n.registrationFailed('Network timeout'),
          isNotEmpty,
          reason: 'EN registrationFailed empty',
        );
        expect(
          ruL10n.registrationFailed('Network timeout'),
          isNotEmpty,
          reason: 'RU registrationFailed empty',
        );
        // resetPasswordTitle
        expect(
          enL10n.resetPasswordTitle,
          isNotEmpty,
          reason: 'EN resetPasswordTitle empty',
        );
        expect(
          ruL10n.resetPasswordTitle,
          isNotEmpty,
          reason: 'RU resetPasswordTitle empty',
        );
        // enterResetCodeTitle
        expect(
          enL10n.enterResetCodeTitle,
          isNotEmpty,
          reason: 'EN enterResetCodeTitle empty',
        );
        expect(
          ruL10n.enterResetCodeTitle,
          isNotEmpty,
          reason: 'RU enterResetCodeTitle empty',
        );
        // resetPasswordStep1Body
        expect(
          enL10n.resetPasswordStep1Body,
          isNotEmpty,
          reason: 'EN resetPasswordStep1Body empty',
        );
        expect(
          ruL10n.resetPasswordStep1Body,
          isNotEmpty,
          reason: 'RU resetPasswordStep1Body empty',
        );
        // resetPasswordStep2Body
        expect(
          enL10n.resetPasswordStep2Body,
          isNotEmpty,
          reason: 'EN resetPasswordStep2Body empty',
        );
        expect(
          ruL10n.resetPasswordStep2Body,
          isNotEmpty,
          reason: 'RU resetPasswordStep2Body empty',
        );
        // resetCodeLabel
        expect(
          enL10n.resetCodeLabel,
          isNotEmpty,
          reason: 'EN resetCodeLabel empty',
        );
        expect(
          ruL10n.resetCodeLabel,
          isNotEmpty,
          reason: 'RU resetCodeLabel empty',
        );
        // resetCodeHint
        expect(
          enL10n.resetCodeHint,
          isNotEmpty,
          reason: 'EN resetCodeHint empty',
        );
        expect(
          ruL10n.resetCodeHint,
          isNotEmpty,
          reason: 'RU resetCodeHint empty',
        );
        // newPasswordLabel
        expect(
          enL10n.newPasswordLabel,
          isNotEmpty,
          reason: 'EN newPasswordLabel empty',
        );
        expect(
          ruL10n.newPasswordLabel,
          isNotEmpty,
          reason: 'RU newPasswordLabel empty',
        );
        // newPasswordHint
        expect(
          enL10n.newPasswordHint,
          isNotEmpty,
          reason: 'EN newPasswordHint empty',
        );
        expect(
          ruL10n.newPasswordHint,
          isNotEmpty,
          reason: 'RU newPasswordHint empty',
        );
        // passwordResetSuccessfully
        expect(
          enL10n.passwordResetSuccessfully,
          isNotEmpty,
          reason: 'EN passwordResetSuccessfully empty',
        );
        expect(
          ruL10n.passwordResetSuccessfully,
          isNotEmpty,
          reason: 'RU passwordResetSuccessfully empty',
        );
        // usernameIsRequired
        expect(
          enL10n.usernameIsRequired,
          isNotEmpty,
          reason: 'EN usernameIsRequired empty',
        );
        expect(
          ruL10n.usernameIsRequired,
          isNotEmpty,
          reason: 'RU usernameIsRequired empty',
        );
        // codeAndPasswordRequired
        expect(
          enL10n.codeAndPasswordRequired,
          isNotEmpty,
          reason: 'EN codeAndPasswordRequired empty',
        );
        expect(
          ruL10n.codeAndPasswordRequired,
          isNotEmpty,
          reason: 'RU codeAndPasswordRequired empty',
        );
        // failedToRequestReset
        expect(
          enL10n.failedToRequestReset,
          isNotEmpty,
          reason: 'EN failedToRequestReset empty',
        );
        expect(
          ruL10n.failedToRequestReset,
          isNotEmpty,
          reason: 'RU failedToRequestReset empty',
        );
        // failedToResetPassword
        expect(
          enL10n.failedToResetPassword,
          isNotEmpty,
          reason: 'EN failedToResetPassword empty',
        );
        expect(
          ruL10n.failedToResetPassword,
          isNotEmpty,
          reason: 'RU failedToResetPassword empty',
        );
        // pleaseEnterServerUrlFirst
        expect(
          enL10n.pleaseEnterServerUrlFirst,
          isNotEmpty,
          reason: 'EN pleaseEnterServerUrlFirst empty',
        );
        expect(
          ruL10n.pleaseEnterServerUrlFirst,
          isNotEmpty,
          reason: 'RU pleaseEnterServerUrlFirst empty',
        );
        // sendCode
        expect(enL10n.sendCode, isNotEmpty, reason: 'EN sendCode empty');
        expect(ruL10n.sendCode, isNotEmpty, reason: 'RU sendCode empty');
        // settingsTitle
        expect(
          enL10n.settingsTitle,
          isNotEmpty,
          reason: 'EN settingsTitle empty',
        );
        expect(
          ruL10n.settingsTitle,
          isNotEmpty,
          reason: 'RU settingsTitle empty',
        );
        // sectionBackupSync
        expect(
          enL10n.sectionBackupSync,
          isNotEmpty,
          reason: 'EN sectionBackupSync empty',
        );
        expect(
          ruL10n.sectionBackupSync,
          isNotEmpty,
          reason: 'RU sectionBackupSync empty',
        );
        // sectionStorageCache
        expect(
          enL10n.sectionStorageCache,
          isNotEmpty,
          reason: 'EN sectionStorageCache empty',
        );
        expect(
          ruL10n.sectionStorageCache,
          isNotEmpty,
          reason: 'RU sectionStorageCache empty',
        );
        // sectionSecurityBehavior
        expect(
          enL10n.sectionSecurityBehavior,
          isNotEmpty,
          reason: 'EN sectionSecurityBehavior empty',
        );
        expect(
          ruL10n.sectionSecurityBehavior,
          isNotEmpty,
          reason: 'RU sectionSecurityBehavior empty',
        );
        // sectionAboutUpdates
        expect(
          enL10n.sectionAboutUpdates,
          isNotEmpty,
          reason: 'EN sectionAboutUpdates empty',
        );
        expect(
          ruL10n.sectionAboutUpdates,
          isNotEmpty,
          reason: 'RU sectionAboutUpdates empty',
        );
        // sectionAppearance
        expect(
          enL10n.sectionAppearance,
          isNotEmpty,
          reason: 'EN sectionAppearance empty',
        );
        expect(
          ruL10n.sectionAppearance,
          isNotEmpty,
          reason: 'RU sectionAppearance empty',
        );
        // noServersConfiguredSync
        expect(
          enL10n.noServersConfiguredSync,
          isNotEmpty,
          reason: 'EN noServersConfiguredSync empty',
        );
        expect(
          ruL10n.noServersConfiguredSync,
          isNotEmpty,
          reason: 'RU noServersConfiguredSync empty',
        );
        // addServerBeforeSync
        expect(
          enL10n.addServerBeforeSync,
          isNotEmpty,
          reason: 'EN addServerBeforeSync empty',
        );
        expect(
          ruL10n.addServerBeforeSync,
          isNotEmpty,
          reason: 'RU addServerBeforeSync empty',
        );
        // selectServerToConfigureSync
        expect(
          enL10n.selectServerToConfigureSync,
          isNotEmpty,
          reason: 'EN selectServerToConfigureSync empty',
        );
        expect(
          ruL10n.selectServerToConfigureSync,
          isNotEmpty,
          reason: 'RU selectServerToConfigureSync empty',
        );
        // activeServerSuffix
        expect(
          enL10n.activeServerSuffix,
          isNotEmpty,
          reason: 'EN activeServerSuffix empty',
        );
        expect(
          ruL10n.activeServerSuffix,
          isNotEmpty,
          reason: 'RU activeServerSuffix empty',
        );
        // folderAndCategorySync
        expect(
          enL10n.folderAndCategorySync,
          isNotEmpty,
          reason: 'EN folderAndCategorySync empty',
        );
        expect(
          ruL10n.folderAndCategorySync,
          isNotEmpty,
          reason: 'RU folderAndCategorySync empty',
        );
        // keepCategoriesSynced
        expect(
          enL10n.keepCategoriesSynced,
          isNotEmpty,
          reason: 'EN keepCategoriesSynced empty',
        );
        expect(
          ruL10n.keepCategoriesSynced,
          isNotEmpty,
          reason: 'RU keepCategoriesSynced empty',
        );
        // addServerBeforeSyncEnable
        expect(
          enL10n.addServerBeforeSyncEnable,
          isNotEmpty,
          reason: 'EN addServerBeforeSyncEnable empty',
        );
        expect(
          ruL10n.addServerBeforeSyncEnable,
          isNotEmpty,
          reason: 'RU addServerBeforeSyncEnable empty',
        );
        // onlyOnWifi
        expect(enL10n.onlyOnWifi, isNotEmpty, reason: 'EN onlyOnWifi empty');
        expect(ruL10n.onlyOnWifi, isNotEmpty, reason: 'RU onlyOnWifi empty');
        // onlyWhileCharging
        expect(
          enL10n.onlyWhileCharging,
          isNotEmpty,
          reason: 'EN onlyWhileCharging empty',
        );
        expect(
          ruL10n.onlyWhileCharging,
          isNotEmpty,
          reason: 'RU onlyWhileCharging empty',
        );
        // serverTargetDirectory
        expect(
          enL10n.serverTargetDirectory,
          isNotEmpty,
          reason: 'EN serverTargetDirectory empty',
        );
        expect(
          ruL10n.serverTargetDirectory,
          isNotEmpty,
          reason: 'RU serverTargetDirectory empty',
        );
        // serverTargetDirectoryHint
        expect(
          enL10n.serverTargetDirectoryHint,
          isNotEmpty,
          reason: 'EN serverTargetDirectoryHint empty',
        );
        expect(
          ruL10n.serverTargetDirectoryHint,
          isNotEmpty,
          reason: 'RU serverTargetDirectoryHint empty',
        );
        // synchronizationFrequency
        expect(
          enL10n.synchronizationFrequency,
          isNotEmpty,
          reason: 'EN synchronizationFrequency empty',
        );
        expect(
          ruL10n.synchronizationFrequency,
          isNotEmpty,
          reason: 'RU synchronizationFrequency empty',
        );
        // syncNow
        expect(enL10n.syncNow, isNotEmpty, reason: 'EN syncNow empty');
        expect(ruL10n.syncNow, isNotEmpty, reason: 'RU syncNow empty');
        // syncing
        expect(enL10n.syncing, isNotEmpty, reason: 'EN syncing empty');
        expect(ruL10n.syncing, isNotEmpty, reason: 'RU syncing empty');
        // categoriesToSynchronize
        expect(
          enL10n.categoriesToSynchronize,
          isNotEmpty,
          reason: 'EN categoriesToSynchronize empty',
        );
        expect(
          ruL10n.categoriesToSynchronize,
          isNotEmpty,
          reason: 'RU categoriesToSynchronize empty',
        );
        // noCategoriesSelected
        expect(
          enL10n.noCategoriesSelected,
          isNotEmpty,
          reason: 'EN noCategoriesSelected empty',
        );
        expect(
          ruL10n.noCategoriesSelected,
          isNotEmpty,
          reason: 'RU noCategoriesSelected empty',
        );
        // nCategoriesSelected(int count)
        expect(
          enL10n.nCategoriesSelected(5),
          isNotEmpty,
          reason: 'EN nCategoriesSelected empty',
        );
        expect(
          ruL10n.nCategoriesSelected(5),
          isNotEmpty,
          reason: 'RU nCategoriesSelected empty',
        );
        // foldersToSynchronize
        expect(
          enL10n.foldersToSynchronize,
          isNotEmpty,
          reason: 'EN foldersToSynchronize empty',
        );
        expect(
          ruL10n.foldersToSynchronize,
          isNotEmpty,
          reason: 'RU foldersToSynchronize empty',
        );
        // noCustomFolders
        expect(
          enL10n.noCustomFolders,
          isNotEmpty,
          reason: 'EN noCustomFolders empty',
        );
        expect(
          ruL10n.noCustomFolders,
          isNotEmpty,
          reason: 'RU noCustomFolders empty',
        );
        // nFolders(int count)
        expect(enL10n.nFolders(5), isNotEmpty, reason: 'EN nFolders empty');
        expect(ruL10n.nFolders(5), isNotEmpty, reason: 'RU nFolders empty');
        // addFolder
        expect(enL10n.addFolder, isNotEmpty, reason: 'EN addFolder empty');
        expect(ruL10n.addFolder, isNotEmpty, reason: 'RU addFolder empty');
        // removeFolder
        expect(
          enL10n.removeFolder,
          isNotEmpty,
          reason: 'EN removeFolder empty',
        );
        expect(
          ruL10n.removeFolder,
          isNotEmpty,
          reason: 'RU removeFolder empty',
        );
        // removeServer
        expect(
          enL10n.removeServer,
          isNotEmpty,
          reason: 'EN removeServer empty',
        );
        expect(
          ruL10n.removeServer,
          isNotEmpty,
          reason: 'RU removeServer empty',
        );
        // syncFreqEvery15Min
        expect(
          enL10n.syncFreqEvery15Min,
          isNotEmpty,
          reason: 'EN syncFreqEvery15Min empty',
        );
        expect(
          ruL10n.syncFreqEvery15Min,
          isNotEmpty,
          reason: 'RU syncFreqEvery15Min empty',
        );
        // syncFreqEvery30Min
        expect(
          enL10n.syncFreqEvery30Min,
          isNotEmpty,
          reason: 'EN syncFreqEvery30Min empty',
        );
        expect(
          ruL10n.syncFreqEvery30Min,
          isNotEmpty,
          reason: 'RU syncFreqEvery30Min empty',
        );
        // syncFreqEvery1Hour
        expect(
          enL10n.syncFreqEvery1Hour,
          isNotEmpty,
          reason: 'EN syncFreqEvery1Hour empty',
        );
        expect(
          ruL10n.syncFreqEvery1Hour,
          isNotEmpty,
          reason: 'RU syncFreqEvery1Hour empty',
        );
        // syncFreqEveryNHours(int hours)
        expect(
          enL10n.syncFreqEveryNHours(5),
          isNotEmpty,
          reason: 'EN syncFreqEveryNHours empty',
        );
        expect(
          ruL10n.syncFreqEveryNHours(5),
          isNotEmpty,
          reason: 'RU syncFreqEveryNHours empty',
        );
        // syncFreqEveryNMin(int minutes)
        expect(
          enL10n.syncFreqEveryNMin(5),
          isNotEmpty,
          reason: 'EN syncFreqEveryNMin empty',
        );
        expect(
          ruL10n.syncFreqEveryNMin(5),
          isNotEmpty,
          reason: 'RU syncFreqEveryNMin empty',
        );
        // syncFreqDaily
        expect(
          enL10n.syncFreqDaily,
          isNotEmpty,
          reason: 'EN syncFreqDaily empty',
        );
        expect(
          ruL10n.syncFreqDaily,
          isNotEmpty,
          reason: 'RU syncFreqDaily empty',
        );
        // chooseSyncFrequencyTitle
        expect(
          enL10n.chooseSyncFrequencyTitle,
          isNotEmpty,
          reason: 'EN chooseSyncFrequencyTitle empty',
        );
        expect(
          ruL10n.chooseSyncFrequencyTitle,
          isNotEmpty,
          reason: 'RU chooseSyncFrequencyTitle empty',
        );
        // cacheSize
        expect(enL10n.cacheSize, isNotEmpty, reason: 'EN cacheSize empty');
        expect(ruL10n.cacheSize, isNotEmpty, reason: 'RU cacheSize empty');
        // refreshTooltip
        expect(
          enL10n.refreshTooltip,
          isNotEmpty,
          reason: 'EN refreshTooltip empty',
        );
        expect(
          ruL10n.refreshTooltip,
          isNotEmpty,
          reason: 'RU refreshTooltip empty',
        );
        // cacheLimit
        expect(enL10n.cacheLimit, isNotEmpty, reason: 'EN cacheLimit empty');
        expect(ruL10n.cacheLimit, isNotEmpty, reason: 'RU cacheLimit empty');
        // downloadPath
        expect(
          enL10n.downloadPath,
          isNotEmpty,
          reason: 'EN downloadPath empty',
        );
        expect(
          ruL10n.downloadPath,
          isNotEmpty,
          reason: 'RU downloadPath empty',
        );
        // defaultDownloadFolder
        expect(
          enL10n.defaultDownloadFolder,
          isNotEmpty,
          reason: 'EN defaultDownloadFolder empty',
        );
        expect(
          ruL10n.defaultDownloadFolder,
          isNotEmpty,
          reason: 'RU defaultDownloadFolder empty',
        );
        // clearCache
        expect(enL10n.clearCache, isNotEmpty, reason: 'EN clearCache empty');
        expect(ruL10n.clearCache, isNotEmpty, reason: 'RU clearCache empty');
        // clearCacheTitle
        expect(
          enL10n.clearCacheTitle,
          isNotEmpty,
          reason: 'EN clearCacheTitle empty',
        );
        expect(
          ruL10n.clearCacheTitle,
          isNotEmpty,
          reason: 'RU clearCacheTitle empty',
        );
        // clearCacheBody
        expect(
          enL10n.clearCacheBody,
          isNotEmpty,
          reason: 'EN clearCacheBody empty',
        );
        expect(
          ruL10n.clearCacheBody,
          isNotEmpty,
          reason: 'RU clearCacheBody empty',
        );
        // downloadPathDialogTitle
        expect(
          enL10n.downloadPathDialogTitle,
          isNotEmpty,
          reason: 'EN downloadPathDialogTitle empty',
        );
        expect(
          ruL10n.downloadPathDialogTitle,
          isNotEmpty,
          reason: 'RU downloadPathDialogTitle empty',
        );
        // downloadPathHint
        expect(
          enL10n.downloadPathHint,
          isNotEmpty,
          reason: 'EN downloadPathHint empty',
        );
        expect(
          ruL10n.downloadPathHint,
          isNotEmpty,
          reason: 'RU downloadPathHint empty',
        );
        // useDefault
        expect(enL10n.useDefault, isNotEmpty, reason: 'EN useDefault empty');
        expect(ruL10n.useDefault, isNotEmpty, reason: 'RU useDefault empty');
        // serverTargetDirDialogTitle
        expect(
          enL10n.serverTargetDirDialogTitle,
          isNotEmpty,
          reason: 'EN serverTargetDirDialogTitle empty',
        );
        expect(
          ruL10n.serverTargetDirDialogTitle,
          isNotEmpty,
          reason: 'RU serverTargetDirDialogTitle empty',
        );
        // requireLogin
        expect(
          enL10n.requireLogin,
          isNotEmpty,
          reason: 'EN requireLogin empty',
        );
        expect(
          ruL10n.requireLogin,
          isNotEmpty,
          reason: 'RU requireLogin empty',
        );
        // biometricLogin
        expect(
          enL10n.biometricLogin,
          isNotEmpty,
          reason: 'EN biometricLogin empty',
        );
        expect(
          ruL10n.biometricLogin,
          isNotEmpty,
          reason: 'RU biometricLogin empty',
        );
        // biometricLoginSubtitle
        expect(
          enL10n.biometricLoginSubtitle,
          isNotEmpty,
          reason: 'EN biometricLoginSubtitle empty',
        );
        expect(
          ruL10n.biometricLoginSubtitle,
          isNotEmpty,
          reason: 'RU biometricLoginSubtitle empty',
        );
        // biometricsNotAvailable
        expect(
          enL10n.biometricsNotAvailable,
          isNotEmpty,
          reason: 'EN biometricsNotAvailable empty',
        );
        expect(
          ruL10n.biometricsNotAvailable,
          isNotEmpty,
          reason: 'RU biometricsNotAvailable empty',
        );
        // showHiddenFiles
        expect(
          enL10n.showHiddenFiles,
          isNotEmpty,
          reason: 'EN showHiddenFiles empty',
        );
        expect(
          ruL10n.showHiddenFiles,
          isNotEmpty,
          reason: 'RU showHiddenFiles empty',
        );
        // showHiddenFilesSubtitle
        expect(
          enL10n.showHiddenFilesSubtitle,
          isNotEmpty,
          reason: 'EN showHiddenFilesSubtitle empty',
        );
        expect(
          ruL10n.showHiddenFilesSubtitle,
          isNotEmpty,
          reason: 'RU showHiddenFilesSubtitle empty',
        );
        // changePassword
        expect(
          enL10n.changePassword,
          isNotEmpty,
          reason: 'EN changePassword empty',
        );
        expect(
          ruL10n.changePassword,
          isNotEmpty,
          reason: 'RU changePassword empty',
        );
        // changePasswordSubtitle(String serverName)
        expect(
          enL10n.changePasswordSubtitle('document.pdf'),
          isNotEmpty,
          reason: 'EN changePasswordSubtitle empty',
        );
        expect(
          ruL10n.changePasswordSubtitle('document.pdf'),
          isNotEmpty,
          reason: 'RU changePasswordSubtitle empty',
        );
        // addServerBeforeChangePassword
        expect(
          enL10n.addServerBeforeChangePassword,
          isNotEmpty,
          reason: 'EN addServerBeforeChangePassword empty',
        );
        expect(
          ruL10n.addServerBeforeChangePassword,
          isNotEmpty,
          reason: 'RU addServerBeforeChangePassword empty',
        );
        // deleteUserAccount
        expect(
          enL10n.deleteUserAccount,
          isNotEmpty,
          reason: 'EN deleteUserAccount empty',
        );
        expect(
          ruL10n.deleteUserAccount,
          isNotEmpty,
          reason: 'RU deleteUserAccount empty',
        );
        // deleteUserAccountSubtitle
        expect(
          enL10n.deleteUserAccountSubtitle,
          isNotEmpty,
          reason: 'EN deleteUserAccountSubtitle empty',
        );
        expect(
          ruL10n.deleteUserAccountSubtitle,
          isNotEmpty,
          reason: 'RU deleteUserAccountSubtitle empty',
        );
        // deleteAccountTitle
        expect(
          enL10n.deleteAccountTitle,
          isNotEmpty,
          reason: 'EN deleteAccountTitle empty',
        );
        expect(
          ruL10n.deleteAccountTitle,
          isNotEmpty,
          reason: 'RU deleteAccountTitle empty',
        );
        // deleteAccountBody(String serverName)
        expect(
          enL10n.deleteAccountBody('document.pdf'),
          isNotEmpty,
          reason: 'EN deleteAccountBody empty',
        );
        expect(
          ruL10n.deleteAccountBody('document.pdf'),
          isNotEmpty,
          reason: 'RU deleteAccountBody empty',
        );
        // deleteAccountButton
        expect(
          enL10n.deleteAccountButton,
          isNotEmpty,
          reason: 'EN deleteAccountButton empty',
        );
        expect(
          ruL10n.deleteAccountButton,
          isNotEmpty,
          reason: 'RU deleteAccountButton empty',
        );
        // changePasswordDialogTitle
        expect(
          enL10n.changePasswordDialogTitle,
          isNotEmpty,
          reason: 'EN changePasswordDialogTitle empty',
        );
        expect(
          ruL10n.changePasswordDialogTitle,
          isNotEmpty,
          reason: 'RU changePasswordDialogTitle empty',
        );
        // newPasswordFieldLabel
        expect(
          enL10n.newPasswordFieldLabel,
          isNotEmpty,
          reason: 'EN newPasswordFieldLabel empty',
        );
        expect(
          ruL10n.newPasswordFieldLabel,
          isNotEmpty,
          reason: 'RU newPasswordFieldLabel empty',
        );
        // confirmPasswordLabel
        expect(
          enL10n.confirmPasswordLabel,
          isNotEmpty,
          reason: 'EN confirmPasswordLabel empty',
        );
        expect(
          ruL10n.confirmPasswordLabel,
          isNotEmpty,
          reason: 'RU confirmPasswordLabel empty',
        );
        // enterNewPassword
        expect(
          enL10n.enterNewPassword,
          isNotEmpty,
          reason: 'EN enterNewPassword empty',
        );
        expect(
          ruL10n.enterNewPassword,
          isNotEmpty,
          reason: 'RU enterNewPassword empty',
        );
        // passwordUpdated
        expect(
          enL10n.passwordUpdated,
          isNotEmpty,
          reason: 'EN passwordUpdated empty',
        );
        expect(
          ruL10n.passwordUpdated,
          isNotEmpty,
          reason: 'RU passwordUpdated empty',
        );
        // passwordChangeFailed(String error)
        expect(
          enL10n.passwordChangeFailed('Network timeout'),
          isNotEmpty,
          reason: 'EN passwordChangeFailed empty',
        );
        expect(
          ruL10n.passwordChangeFailed('Network timeout'),
          isNotEmpty,
          reason: 'RU passwordChangeFailed empty',
        );
        // passwordChangeFailedGeneric
        expect(
          enL10n.passwordChangeFailedGeneric,
          isNotEmpty,
          reason: 'EN passwordChangeFailedGeneric empty',
        );
        expect(
          ruL10n.passwordChangeFailedGeneric,
          isNotEmpty,
          reason: 'RU passwordChangeFailedGeneric empty',
        );
        // accountDeleted
        expect(
          enL10n.accountDeleted,
          isNotEmpty,
          reason: 'EN accountDeleted empty',
        );
        expect(
          ruL10n.accountDeleted,
          isNotEmpty,
          reason: 'RU accountDeleted empty',
        );
        // accountDeletionFailed(String error)
        expect(
          enL10n.accountDeletionFailed('Network timeout'),
          isNotEmpty,
          reason: 'EN accountDeletionFailed empty',
        );
        expect(
          ruL10n.accountDeletionFailed('Network timeout'),
          isNotEmpty,
          reason: 'RU accountDeletionFailed empty',
        );
        // accountDeletionFailedGeneric
        expect(
          enL10n.accountDeletionFailedGeneric,
          isNotEmpty,
          reason: 'EN accountDeletionFailedGeneric empty',
        );
        expect(
          ruL10n.accountDeletionFailedGeneric,
          isNotEmpty,
          reason: 'RU accountDeletionFailedGeneric empty',
        );
        // checkForUpdates
        expect(
          enL10n.checkForUpdates,
          isNotEmpty,
          reason: 'EN checkForUpdates empty',
        );
        expect(
          ruL10n.checkForUpdates,
          isNotEmpty,
          reason: 'RU checkForUpdates empty',
        );
        // checkingForUpdates
        expect(
          enL10n.checkingForUpdates,
          isNotEmpty,
          reason: 'EN checkingForUpdates empty',
        );
        expect(
          ruL10n.checkingForUpdates,
          isNotEmpty,
          reason: 'RU checkingForUpdates empty',
        );
        // versionLabel(String version)
        expect(
          enL10n.versionLabel('1.2.3'),
          isNotEmpty,
          reason: 'EN versionLabel empty',
        );
        expect(
          ruL10n.versionLabel('1.2.3'),
          isNotEmpty,
          reason: 'RU versionLabel empty',
        );
        // appIsUpToDate(String version)
        expect(
          enL10n.appIsUpToDate('1.2.3'),
          isNotEmpty,
          reason: 'EN appIsUpToDate empty',
        );
        expect(
          ruL10n.appIsUpToDate('1.2.3'),
          isNotEmpty,
          reason: 'RU appIsUpToDate empty',
        );
        // updateCheckFailed
        expect(
          enL10n.updateCheckFailed,
          isNotEmpty,
          reason: 'EN updateCheckFailed empty',
        );
        expect(
          ruL10n.updateCheckFailed,
          isNotEmpty,
          reason: 'RU updateCheckFailed empty',
        );
        // themeModeTitle
        expect(
          enL10n.themeModeTitle,
          isNotEmpty,
          reason: 'EN themeModeTitle empty',
        );
        expect(
          ruL10n.themeModeTitle,
          isNotEmpty,
          reason: 'RU themeModeTitle empty',
        );
        // themeDark
        expect(enL10n.themeDark, isNotEmpty, reason: 'EN themeDark empty');
        expect(ruL10n.themeDark, isNotEmpty, reason: 'RU themeDark empty');
        // themeLight
        expect(enL10n.themeLight, isNotEmpty, reason: 'EN themeLight empty');
        expect(ruL10n.themeLight, isNotEmpty, reason: 'RU themeLight empty');
        // themeCustom
        expect(enL10n.themeCustom, isNotEmpty, reason: 'EN themeCustom empty');
        expect(ruL10n.themeCustom, isNotEmpty, reason: 'RU themeCustom empty');
        // themeDarkFull
        expect(
          enL10n.themeDarkFull,
          isNotEmpty,
          reason: 'EN themeDarkFull empty',
        );
        expect(
          ruL10n.themeDarkFull,
          isNotEmpty,
          reason: 'RU themeDarkFull empty',
        );
        // themeLightFull
        expect(
          enL10n.themeLightFull,
          isNotEmpty,
          reason: 'EN themeLightFull empty',
        );
        expect(
          ruL10n.themeLightFull,
          isNotEmpty,
          reason: 'RU themeLightFull empty',
        );
        // themeCustomFull
        expect(
          enL10n.themeCustomFull,
          isNotEmpty,
          reason: 'EN themeCustomFull empty',
        );
        expect(
          ruL10n.themeCustomFull,
          isNotEmpty,
          reason: 'RU themeCustomFull empty',
        );
        // accentColor
        expect(enL10n.accentColor, isNotEmpty, reason: 'EN accentColor empty');
        expect(ruL10n.accentColor, isNotEmpty, reason: 'RU accentColor empty');
        // primaryAccentColor
        expect(
          enL10n.primaryAccentColor,
          isNotEmpty,
          reason: 'EN primaryAccentColor empty',
        );
        expect(
          ruL10n.primaryAccentColor,
          isNotEmpty,
          reason: 'RU primaryAccentColor empty',
        );
        // selectAccentColor
        expect(
          enL10n.selectAccentColor,
          isNotEmpty,
          reason: 'EN selectAccentColor empty',
        );
        expect(
          ruL10n.selectAccentColor,
          isNotEmpty,
          reason: 'RU selectAccentColor empty',
        );
        // backgroundColor
        expect(
          enL10n.backgroundColor,
          isNotEmpty,
          reason: 'EN backgroundColor empty',
        );
        expect(
          ruL10n.backgroundColor,
          isNotEmpty,
          reason: 'RU backgroundColor empty',
        );
        // surfaceColor
        expect(
          enL10n.surfaceColor,
          isNotEmpty,
          reason: 'EN surfaceColor empty',
        );
        expect(
          ruL10n.surfaceColor,
          isNotEmpty,
          reason: 'RU surfaceColor empty',
        );
        // textColor
        expect(enL10n.textColor, isNotEmpty, reason: 'EN textColor empty');
        expect(ruL10n.textColor, isNotEmpty, reason: 'RU textColor empty');
        // subtextColor
        expect(
          enL10n.subtextColor,
          isNotEmpty,
          reason: 'EN subtextColor empty',
        );
        expect(
          ruL10n.subtextColor,
          isNotEmpty,
          reason: 'RU subtextColor empty',
        );
        // borderColor
        expect(enL10n.borderColor, isNotEmpty, reason: 'EN borderColor empty');
        expect(ruL10n.borderColor, isNotEmpty, reason: 'RU borderColor empty');
        // fontSizeScale
        expect(
          enL10n.fontSizeScale,
          isNotEmpty,
          reason: 'EN fontSizeScale empty',
        );
        expect(
          ruL10n.fontSizeScale,
          isNotEmpty,
          reason: 'RU fontSizeScale empty',
        );
        // selectColor(String title)
        expect(
          enL10n.selectColor('Primary Color'),
          isNotEmpty,
          reason: 'EN selectColor empty',
        );
        expect(
          ruL10n.selectColor('Primary Color'),
          isNotEmpty,
          reason: 'RU selectColor empty',
        );
        // categoriesToSyncDialogTitle
        expect(
          enL10n.categoriesToSyncDialogTitle,
          isNotEmpty,
          reason: 'EN categoriesToSyncDialogTitle empty',
        );
        expect(
          ruL10n.categoriesToSyncDialogTitle,
          isNotEmpty,
          reason: 'RU categoriesToSyncDialogTitle empty',
        );
        // categoriesToSyncBody
        expect(
          enL10n.categoriesToSyncBody,
          isNotEmpty,
          reason: 'EN categoriesToSyncBody empty',
        );
        expect(
          ruL10n.categoriesToSyncBody,
          isNotEmpty,
          reason: 'RU categoriesToSyncBody empty',
        );
        // syncCategorySectionMedia
        expect(
          enL10n.syncCategorySectionMedia,
          isNotEmpty,
          reason: 'EN syncCategorySectionMedia empty',
        );
        expect(
          ruL10n.syncCategorySectionMedia,
          isNotEmpty,
          reason: 'RU syncCategorySectionMedia empty',
        );
        // syncCategorySectionAudioDocs
        expect(
          enL10n.syncCategorySectionAudioDocs,
          isNotEmpty,
          reason: 'EN syncCategorySectionAudioDocs empty',
        );
        expect(
          ruL10n.syncCategorySectionAudioDocs,
          isNotEmpty,
          reason: 'RU syncCategorySectionAudioDocs empty',
        );
        // syncCategorySectionOther
        expect(
          enL10n.syncCategorySectionOther,
          isNotEmpty,
          reason: 'EN syncCategorySectionOther empty',
        );
        expect(
          ruL10n.syncCategorySectionOther,
          isNotEmpty,
          reason: 'RU syncCategorySectionOther empty',
        );
        // clearAll
        expect(enL10n.clearAll, isNotEmpty, reason: 'EN clearAll empty');
        expect(ruL10n.clearAll, isNotEmpty, reason: 'RU clearAll empty');
        // noSyncHasRunYet
        expect(
          enL10n.noSyncHasRunYet,
          isNotEmpty,
          reason: 'EN noSyncHasRunYet empty',
        );
        expect(
          ruL10n.noSyncHasRunYet,
          isNotEmpty,
          reason: 'RU noSyncHasRunYet empty',
        );
        // lastRunAt(String date)
        expect(
          enL10n.lastRunAt('2026-08-18'),
          isNotEmpty,
          reason: 'EN lastRunAt empty',
        );
        expect(
          ruL10n.lastRunAt('2026-08-18'),
          isNotEmpty,
          reason: 'RU lastRunAt empty',
        );
        // syncResultSuccess(int uploaded, int skipped)
        expect(
          enL10n.syncResultSuccess(5, 5),
          isNotEmpty,
          reason: 'EN syncResultSuccess empty',
        );
        expect(
          ruL10n.syncResultSuccess(5, 5),
          isNotEmpty,
          reason: 'RU syncResultSuccess empty',
        );
        // syncResultNoFiles
        expect(
          enL10n.syncResultNoFiles,
          isNotEmpty,
          reason: 'EN syncResultNoFiles empty',
        );
        expect(
          ruL10n.syncResultNoFiles,
          isNotEmpty,
          reason: 'RU syncResultNoFiles empty',
        );
        // syncResultPartial(int uploaded, int failed)
        expect(
          enL10n.syncResultPartial(5, 5),
          isNotEmpty,
          reason: 'EN syncResultPartial empty',
        );
        expect(
          ruL10n.syncResultPartial(5, 5),
          isNotEmpty,
          reason: 'RU syncResultPartial empty',
        );
        // syncResultAuthRequired
        expect(
          enL10n.syncResultAuthRequired,
          isNotEmpty,
          reason: 'EN syncResultAuthRequired empty',
        );
        expect(
          ruL10n.syncResultAuthRequired,
          isNotEmpty,
          reason: 'RU syncResultAuthRequired empty',
        );
        // syncResultUnreachable
        expect(
          enL10n.syncResultUnreachable,
          isNotEmpty,
          reason: 'EN syncResultUnreachable empty',
        );
        expect(
          ruL10n.syncResultUnreachable,
          isNotEmpty,
          reason: 'RU syncResultUnreachable empty',
        );
        // syncResultFailed
        expect(
          enL10n.syncResultFailed,
          isNotEmpty,
          reason: 'EN syncResultFailed empty',
        );
        expect(
          ruL10n.syncResultFailed,
          isNotEmpty,
          reason: 'RU syncResultFailed empty',
        );
        // serverSetupAddServer
        expect(
          enL10n.serverSetupAddServer,
          isNotEmpty,
          reason: 'EN serverSetupAddServer empty',
        );
        expect(
          ruL10n.serverSetupAddServer,
          isNotEmpty,
          reason: 'RU serverSetupAddServer empty',
        );
        // serverSetupCardTitle
        expect(
          enL10n.serverSetupCardTitle,
          isNotEmpty,
          reason: 'EN serverSetupCardTitle empty',
        );
        expect(
          ruL10n.serverSetupCardTitle,
          isNotEmpty,
          reason: 'RU serverSetupCardTitle empty',
        );
        // serverSetupCardSubtitle
        expect(
          enL10n.serverSetupCardSubtitle,
          isNotEmpty,
          reason: 'EN serverSetupCardSubtitle empty',
        );
        expect(
          ruL10n.serverSetupCardSubtitle,
          isNotEmpty,
          reason: 'RU serverSetupCardSubtitle empty',
        );
        // serverSetupSubmitButton
        expect(
          enL10n.serverSetupSubmitButton,
          isNotEmpty,
          reason: 'EN serverSetupSubmitButton empty',
        );
        expect(
          ruL10n.serverSetupSubmitButton,
          isNotEmpty,
          reason: 'RU serverSetupSubmitButton empty',
        );
        // serverNameLabel
        expect(
          enL10n.serverNameLabel,
          isNotEmpty,
          reason: 'EN serverNameLabel empty',
        );
        expect(
          ruL10n.serverNameLabel,
          isNotEmpty,
          reason: 'RU serverNameLabel empty',
        );
        // serverNameHint
        expect(
          enL10n.serverNameHint,
          isNotEmpty,
          reason: 'EN serverNameHint empty',
        );
        expect(
          ruL10n.serverNameHint,
          isNotEmpty,
          reason: 'RU serverNameHint empty',
        );
        // baseUrlLabel
        expect(
          enL10n.baseUrlLabel,
          isNotEmpty,
          reason: 'EN baseUrlLabel empty',
        );
        expect(
          ruL10n.baseUrlLabel,
          isNotEmpty,
          reason: 'RU baseUrlLabel empty',
        );
        // baseUrlHint
        expect(enL10n.baseUrlHint, isNotEmpty, reason: 'EN baseUrlHint empty');
        expect(ruL10n.baseUrlHint, isNotEmpty, reason: 'RU baseUrlHint empty');
        // allFieldsRequired
        expect(
          enL10n.allFieldsRequired,
          isNotEmpty,
          reason: 'EN allFieldsRequired empty',
        );
        expect(
          ruL10n.allFieldsRequired,
          isNotEmpty,
          reason: 'RU allFieldsRequired empty',
        );
        // localFilesTitle
        expect(
          enL10n.localFilesTitle,
          isNotEmpty,
          reason: 'EN localFilesTitle empty',
        );
        expect(
          ruL10n.localFilesTitle,
          isNotEmpty,
          reason: 'RU localFilesTitle empty',
        );
        // serverFilesTitle
        expect(
          enL10n.serverFilesTitle,
          isNotEmpty,
          reason: 'EN serverFilesTitle empty',
        );
        expect(
          ruL10n.serverFilesTitle,
          isNotEmpty,
          reason: 'RU serverFilesTitle empty',
        );
        // restoreItemsTitle
        expect(
          enL10n.restoreItemsTitle,
          isNotEmpty,
          reason: 'EN restoreItemsTitle empty',
        );
        expect(
          ruL10n.restoreItemsTitle,
          isNotEmpty,
          reason: 'RU restoreItemsTitle empty',
        );
        // restoreItemsBody(int count)
        expect(
          enL10n.restoreItemsBody(5),
          isNotEmpty,
          reason: 'EN restoreItemsBody empty',
        );
        expect(
          ruL10n.restoreItemsBody(5),
          isNotEmpty,
          reason: 'RU restoreItemsBody empty',
        );
        // permanentlyDeleteTitle
        expect(
          enL10n.permanentlyDeleteTitle,
          isNotEmpty,
          reason: 'EN permanentlyDeleteTitle empty',
        );
        expect(
          ruL10n.permanentlyDeleteTitle,
          isNotEmpty,
          reason: 'RU permanentlyDeleteTitle empty',
        );
        // permanentlyDeleteBody(int count)
        expect(
          enL10n.permanentlyDeleteBody(5),
          isNotEmpty,
          reason: 'EN permanentlyDeleteBody empty',
        );
        expect(
          ruL10n.permanentlyDeleteBody(5),
          isNotEmpty,
          reason: 'RU permanentlyDeleteBody empty',
        );
        // trashIsEmpty
        expect(
          enL10n.trashIsEmpty,
          isNotEmpty,
          reason: 'EN trashIsEmpty empty',
        );
        expect(
          ruL10n.trashIsEmpty,
          isNotEmpty,
          reason: 'RU trashIsEmpty empty',
        );
        // trashRetentionInfo(int days)
        expect(
          enL10n.trashRetentionInfo(5),
          isNotEmpty,
          reason: 'EN trashRetentionInfo empty',
        );
        expect(
          ruL10n.trashRetentionInfo(5),
          isNotEmpty,
          reason: 'RU trashRetentionInfo empty',
        );
        // deletionDate
        expect(
          enL10n.deletionDate,
          isNotEmpty,
          reason: 'EN deletionDate empty',
        );
        expect(
          ruL10n.deletionDate,
          isNotEmpty,
          reason: 'RU deletionDate empty',
        );
        // deletePermanentlyAction
        expect(
          enL10n.deletePermanentlyAction,
          isNotEmpty,
          reason: 'EN deletePermanentlyAction empty',
        );
        expect(
          ruL10n.deletePermanentlyAction,
          isNotEmpty,
          reason: 'RU deletePermanentlyAction empty',
        );
        // conflictFileAlreadyExists
        expect(
          enL10n.conflictFileAlreadyExists,
          isNotEmpty,
          reason: 'EN conflictFileAlreadyExists empty',
        );
        expect(
          ruL10n.conflictFileAlreadyExists,
          isNotEmpty,
          reason: 'RU conflictFileAlreadyExists empty',
        );
        // conflictNofM(int current, int total)
        expect(
          enL10n.conflictNofM(5, 5),
          isNotEmpty,
          reason: 'EN conflictNofM empty',
        );
        expect(
          ruL10n.conflictNofM(5, 5),
          isNotEmpty,
          reason: 'RU conflictNofM empty',
        );
        // conflictAFileNamed
        expect(
          enL10n.conflictAFileNamed,
          isNotEmpty,
          reason: 'EN conflictAFileNamed empty',
        );
        expect(
          ruL10n.conflictAFileNamed,
          isNotEmpty,
          reason: 'RU conflictAFileNamed empty',
        );
        // conflictAlreadyExistsAt
        expect(
          enL10n.conflictAlreadyExistsAt,
          isNotEmpty,
          reason: 'EN conflictAlreadyExistsAt empty',
        );
        expect(
          ruL10n.conflictAlreadyExistsAt,
          isNotEmpty,
          reason: 'RU conflictAlreadyExistsAt empty',
        );
        // conflictAlreadyExistsInFolder
        expect(
          enL10n.conflictAlreadyExistsInFolder,
          isNotEmpty,
          reason: 'EN conflictAlreadyExistsInFolder empty',
        );
        expect(
          ruL10n.conflictAlreadyExistsInFolder,
          isNotEmpty,
          reason: 'RU conflictAlreadyExistsInFolder empty',
        );
        // conflictInFolder
        expect(
          enL10n.conflictInFolder,
          isNotEmpty,
          reason: 'EN conflictInFolder empty',
        );
        expect(
          ruL10n.conflictInFolder,
          isNotEmpty,
          reason: 'RU conflictInFolder empty',
        );
        // conflictFromTrash
        expect(
          enL10n.conflictFromTrash,
          isNotEmpty,
          reason: 'EN conflictFromTrash empty',
        );
        expect(
          ruL10n.conflictFromTrash,
          isNotEmpty,
          reason: 'RU conflictFromTrash empty',
        );
        // conflictExisting
        expect(
          enL10n.conflictExisting,
          isNotEmpty,
          reason: 'EN conflictExisting empty',
        );
        expect(
          ruL10n.conflictExisting,
          isNotEmpty,
          reason: 'RU conflictExisting empty',
        );
        // conflictNewUpload
        expect(
          enL10n.conflictNewUpload,
          isNotEmpty,
          reason: 'EN conflictNewUpload empty',
        );
        expect(
          ruL10n.conflictNewUpload,
          isNotEmpty,
          reason: 'RU conflictNewUpload empty',
        );
        // conflictSizeLabel(String size)
        expect(
          enL10n.conflictSizeLabel('12.5 MB'),
          isNotEmpty,
          reason: 'EN conflictSizeLabel empty',
        );
        expect(
          ruL10n.conflictSizeLabel('12.5 MB'),
          isNotEmpty,
          reason: 'RU conflictSizeLabel empty',
        );
        // conflictDateLabel(String date)
        expect(
          enL10n.conflictDateLabel('2026-08-18'),
          isNotEmpty,
          reason: 'EN conflictDateLabel empty',
        );
        expect(
          ruL10n.conflictDateLabel('2026-08-18'),
          isNotEmpty,
          reason: 'RU conflictDateLabel empty',
        );
        // conflictDeletedLabel(String date)
        expect(
          enL10n.conflictDeletedLabel('2026-08-18'),
          isNotEmpty,
          reason: 'EN conflictDeletedLabel empty',
        );
        expect(
          ruL10n.conflictDeletedLabel('2026-08-18'),
          isNotEmpty,
          reason: 'RU conflictDeletedLabel empty',
        );
        // conflictApplyToRemaining(int count)
        expect(
          enL10n.conflictApplyToRemaining(5),
          isNotEmpty,
          reason: 'EN conflictApplyToRemaining empty',
        );
        expect(
          ruL10n.conflictApplyToRemaining(5),
          isNotEmpty,
          reason: 'RU conflictApplyToRemaining empty',
        );
        // conflictKeepAllCopies
        expect(
          enL10n.conflictKeepAllCopies,
          isNotEmpty,
          reason: 'EN conflictKeepAllCopies empty',
        );
        expect(
          ruL10n.conflictKeepAllCopies,
          isNotEmpty,
          reason: 'RU conflictKeepAllCopies empty',
        );
        // conflictOverwriteAll
        expect(
          enL10n.conflictOverwriteAll,
          isNotEmpty,
          reason: 'EN conflictOverwriteAll empty',
        );
        expect(
          ruL10n.conflictOverwriteAll,
          isNotEmpty,
          reason: 'RU conflictOverwriteAll empty',
        );
        // conflictRestoreAllAsCopies
        expect(
          enL10n.conflictRestoreAllAsCopies,
          isNotEmpty,
          reason: 'EN conflictRestoreAllAsCopies empty',
        );
        expect(
          ruL10n.conflictRestoreAllAsCopies,
          isNotEmpty,
          reason: 'RU conflictRestoreAllAsCopies empty',
        );
        // conflictRestoreAsCopy
        expect(
          enL10n.conflictRestoreAsCopy,
          isNotEmpty,
          reason: 'EN conflictRestoreAsCopy empty',
        );
        expect(
          ruL10n.conflictRestoreAsCopy,
          isNotEmpty,
          reason: 'RU conflictRestoreAsCopy empty',
        );
        // conflictOverwriteAllRemaining
        expect(
          enL10n.conflictOverwriteAllRemaining,
          isNotEmpty,
          reason: 'EN conflictOverwriteAllRemaining empty',
        );
        expect(
          ruL10n.conflictOverwriteAllRemaining,
          isNotEmpty,
          reason: 'RU conflictOverwriteAllRemaining empty',
        );
        // conflictSkipAll
        expect(
          enL10n.conflictSkipAll,
          isNotEmpty,
          reason: 'EN conflictSkipAll empty',
        );
        expect(
          ruL10n.conflictSkipAll,
          isNotEmpty,
          reason: 'RU conflictSkipAll empty',
        );
        // conflictSkipAllRemaining
        expect(
          enL10n.conflictSkipAllRemaining,
          isNotEmpty,
          reason: 'EN conflictSkipAllRemaining empty',
        );
        expect(
          ruL10n.conflictSkipAllRemaining,
          isNotEmpty,
          reason: 'RU conflictSkipAllRemaining empty',
        );
        // conflictSkip
        expect(
          enL10n.conflictSkip,
          isNotEmpty,
          reason: 'EN conflictSkip empty',
        );
        expect(
          ruL10n.conflictSkip,
          isNotEmpty,
          reason: 'RU conflictSkip empty',
        );
        // conflictOverwrite
        expect(
          enL10n.conflictOverwrite,
          isNotEmpty,
          reason: 'EN conflictOverwrite empty',
        );
        expect(
          ruL10n.conflictOverwrite,
          isNotEmpty,
          reason: 'RU conflictOverwrite empty',
        );
        // transfersTitle
        expect(
          enL10n.transfersTitle,
          isNotEmpty,
          reason: 'EN transfersTitle empty',
        );
        expect(
          ruL10n.transfersTitle,
          isNotEmpty,
          reason: 'RU transfersTitle empty',
        );
        // transferResume
        expect(
          enL10n.transferResume,
          isNotEmpty,
          reason: 'EN transferResume empty',
        );
        expect(
          ruL10n.transferResume,
          isNotEmpty,
          reason: 'RU transferResume empty',
        );
        // transferPause
        expect(
          enL10n.transferPause,
          isNotEmpty,
          reason: 'EN transferPause empty',
        );
        expect(
          ruL10n.transferPause,
          isNotEmpty,
          reason: 'RU transferPause empty',
        );
        // transferCancel
        expect(
          enL10n.transferCancel,
          isNotEmpty,
          reason: 'EN transferCancel empty',
        );
        expect(
          ruL10n.transferCancel,
          isNotEmpty,
          reason: 'RU transferCancel empty',
        );
        // transferResumeAll
        expect(
          enL10n.transferResumeAll,
          isNotEmpty,
          reason: 'EN transferResumeAll empty',
        );
        expect(
          ruL10n.transferResumeAll,
          isNotEmpty,
          reason: 'RU transferResumeAll empty',
        );
        // transferPauseAll
        expect(
          enL10n.transferPauseAll,
          isNotEmpty,
          reason: 'EN transferPauseAll empty',
        );
        expect(
          ruL10n.transferPauseAll,
          isNotEmpty,
          reason: 'RU transferPauseAll empty',
        );
        // transferCancelAll
        expect(
          enL10n.transferCancelAll,
          isNotEmpty,
          reason: 'EN transferCancelAll empty',
        );
        expect(
          ruL10n.transferCancelAll,
          isNotEmpty,
          reason: 'RU transferCancelAll empty',
        );
        // transferCancelFile
        expect(
          enL10n.transferCancelFile,
          isNotEmpty,
          reason: 'EN transferCancelFile empty',
        );
        expect(
          ruL10n.transferCancelFile,
          isNotEmpty,
          reason: 'RU transferCancelFile empty',
        );
        // noTransfers
        expect(enL10n.noTransfers, isNotEmpty, reason: 'EN noTransfers empty');
        expect(ruL10n.noTransfers, isNotEmpty, reason: 'RU noTransfers empty');
        // transferStatusQueued
        expect(
          enL10n.transferStatusQueued,
          isNotEmpty,
          reason: 'EN transferStatusQueued empty',
        );
        expect(
          ruL10n.transferStatusQueued,
          isNotEmpty,
          reason: 'RU transferStatusQueued empty',
        );
        // transferStatusRunning
        expect(
          enL10n.transferStatusRunning,
          isNotEmpty,
          reason: 'EN transferStatusRunning empty',
        );
        expect(
          ruL10n.transferStatusRunning,
          isNotEmpty,
          reason: 'RU transferStatusRunning empty',
        );
        // transferStatusPaused
        expect(
          enL10n.transferStatusPaused,
          isNotEmpty,
          reason: 'EN transferStatusPaused empty',
        );
        expect(
          ruL10n.transferStatusPaused,
          isNotEmpty,
          reason: 'RU transferStatusPaused empty',
        );
        // transferStatusCompleted
        expect(
          enL10n.transferStatusCompleted,
          isNotEmpty,
          reason: 'EN transferStatusCompleted empty',
        );
        expect(
          ruL10n.transferStatusCompleted,
          isNotEmpty,
          reason: 'RU transferStatusCompleted empty',
        );
        // transferStatusFailed
        expect(
          enL10n.transferStatusFailed,
          isNotEmpty,
          reason: 'EN transferStatusFailed empty',
        );
        expect(
          ruL10n.transferStatusFailed,
          isNotEmpty,
          reason: 'RU transferStatusFailed empty',
        );
        // transferStatusCanceled
        expect(
          enL10n.transferStatusCanceled,
          isNotEmpty,
          reason: 'EN transferStatusCanceled empty',
        );
        expect(
          ruL10n.transferStatusCanceled,
          isNotEmpty,
          reason: 'RU transferStatusCanceled empty',
        );
        // themePresetsSection
        expect(
          enL10n.themePresetsSection,
          isNotEmpty,
          reason: 'EN themePresetsSection empty',
        );
        expect(
          ruL10n.themePresetsSection,
          isNotEmpty,
          reason: 'RU themePresetsSection empty',
        );
        // themeCustomPaletteSection
        expect(
          enL10n.themeCustomPaletteSection,
          isNotEmpty,
          reason: 'EN themeCustomPaletteSection empty',
        );
        expect(
          ruL10n.themeCustomPaletteSection,
          isNotEmpty,
          reason: 'RU themeCustomPaletteSection empty',
        );
        // themeHexRgbLabel
        expect(
          enL10n.themeHexRgbLabel,
          isNotEmpty,
          reason: 'EN themeHexRgbLabel empty',
        );
        expect(
          ruL10n.themeHexRgbLabel,
          isNotEmpty,
          reason: 'RU themeHexRgbLabel empty',
        );
        // themeHexRgbHint
        expect(
          enL10n.themeHexRgbHint,
          isNotEmpty,
          reason: 'EN themeHexRgbHint empty',
        );
        expect(
          ruL10n.themeHexRgbHint,
          isNotEmpty,
          reason: 'RU themeHexRgbHint empty',
        );
        // imageViewerNoFetchHandler
        expect(
          enL10n.imageViewerNoFetchHandler,
          isNotEmpty,
          reason: 'EN imageViewerNoFetchHandler empty',
        );
        expect(
          ruL10n.imageViewerNoFetchHandler,
          isNotEmpty,
          reason: 'RU imageViewerNoFetchHandler empty',
        );
        // imageViewerFailedToLoad
        expect(
          enL10n.imageViewerFailedToLoad,
          isNotEmpty,
          reason: 'EN imageViewerFailedToLoad empty',
        );
        expect(
          ruL10n.imageViewerFailedToLoad,
          isNotEmpty,
          reason: 'RU imageViewerFailedToLoad empty',
        );
        // errorDeletingFile(String filename, String error)
        expect(
          enL10n.errorDeletingFile('document.pdf', 'Network timeout'),
          isNotEmpty,
          reason: 'EN errorDeletingFile empty',
        );
        expect(
          ruL10n.errorDeletingFile('document.pdf', 'Network timeout'),
          isNotEmpty,
          reason: 'RU errorDeletingFile empty',
        );
        // errorReadingFile(String error)
        expect(
          enL10n.errorReadingFile('Network timeout'),
          isNotEmpty,
          reason: 'EN errorReadingFile empty',
        );
        expect(
          ruL10n.errorReadingFile('Network timeout'),
          isNotEmpty,
          reason: 'RU errorReadingFile empty',
        );
        // syncChannelName
        expect(
          enL10n.syncChannelName,
          isNotEmpty,
          reason: 'EN syncChannelName empty',
        );
        expect(
          ruL10n.syncChannelName,
          isNotEmpty,
          reason: 'RU syncChannelName empty',
        );
        // syncChannelDescription
        expect(
          enL10n.syncChannelDescription,
          isNotEmpty,
          reason: 'EN syncChannelDescription empty',
        );
        expect(
          ruL10n.syncChannelDescription,
          isNotEmpty,
          reason: 'RU syncChannelDescription empty',
        );
        // storageStatsTitle
        expect(
          enL10n.storageStatsTitle,
          isNotEmpty,
          reason: 'EN storageStatsTitle empty',
        );
        expect(
          ruL10n.storageStatsTitle,
          isNotEmpty,
          reason: 'RU storageStatsTitle empty',
        );
        // storageStatsUsedSpace
        expect(
          enL10n.storageStatsUsedSpace,
          isNotEmpty,
          reason: 'EN storageStatsUsedSpace empty',
        );
        expect(
          ruL10n.storageStatsUsedSpace,
          isNotEmpty,
          reason: 'RU storageStatsUsedSpace empty',
        );
        // storageStatsTotalFiles
        expect(
          enL10n.storageStatsTotalFiles,
          isNotEmpty,
          reason: 'EN storageStatsTotalFiles empty',
        );
        expect(
          ruL10n.storageStatsTotalFiles,
          isNotEmpty,
          reason: 'RU storageStatsTotalFiles empty',
        );
        // storageStatsNItems(int count)
        expect(
          enL10n.storageStatsNItems(5),
          isNotEmpty,
          reason: 'EN storageStatsNItems empty',
        );
        expect(
          ruL10n.storageStatsNItems(5),
          isNotEmpty,
          reason: 'RU storageStatsNItems empty',
        );
        // userFallback(int userId)
        expect(
          enL10n.userFallback(42),
          isNotEmpty,
          reason: 'EN userFallback empty',
        );
        expect(
          ruL10n.userFallback(42),
          isNotEmpty,
          reason: 'RU userFallback empty',
        );
        // biometricUnlockReason
        expect(
          enL10n.biometricUnlockReason,
          isNotEmpty,
          reason: 'EN biometricUnlockReason empty',
        );
        expect(
          ruL10n.biometricUnlockReason,
          isNotEmpty,
          reason: 'RU biometricUnlockReason empty',
        );
        // tokenLifetimeEveryOpen
        expect(
          enL10n.tokenLifetimeEveryOpen,
          isNotEmpty,
          reason: 'EN tokenLifetimeEveryOpen empty',
        );
        expect(
          ruL10n.tokenLifetimeEveryOpen,
          isNotEmpty,
          reason: 'RU tokenLifetimeEveryOpen empty',
        );
        // tokenLifetimeOneHour
        expect(
          enL10n.tokenLifetimeOneHour,
          isNotEmpty,
          reason: 'EN tokenLifetimeOneHour empty',
        );
        expect(
          ruL10n.tokenLifetimeOneHour,
          isNotEmpty,
          reason: 'RU tokenLifetimeOneHour empty',
        );
        // tokenLifetime1Hour
        expect(
          enL10n.tokenLifetime1Hour,
          isNotEmpty,
          reason: 'EN tokenLifetime1Hour empty',
        );
        expect(
          ruL10n.tokenLifetime1Hour,
          isNotEmpty,
          reason: 'RU tokenLifetime1Hour empty',
        );
        // tokenLifetimeOneDay
        expect(
          enL10n.tokenLifetimeOneDay,
          isNotEmpty,
          reason: 'EN tokenLifetimeOneDay empty',
        );
        expect(
          ruL10n.tokenLifetimeOneDay,
          isNotEmpty,
          reason: 'RU tokenLifetimeOneDay empty',
        );
        // tokenLifetime1Day
        expect(
          enL10n.tokenLifetime1Day,
          isNotEmpty,
          reason: 'EN tokenLifetime1Day empty',
        );
        expect(
          ruL10n.tokenLifetime1Day,
          isNotEmpty,
          reason: 'RU tokenLifetime1Day empty',
        );
        // tokenLifetimeOneWeek
        expect(
          enL10n.tokenLifetimeOneWeek,
          isNotEmpty,
          reason: 'EN tokenLifetimeOneWeek empty',
        );
        expect(
          ruL10n.tokenLifetimeOneWeek,
          isNotEmpty,
          reason: 'RU tokenLifetimeOneWeek empty',
        );
        // tokenLifetime1Week
        expect(
          enL10n.tokenLifetime1Week,
          isNotEmpty,
          reason: 'EN tokenLifetime1Week empty',
        );
        expect(
          ruL10n.tokenLifetime1Week,
          isNotEmpty,
          reason: 'RU tokenLifetime1Week empty',
        );
        // tokenLifetimeOneMonth
        expect(
          enL10n.tokenLifetimeOneMonth,
          isNotEmpty,
          reason: 'EN tokenLifetimeOneMonth empty',
        );
        expect(
          ruL10n.tokenLifetimeOneMonth,
          isNotEmpty,
          reason: 'RU tokenLifetimeOneMonth empty',
        );
        // tokenLifetime1Month
        expect(
          enL10n.tokenLifetime1Month,
          isNotEmpty,
          reason: 'EN tokenLifetime1Month empty',
        );
        expect(
          ruL10n.tokenLifetime1Month,
          isNotEmpty,
          reason: 'RU tokenLifetime1Month empty',
        );
        // tokenLifetimeThreeMonths
        expect(
          enL10n.tokenLifetimeThreeMonths,
          isNotEmpty,
          reason: 'EN tokenLifetimeThreeMonths empty',
        );
        expect(
          ruL10n.tokenLifetimeThreeMonths,
          isNotEmpty,
          reason: 'RU tokenLifetimeThreeMonths empty',
        );
        // tokenLifetime3Months
        expect(
          enL10n.tokenLifetime3Months,
          isNotEmpty,
          reason: 'EN tokenLifetime3Months empty',
        );
        expect(
          ruL10n.tokenLifetime3Months,
          isNotEmpty,
          reason: 'RU tokenLifetime3Months empty',
        );
        // tokenLifetimeNever
        expect(
          enL10n.tokenLifetimeNever,
          isNotEmpty,
          reason: 'EN tokenLifetimeNever empty',
        );
        expect(
          ruL10n.tokenLifetimeNever,
          isNotEmpty,
          reason: 'RU tokenLifetimeNever empty',
        );
        // cacheLimitUnlimited
        expect(
          enL10n.cacheLimitUnlimited,
          isNotEmpty,
          reason: 'EN cacheLimitUnlimited empty',
        );
        expect(
          ruL10n.cacheLimitUnlimited,
          isNotEmpty,
          reason: 'RU cacheLimitUnlimited empty',
        );
        // syncCategoryOtherFiles
        expect(
          enL10n.syncCategoryOtherFiles,
          isNotEmpty,
          reason: 'EN syncCategoryOtherFiles empty',
        );
        expect(
          ruL10n.syncCategoryOtherFiles,
          isNotEmpty,
          reason: 'RU syncCategoryOtherFiles empty',
        );
        // internalStorage
        expect(
          enL10n.internalStorage,
          isNotEmpty,
          reason: 'EN internalStorage empty',
        );
        expect(
          ruL10n.internalStorage,
          isNotEmpty,
          reason: 'RU internalStorage empty',
        );
        // localStorageRootName
        expect(
          enL10n.localStorageRootName,
          isNotEmpty,
          reason: 'EN localStorageRootName empty',
        );
        expect(
          ruL10n.localStorageRootName,
          isNotEmpty,
          reason: 'RU localStorageRootName empty',
        );
        // syncNotificationSyncingWith(String serverName)
        expect(
          enL10n.syncNotificationSyncingWith('document.pdf'),
          isNotEmpty,
          reason: 'EN syncNotificationSyncingWith empty',
        );
        expect(
          ruL10n.syncNotificationSyncingWith('document.pdf'),
          isNotEmpty,
          reason: 'RU syncNotificationSyncingWith empty',
        );
        // syncNotificationPausedTitle(String serverName)
        expect(
          enL10n.syncNotificationPausedTitle('document.pdf'),
          isNotEmpty,
          reason: 'EN syncNotificationPausedTitle empty',
        );
        expect(
          ruL10n.syncNotificationPausedTitle('document.pdf'),
          isNotEmpty,
          reason: 'RU syncNotificationPausedTitle empty',
        );
        // syncNotificationUnreachableBody
        expect(
          enL10n.syncNotificationUnreachableBody,
          isNotEmpty,
          reason: 'EN syncNotificationUnreachableBody empty',
        );
        expect(
          ruL10n.syncNotificationUnreachableBody,
          isNotEmpty,
          reason: 'RU syncNotificationUnreachableBody empty',
        );
        // syncNotificationAuthRequiredBody
        expect(
          enL10n.syncNotificationAuthRequiredBody,
          isNotEmpty,
          reason: 'EN syncNotificationAuthRequiredBody empty',
        );
        expect(
          ruL10n.syncNotificationAuthRequiredBody,
          isNotEmpty,
          reason: 'RU syncNotificationAuthRequiredBody empty',
        );
        // syncNotificationFailedTitle(String serverName)
        expect(
          enL10n.syncNotificationFailedTitle('document.pdf'),
          isNotEmpty,
          reason: 'EN syncNotificationFailedTitle empty',
        );
        expect(
          ruL10n.syncNotificationFailedTitle('document.pdf'),
          isNotEmpty,
          reason: 'RU syncNotificationFailedTitle empty',
        );
        // syncNotificationGenericErrorBody
        expect(
          enL10n.syncNotificationGenericErrorBody,
          isNotEmpty,
          reason: 'EN syncNotificationGenericErrorBody empty',
        );
        expect(
          ruL10n.syncNotificationGenericErrorBody,
          isNotEmpty,
          reason: 'RU syncNotificationGenericErrorBody empty',
        );
        // syncNotificationCompleteTitle(String serverName)
        expect(
          enL10n.syncNotificationCompleteTitle('document.pdf'),
          isNotEmpty,
          reason: 'EN syncNotificationCompleteTitle empty',
        );
        expect(
          ruL10n.syncNotificationCompleteTitle('document.pdf'),
          isNotEmpty,
          reason: 'RU syncNotificationCompleteTitle empty',
        );
        // syncNotificationCompleteBody
        expect(
          enL10n.syncNotificationCompleteBody,
          isNotEmpty,
          reason: 'EN syncNotificationCompleteBody empty',
        );
        expect(
          ruL10n.syncNotificationCompleteBody,
          isNotEmpty,
          reason: 'RU syncNotificationCompleteBody empty',
        );
        // syncStatusConnecting
        expect(
          enL10n.syncStatusConnecting,
          isNotEmpty,
          reason: 'EN syncStatusConnecting empty',
        );
        expect(
          ruL10n.syncStatusConnecting,
          isNotEmpty,
          reason: 'RU syncStatusConnecting empty',
        );
        // syncStatusConnectionLost(String serverName)
        expect(
          enL10n.syncStatusConnectionLost('document.pdf'),
          isNotEmpty,
          reason: 'EN syncStatusConnectionLost empty',
        );
        expect(
          ruL10n.syncStatusConnectionLost('document.pdf'),
          isNotEmpty,
          reason: 'RU syncStatusConnectionLost empty',
        );
        // syncResultServerUnreachableWithServer(String serverName)
        expect(
          enL10n.syncResultServerUnreachableWithServer('document.pdf'),
          isNotEmpty,
          reason: 'EN syncResultServerUnreachableWithServer empty',
        );
        expect(
          ruL10n.syncResultServerUnreachableWithServer('document.pdf'),
          isNotEmpty,
          reason: 'RU syncResultServerUnreachableWithServer empty',
        );
        // syncStatusScanningFiles
        expect(
          enL10n.syncStatusScanningFiles,
          isNotEmpty,
          reason: 'EN syncStatusScanningFiles empty',
        );
        expect(
          ruL10n.syncStatusScanningFiles,
          isNotEmpty,
          reason: 'RU syncStatusScanningFiles empty',
        );
        // syncStatusNoFilesFound
        expect(
          enL10n.syncStatusNoFilesFound,
          isNotEmpty,
          reason: 'EN syncStatusNoFilesFound empty',
        );
        expect(
          ruL10n.syncStatusNoFilesFound,
          isNotEmpty,
          reason: 'RU syncStatusNoFilesFound empty',
        );
        // syncStatusNoFilesSelected
        expect(
          enL10n.syncStatusNoFilesSelected,
          isNotEmpty,
          reason: 'EN syncStatusNoFilesSelected empty',
        );
        expect(
          ruL10n.syncStatusNoFilesSelected,
          isNotEmpty,
          reason: 'RU syncStatusNoFilesSelected empty',
        );
        // syncStatusCalculatingChecksum(int current, int total, String filename)
        expect(
          enL10n.syncStatusCalculatingChecksum(5, 5, 'document.pdf'),
          isNotEmpty,
          reason: 'EN syncStatusCalculatingChecksum empty',
        );
        expect(
          ruL10n.syncStatusCalculatingChecksum(5, 5, 'document.pdf'),
          isNotEmpty,
          reason: 'RU syncStatusCalculatingChecksum empty',
        );
        // syncStatusCheckingDuplicates
        expect(
          enL10n.syncStatusCheckingDuplicates,
          isNotEmpty,
          reason: 'EN syncStatusCheckingDuplicates empty',
        );
        expect(
          ruL10n.syncStatusCheckingDuplicates,
          isNotEmpty,
          reason: 'RU syncStatusCheckingDuplicates empty',
        );
        // syncStatusSyncingFile(int current, int total, String filename)
        expect(
          enL10n.syncStatusSyncingFile(5, 5, 'document.pdf'),
          isNotEmpty,
          reason: 'EN syncStatusSyncingFile empty',
        );
        expect(
          ruL10n.syncStatusSyncingFile(5, 5, 'document.pdf'),
          isNotEmpty,
          reason: 'RU syncStatusSyncingFile empty',
        );
        // syncStatusCompleting
        expect(
          enL10n.syncStatusCompleting,
          isNotEmpty,
          reason: 'EN syncStatusCompleting empty',
        );
        expect(
          ruL10n.syncStatusCompleting,
          isNotEmpty,
          reason: 'RU syncStatusCompleting empty',
        );
        // showingCachedFiles
        expect(
          enL10n.showingCachedFiles,
          isNotEmpty,
          reason: 'EN showingCachedFiles empty',
        );
        expect(
          ruL10n.showingCachedFiles,
          isNotEmpty,
          reason: 'RU showingCachedFiles empty',
        );
        // showingCachedFilesRefreshFailed
        expect(
          enL10n.showingCachedFilesRefreshFailed,
          isNotEmpty,
          reason: 'EN showingCachedFilesRefreshFailed empty',
        );
        expect(
          ruL10n.showingCachedFilesRefreshFailed,
          isNotEmpty,
          reason: 'RU showingCachedFilesRefreshFailed empty',
        );
        // downloadCanceled
        expect(
          enL10n.downloadCanceled,
          isNotEmpty,
          reason: 'EN downloadCanceled empty',
        );
        expect(
          ruL10n.downloadCanceled,
          isNotEmpty,
          reason: 'RU downloadCanceled empty',
        );
        // downloadedNFilesToPath(int count, String path)
        expect(
          enL10n.downloadedNFilesToPath(5, '/storage/emulated/0/Download'),
          isNotEmpty,
          reason: 'EN downloadedNFilesToPath empty',
        );
        expect(
          ruL10n.downloadedNFilesToPath(5, '/storage/emulated/0/Download'),
          isNotEmpty,
          reason: 'RU downloadedNFilesToPath empty',
        );
        // downloadedNFilesFailedM(int downloaded, int failed, String detail)
        expect(
          enL10n.downloadedNFilesFailedM(5, 5, 'Network timeout'),
          isNotEmpty,
          reason: 'EN downloadedNFilesFailedM empty',
        );
        expect(
          ruL10n.downloadedNFilesFailedM(5, 5, 'Network timeout'),
          isNotEmpty,
          reason: 'RU downloadedNFilesFailedM empty',
        );
        // downloadedNFilesWithFailures(int count, int failed, String error)
        expect(
          enL10n.downloadedNFilesWithFailures(5, 5, 'Network timeout'),
          isNotEmpty,
          reason: 'EN downloadedNFilesWithFailures empty',
        );
        expect(
          ruL10n.downloadedNFilesWithFailures(5, 5, 'Network timeout'),
          isNotEmpty,
          reason: 'RU downloadedNFilesWithFailures empty',
        );
        // createdNShareLinks(int count)
        expect(
          enL10n.createdNShareLinks(5),
          isNotEmpty,
          reason: 'EN createdNShareLinks empty',
        );
        expect(
          ruL10n.createdNShareLinks(5),
          isNotEmpty,
          reason: 'RU createdNShareLinks empty',
        );
        // failedToCreateShareLinks
        expect(
          enL10n.failedToCreateShareLinks,
          isNotEmpty,
          reason: 'EN failedToCreateShareLinks empty',
        );
        expect(
          ruL10n.failedToCreateShareLinks,
          isNotEmpty,
          reason: 'RU failedToCreateShareLinks empty',
        );
        // alreadyInSharedScope
        expect(
          enL10n.alreadyInSharedScope,
          isNotEmpty,
          reason: 'EN alreadyInSharedScope empty',
        );
        expect(
          ruL10n.alreadyInSharedScope,
          isNotEmpty,
          reason: 'RU alreadyInSharedScope empty',
        );
        // sharedNItemsInServer(int count)
        expect(
          enL10n.sharedNItemsInServer(5),
          isNotEmpty,
          reason: 'EN sharedNItemsInServer empty',
        );
        expect(
          ruL10n.sharedNItemsInServer(5),
          isNotEmpty,
          reason: 'RU sharedNItemsInServer empty',
        );
        // sharedNItemsWithFailures(int count, int failed)
        expect(
          enL10n.sharedNItemsWithFailures(5, 5),
          isNotEmpty,
          reason: 'EN sharedNItemsWithFailures empty',
        );
        expect(
          ruL10n.sharedNItemsWithFailures(5, 5),
          isNotEmpty,
          reason: 'RU sharedNItemsWithFailures empty',
        );
        // sharedNItemsFailedM(int shared, int failed)
        expect(
          enL10n.sharedNItemsFailedM(5, 5),
          isNotEmpty,
          reason: 'EN sharedNItemsFailedM empty',
        );
        expect(
          ruL10n.sharedNItemsFailedM(5, 5),
          isNotEmpty,
          reason: 'RU sharedNItemsFailedM empty',
        );
        // folderNameCannotBeEmpty
        expect(
          enL10n.folderNameCannotBeEmpty,
          isNotEmpty,
          reason: 'EN folderNameCannotBeEmpty empty',
        );
        expect(
          ruL10n.folderNameCannotBeEmpty,
          isNotEmpty,
          reason: 'RU folderNameCannotBeEmpty empty',
        );
        // folderAlreadyExists
        expect(
          enL10n.folderAlreadyExists,
          isNotEmpty,
          reason: 'EN folderAlreadyExists empty',
        );
        expect(
          ruL10n.folderAlreadyExists,
          isNotEmpty,
          reason: 'RU folderAlreadyExists empty',
        );
        // folderCreationOnlyInAllFiles
        expect(
          enL10n.folderCreationOnlyInAllFiles,
          isNotEmpty,
          reason: 'EN folderCreationOnlyInAllFiles empty',
        );
        expect(
          ruL10n.folderCreationOnlyInAllFiles,
          isNotEmpty,
          reason: 'RU folderCreationOnlyInAllFiles empty',
        );
        // currentDirectoryUnavailable
        expect(
          enL10n.currentDirectoryUnavailable,
          isNotEmpty,
          reason: 'EN currentDirectoryUnavailable empty',
        );
        expect(
          ruL10n.currentDirectoryUnavailable,
          isNotEmpty,
          reason: 'RU currentDirectoryUnavailable empty',
        );
        // nothingSelected
        expect(
          enL10n.nothingSelected,
          isNotEmpty,
          reason: 'EN nothingSelected empty',
        );
        expect(
          ruL10n.nothingSelected,
          isNotEmpty,
          reason: 'RU nothingSelected empty',
        );
        // destinationFolderDoesNotExist
        expect(
          enL10n.destinationFolderDoesNotExist,
          isNotEmpty,
          reason: 'EN destinationFolderDoesNotExist empty',
        );
        expect(
          ruL10n.destinationFolderDoesNotExist,
          isNotEmpty,
          reason: 'RU destinationFolderDoesNotExist empty',
        );
        // cannotMoveFolderIntoItself(String name)
        expect(
          enL10n.cannotMoveFolderIntoItself('document.pdf'),
          isNotEmpty,
          reason: 'EN cannotMoveFolderIntoItself empty',
        );
        expect(
          ruL10n.cannotMoveFolderIntoItself('document.pdf'),
          isNotEmpty,
          reason: 'RU cannotMoveFolderIntoItself empty',
        );
        // failedToMoveItem(String name, String error)
        expect(
          enL10n.failedToMoveItem('document.pdf', 'Network timeout'),
          isNotEmpty,
          reason: 'EN failedToMoveItem empty',
        );
        expect(
          ruL10n.failedToMoveItem('document.pdf', 'Network timeout'),
          isNotEmpty,
          reason: 'RU failedToMoveItem empty',
        );
        // movedNItems(int count)
        expect(
          enL10n.movedNItems(5),
          isNotEmpty,
          reason: 'EN movedNItems empty',
        );
        expect(
          ruL10n.movedNItems(5),
          isNotEmpty,
          reason: 'RU movedNItems empty',
        );
        // movedNItemsWithFailures(int count, int failed)
        expect(
          enL10n.movedNItemsWithFailures(5, 5),
          isNotEmpty,
          reason: 'EN movedNItemsWithFailures empty',
        );
        expect(
          ruL10n.movedNItemsWithFailures(5, 5),
          isNotEmpty,
          reason: 'RU movedNItemsWithFailures empty',
        );
        // movedNItemsFailedM(int moved, int failed)
        expect(
          enL10n.movedNItemsFailedM(5, 5),
          isNotEmpty,
          reason: 'EN movedNItemsFailedM empty',
        );
        expect(
          ruL10n.movedNItemsFailedM(5, 5),
          isNotEmpty,
          reason: 'RU movedNItemsFailedM empty',
        );
        // failedToMoveSelectedItems
        expect(
          enL10n.failedToMoveSelectedItems,
          isNotEmpty,
          reason: 'EN failedToMoveSelectedItems empty',
        );
        expect(
          ruL10n.failedToMoveSelectedItems,
          isNotEmpty,
          reason: 'RU failedToMoveSelectedItems empty',
        );
        // noFilesWereMoved
        expect(
          enL10n.noFilesWereMoved,
          isNotEmpty,
          reason: 'EN noFilesWereMoved empty',
        );
        expect(
          ruL10n.noFilesWereMoved,
          isNotEmpty,
          reason: 'RU noFilesWereMoved empty',
        );
        // renamedOldToNew(String oldName, String newName)
        expect(
          enL10n.renamedOldToNew('document.pdf', 'document.pdf'),
          isNotEmpty,
          reason: 'EN renamedOldToNew empty',
        );
        expect(
          ruL10n.renamedOldToNew('document.pdf', 'document.pdf'),
          isNotEmpty,
          reason: 'RU renamedOldToNew empty',
        );
        // renamedFileFromTo(String oldName, String newName)
        expect(
          enL10n.renamedFileFromTo('document.pdf', 'document.pdf'),
          isNotEmpty,
          reason: 'EN renamedFileFromTo empty',
        );
        expect(
          ruL10n.renamedFileFromTo('document.pdf', 'document.pdf'),
          isNotEmpty,
          reason: 'RU renamedFileFromTo empty',
        );
        // failedToRenameWithStatus(String name, int statusCode)
        expect(
          enL10n.failedToRenameWithStatus('document.pdf', 404),
          isNotEmpty,
          reason: 'EN failedToRenameWithStatus empty',
        );
        expect(
          ruL10n.failedToRenameWithStatus('document.pdf', 404),
          isNotEmpty,
          reason: 'RU failedToRenameWithStatus empty',
        );
        // failedToRenameFileWithCode(String name, int statusCode)
        expect(
          enL10n.failedToRenameFileWithCode('document.pdf', 404),
          isNotEmpty,
          reason: 'EN failedToRenameFileWithCode empty',
        );
        expect(
          ruL10n.failedToRenameFileWithCode('document.pdf', 404),
          isNotEmpty,
          reason: 'RU failedToRenameFileWithCode empty',
        );
        // failedToRenameWithError(String name, String error)
        expect(
          enL10n.failedToRenameWithError('document.pdf', 'Network timeout'),
          isNotEmpty,
          reason: 'EN failedToRenameWithError empty',
        );
        expect(
          ruL10n.failedToRenameWithError('document.pdf', 'Network timeout'),
          isNotEmpty,
          reason: 'RU failedToRenameWithError empty',
        );
        // failedToRenameFile(String name, String error)
        expect(
          enL10n.failedToRenameFile('document.pdf', 'Network timeout'),
          isNotEmpty,
          reason: 'EN failedToRenameFile empty',
        );
        expect(
          ruL10n.failedToRenameFile('document.pdf', 'Network timeout'),
          isNotEmpty,
          reason: 'RU failedToRenameFile empty',
        );
        // renameConflictAlreadyExists
        expect(
          enL10n.renameConflictAlreadyExists,
          isNotEmpty,
          reason: 'EN renameConflictAlreadyExists empty',
        );
        expect(
          ruL10n.renameConflictAlreadyExists,
          isNotEmpty,
          reason: 'RU renameConflictAlreadyExists empty',
        );
        // renameFailedAlreadyExists
        expect(
          enL10n.renameFailedAlreadyExists,
          isNotEmpty,
          reason: 'EN renameFailedAlreadyExists empty',
        );
        expect(
          ruL10n.renameFailedAlreadyExists,
          isNotEmpty,
          reason: 'RU renameFailedAlreadyExists empty',
        );
        // failedToCreateFolderWithCode(int statusCode)
        expect(
          enL10n.failedToCreateFolderWithCode(404),
          isNotEmpty,
          reason: 'EN failedToCreateFolderWithCode empty',
        );
        expect(
          ruL10n.failedToCreateFolderWithCode(404),
          isNotEmpty,
          reason: 'RU failedToCreateFolderWithCode empty',
        );
        // deletedNItemsFailedM(int deleted, int failed)
        expect(
          enL10n.deletedNItemsFailedM(5, 5),
          isNotEmpty,
          reason: 'EN deletedNItemsFailedM empty',
        );
        expect(
          ruL10n.deletedNItemsFailedM(5, 5),
          isNotEmpty,
          reason: 'RU deletedNItemsFailedM empty',
        );
        // transferSummaryFiles(int percent, int completed, int total)
        expect(
          enL10n.transferSummaryFiles(75, 5, 5),
          isNotEmpty,
          reason: 'EN transferSummaryFiles empty',
        );
        expect(
          ruL10n.transferSummaryFiles(75, 5, 5),
          isNotEmpty,
          reason: 'RU transferSummaryFiles empty',
        );
        // transferSummaryProgress(int percent, int completed, int total)
        expect(
          enL10n.transferSummaryProgress(75, 5, 5),
          isNotEmpty,
          reason: 'EN transferSummaryProgress empty',
        );
        expect(
          ruL10n.transferSummaryProgress(75, 5, 5),
          isNotEmpty,
          reason: 'RU transferSummaryProgress empty',
        );
        // downloadFailedGeneric
        expect(
          enL10n.downloadFailedGeneric,
          isNotEmpty,
          reason: 'EN downloadFailedGeneric empty',
        );
        expect(
          ruL10n.downloadFailedGeneric,
          isNotEmpty,
          reason: 'RU downloadFailedGeneric empty',
        );
        // uploadedNItemsWithFailures(int uploaded, int failed)
        expect(
          enL10n.uploadedNItemsWithFailures(5, 5),
          isNotEmpty,
          reason: 'EN uploadedNItemsWithFailures empty',
        );
        expect(
          ruL10n.uploadedNItemsWithFailures(5, 5),
          isNotEmpty,
          reason: 'RU uploadedNItemsWithFailures empty',
        );
        // uploadedNItemsFailedM(int uploaded, int failed)
        expect(
          enL10n.uploadedNItemsFailedM(5, 5),
          isNotEmpty,
          reason: 'EN uploadedNItemsFailedM empty',
        );
        expect(
          ruL10n.uploadedNItemsFailedM(5, 5),
          isNotEmpty,
          reason: 'RU uploadedNItemsFailedM empty',
        );
        // uploadSummaryFailedCount(int count)
        expect(
          enL10n.uploadSummaryFailedCount(5),
          isNotEmpty,
          reason: 'EN uploadSummaryFailedCount empty',
        );
        expect(
          ruL10n.uploadSummaryFailedCount(5),
          isNotEmpty,
          reason: 'RU uploadSummaryFailedCount empty',
        );
        // uploadLocalPathEmpty(String name)
        expect(
          enL10n.uploadLocalPathEmpty('document.pdf'),
          isNotEmpty,
          reason: 'EN uploadLocalPathEmpty empty',
        );
        expect(
          ruL10n.uploadLocalPathEmpty('document.pdf'),
          isNotEmpty,
          reason: 'RU uploadLocalPathEmpty empty',
        );
        // uploadErrorLocalPathEmpty(String name)
        expect(
          enL10n.uploadErrorLocalPathEmpty('document.pdf'),
          isNotEmpty,
          reason: 'EN uploadErrorLocalPathEmpty empty',
        );
        expect(
          ruL10n.uploadErrorLocalPathEmpty('document.pdf'),
          isNotEmpty,
          reason: 'RU uploadErrorLocalPathEmpty empty',
        );
        // directoryUploadFailed
        expect(
          enL10n.directoryUploadFailed,
          isNotEmpty,
          reason: 'EN directoryUploadFailed empty',
        );
        expect(
          ruL10n.directoryUploadFailed,
          isNotEmpty,
          reason: 'RU directoryUploadFailed empty',
        );
        // uploadDirectoryFailed
        expect(
          enL10n.uploadDirectoryFailed,
          isNotEmpty,
          reason: 'EN uploadDirectoryFailed empty',
        );
        expect(
          ruL10n.uploadDirectoryFailed,
          isNotEmpty,
          reason: 'RU uploadDirectoryFailed empty',
        );
        // localFileNotFound
        expect(
          enL10n.localFileNotFound,
          isNotEmpty,
          reason: 'EN localFileNotFound empty',
        );
        expect(
          ruL10n.localFileNotFound,
          isNotEmpty,
          reason: 'RU localFileNotFound empty',
        );
        // uploadErrorLocalFileNotFound
        expect(
          enL10n.uploadErrorLocalFileNotFound,
          isNotEmpty,
          reason: 'EN uploadErrorLocalFileNotFound empty',
        );
        expect(
          ruL10n.uploadErrorLocalFileNotFound,
          isNotEmpty,
          reason: 'RU uploadErrorLocalFileNotFound empty',
        );
        // noSessionToken
        expect(
          enL10n.noSessionToken,
          isNotEmpty,
          reason: 'EN noSessionToken empty',
        );
        expect(
          ruL10n.noSessionToken,
          isNotEmpty,
          reason: 'RU noSessionToken empty',
        );
        // uploadErrorNoSessionToken
        expect(
          enL10n.uploadErrorNoSessionToken,
          isNotEmpty,
          reason: 'EN uploadErrorNoSessionToken empty',
        );
        expect(
          ruL10n.uploadErrorNoSessionToken,
          isNotEmpty,
          reason: 'RU uploadErrorNoSessionToken empty',
        );
        // serverDisconnectedStatus
        expect(
          enL10n.serverDisconnectedStatus,
          isNotEmpty,
          reason: 'EN serverDisconnectedStatus empty',
        );
        expect(
          ruL10n.serverDisconnectedStatus,
          isNotEmpty,
          reason: 'RU serverDisconnectedStatus empty',
        );
        // serverDisconnected
        expect(
          enL10n.serverDisconnected,
          isNotEmpty,
          reason: 'EN serverDisconnected empty',
        );
        expect(
          ruL10n.serverDisconnected,
          isNotEmpty,
          reason: 'RU serverDisconnected empty',
        );
        // serverIsUnreachable
        expect(
          enL10n.serverIsUnreachable,
          isNotEmpty,
          reason: 'EN serverIsUnreachable empty',
        );
        expect(
          ruL10n.serverIsUnreachable,
          isNotEmpty,
          reason: 'RU serverIsUnreachable empty',
        );
        // serverUnreachable
        expect(
          enL10n.serverUnreachable,
          isNotEmpty,
          reason: 'EN serverUnreachable empty',
        );
        expect(
          ruL10n.serverUnreachable,
          isNotEmpty,
          reason: 'RU serverUnreachable empty',
        );
        // uploadErrorLocalDirectoryNotFound
        expect(
          enL10n.uploadErrorLocalDirectoryNotFound,
          isNotEmpty,
          reason: 'EN uploadErrorLocalDirectoryNotFound empty',
        );
        expect(
          ruL10n.uploadErrorLocalDirectoryNotFound,
          isNotEmpty,
          reason: 'RU uploadErrorLocalDirectoryNotFound empty',
        );
        // uploadErrorFailedToScanDirectory
        expect(
          enL10n.uploadErrorFailedToScanDirectory,
          isNotEmpty,
          reason: 'EN uploadErrorFailedToScanDirectory empty',
        );
        expect(
          ruL10n.uploadErrorFailedToScanDirectory,
          isNotEmpty,
          reason: 'RU uploadErrorFailedToScanDirectory empty',
        );
        // uploadErrorFolderCreateHttp(int statusCode)
        expect(
          enL10n.uploadErrorFolderCreateHttp(404),
          isNotEmpty,
          reason: 'EN uploadErrorFolderCreateHttp empty',
        );
        expect(
          ruL10n.uploadErrorFolderCreateHttp(404),
          isNotEmpty,
          reason: 'RU uploadErrorFolderCreateHttp empty',
        );
        // authErrorMissingAccessToken
        expect(
          enL10n.authErrorMissingAccessToken,
          isNotEmpty,
          reason: 'EN authErrorMissingAccessToken empty',
        );
        expect(
          ruL10n.authErrorMissingAccessToken,
          isNotEmpty,
          reason: 'RU authErrorMissingAccessToken empty',
        );
        // authErrorMissingRefreshToken
        expect(
          enL10n.authErrorMissingRefreshToken,
          isNotEmpty,
          reason: 'EN authErrorMissingRefreshToken empty',
        );
        expect(
          ruL10n.authErrorMissingRefreshToken,
          isNotEmpty,
          reason: 'RU authErrorMissingRefreshToken empty',
        );
        // authErrorNoSavedCredentials
        expect(
          enL10n.authErrorNoSavedCredentials,
          isNotEmpty,
          reason: 'EN authErrorNoSavedCredentials empty',
        );
        expect(
          ruL10n.authErrorNoSavedCredentials,
          isNotEmpty,
          reason: 'RU authErrorNoSavedCredentials empty',
        );
        // authErrorNoRefreshToken
        expect(
          enL10n.authErrorNoRefreshToken,
          isNotEmpty,
          reason: 'EN authErrorNoRefreshToken empty',
        );
        expect(
          ruL10n.authErrorNoRefreshToken,
          isNotEmpty,
          reason: 'RU authErrorNoRefreshToken empty',
        );
        // authErrorNoActiveSession
        expect(
          enL10n.authErrorNoActiveSession,
          isNotEmpty,
          reason: 'EN authErrorNoActiveSession empty',
        );
        expect(
          ruL10n.authErrorNoActiveSession,
          isNotEmpty,
          reason: 'RU authErrorNoActiveSession empty',
        );
        // authErrorNoSavedUsername
        expect(
          enL10n.authErrorNoSavedUsername,
          isNotEmpty,
          reason: 'EN authErrorNoSavedUsername empty',
        );
        expect(
          ruL10n.authErrorNoSavedUsername,
          isNotEmpty,
          reason: 'RU authErrorNoSavedUsername empty',
        );
        // updateNoReleasesPublished
        expect(
          enL10n.updateNoReleasesPublished,
          isNotEmpty,
          reason: 'EN updateNoReleasesPublished empty',
        );
        expect(
          ruL10n.updateNoReleasesPublished,
          isNotEmpty,
          reason: 'RU updateNoReleasesPublished empty',
        );
      },
    );

    test('Stress-test plural and numerical keys with varied quantities', () {
      final quantities = [
        -1,
        0,
        1,
        2,
        3,
        4,
        5,
        6,
        10,
        11,
        12,
        14,
        15,
        20,
        21,
        22,
        25,
        100,
        101,
        111,
        121,
        1000,
        999999,
      ];
      for (final q in quantities) {
        expect(enL10n.deleteNItemsTitle(q), isNotEmpty);
        expect(ruL10n.deleteNItemsTitle(q), isNotEmpty);
        expect(enL10n.deleteFilesBody(q), isNotEmpty);
        expect(ruL10n.deleteFilesBody(q), isNotEmpty);
        expect(enL10n.unshareItemsBody(q), isNotEmpty);
        expect(ruL10n.unshareItemsBody(q), isNotEmpty);
        expect(enL10n.movedNItemsToTrash(q), isNotEmpty);
        expect(ruL10n.movedNItemsToTrash(q), isNotEmpty);
        expect(enL10n.deletedNItems(q), isNotEmpty);
        expect(ruL10n.deletedNItems(q), isNotEmpty);
        expect(enL10n.uploadedNItems(q), isNotEmpty);
        expect(ruL10n.uploadedNItems(q), isNotEmpty);
        expect(enL10n.nSelected(q), isNotEmpty);
        expect(ruL10n.nSelected(q), isNotEmpty);
        expect(enL10n.nCategoriesSelected(q), isNotEmpty);
        expect(ruL10n.nCategoriesSelected(q), isNotEmpty);
        expect(enL10n.nFolders(q), isNotEmpty);
        expect(ruL10n.nFolders(q), isNotEmpty);
        expect(enL10n.syncFreqEveryNHours(q), isNotEmpty);
        expect(ruL10n.syncFreqEveryNHours(q), isNotEmpty);
        expect(enL10n.syncFreqEveryNMin(q), isNotEmpty);
        expect(ruL10n.syncFreqEveryNMin(q), isNotEmpty);
        expect(enL10n.restoreItemsBody(q), isNotEmpty);
        expect(ruL10n.restoreItemsBody(q), isNotEmpty);
        expect(enL10n.permanentlyDeleteBody(q), isNotEmpty);
        expect(ruL10n.permanentlyDeleteBody(q), isNotEmpty);
        expect(enL10n.trashRetentionInfo(q), isNotEmpty);
        expect(ruL10n.trashRetentionInfo(q), isNotEmpty);
        expect(enL10n.conflictApplyToRemaining(q), isNotEmpty);
        expect(ruL10n.conflictApplyToRemaining(q), isNotEmpty);
        expect(enL10n.storageStatsNItems(q), isNotEmpty);
        expect(ruL10n.storageStatsNItems(q), isNotEmpty);
        expect(enL10n.createdNShareLinks(q), isNotEmpty);
        expect(ruL10n.createdNShareLinks(q), isNotEmpty);
        expect(enL10n.sharedNItemsInServer(q), isNotEmpty);
        expect(ruL10n.sharedNItemsInServer(q), isNotEmpty);
        expect(enL10n.movedNItems(q), isNotEmpty);
        expect(ruL10n.movedNItems(q), isNotEmpty);
        expect(enL10n.uploadSummaryFailedCount(q), isNotEmpty);
        expect(ruL10n.uploadSummaryFailedCount(q), isNotEmpty);
        expect(enL10n.userFallback(q), isNotEmpty);
        expect(ruL10n.userFallback(q), isNotEmpty);
      }
    });

    test(
      'Stress-test string placeholders with special characters, unicode, and empty strings',
      () {
        final testStrings = [
          '',
          ' ',
          'Simple String',
          r'String with <xml>&"quotes`',
          r'Path/with/nested/slashes/and spaces/file (1).tar.gz',
          'Совершенно русский заголовок с эмодзи 🚀 📁 🔒',
          'Multiline\nstring\twith\rspecial characters',
          'A' * 200,
        ];

        for (final s in testStrings) {
          expect(enL10n.errorWithMessage(s), contains(s));
          expect(ruL10n.errorWithMessage(s), contains(s));
          expect(enL10n.switchServerBody(s), contains(s));
          expect(ruL10n.switchServerBody(s), contains(s));
          expect(enL10n.deletePermanentlyBody(s), contains(s));
          expect(ruL10n.deletePermanentlyBody(s), contains(s));
          expect(enL10n.syncNotificationSyncingWith(s), contains(s));
          expect(ruL10n.syncNotificationSyncingWith(s), contains(s));
          expect(enL10n.renamedOldToNew(s, 'new_$s'), isNotEmpty);
          expect(ruL10n.renamedOldToNew(s, 'new_$s'), isNotEmpty);
          expect(enL10n.connectionFailed(s), isNotEmpty);
          expect(ruL10n.connectionFailed(s), isNotEmpty);
        }
      },
    );

    test('Complex multiple placeholder formatting in EN and RU', () {
      expect(enL10n.transferSummaryFiles(75, 3, 4), '75%  3/4 files');
      expect(ruL10n.transferSummaryFiles(75, 3, 4), '75%  3/4 файлов');

      expect(enL10n.transferSummaryProgress(100, 10, 10), '100%  10/10 files');
      expect(ruL10n.transferSummaryProgress(100, 10, 10), '100%  10/10 файлов');

      expect(
        enL10n.downloadedNFilesToPath(5, '/home/user/downloads'),
        'Downloaded 5 file(s) to /home/user/downloads',
      );
      expect(
        ruL10n.downloadedNFilesToPath(5, '/home/user/downloads'),
        'Скачано файлов: 5 в /home/user/downloads',
      );

      expect(
        enL10n.downloadedNFilesFailedM(8, 2, 'Timeout'),
        'Downloaded 8 file(s), failed 2: Timeout',
      );
      expect(
        ruL10n.downloadedNFilesFailedM(8, 2, 'Timeout'),
        'Скачано файлов: 8, ошибок 2: Timeout',
      );

      expect(enL10n.conflictNofM(1, 10), 'Conflict 1 of 10');
      expect(ruL10n.conflictNofM(1, 10), 'Конфликт 1 из 10');

      expect(
        enL10n.failedToRenameWithStatus('test.txt', 500),
        'Failed to rename "test.txt" (500).',
      );
      expect(
        ruL10n.failedToRenameWithStatus('test.txt', 500),
        'Не удалось переименовать «test.txt» (500).',
      );

      expect(
        enL10n.syncStatusCalculatingChecksum(3, 10, 'data.bin'),
        'Calculating checksum (3/10): data.bin',
      );
      expect(
        ruL10n.syncStatusCalculatingChecksum(3, 10, 'data.bin'),
        'Вычисление контрольной суммы (3/10): data.bin',
      );

      expect(
        enL10n.syncStatusSyncingFile(2, 5, 'image.png'),
        'Syncing (2/5): image.png',
      );
      expect(
        ruL10n.syncStatusSyncingFile(2, 5, 'image.png'),
        'Синхронизация (2/5): image.png',
      );
    });
  });
}
