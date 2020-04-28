// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/ios/ios_deploy.dart';
import 'package:flutter_tools/src/ios/mac.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:quiver/testing/async.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';

const List<String> kRunReleaseArgs = <String>[
  '/usr/bin/env',
  'xcrun',
  'xcodebuild',
  '-configuration',
  'Release',
  '-quiet',
  '-workspace',
  'Runner.xcworkspace',
  '-scheme',
  'Runner',
  'BUILD_DIR=/build/ios',
  '-sdk',
  'iphoneos',
  'ONLY_ACTIVE_ARCH=YES',
  'ARCHS=arm64',
  'FLUTTER_SUPPRESS_ANALYTICS=true',
  'COMPILER_INDEX_STORE_ENABLE=NO',
];

const String kConcurrentBuildErrorMessage = '''
"/Developer/Xcode/DerivedData/foo/XCBuildData/build.db":
database is locked
Possibly there are two concurrent builds running in the same filesystem location.
''';

final FakePlatform macPlatform = FakePlatform(
  operatingSystem: 'macos',
  environment: <String, String>{},
);

void main() {
  FileSystem fileSystem;
  FakeProcessManager processManager;
  BufferLogger logger;

  setUp(() {
    logger = BufferLogger.test();
    fileSystem = MemoryFileSystem.test();
    processManager = FakeProcessManager.list(<FakeCommand>[]);
  });

  testUsingContext('IOSDevice.startApp succeeds in release mode with buildable app', () async {
    final IOSDevice iosDevice = setUpIOSDevice(
      fileSystem: fileSystem,
      processManager: processManager,
      logger: logger,
    );
    setUpIOSProject(fileSystem);
    final FlutterProject flutterProject = FlutterProject.fromDirectory(fileSystem.currentDirectory);
    final BuildableIOSApp buildableIOSApp = BuildableIOSApp(flutterProject.ios, 'flutter');

    processManager.addCommand(const FakeCommand(command: kRunReleaseArgs));
    processManager.addCommand(const FakeCommand(command: <String>[...kRunReleaseArgs, '-showBuildSettings']));
    processManager.addCommand(FakeCommand(
      command: <String>[
        'ios-deploy',
        '--id',
        '123',
        '--bundle',
        'build/ios/iphoneos/Runner.app',
        '--no-wifi',
        '--justlaunch',
        '--args',
        const <String>[
          '--enable-dart-profiling',
          '--enable-service-port-fallback',
          '--disable-service-auth-codes',
          '--observatory-port=53781',
        ].join(' ')
      ])
    );

    final LaunchResult launchResult = await iosDevice.startApp(
      buildableIOSApp,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      platformArgs: <String, Object>{},
    );

    expect(launchResult.started, true);
    expect(processManager.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    ProcessManager: () => processManager,
    FileSystem: () => fileSystem,
    Logger: () => logger,
    Platform: () => macPlatform,
  });

  testUsingContext('IOSDevice.startApp succeeds in release mode with buildable '
    'app with flaky buildSettings call', () async {
    LaunchResult launchResult;
    FakeAsync().run((FakeAsync time) {
      final IOSDevice iosDevice = setUpIOSDevice(
        fileSystem: fileSystem,
        processManager: processManager,
        logger: logger,
      );
      setUpIOSProject(fileSystem);
      final FlutterProject flutterProject = FlutterProject.fromDirectory(fileSystem.currentDirectory);
      final BuildableIOSApp buildableIOSApp = BuildableIOSApp(flutterProject.ios, 'flutter');

      processManager.addCommand(const FakeCommand(command: kRunReleaseArgs));
      // The first showBuildSettings call should timeout.
      processManager.addCommand(
        const FakeCommand(
          command: <String>[...kRunReleaseArgs, '-showBuildSettings'],
          duration: Duration(minutes: 5), // this is longer than the timeout of 1 minute.
      ));
      // The second call succeedes and is made after the first times out.
      processManager.addCommand(
        const FakeCommand(
          command: <String>[...kRunReleaseArgs, '-showBuildSettings'],
          exitCode: 0,
      ));
      processManager.addCommand(FakeCommand(
        command: <String>[
          'ios-deploy',
          '--id',
          '123',
          '--bundle',
          'build/ios/iphoneos/Runner.app',
          '--no-wifi',
          '--justlaunch',
          '--args',
          const <String>[
            '--enable-dart-profiling',
            '--enable-service-port-fallback',
            '--disable-service-auth-codes',
            '--observatory-port=53781',
          ].join(' ')
        ])
      );

      iosDevice.startApp(
        buildableIOSApp,
        debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
        platformArgs: <String, Object>{},
      ).then((LaunchResult result) {
        launchResult = result;
      });

      // Elapse duration for process timeout.
      time.flushMicrotasks();
      time.elapse(const Duration(minutes: 1));

      // Elapse duration for overall process timer.
      time.flushMicrotasks();
      time.elapse(const Duration(minutes: 5));

      time.flushTimers();
    });

    expect(launchResult?.started, true);
    expect(processManager.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    ProcessManager: () => processManager,
    FileSystem: () => fileSystem,
    Logger: () => logger,
    Platform: () => macPlatform,
  });

  testUsingContext('IOSDevice.startApp succeeds in release mode with buildable '
    'app with concurrent build failure', () async {
    final IOSDevice iosDevice = setUpIOSDevice(
      fileSystem: fileSystem,
      processManager: processManager,
      logger: logger,
    );
    setUpIOSProject(fileSystem);
    final FlutterProject flutterProject = FlutterProject.fromDirectory(fileSystem.currentDirectory);
    final BuildableIOSApp buildableIOSApp = BuildableIOSApp(flutterProject.ios, 'flutter');

    // The first xcrun call should fail with a
    // concurrent build exception.
    processManager.addCommand(
      const FakeCommand(
        command: kRunReleaseArgs,
        exitCode: 1,
        stdout: kConcurrentBuildErrorMessage,
    ));
    processManager.addCommand(const FakeCommand(command: kRunReleaseArgs));
    processManager.addCommand(
      const FakeCommand(
        command: <String>[...kRunReleaseArgs, '-showBuildSettings'],
        exitCode: 0,
    ));
    processManager.addCommand(FakeCommand(
      command: <String>[
        'ios-deploy',
        '--id',
        '123',
        '--bundle',
        'build/ios/iphoneos/Runner.app',
        '--no-wifi',
        '--justlaunch',
        '--args',
        const <String>[
          '--enable-dart-profiling',
          '--enable-service-port-fallback',
          '--disable-service-auth-codes',
          '--observatory-port=53781',
        ].join(' ')
      ])
    );

    final LaunchResult launchResult = await iosDevice.startApp(
      buildableIOSApp,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      platformArgs: <String, Object>{},
    );

    expect(logger.statusText,
      contains('Xcode build failed due to concurrent builds, will retry in 2 seconds'));
    expect(launchResult.started, true);
    expect(processManager.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    ProcessManager: () => processManager,
    FileSystem: () => fileSystem,
    Logger: () => logger,
    Platform: () => macPlatform,
  });
}

void setUpIOSProject(FileSystem fileSystem) {
  fileSystem.file('pubspec.yaml').createSync();
  fileSystem.file('.packages').writeAsStringSync('\n');
  fileSystem.directory('ios').createSync();
  fileSystem.directory('ios/Runner.xcworkspace').createSync();
  fileSystem.directory('ios/Runner.xcodeproj').createSync();
  fileSystem.file('ios/Runner.xcodeproj/project.pbxproj').createSync();
  // This is the expected output directory.
  fileSystem.directory('build/ios/iphoneos/Runner.app').createSync(recursive: true);
}

IOSDevice setUpIOSDevice({
  String sdkVersion = '13.0.1',
  FileSystem fileSystem,
  Logger logger,
  ProcessManager processManager,
}) {
  const MapEntry<String, String> dyldLibraryEntry = MapEntry<String, String>(
    'DYLD_LIBRARY_PATH',
    '/path/to/libraries',
  );
  final MockCache cache = MockCache();
  final MockArtifacts artifacts = MockArtifacts();
  logger ??= BufferLogger.test();
  when(cache.dyLdLibEntry).thenReturn(dyldLibraryEntry);
  when(artifacts.getArtifactPath(Artifact.iosDeploy, platform: anyNamed('platform')))
    .thenReturn('ios-deploy');
  return IOSDevice('123',
    name: 'iPhone 1',
    sdkVersion: sdkVersion,
    fileSystem: fileSystem ?? MemoryFileSystem.test(),
    platform: macPlatform,
    artifacts: artifacts,
    logger: logger,
    iosDeploy: IOSDeploy(
      logger: logger,
      platform: macPlatform,
      processManager: processManager ?? FakeProcessManager.any(),
      artifacts: artifacts,
      cache: cache,
    ),
    iMobileDevice: IMobileDevice(
      logger: logger,
      processManager: processManager ?? FakeProcessManager.any(),
      artifacts: artifacts,
      cache: cache,
    ),
    cpuArchitecture: DarwinArch.arm64,
  );
}

class MockArtifacts extends Mock implements Artifacts {}
class MockCache extends Mock implements Cache {}
