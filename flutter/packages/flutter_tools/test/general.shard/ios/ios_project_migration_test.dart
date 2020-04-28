// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/ios/migrations/ios_migrator.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/ios/migrations/remove_framework_link_and_embedding_migration.dart';
import 'package:flutter_tools/src/ios/migrations/xcode_build_system_migration.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';

import '../../src/common.dart';

void main () {
  group('iOS migration', () {
    MockUsage mockUsage;
    setUp(() {
      mockUsage = MockUsage();
    });

    testWithoutContext('migrators succeed', () {
      final FakeIOSMigrator fakeIOSMigrator = FakeIOSMigrator(succeeds: true);
      final IOSMigration migration = IOSMigration(<IOSMigrator>[fakeIOSMigrator]);
      expect(migration.run(), isTrue);
    });

    testWithoutContext('migrators fail', () {
      final FakeIOSMigrator fakeIOSMigrator = FakeIOSMigrator(succeeds: false);
      final IOSMigration migration = IOSMigration(<IOSMigrator>[fakeIOSMigrator]);
      expect(migration.run(), isFalse);
    });

    group('remove framework linking and embedding migration', () {
      MemoryFileSystem memoryFileSystem;
      BufferLogger testLogger;
      MockIosProject mockIosProject;
      File xcodeProjectInfoFile;
      MockXcode mockXcode;

      setUp(() {
        memoryFileSystem = MemoryFileSystem();
        mockXcode = MockXcode();
        xcodeProjectInfoFile = memoryFileSystem.file('project.pbxproj');

        testLogger = BufferLogger(
          terminal: AnsiTerminal(
            stdio: null,
            platform: const LocalPlatform(),
          ),
          outputPreferences: OutputPreferences.test(),
        );

        mockIosProject = MockIosProject();
        when(mockIosProject.xcodeProjectInfoFile).thenReturn(xcodeProjectInfoFile);
      });

      testWithoutContext('skipped if files are missing', () {
        final RemoveFrameworkLinkAndEmbeddingMigration iosProjectMigration = RemoveFrameworkLinkAndEmbeddingMigration(
          mockIosProject,
          testLogger,
          mockXcode,
          mockUsage
        );
        expect(iosProjectMigration.migrate(), isTrue);
        verifyNever(mockUsage.sendEvent(any, any, label: anyNamed('label'), value: anyNamed('value')));

        expect(xcodeProjectInfoFile.existsSync(), isFalse);

        expect(testLogger.traceText, contains('Xcode project not found, skipping migration'));
        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('skipped if nothing to upgrade', () {
        const String contents = 'Nothing to upgrade';
        xcodeProjectInfoFile.writeAsStringSync(contents);
        final DateTime projectLastModified = xcodeProjectInfoFile.lastModifiedSync();

        final RemoveFrameworkLinkAndEmbeddingMigration iosProjectMigration = RemoveFrameworkLinkAndEmbeddingMigration(
          mockIosProject,
          testLogger,
          mockXcode,
          mockUsage,
        );
        expect(iosProjectMigration.migrate(), isTrue);
        verifyNever(mockUsage.sendEvent(any, any, label: anyNamed('label'), value: anyNamed('value')));

        expect(xcodeProjectInfoFile.lastModifiedSync(), projectLastModified);
        expect(xcodeProjectInfoFile.readAsStringSync(), contents);

        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('skips migrating script with embed', () {
        const String contents = '''
shellScript = "/bin/sh \"\$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh\\" embed\\n/bin/sh \"\$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh\\" thin\n";
			''';
        xcodeProjectInfoFile.writeAsStringSync(contents);

        final RemoveFrameworkLinkAndEmbeddingMigration iosProjectMigration = RemoveFrameworkLinkAndEmbeddingMigration(
          mockIosProject,
          testLogger,
          mockXcode,
          mockUsage,
        );
        expect(iosProjectMigration.migrate(), isTrue);
        expect(xcodeProjectInfoFile.readAsStringSync(), contents);
        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('Xcode project is migrated', () {
        xcodeProjectInfoFile.writeAsStringSync('''
prefix 3B80C3941E831B6300D905FE
3B80C3951E831B6300D905FE suffix
741F496821356857001E2961
keep this 1
  3B80C3931E831B6300D905FE spaces
741F496521356807001E2961
9705A1C61CF904A100538489
9705A1C71CF904A300538489
741F496221355F47001E2961
9740EEBA1CF902C7004384FC
741F495E21355F27001E2961
			shellScript = "/bin/sh \"\$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh\\" thin";
keep this 2
''');

        final RemoveFrameworkLinkAndEmbeddingMigration iosProjectMigration = RemoveFrameworkLinkAndEmbeddingMigration(
          mockIosProject,
          testLogger,
          mockXcode,
          mockUsage,
        );
        expect(iosProjectMigration.migrate(), isTrue);
        verifyNever(mockUsage.sendEvent(any, any, label: anyNamed('label'), value: anyNamed('value')));

        expect(xcodeProjectInfoFile.readAsStringSync(), '''
keep this 1
			shellScript = "/bin/sh "\$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh\\" embed_and_thin";
keep this 2

''');
        expect(testLogger.statusText, contains('Upgrading project.pbxproj'));
      });

      testWithoutContext('migration fails with leftover App.framework reference', () {
        xcodeProjectInfoFile.writeAsStringSync('''
        746232531E83B71900CC1A5E /* App.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = 746232521E83B71900CC1A5E /* App.framework */; };
''');
        when(mockXcode.isInstalled).thenReturn(true);
        when(mockXcode.majorVersion).thenReturn(11);
        when(mockXcode.minorVersion).thenReturn(4);

        final RemoveFrameworkLinkAndEmbeddingMigration iosProjectMigration = RemoveFrameworkLinkAndEmbeddingMigration(
          mockIosProject,
          testLogger,
          mockXcode,
          mockUsage,
        );

        expect(() =>iosProjectMigration.migrate(), throwsToolExit(message: 'Your Xcode project requires migration'));
        verify(mockUsage.sendEvent('ios-migration', 'remove-frameworks', label: 'failure', value: null));
      });

      testWithoutContext('migration fails with leftover Flutter.framework reference', () {
        xcodeProjectInfoFile.writeAsStringSync('''
      9705A1C71CF904A300538480 /* Flutter.framework in Embed Frameworks */,
''');
        when(mockXcode.isInstalled).thenReturn(true);
        when(mockXcode.majorVersion).thenReturn(11);
        when(mockXcode.minorVersion).thenReturn(4);

        final RemoveFrameworkLinkAndEmbeddingMigration iosProjectMigration = RemoveFrameworkLinkAndEmbeddingMigration(
          mockIosProject,
          testLogger,
          mockXcode,
          mockUsage,
        );
        expect(() =>iosProjectMigration.migrate(), throwsToolExit(message: 'Your Xcode project requires migration'));
        verify(mockUsage.sendEvent('ios-migration', 'remove-frameworks', label: 'failure', value: null));
      });

      testWithoutContext('migration fails without Xcode installed', () {
        xcodeProjectInfoFile.writeAsStringSync('''
        746232531E83B71900CC1A5E /* App.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = 746232521E83B71900CC1A5E /* App.framework */; };
''');
        when(mockXcode.isInstalled).thenReturn(false);

        final RemoveFrameworkLinkAndEmbeddingMigration iosProjectMigration = RemoveFrameworkLinkAndEmbeddingMigration(
          mockIosProject,
          testLogger,
          mockXcode,
          mockUsage,
        );
        expect(() =>iosProjectMigration.migrate(), throwsToolExit(message: 'Your Xcode project requires migration'));
        verify(mockUsage.sendEvent('ios-migration', 'remove-frameworks', label: 'failure', value: null));
      });

      testWithoutContext('migration fails on Xcode < 11.4', () {
        xcodeProjectInfoFile.writeAsStringSync('''
        746232531E83B71900CC1A5E /* App.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = 746232521E83B71900CC1A5E /* App.framework */; };
''');
        when(mockXcode.isInstalled).thenReturn(true);
        when(mockXcode.majorVersion).thenReturn(11);
        when(mockXcode.minorVersion).thenReturn(3);

        final RemoveFrameworkLinkAndEmbeddingMigration iosProjectMigration = RemoveFrameworkLinkAndEmbeddingMigration(
          mockIosProject,
          testLogger,
          mockXcode,
          mockUsage,
        );
        expect(iosProjectMigration.migrate(), isTrue);
        verifyNever(mockUsage.sendEvent(any, any, label: anyNamed('label'), value: anyNamed('value')));
        expect(testLogger.errorText, isEmpty);
      });

      testWithoutContext('migration fails on Xcode 11.4', () {
        xcodeProjectInfoFile.writeAsStringSync('''
        746232531E83B71900CC1A5E /* App.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = 746232521E83B71900CC1A5E /* App.framework */; };
''');
        when(mockXcode.isInstalled).thenReturn(true);
        when(mockXcode.majorVersion).thenReturn(11);
        when(mockXcode.minorVersion).thenReturn(4);

        final RemoveFrameworkLinkAndEmbeddingMigration iosProjectMigration = RemoveFrameworkLinkAndEmbeddingMigration(
          mockIosProject,
          testLogger,
          mockXcode,
          mockUsage,
        );
        expect(() =>iosProjectMigration.migrate(), throwsToolExit(message: 'Your Xcode project requires migration'));
        verify(mockUsage.sendEvent('ios-migration', 'remove-frameworks', label: 'failure', value: null));
      });

      testWithoutContext('migration fails on Xcode 12,0', () {
        xcodeProjectInfoFile.writeAsStringSync('''
        746232531E83B71900CC1A5E /* App.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = 746232521E83B71900CC1A5E /* App.framework */; };
''');
        when(mockXcode.isInstalled).thenReturn(true);
        when(mockXcode.majorVersion).thenReturn(12);
        when(mockXcode.minorVersion).thenReturn(0);

        final RemoveFrameworkLinkAndEmbeddingMigration iosProjectMigration = RemoveFrameworkLinkAndEmbeddingMigration(
          mockIosProject,
          testLogger,
          mockXcode,
          mockUsage,
        );
        expect(() =>iosProjectMigration.migrate(), throwsToolExit(message: 'Your Xcode project requires migration'));
        verify(mockUsage.sendEvent('ios-migration', 'remove-frameworks', label: 'failure', value: null));
      });
    });

    group('new Xcode build system', () {
      MemoryFileSystem memoryFileSystem;
      BufferLogger testLogger;
      MockIosProject mockIosProject;
      File xcodeWorkspaceSharedSettings;

      setUp(() {
        memoryFileSystem = MemoryFileSystem();
        xcodeWorkspaceSharedSettings = memoryFileSystem.file('WorkspaceSettings.xcsettings');

        testLogger = BufferLogger(
          terminal: AnsiTerminal(
            stdio: null,
            platform: const LocalPlatform(),
          ),
          outputPreferences: OutputPreferences.test(),
        );

        mockIosProject = MockIosProject();
        when(mockIosProject.xcodeWorkspaceSharedSettings).thenReturn(xcodeWorkspaceSharedSettings);
      });

      testWithoutContext('skipped if files are missing', () {
        final XcodeBuildSystemMigration iosProjectMigration = XcodeBuildSystemMigration(
          mockIosProject,
          testLogger,
        );
        expect(iosProjectMigration.migrate(), isTrue);
        expect(xcodeWorkspaceSharedSettings.existsSync(), isFalse);

        expect(testLogger.traceText, contains('Xcode workspace settings not found, skipping migration'));
        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('skipped if nothing to upgrade', () {
        const String contents = '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>BuildSystemType</key>
	<string></string>
</dict>
</plist>''';
        xcodeWorkspaceSharedSettings.writeAsStringSync(contents);

        final XcodeBuildSystemMigration iosProjectMigration = XcodeBuildSystemMigration(
          mockIosProject,
          testLogger,
        );
        expect(iosProjectMigration.migrate(), isTrue);
        expect(xcodeWorkspaceSharedSettings.existsSync(), isTrue);
        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('Xcode project is migrated', () {
        const String contents = '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>BuildSystemType</key>
	<string>Original</string>
</dict>
</plist>''';
        xcodeWorkspaceSharedSettings.writeAsStringSync(contents);

        final XcodeBuildSystemMigration iosProjectMigration = XcodeBuildSystemMigration(
          mockIosProject,
          testLogger,
        );
        expect(iosProjectMigration.migrate(), isTrue);
        expect(xcodeWorkspaceSharedSettings.existsSync(), isFalse);

        expect(testLogger.statusText, contains('Legacy build system detected, removing'));
      });
    });
  });
}

class MockIosProject extends Mock implements IosProject {}
class MockXcode extends Mock implements Xcode {}
class MockUsage extends Mock implements Usage {}

class FakeIOSMigrator extends IOSMigrator {
  FakeIOSMigrator({@required this.succeeds})
    : super(null);

  final bool succeeds;

  @override
  bool migrate() {
    return succeeds;
  }

  @override
  String migrateLine(String line) {
    return line;
  }
}
