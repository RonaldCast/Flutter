// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/project.dart';

import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart' as mocks;
import '../../src/pubspec_schema.dart';

const String xcodebuild = '/usr/bin/xcodebuild';

void main() {
  mocks.MockProcessManager processManager;
  XcodeProjectInterpreter xcodeProjectInterpreter;
  FakePlatform platform;
  FileSystem fileSystem;
  BufferLogger logger;
  AnsiTerminal terminal;

  setUp(() {
    processManager = mocks.MockProcessManager();
    platform = fakePlatform('macos');
    fileSystem = MemoryFileSystem();
    fileSystem.file(xcodebuild).createSync(recursive: true);
    terminal = MockAnsiTerminal();
    logger = BufferLogger.test(
      terminal: terminal
    );
    xcodeProjectInterpreter = XcodeProjectInterpreter(
      logger: logger,
      fileSystem: fileSystem,
      platform: platform,
      processManager: processManager,
      terminal: terminal,
    );
  });

  testWithoutContext('xcodebuild versionText returns null when xcodebuild is not installed', () {
    when(processManager.runSync(<String>[xcodebuild, '-version']))
        .thenThrow(const ProcessException(xcodebuild, <String>['-version']));

    expect(xcodeProjectInterpreter.versionText, isNull);
  });

  testWithoutContext('xcodebuild versionText returns null when xcodebuild is not fully installed', () {
    when(processManager.runSync(<String>[xcodebuild, '-version'])).thenReturn(
      ProcessResult(
        0,
        1,
        "xcode-select: error: tool 'xcodebuild' requires Xcode, "
        "but active developer directory '/Library/Developer/CommandLineTools' "
        'is a command line tools instance',
        '',
      ),
    );

    expect(xcodeProjectInterpreter.versionText, isNull);
  });

  testWithoutContext('xcodebuild versionText returns formatted version text', () {
    when(processManager.runSync(<String>[xcodebuild, '-version']))
        .thenReturn(ProcessResult(1, 0, 'Xcode 8.3.3\nBuild version 8E3004b', ''));

    expect(xcodeProjectInterpreter.versionText, 'Xcode 8.3.3, Build version 8E3004b');
  });

  testWithoutContext('xcodebuild versionText handles Xcode version string with unexpected format', () {
    when(processManager.runSync(<String>[xcodebuild, '-version']))
        .thenReturn(ProcessResult(1, 0, 'Xcode Ultra5000\nBuild version 8E3004b', ''));

    expect(xcodeProjectInterpreter.versionText, 'Xcode Ultra5000, Build version 8E3004b');
  });

  testWithoutContext('xcodebuild majorVersion returns major version', () {
    when(processManager.runSync(<String>[xcodebuild, '-version']))
        .thenReturn(ProcessResult(1, 0, 'Xcode 11.4.1\nBuild version 11N111s', ''));

    expect(xcodeProjectInterpreter.majorVersion, 11);
  });

  testWithoutContext('xcodebuild majorVersion is null when version has unexpected format', () {
    when(processManager.runSync(<String>[xcodebuild, '-version']))
        .thenReturn(ProcessResult(1, 0, 'Xcode Ultra5000\nBuild version 8E3004b', ''));

    expect(xcodeProjectInterpreter.majorVersion, isNull);
  });

  testWithoutContext('xcodebuild minorVersion returns minor version', () {
    when(processManager.runSync(<String>[xcodebuild, '-version']))
        .thenReturn(ProcessResult(1, 0, 'Xcode 8.3.3\nBuild version 8E3004b', ''));

    expect(xcodeProjectInterpreter.minorVersion, 3);
  });

  testWithoutContext('xcodebuild minorVersion returns 0 when minor version is unspecified', () {
    when(processManager.runSync(<String>[xcodebuild, '-version']))
        .thenReturn(ProcessResult(1, 0, 'Xcode 8\nBuild version 8E3004b', ''));

    expect(xcodeProjectInterpreter.minorVersion, 0);
  });

  testWithoutContext('xcodebuild minorVersion is null when version has unexpected format', () {
    when(processManager.runSync(<String>[xcodebuild, '-version']))
        .thenReturn(ProcessResult(1, 0, 'Xcode Ultra5000\nBuild version 8E3004b', ''));

    expect(xcodeProjectInterpreter.minorVersion, isNull);
  });

  testWithoutContext('xcodebuild isInstalled is false when not on MacOS', () {
    final Platform platform = fakePlatform('notMacOS');
    xcodeProjectInterpreter = XcodeProjectInterpreter(
      logger: logger,
      fileSystem: fileSystem,
      platform: platform,
      processManager: processManager,
      terminal: terminal,
    );
    fileSystem.file(xcodebuild).deleteSync();

    expect(xcodeProjectInterpreter.isInstalled, isFalse);
  });

  testWithoutContext('xcodebuild isInstalled is false when xcodebuild does not exist', () {
    fileSystem.file(xcodebuild).deleteSync();

    expect(xcodeProjectInterpreter.isInstalled, isFalse);
  });

  testWithoutContext('xcodebuild isInstalled is false when Xcode is not fully installed', () {
    when(processManager.runSync(<String>[xcodebuild, '-version'])).thenReturn(
      ProcessResult(
        0,
        1,
        "xcode-select: error: tool 'xcodebuild' requires Xcode, "
        "but active developer directory '/Library/Developer/CommandLineTools' "
        'is a command line tools instance',
        '',
      ),
    );

    expect(xcodeProjectInterpreter.isInstalled, isFalse);
  });

  testWithoutContext('xcodebuild isInstalled is false when version has unexpected format', () {
    when(processManager.runSync(<String>[xcodebuild, '-version']))
        .thenReturn(ProcessResult(1, 0, 'Xcode Ultra5000\nBuild version 8E3004b', ''));

    expect(xcodeProjectInterpreter.isInstalled, isFalse);
  });

  testWithoutContext('xcodebuild isInstalled is true when version has expected format', () {
    when(processManager.runSync(<String>[xcodebuild, '-version']))
        .thenReturn(ProcessResult(1, 0, 'Xcode 8.3.3\nBuild version 8E3004b', ''));

    expect(xcodeProjectInterpreter.isInstalled, isTrue);
  });

  testWithoutContext('xcodebuild build settings is empty when xcodebuild failed to get the build settings', () async {
    when(processManager.runSync(
              argThat(contains(xcodebuild)),
              workingDirectory: anyNamed('workingDirectory'),
              environment: anyNamed('environment')))
        .thenReturn(ProcessResult(0, 1, '', ''));

    expect(await xcodeProjectInterpreter.getBuildSettings('', ''), const <String, String>{});
  });

  testWithoutContext('xcodebuild build settings flakes', () async {
    const Duration delay = Duration(seconds: 1);
    processManager.processFactory = mocks.flakyProcessFactory(
      flakes: 1,
      delay: delay + const Duration(seconds: 1),
    );

    expect(await xcodeProjectInterpreter.getBuildSettings(
                '', '', timeout: delay),
            const <String, String>{});
    // build settings times out and is killed once, then succeeds.
    verify(processManager.killPid(any)).called(1);
    // The verbose logs should tell us something timed out.
    expect(logger.traceText, contains('timed out'));
  });

  testWithoutContext('xcodebuild build settings contains Flutter Xcode environment variables', () async {
    platform.environment = Map<String, String>.unmodifiable(<String, String>{
      'FLUTTER_XCODE_CODE_SIGN_STYLE': 'Manual',
      'FLUTTER_XCODE_ARCHS': 'arm64'
    });
    when(processManager.runSync(<String>[
      xcodebuild,
      '-project',
      platform.pathSeparator,
      '-target',
      '',
      '-showBuildSettings',
      'CODE_SIGN_STYLE=Manual',
      'ARCHS=arm64'
    ],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment')))
      .thenReturn(ProcessResult(1, 0, '', ''));
    expect(await xcodeProjectInterpreter.getBuildSettings('', ''), const <String, String>{});
  });

  testWithoutContext('xcodebuild clean contains Flutter Xcode environment variables', () async {
    platform.environment = Map<String, String>.unmodifiable(<String, String>{
      'FLUTTER_XCODE_CODE_SIGN_STYLE': 'Manual',
      'FLUTTER_XCODE_ARCHS': 'arm64'
    });
    when(processManager.run(
      any,
      workingDirectory: anyNamed('workingDirectory')))
      .thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(1, 0, '', '')));
    await xcodeProjectInterpreter.cleanWorkspace('workspace_path', 'Runner');
    final List<dynamic> captured = verify(processManager.run(
      captureAny,
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'))).captured;

    expect(captured.first, <String>[
      xcodebuild,
      '-workspace',
      'workspace_path',
      '-scheme',
      'Runner',
      '-quiet',
      'clean',
      'CODE_SIGN_STYLE=Manual',
      'ARCHS=arm64'
    ]);
  });

  testWithoutContext('xcodebuild -list getInfo returns something when xcodebuild -list succeeds', () async {
    const String workingDirectory = '/';
    when(processManager.run(
      <String>[xcodebuild, '-list'],
      environment: anyNamed('environment'),
      workingDirectory: workingDirectory),
    ).thenAnswer((_) {
      return Future<ProcessResult>.value(ProcessResult(1, 0, '', ''));
    });
    final XcodeProjectInterpreter xcodeProjectInterpreter = XcodeProjectInterpreter(
      logger: logger,
      fileSystem: fileSystem,
      platform: platform,
      processManager: processManager,
      terminal: terminal,
    );

    expect(await xcodeProjectInterpreter.getInfo(workingDirectory), isNotNull);
  });

  testWithoutContext('xcodebuild -list getInfo throws a tool exit when it is unable to find a project', () async {
    const String workingDirectory = '/';
    const String stderr = 'Useful Xcode failure message about missing project.';
    when(processManager.run(
      <String>[xcodebuild, '-list'],
      environment: anyNamed('environment'),
      workingDirectory: workingDirectory),
    ).thenAnswer((_) {
      return Future<ProcessResult>.value(ProcessResult(1, 66, '', stderr));
    });
    final XcodeProjectInterpreter xcodeProjectInterpreter = XcodeProjectInterpreter(
      logger: logger,
      fileSystem: fileSystem,
      platform: platform,
      processManager: processManager,
      terminal: terminal,
    );

    expect(
        () async => await xcodeProjectInterpreter.getInfo(workingDirectory),
        throwsToolExit(message: stderr));
  });

  testWithoutContext('Xcode project properties from default project can be parsed', () {
    const String output = '''
Information about project "Runner":
    Targets:
        Runner

    Build Configurations:
        Debug
        Release

    If no build configuration is specified and -scheme is not passed then "Release" is used.

    Schemes:
        Runner

''';
    final XcodeProjectInfo info = XcodeProjectInfo.fromXcodeBuildOutput(output);
    expect(info.targets, <String>['Runner']);
    expect(info.schemes, <String>['Runner']);
    expect(info.buildConfigurations, <String>['Debug', 'Release']);
  });

  testWithoutContext('Xcode project properties from project with custom schemes can be parsed', () {
    const String output = '''
Information about project "Runner":
    Targets:
        Runner

    Build Configurations:
        Debug (Free)
        Debug (Paid)
        Release (Free)
        Release (Paid)

    If no build configuration is specified and -scheme is not passed then "Release (Free)" is used.

    Schemes:
        Free
        Paid

''';
    final XcodeProjectInfo info = XcodeProjectInfo.fromXcodeBuildOutput(output);
    expect(info.targets, <String>['Runner']);
    expect(info.schemes, <String>['Free', 'Paid']);
    expect(info.buildConfigurations, <String>['Debug (Free)', 'Debug (Paid)', 'Release (Free)', 'Release (Paid)']);
  });

  testWithoutContext('expected scheme for non-flavored build is Runner', () {
    expect(XcodeProjectInfo.expectedSchemeFor(BuildInfo.debug), 'Runner');
    expect(XcodeProjectInfo.expectedSchemeFor(BuildInfo.profile), 'Runner');
    expect(XcodeProjectInfo.expectedSchemeFor(BuildInfo.release), 'Runner');
  });

  testWithoutContext('expected build configuration for non-flavored build is derived from BuildMode', () {
    expect(XcodeProjectInfo.expectedBuildConfigurationFor(BuildInfo.debug, 'Runner'), 'Debug');
    expect(XcodeProjectInfo.expectedBuildConfigurationFor(BuildInfo.profile, 'Runner'), 'Profile');
    expect(XcodeProjectInfo.expectedBuildConfigurationFor(BuildInfo.release, 'Runner'), 'Release');
  });

  testWithoutContext('expected scheme for flavored build is the title-cased flavor', () {
    expect(XcodeProjectInfo.expectedSchemeFor(const BuildInfo(BuildMode.debug, 'hello', treeShakeIcons: false)), 'Hello');
    expect(XcodeProjectInfo.expectedSchemeFor(const BuildInfo(BuildMode.profile, 'HELLO', treeShakeIcons: false)), 'HELLO');
    expect(XcodeProjectInfo.expectedSchemeFor(const BuildInfo(BuildMode.release, 'Hello', treeShakeIcons: false)), 'Hello');
  });
  testWithoutContext('expected build configuration for flavored build is Mode-Flavor', () {
    expect(XcodeProjectInfo.expectedBuildConfigurationFor(const BuildInfo(BuildMode.debug, 'hello', treeShakeIcons: false), 'Hello'), 'Debug-Hello');
    expect(XcodeProjectInfo.expectedBuildConfigurationFor(const BuildInfo(BuildMode.profile, 'HELLO', treeShakeIcons: false), 'Hello'), 'Profile-Hello');
    expect(XcodeProjectInfo.expectedBuildConfigurationFor(const BuildInfo(BuildMode.release, 'Hello', treeShakeIcons: false), 'Hello'), 'Release-Hello');
  });

  testWithoutContext('scheme for default project is Runner', () {
    final XcodeProjectInfo info = XcodeProjectInfo(<String>['Runner'], <String>['Debug', 'Release'], <String>['Runner']);

    expect(info.schemeFor(BuildInfo.debug), 'Runner');
    expect(info.schemeFor(BuildInfo.profile), 'Runner');
    expect(info.schemeFor(BuildInfo.release), 'Runner');
    expect(info.schemeFor(const BuildInfo(BuildMode.debug, 'unknown', treeShakeIcons: false)), isNull);
  });

  testWithoutContext('build configuration for default project is matched against BuildMode', () {
    final XcodeProjectInfo info = XcodeProjectInfo(<String>['Runner'], <String>['Debug', 'Profile', 'Release'], <String>['Runner']);

    expect(info.buildConfigurationFor(BuildInfo.debug, 'Runner'), 'Debug');
    expect(info.buildConfigurationFor(BuildInfo.profile, 'Runner'), 'Profile');
    expect(info.buildConfigurationFor(BuildInfo.release, 'Runner'), 'Release');
  });

  testWithoutContext('scheme for project with custom schemes is matched against flavor', () {
    final XcodeProjectInfo info = XcodeProjectInfo(
      <String>['Runner'],
      <String>['Debug (Free)', 'Debug (Paid)', 'Release (Free)', 'Release (Paid)'],
      <String>['Free', 'Paid'],
    );

    expect(info.schemeFor(const BuildInfo(BuildMode.debug, 'free', treeShakeIcons: false)), 'Free');
    expect(info.schemeFor(const BuildInfo(BuildMode.profile, 'Free', treeShakeIcons: false)), 'Free');
    expect(info.schemeFor(const BuildInfo(BuildMode.release, 'paid', treeShakeIcons: false)), 'Paid');
    expect(info.schemeFor(const BuildInfo(BuildMode.debug, null, treeShakeIcons: false)), isNull);
    expect(info.schemeFor(const BuildInfo(BuildMode.debug, 'unknown', treeShakeIcons: false)), isNull);
  });

  testWithoutContext('build configuration for project with custom schemes is matched against BuildMode and flavor', () {
    final XcodeProjectInfo info = XcodeProjectInfo(
      <String>['Runner'],
      <String>['debug (free)', 'Debug paid', 'profile - Free', 'Profile-Paid', 'release - Free', 'Release-Paid'],
      <String>['Free', 'Paid'],
    );

    expect(info.buildConfigurationFor(const BuildInfo(BuildMode.debug, 'free', treeShakeIcons: false), 'Free'), 'debug (free)');
    expect(info.buildConfigurationFor(const BuildInfo(BuildMode.debug, 'Paid', treeShakeIcons: false), 'Paid'), 'Debug paid');
    expect(info.buildConfigurationFor(const BuildInfo(BuildMode.profile, 'FREE', treeShakeIcons: false), 'Free'), 'profile - Free');
    expect(info.buildConfigurationFor(const BuildInfo(BuildMode.release, 'paid', treeShakeIcons: false), 'Paid'), 'Release-Paid');
  });

  testWithoutContext('build configuration for project with inconsistent naming is null', () {
    final XcodeProjectInfo info = XcodeProjectInfo(
      <String>['Runner'],
      <String>['Debug-F', 'Dbg Paid', 'Rel Free', 'Release Full'],
      <String>['Free', 'Paid'],
    );
    expect(info.buildConfigurationFor(const BuildInfo(BuildMode.debug, 'Free', treeShakeIcons: false), 'Free'), null);
    expect(info.buildConfigurationFor(const BuildInfo(BuildMode.profile, 'Free', treeShakeIcons: false), 'Free'), null);
    expect(info.buildConfigurationFor(const BuildInfo(BuildMode.release, 'Paid', treeShakeIcons: false), 'Paid'), null);
  });
 group('environmentVariablesAsXcodeBuildSettings', () {
    FakePlatform platform;

    setUp(() {
      platform = fakePlatform('ignored');
    });

    testWithoutContext('environment variables as Xcode build settings', () {
      platform.environment = Map<String, String>.unmodifiable(<String, String>{
        'Ignored': 'Bogus',
        'FLUTTER_NOT_XCODE': 'Bogus',
        'FLUTTER_XCODE_CODE_SIGN_STYLE': 'Manual',
        'FLUTTER_XCODE_ARCHS': 'arm64'
      });
      final List<String> environmentVariablesAsBuildSettings = environmentVariablesAsXcodeBuildSettings(platform);
      expect(environmentVariablesAsBuildSettings, <String>['CODE_SIGN_STYLE=Manual', 'ARCHS=arm64']);
    });
  });

  group('updateGeneratedXcodeProperties', () {
    MockLocalEngineArtifacts mockArtifacts;
    MockProcessManager mockProcessManager;
    FakePlatform macOS;
    FileSystem fs;

    setUp(() {
      fs = MemoryFileSystem();
      mockArtifacts = MockLocalEngineArtifacts();
      mockProcessManager = MockProcessManager();
      macOS = fakePlatform('macos');
      fs.file(xcodebuild).createSync(recursive: true);
    });

    void testUsingOsxContext(String description, dynamic testMethod()) {
      testUsingContext(description, testMethod, overrides: <Type, Generator>{
        Artifacts: () => mockArtifacts,
        Platform: () => macOS,
        FileSystem: () => fs,
        ProcessManager: () => mockProcessManager,
      });
    }

    testUsingOsxContext('sets OTHER_LDFLAGS for iOS', () async {
      when(mockArtifacts.getArtifactPath(Artifact.flutterFramework,
          platform: TargetPlatform.ios, mode: anyNamed('mode'))).thenReturn(fs.path.join('engine', 'Flutter.framework'));
      when(mockArtifacts.engineOutPath).thenReturn(fs.path.join('out', 'ios_profile_arm'));

      const BuildInfo buildInfo = BuildInfo(BuildMode.debug, null, treeShakeIcons: false);
      final FlutterProject project = FlutterProject.fromPath('path/to/project');
      await updateGeneratedXcodeProperties(
        project: project,
        buildInfo: buildInfo,
      );

      final File config = fs.file('path/to/project/ios/Flutter/Generated.xcconfig');
      expect(config.existsSync(), isTrue);

      final String contents = config.readAsStringSync();
      expect(contents.contains('OTHER_LDFLAGS=\$(inherited) -framework Flutter'), isTrue);

      final File buildPhaseScript = fs.file('path/to/project/ios/Flutter/flutter_export_environment.sh');
      expect(buildPhaseScript.existsSync(), isTrue);

      final String buildPhaseScriptContents = buildPhaseScript.readAsStringSync();
      expect(buildPhaseScriptContents.contains('OTHER_LDFLAGS=\$(inherited) -framework Flutter'), isTrue);
    });

    testUsingOsxContext('do not set OTHER_LDFLAGS for macOS', () async {
      when(mockArtifacts.getArtifactPath(Artifact.flutterMacOSFramework,
          platform: TargetPlatform.darwin_x64, mode: anyNamed('mode'))).thenReturn(fs.path.join('engine', 'FlutterMacOS.framework'));
      when(mockArtifacts.engineOutPath).thenReturn(fs.path.join('out', 'ios_profile_arm'));

      const BuildInfo buildInfo = BuildInfo(BuildMode.debug, null, treeShakeIcons: false);
      final FlutterProject project = FlutterProject.fromPath('path/to/project');
      await updateGeneratedXcodeProperties(
        project: project,
        buildInfo: buildInfo,
        useMacOSConfig: true,
      );

      final File config = fs.file('path/to/project/macos/Flutter/ephemeral/Flutter-Generated.xcconfig');
      expect(config.existsSync(), isTrue);

      final String contents = config.readAsStringSync();
      expect(contents.contains('OTHER_LDFLAGS'), isFalse);

      final File buildPhaseScript = fs.file('path/to/project/macos/Flutter/ephemeral/flutter_export_environment.sh');
      expect(buildPhaseScript.existsSync(), isTrue);

      final String buildPhaseScriptContents = buildPhaseScript.readAsStringSync();
      expect(buildPhaseScriptContents.contains('OTHER_LDFLAGS'), isFalse);
    });

    testUsingOsxContext('sets ARCHS=armv7 when armv7 local engine is set', () async {
      when(mockArtifacts.getArtifactPath(Artifact.flutterFramework,
          platform: TargetPlatform.ios, mode: anyNamed('mode'))).thenReturn('engine');
      when(mockArtifacts.engineOutPath).thenReturn(fs.path.join('out', 'ios_profile_arm'));

      const BuildInfo buildInfo = BuildInfo(BuildMode.debug, null, treeShakeIcons: false);
      final FlutterProject project = FlutterProject.fromPath('path/to/project');
      await updateGeneratedXcodeProperties(
        project: project,
        buildInfo: buildInfo,
      );

      final File config = fs.file('path/to/project/ios/Flutter/Generated.xcconfig');
      expect(config.existsSync(), isTrue);

      final String contents = config.readAsStringSync();
      expect(contents.contains('ARCHS=armv7'), isTrue);

      final File buildPhaseScript = fs.file('path/to/project/ios/Flutter/flutter_export_environment.sh');
      expect(buildPhaseScript.existsSync(), isTrue);

      final String buildPhaseScriptContents = buildPhaseScript.readAsStringSync();
      expect(buildPhaseScriptContents.contains('ARCHS=armv7'), isTrue);
    });

    testUsingOsxContext('sets TRACK_WIDGET_CREATION=true when trackWidgetCreation is true', () async {
      when(mockArtifacts.getArtifactPath(Artifact.flutterFramework,
          platform: TargetPlatform.ios, mode: anyNamed('mode'))).thenReturn('engine');
      when(mockArtifacts.engineOutPath).thenReturn(fs.path.join('out', 'ios_profile_arm'));
      const BuildInfo buildInfo = BuildInfo(BuildMode.debug, null, trackWidgetCreation: true, treeShakeIcons: false);
      final FlutterProject project = FlutterProject.fromPath('path/to/project');
      await updateGeneratedXcodeProperties(
        project: project,
        buildInfo: buildInfo,
      );

      final File config = fs.file('path/to/project/ios/Flutter/Generated.xcconfig');
      expect(config.existsSync(), isTrue);

      final String contents = config.readAsStringSync();
      expect(contents.contains('TRACK_WIDGET_CREATION=true'), isTrue);

      final File buildPhaseScript = fs.file('path/to/project/ios/Flutter/flutter_export_environment.sh');
      expect(buildPhaseScript.existsSync(), isTrue);

      final String buildPhaseScriptContents = buildPhaseScript.readAsStringSync();
      expect(buildPhaseScriptContents.contains('TRACK_WIDGET_CREATION=true'), isTrue);
    });

    testUsingOsxContext('does not set TRACK_WIDGET_CREATION when trackWidgetCreation is false', () async {
      when(mockArtifacts.getArtifactPath(Artifact.flutterFramework,
          platform: TargetPlatform.ios, mode: anyNamed('mode'))).thenReturn('engine');
      when(mockArtifacts.engineOutPath).thenReturn(fs.path.join('out', 'ios_profile_arm'));
      const BuildInfo buildInfo = BuildInfo(BuildMode.debug, null, treeShakeIcons: false);
      final FlutterProject project = FlutterProject.fromPath('path/to/project');
      await updateGeneratedXcodeProperties(
        project: project,
        buildInfo: buildInfo,
      );

      final File config = fs.file('path/to/project/ios/Flutter/Generated.xcconfig');
      expect(config.existsSync(), isTrue);

      final String contents = config.readAsStringSync();
      expect(contents.contains('TRACK_WIDGET_CREATION=true'), isFalse);

      final File buildPhaseScript = fs.file('path/to/project/ios/Flutter/flutter_export_environment.sh');
      expect(buildPhaseScript.existsSync(), isTrue);

      final String buildPhaseScriptContents = buildPhaseScript.readAsStringSync();
      expect(buildPhaseScriptContents.contains('TRACK_WIDGET_CREATION=true'), isFalse);
    });

    testUsingOsxContext('sets ARCHS=armv7 when armv7 local engine is set', () async {
      when(mockArtifacts.getArtifactPath(Artifact.flutterFramework,
          platform: TargetPlatform.ios, mode: anyNamed('mode'))).thenReturn('engine');
      when(mockArtifacts.engineOutPath).thenReturn(fs.path.join('out', 'ios_profile'));
      const BuildInfo buildInfo = BuildInfo(BuildMode.debug, null, treeShakeIcons: false);

      final FlutterProject project = FlutterProject.fromPath('path/to/project');
      await updateGeneratedXcodeProperties(
        project: project,
        buildInfo: buildInfo,
      );

      final File config = fs.file('path/to/project/ios/Flutter/Generated.xcconfig');
      expect(config.existsSync(), isTrue);

      final String contents = config.readAsStringSync();
      expect(contents.contains('ARCHS=arm64'), isTrue);
    });

    String propertyFor(String key, File file) {
      final List<String> properties = file
          .readAsLinesSync()
          .where((String line) => line.startsWith('$key='))
          .map((String line) => line.split('=')[1])
          .toList();
      return properties.isEmpty ? null : properties.first;
    }

    Future<void> checkBuildVersion({
      String manifestString,
      BuildInfo buildInfo,
      String expectedBuildName,
      String expectedBuildNumber,
    }) async {
      when(mockArtifacts.getArtifactPath(Artifact.flutterFramework,
          platform: TargetPlatform.ios, mode: anyNamed('mode'))).thenReturn('engine');
      when(mockArtifacts.engineOutPath).thenReturn(fs.path.join('out', 'ios'));

      final File manifestFile = fs.file('path/to/project/pubspec.yaml');
      manifestFile.createSync(recursive: true);
      manifestFile.writeAsStringSync(manifestString);

      // write schemaData otherwise pubspec.yaml file can't be loaded
      writeEmptySchemaFile(fs);

      await updateGeneratedXcodeProperties(
        project: FlutterProject.fromPath('path/to/project'),
        buildInfo: buildInfo,
      );

      final File localPropertiesFile = fs.file('path/to/project/ios/Flutter/Generated.xcconfig');
      expect(propertyFor('FLUTTER_BUILD_NAME', localPropertiesFile), expectedBuildName);
      expect(propertyFor('FLUTTER_BUILD_NUMBER', localPropertiesFile), expectedBuildNumber);
      expect(propertyFor('FLUTTER_BUILD_NUMBER', localPropertiesFile), isNotNull);
    }

    testUsingOsxContext('extract build name and number from pubspec.yaml', () async {
      const String manifest = '''
name: test
version: 1.0.0+1
dependencies:
  flutter:
    sdk: flutter
flutter:
''';

      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null, treeShakeIcons: false);
      await checkBuildVersion(
        manifestString: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.0',
        expectedBuildNumber: '1',
      );
    });

    testUsingOsxContext('extract build name from pubspec.yaml', () async {
      const String manifest = '''
name: test
version: 1.0.0
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null, treeShakeIcons: false);
      await checkBuildVersion(
        manifestString: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.0',
        expectedBuildNumber: '1.0.0',
      );
    });

    testUsingOsxContext('allow build info to override build name', () async {
      const String manifest = '''
name: test
version: 1.0.0+1
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null, buildName: '1.0.2', treeShakeIcons: false);
      await checkBuildVersion(
        manifestString: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.2',
        expectedBuildNumber: '1',
      );
    });

    testUsingOsxContext('allow build info to override build name with build number fallback', () async {
      const String manifest = '''
name: test
version: 1.0.0
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null, buildName: '1.0.2', treeShakeIcons: false);
      await checkBuildVersion(
        manifestString: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.2',
        expectedBuildNumber: '1.0.2',
      );
    });

    testUsingOsxContext('allow build info to override build number', () async {
      const String manifest = '''
name: test
version: 1.0.0+1
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null, buildNumber: '3', treeShakeIcons: false);
      await checkBuildVersion(
        manifestString: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.0',
        expectedBuildNumber: '3',
      );
    });

    testUsingOsxContext('allow build info to override build name and number', () async {
      const String manifest = '''
name: test
version: 1.0.0+1
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null, buildName: '1.0.2', buildNumber: '3', treeShakeIcons: false);
      await checkBuildVersion(
        manifestString: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.2',
        expectedBuildNumber: '3',
      );
    });

    testUsingOsxContext('allow build info to override build name and set number', () async {
      const String manifest = '''
name: test
version: 1.0.0
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null, buildName: '1.0.2', buildNumber: '3', treeShakeIcons: false);
      await checkBuildVersion(
        manifestString: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.2',
        expectedBuildNumber: '3',
      );
    });

    testUsingOsxContext('allow build info to set build name and number', () async {
      const String manifest = '''
name: test
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null, buildName: '1.0.2', buildNumber: '3', treeShakeIcons: false);
      await checkBuildVersion(
        manifestString: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.2',
        expectedBuildNumber: '3',
      );
    });

    testUsingOsxContext('default build name and number when version is missing', () async {
      const String manifest = '''
name: test
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null, treeShakeIcons: false);
      await checkBuildVersion(
        manifestString: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.0',
        expectedBuildNumber: '1',
      );
    });
  });
}

FakePlatform fakePlatform(String name) {
  return FakePlatform.fromPlatform(const LocalPlatform())..operatingSystem = name;
}

class MockLocalEngineArtifacts extends Mock implements LocalEngineArtifacts {}
class MockProcessManager extends Mock implements ProcessManager {}
class MockXcodeProjectInterpreter extends Mock implements XcodeProjectInterpreter {}
class MockAnsiTerminal extends Mock implements AnsiTerminal {
  @override
  bool get supportsColor => false;
}
