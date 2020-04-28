// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/android/android_builder.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build_appbundle.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/android_common.dart';
import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';

void main() {
  Cache.disableLocking();

  group('Usage', () {
    Directory tempDir;
    Usage mockUsage;

    setUp(() {
      tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_tools_packages_test.');
      mockUsage = MockUsage();
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    testUsingContext('indicate the default target platforms', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=app']);
      final BuildAppBundleCommand command = await runBuildAppBundleCommand(projectPath);

      expect(await command.usageValues,
          containsPair(CustomDimensions.commandBuildAppBundleTargetPlatform, 'android-arm,android-arm64,android-x64'));

    }, overrides: <Type, Generator>{
      AndroidBuilder: () => FakeAndroidBuilder(),
    });

    testUsingContext('build type', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=app']);

      final BuildAppBundleCommand commandDefault = await runBuildAppBundleCommand(projectPath);
      expect(await commandDefault.usageValues,
          containsPair(CustomDimensions.commandBuildAppBundleBuildMode, 'release'));

      final BuildAppBundleCommand commandInRelease = await runBuildAppBundleCommand(projectPath,
          arguments: <String>['--release']);
      expect(await commandInRelease.usageValues,
          containsPair(CustomDimensions.commandBuildAppBundleBuildMode, 'release'));

      final BuildAppBundleCommand commandInDebug = await runBuildAppBundleCommand(projectPath,
          arguments: <String>['--debug']);
      expect(await commandInDebug.usageValues,
          containsPair(CustomDimensions.commandBuildAppBundleBuildMode, 'debug'));

      final BuildAppBundleCommand commandInProfile = await runBuildAppBundleCommand(projectPath,
          arguments: <String>['--profile']);
      expect(await commandInProfile.usageValues,
          containsPair(CustomDimensions.commandBuildAppBundleBuildMode, 'profile'));

    }, overrides: <Type, Generator>{
      AndroidBuilder: () => FakeAndroidBuilder(),
    });

    testUsingContext('logs success', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=app']);

      await runBuildAppBundleCommand(projectPath);

      verify(mockUsage.sendEvent(
        'tool-command-result',
        'appbundle',
        label: 'success',
        value: anyNamed('value'),
        parameters: anyNamed('parameters'),
      )).called(1);
    },
    overrides: <Type, Generator>{
      AndroidBuilder: () => FakeAndroidBuilder(),
      Usage: () => mockUsage,
    });
  });

  group('Gradle', () {
    Directory tempDir;
    ProcessManager mockProcessManager;
    MockAndroidSdk mockAndroidSdk;
    String gradlew;
    Usage mockUsage;

    setUp(() {
      mockUsage = MockUsage();
      when(mockUsage.isFirstRun).thenReturn(true);

      tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_tools_packages_test.');
      gradlew = globals.fs.path.join(tempDir.path, 'flutter_project', 'android',
          globals.platform.isWindows ? 'gradlew.bat' : 'gradlew');

      mockProcessManager = MockProcessManager();
      when(mockProcessManager.run(<String>[gradlew, '-v'],
          environment: anyNamed('environment')))
        .thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(0, 0, '', '')));

      when(mockProcessManager.run(<String>[gradlew, 'app:properties'],
          workingDirectory: anyNamed('workingDirectory'),
          environment: anyNamed('environment')))
        .thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(0, 0, 'buildDir: irrelevant', '')));

      when(mockProcessManager.run(<String>[gradlew, 'app:tasks', '--all', '--console=auto'],
          workingDirectory: anyNamed('workingDirectory'),
          environment: anyNamed('environment')))
        .thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(0, 0, 'assembleRelease', '')));
      // Fallback with error.
      final Process process = createMockProcess(exitCode: 1);
      when(mockProcessManager.start(any,
          workingDirectory: anyNamed('workingDirectory'),
          environment: anyNamed('environment')))
        .thenAnswer((_) => Future<Process>.value(process));
      when(mockProcessManager.canRun(any)).thenReturn(false);

      when(mockProcessManager.runSync(
        argThat(contains(contains('gen_snapshot'))),
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenReturn(ProcessResult(0, 255, '', ''));

      when(mockProcessManager.runSync(
        <String>['/usr/bin/xcode-select', '--print-path'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenReturn(ProcessResult(0, 0, '', ''));

      when(mockProcessManager.run(
        <String>['which', 'pod'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) {
        return Future<ProcessResult>.value(ProcessResult(0, 0, '', ''));
      });

      mockAndroidSdk = MockAndroidSdk();
      when(mockAndroidSdk.licensesAvailable).thenReturn(true);
      when(mockAndroidSdk.platformToolsAvailable).thenReturn(true);
      when(mockAndroidSdk.validateSdkWellFormed()).thenReturn(const <String>[]);
      when(mockAndroidSdk.directory).thenReturn('irrelevant');
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    group('AndroidSdk', () {
      testUsingContext('validateSdkWellFormed() not called, sdk reinitialized', () async {
        final String projectPath = await createProject(tempDir,
            arguments: <String>['--no-pub', '--template=app']);

        await expectLater(
          runBuildAppBundleCommand(
            projectPath,
            arguments: <String>['--no-pub'],
          ),
          throwsToolExit(message: 'Gradle task bundleRelease failed with exit code 1'),
        );

        verifyNever(mockAndroidSdk.validateSdkWellFormed());
        verify(mockAndroidSdk.reinitialize()).called(1);
      },
      overrides: <Type, Generator>{
        AndroidSdk: () => mockAndroidSdk,
        FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
        ProcessManager: () => mockProcessManager,
      });

      testUsingContext('throws throwsToolExit if AndroidSdk is null', () async {
        final String projectPath = await createProject(tempDir,
            arguments: <String>['--no-pub', '--template=app']);

        await expectLater(() async {
          await runBuildAppBundleCommand(
            projectPath,
            arguments: <String>['--no-pub'],
          );
        }, throwsToolExit(
          message: 'No Android SDK found. Try setting the ANDROID_HOME environment variable',
        ));
      },
      overrides: <Type, Generator>{
        AndroidSdk: () => null,
        FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
        ProcessManager: () => mockProcessManager,
      });
    });

    testUsingContext('shrinking is enabled by default on release mode', () async {
      final String projectPath = await createProject(
          tempDir,
          arguments: <String>['--no-pub', '--template=app'],
        );

      await expectLater(() async {
        await runBuildAppBundleCommand(projectPath);
      }, throwsToolExit(message: 'Gradle task bundleRelease failed with exit code 1'));

      verify(mockProcessManager.start(
        <String>[
          gradlew,
          '-q',
          '-Ptarget-platform=android-arm,android-arm64,android-x64',
          '-Ptarget=${globals.fs.path.join(tempDir.path, 'flutter_project', 'lib', 'main.dart')}',
          '-Ptrack-widget-creation=false',
          '-Pshrink=true',
          'bundleRelease',
        ],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).called(1);
    },
    overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('shrinking is disabled when --no-shrink is passed', () async {
      final String projectPath = await createProject(
          tempDir,
          arguments: <String>['--no-pub', '--template=app'],
        );

      await expectLater(() async {
        await runBuildAppBundleCommand(
          projectPath,
          arguments: <String>['--no-shrink'],
        );
      }, throwsToolExit(message: 'Gradle task bundleRelease failed with exit code 1'));

      verify(mockProcessManager.start(
        <String>[
          gradlew,
          '-q',
          '-Ptarget-platform=android-arm,android-arm64,android-x64',
          '-Ptarget=${globals.fs.path.join(tempDir.path, 'flutter_project', 'lib', 'main.dart')}',
          '-Ptrack-widget-creation=false',
          'bundleRelease',
        ],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).called(1);
    },
    overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('guides the user when the shrinker fails', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=app']);

      when(mockProcessManager.start(
        <String>[
          gradlew,
          '-q',
          '-Ptarget-platform=android-arm,android-arm64,android-x64',
          '-Ptarget=${globals.fs.path.join(tempDir.path, 'flutter_project', 'lib', 'main.dart')}',
          '-Ptrack-widget-creation=false',
          '-Pshrink=true',
          'bundleRelease',
        ],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) {
        const String r8StdoutWarning =
            "Execution failed for task ':app:transformClassesAndResourcesWithR8ForStageInternal'.\n"
            '> com.android.tools.r8.CompilationFailedException: Compilation failed to complete';
        return Future<Process>.value(
          createMockProcess(
            exitCode: 1,
            stdout: r8StdoutWarning,
          ),
        );
      });

      await expectLater(() async {
        await runBuildAppBundleCommand(
          projectPath,
        );
      }, throwsToolExit(message: 'Gradle task bundleRelease failed with exit code 1'));

      expect(testLogger.statusText,
          contains('The shrinker may have failed to optimize the Java bytecode.'));
      expect(testLogger.statusText,
          contains('To disable the shrinker, pass the `--no-shrink` flag to this command.'));
      expect(testLogger.statusText,
          contains('To learn more, see: https://developer.android.com/studio/build/shrink-code'));

      verify(mockUsage.sendEvent(
        'build',
        'appbundle',
        label: 'gradle-r8-failure',
        parameters: anyNamed('parameters'),
      )).called(1);
    },
    overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
      ProcessManager: () => mockProcessManager,
      Usage: () => mockUsage,
    });

    testUsingContext("reports when the app isn't using AndroidX", () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=app']);
      // Simulate a non-androidx project.
      tempDir
        .childDirectory('flutter_project')
        .childDirectory('android')
        .childFile('gradle.properties')
        .writeAsStringSync('android.useAndroidX=false');

      when(mockProcessManager.start(
        <String>[
          gradlew,
          '-q',
          '-Ptarget-platform=android-arm,android-arm64,android-x64',
          '-Ptarget=${globals.fs.path.join(tempDir.path, 'flutter_project', 'lib', 'main.dart')}',
          '-Ptrack-widget-creation=false',
          '-Pshrink=true',
          'assembleRelease',
        ],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) {
        return Future<Process>.value(
          createMockProcess(
            exitCode: 0,
            stdout: '',
          ),
        );
      });
      // The command throws a [ToolExit] because it expects an AAB in the file system.
      await expectLater(() async {
        await runBuildAppBundleCommand(
          projectPath,
        );
      }, throwsToolExit());

      expect(testLogger.statusText, contains("Your app isn't using AndroidX"));
      expect(testLogger.statusText, contains(
        'To avoid potential build failures, you can quickly migrate your app by '
        'following the steps on https://goo.gl/CP92wY'
        )
      );
      verify(mockUsage.sendEvent(
        'build',
        'appbundle',
        label: 'app-not-using-android-x',
        parameters: anyNamed('parameters'),
      )).called(1);
    },
    overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
      ProcessManager: () => mockProcessManager,
      Usage: () => mockUsage,
    });

    testUsingContext('reports when the app is using AndroidX', () async {
      final String projectPath = await createProject(tempDir,
          arguments: <String>['--no-pub', '--template=app']);

      when(mockProcessManager.start(
        <String>[
          gradlew,
          '-q',
          '-Ptarget-platform=android-arm,android-arm64,android-x64',
          '-Ptarget=${globals.fs.path.join(tempDir.path, 'flutter_project', 'lib', 'main.dart')}',
          '-Ptrack-widget-creation=false',
          '-Pshrink=true',
          'assembleRelease',
        ],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) {
        return Future<Process>.value(
          createMockProcess(
            exitCode: 0,
            stdout: '',
          ),
        );
      });
      // The command throws a [ToolExit] because it expects an AAB in the file system.
      await expectLater(() async {
        await runBuildAppBundleCommand(
          projectPath,
        );
      }, throwsToolExit());

      expect(testLogger.statusText.contains("Your app isn't using AndroidX"), isFalse);
      expect(
        testLogger.statusText.contains(
          'To avoid potential build failures, you can quickly migrate your app by '
          'following the steps on https://goo.gl/CP92wY'
        ),
        isFalse,
      );
      verify(mockUsage.sendEvent(
        'build',
        'appbundle',
        label: 'app-using-android-x',
        parameters: anyNamed('parameters'),
      )).called(1);
    },
    overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      FlutterProjectFactory: () => FakeFlutterProjectFactory(tempDir),
      ProcessManager: () => mockProcessManager,
      Usage: () => mockUsage,
    });
  });
}

Future<BuildAppBundleCommand> runBuildAppBundleCommand(
  String target, {
  List<String> arguments,
}) async {
  final BuildAppBundleCommand command = BuildAppBundleCommand();
  final CommandRunner<void> runner = createTestCommandRunner(command);
  await runner.run(<String>[
    'appbundle',
    ...?arguments,
    '--no-pub',
    globals.fs.path.join(target, 'lib', 'main.dart'),
  ]);
  return command;
}

class MockAndroidSdk extends Mock implements AndroidSdk {}
class MockProcessManager extends Mock implements ProcessManager {}
class MockProcess extends Mock implements Process {}
class MockUsage extends Mock implements Usage {}
