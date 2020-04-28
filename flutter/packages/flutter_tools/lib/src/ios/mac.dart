// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../application_package.dart';
import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../cache.dart';
import '../flutter_manifest.dart';
import '../globals.dart' as globals;
import '../macos/cocoapod_utils.dart';
import '../macos/xcode.dart';
import '../project.dart';
import '../reporting/reporting.dart';
import 'code_signing.dart';
import 'migrations/ios_migrator.dart';
import 'migrations/remove_framework_link_and_embedding_migration.dart';
import 'migrations/xcode_build_system_migration.dart';
import 'xcodeproj.dart';

class IMobileDevice {
  IMobileDevice({
    @required Artifacts artifacts,
    @required Cache cache,
    @required ProcessManager processManager,
    @required Logger logger,
  }) : _idevicesyslogPath = artifacts.getArtifactPath(Artifact.idevicesyslog, platform: TargetPlatform.ios),
      _idevicescreenshotPath = artifacts.getArtifactPath(Artifact.idevicescreenshot, platform: TargetPlatform.ios),
      _dyLdLibEntry = cache.dyLdLibEntry,
      _processUtils = ProcessUtils(logger: logger, processManager: processManager),
      _processManager = processManager;

  final String _idevicesyslogPath;
  final String _idevicescreenshotPath;
  final MapEntry<String, String> _dyLdLibEntry;
  final ProcessManager _processManager;
  final ProcessUtils _processUtils;

  bool get isInstalled => _isInstalled ??= _processManager.canRun(_idevicescreenshotPath);
  bool _isInstalled;

  /// Starts `idevicesyslog` and returns the running process.
  Future<Process> startLogger(String deviceID) {
    return _processUtils.start(
      <String>[
        _idevicesyslogPath,
        '-u',
        deviceID,
      ],
      environment: Map<String, String>.fromEntries(
        <MapEntry<String, String>>[_dyLdLibEntry]
      ),
    );
  }

  /// Captures a screenshot to the specified outputFile.
  Future<void> takeScreenshot(File outputFile) {
    return _processUtils.run(
      <String>[
        _idevicescreenshotPath,
        outputFile.path,
      ],
      throwOnError: true,
      environment: Map<String, String>.fromEntries(
        <MapEntry<String, String>>[_dyLdLibEntry]
      ),
    );
  }
}

Future<XcodeBuildResult> buildXcodeProject({
  BuildableIOSApp app,
  BuildInfo buildInfo,
  String targetOverride,
  bool buildForDevice,
  DarwinArch activeArch,
  bool codesign = true,
}) async {
  if (!upgradePbxProjWithFlutterAssets(app.project, globals.logger)) {
    return XcodeBuildResult(success: false);
  }

  final List<IOSMigrator> migrators = <IOSMigrator>[
    RemoveFrameworkLinkAndEmbeddingMigration(app.project, globals.logger, globals.xcode, globals.flutterUsage),
    XcodeBuildSystemMigration(app.project, globals.logger),
  ];

  final IOSMigration migration = IOSMigration(migrators);
  if (!migration.run()) {
    return XcodeBuildResult(success: false);
  }

  if (!_checkXcodeVersion()) {
    return XcodeBuildResult(success: false);
  }

  final XcodeProjectInfo projectInfo = await globals.xcodeProjectInterpreter.getInfo(app.project.hostAppRoot.path);
  if (!projectInfo.targets.contains('Runner')) {
    globals.printError('The Xcode project does not define target "Runner" which is needed by Flutter tooling.');
    globals.printError('Open Xcode to fix the problem:');
    globals.printError('  open ios/Runner.xcworkspace');
    return XcodeBuildResult(success: false);
  }
  final String scheme = projectInfo.schemeFor(buildInfo);
  if (scheme == null) {
    globals.printError('');
    if (projectInfo.definesCustomSchemes) {
      globals.printError('The Xcode project defines schemes: ${projectInfo.schemes.join(', ')}');
      globals.printError('You must specify a --flavor option to select one of them.');
    } else {
      globals.printError('The Xcode project does not define custom schemes.');
      globals.printError('You cannot use the --flavor option.');
    }
    return XcodeBuildResult(success: false);
  }
  final String configuration = projectInfo.buildConfigurationFor(buildInfo, scheme);
  if (configuration == null) {
    globals.printError('');
    globals.printError('The Xcode project defines build configurations: ${projectInfo.buildConfigurations.join(', ')}');
    globals.printError('Flutter expects a build configuration named ${XcodeProjectInfo.expectedBuildConfigurationFor(buildInfo, scheme)} or similar.');
    globals.printError('Open Xcode to fix the problem:');
    globals.printError('  open ios/Runner.xcworkspace');
    globals.printError('1. Click on "Runner" in the project navigator.');
    globals.printError('2. Ensure the Runner PROJECT is selected, not the Runner TARGET.');
    if (buildInfo.isDebug) {
      globals.printError('3. Click the Editor->Add Configuration->Duplicate "Debug" Configuration.');
    } else {
      globals.printError('3. Click the Editor->Add Configuration->Duplicate "Release" Configuration.');
    }
    globals.printError('');
    globals.printError('   If this option is disabled, it is likely you have the target selected instead');
    globals.printError('   of the project; see:');
    globals.printError('   https://stackoverflow.com/questions/19842746/adding-a-build-configuration-in-xcode');
    globals.printError('');
    globals.printError('   If you have created a completely custom set of build configurations,');
    globals.printError('   you can set the FLUTTER_BUILD_MODE=${buildInfo.modeName.toLowerCase()}');
    globals.printError('   in the .xcconfig file for that configuration and run from Xcode.');
    globals.printError('');
    globals.printError('4. If you are not using completely custom build configurations, name the newly created configuration ${buildInfo.modeName}.');
    return XcodeBuildResult(success: false);
  }

  final FlutterManifest manifest = app.project.parent.manifest;
  final String buildName = parsedBuildName(manifest: manifest, buildInfo: buildInfo);
  final bool buildNameIsMissing = buildName == null || buildName.isEmpty;

  if (buildNameIsMissing) {
    globals.printStatus('Warning: Missing build name (CFBundleShortVersionString).');
  }

  final String buildNumber = parsedBuildNumber(manifest: manifest, buildInfo: buildInfo);
  final bool buildNumberIsMissing = buildNumber == null || buildNumber.isEmpty;

  if (buildNumberIsMissing) {
    globals.printStatus('Warning: Missing build number (CFBundleVersion).');
  }
  if (buildNameIsMissing || buildNumberIsMissing) {
    globals.printError('Action Required: You must set a build name and number in the pubspec.yaml '
      'file version field before submitting to the App Store.');
  }

  Map<String, String> autoSigningConfigs;
  if (codesign && buildForDevice) {
    autoSigningConfigs = await getCodeSigningIdentityDevelopmentTeam(
      iosApp: app,
      processManager: globals.processManager,
      logger: globals.logger
    );
  }

  final FlutterProject project = FlutterProject.current();
  await updateGeneratedXcodeProperties(
    project: project,
    targetOverride: targetOverride,
    buildInfo: buildInfo,
  );
  await processPodsIfNeeded(project.ios, getIosBuildDirectory(), buildInfo.mode);

  final List<String> buildCommands = <String>[
    '/usr/bin/env',
    'xcrun',
    'xcodebuild',
    '-configuration', configuration,
  ];

  if (globals.logger.isVerbose) {
    // An environment variable to be passed to xcode_backend.sh determining
    // whether to echo back executed commands.
    buildCommands.add('VERBOSE_SCRIPT_LOGGING=YES');
  } else {
    // This will print warnings and errors only.
    buildCommands.add('-quiet');
  }

  if (autoSigningConfigs != null) {
    for (final MapEntry<String, String> signingConfig in autoSigningConfigs.entries) {
      buildCommands.add('${signingConfig.key}=${signingConfig.value}');
    }
    buildCommands.add('-allowProvisioningUpdates');
    buildCommands.add('-allowProvisioningDeviceRegistration');
  }

  final List<FileSystemEntity> contents = app.project.hostAppRoot.listSync();
  for (final FileSystemEntity entity in contents) {
    if (globals.fs.path.extension(entity.path) == '.xcworkspace') {
      buildCommands.addAll(<String>[
        '-workspace', globals.fs.path.basename(entity.path),
        '-scheme', scheme,
        'BUILD_DIR=${globals.fs.path.absolute(getIosBuildDirectory())}',
      ]);
      break;
    }
  }

  if (buildForDevice) {
    buildCommands.addAll(<String>['-sdk', 'iphoneos']);
  } else {
    buildCommands.addAll(<String>['-sdk', 'iphonesimulator', '-arch', 'x86_64']);
  }

  if (activeArch != null) {
    final String activeArchName = getNameForDarwinArch(activeArch);
    if (activeArchName != null) {
      buildCommands.add('ONLY_ACTIVE_ARCH=YES');
      buildCommands.add('ARCHS=$activeArchName');
    }
  }

  if (!codesign) {
    buildCommands.addAll(
      <String>[
        'CODE_SIGNING_ALLOWED=NO',
        'CODE_SIGNING_REQUIRED=NO',
        'CODE_SIGNING_IDENTITY=""',
      ],
    );
  }

  Status buildSubStatus;
  Status initialBuildStatus;
  Directory tempDir;

  File scriptOutputPipeFile;
  if (globals.logger.hasTerminal) {
    tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_build_log_pipe.');
    scriptOutputPipeFile = tempDir.childFile('pipe_to_stdout');
    globals.os.makePipe(scriptOutputPipeFile.path);

    Future<void> listenToScriptOutputLine() async {
      final List<String> lines = await scriptOutputPipeFile.readAsLines();
      for (final String line in lines) {
        if (line == 'done' || line == 'all done') {
          buildSubStatus?.stop();
          buildSubStatus = null;
          if (line == 'all done') {
            // Free pipe file.
            tempDir?.deleteSync(recursive: true);
            return;
          }
        } else {
          initialBuildStatus?.cancel();
          initialBuildStatus = null;
          buildSubStatus = globals.logger.startProgress(
            line,
            timeout: timeoutConfiguration.slowOperation,
            progressIndicatorPadding: kDefaultStatusPadding - 7,
          );
        }
      }
      await listenToScriptOutputLine();
    }

    // Trigger the start of the pipe -> stdout loop. Ignore exceptions.
    unawaited(listenToScriptOutputLine());

    buildCommands.add('SCRIPT_OUTPUT_STREAM_FILE=${scriptOutputPipeFile.absolute.path}');
  }

  // Don't log analytics for downstream Flutter commands.
  // e.g. `flutter build bundle`.
  buildCommands.add('FLUTTER_SUPPRESS_ANALYTICS=true');
  buildCommands.add('COMPILER_INDEX_STORE_ENABLE=NO');
  buildCommands.addAll(environmentVariablesAsXcodeBuildSettings(globals.platform));

  final Stopwatch sw = Stopwatch()..start();
  initialBuildStatus = globals.logger.startProgress('Running Xcode build...', timeout: timeoutConfiguration.fastOperation);

  final RunResult buildResult = await _runBuildWithRetries(buildCommands, app);

  // Notifies listener that no more output is coming.
  scriptOutputPipeFile?.writeAsStringSync('all done');
  buildSubStatus?.stop();
  buildSubStatus = null;
  initialBuildStatus?.cancel();
  initialBuildStatus = null;
  globals.printStatus(
    'Xcode build done.'.padRight(kDefaultStatusPadding + 1)
        + getElapsedAsSeconds(sw.elapsed).padLeft(5),
  );
  globals.flutterUsage.sendTiming('build', 'xcode-ios', Duration(milliseconds: sw.elapsedMilliseconds));

  // Run -showBuildSettings again but with the exact same parameters as the
  // build. showBuildSettings is reported to ocassionally timeout. Here, we give
  // it a lot of wiggle room (locally on Flutter Gallery, this takes ~1s).
  // When there is a timeout, we retry once. See issue #35988.
  final List<String> showBuildSettingsCommand = (List<String>
      .from(buildCommands)
      ..add('-showBuildSettings'))
      // Undocumented behavior: xcodebuild craps out if -showBuildSettings
      // is used together with -allowProvisioningUpdates or
      // -allowProvisioningDeviceRegistration and freezes forever.
      .where((String buildCommand) {
        return !const <String>[
          '-allowProvisioningUpdates',
          '-allowProvisioningDeviceRegistration',
        ].contains(buildCommand);
      }).toList();
  const Duration showBuildSettingsTimeout = Duration(minutes: 1);
  Map<String, String> buildSettings;
  try {
    final RunResult showBuildSettingsResult = await processUtils.run(
      showBuildSettingsCommand,
      throwOnError: true,
      workingDirectory: app.project.hostAppRoot.path,
      timeout: showBuildSettingsTimeout,
      timeoutRetries: 1,
    );
    final String showBuildSettings = showBuildSettingsResult.stdout.trim();
    buildSettings = parseXcodeBuildSettings(showBuildSettings);
  } on ProcessException catch (e) {
    if (e.toString().contains('timed out')) {
      BuildEvent('xcode-show-build-settings-timeout',
        command: showBuildSettingsCommand.join(' '),
      ).send();
    }
    rethrow;
  }

  if (buildResult.exitCode != 0) {
    globals.printStatus('Failed to build iOS app');
    if (buildResult.stderr.isNotEmpty) {
      globals.printStatus('Error output from Xcode build:\n↳');
      globals.printStatus(buildResult.stderr, indent: 4);
    }
    if (buildResult.stdout.isNotEmpty) {
      globals.printStatus("Xcode's output:\n↳");
      globals.printStatus(buildResult.stdout, indent: 4);
    }
    return XcodeBuildResult(
      success: false,
      stdout: buildResult.stdout,
      stderr: buildResult.stderr,
      xcodeBuildExecution: XcodeBuildExecution(
        buildCommands: buildCommands,
        appDirectory: app.project.hostAppRoot.path,
        buildForPhysicalDevice: buildForDevice,
        buildSettings: buildSettings,
      ),
    );
  } else {
    final String expectedOutputDirectory = globals.fs.path.join(
      buildSettings['TARGET_BUILD_DIR'],
      buildSettings['WRAPPER_NAME'],
    );

    String outputDir;
    if (globals.fs.isDirectorySync(expectedOutputDirectory)) {
      // Copy app folder to a place where other tools can find it without knowing
      // the BuildInfo.
      outputDir = expectedOutputDirectory.replaceFirst('/$configuration-', '/');
      if (globals.fs.isDirectorySync(outputDir)) {
        // Previous output directory might have incompatible artifacts
        // (for example, kernel binary files produced from previous run).
        globals.fs.directory(outputDir).deleteSync(recursive: true);
      }
      globals.fsUtils.copyDirectorySync(
        globals.fs.directory(expectedOutputDirectory),
        globals.fs.directory(outputDir),
      );
    } else {
      globals.printError('Build succeeded but the expected app at $expectedOutputDirectory not found');
    }
    return XcodeBuildResult(
        success: true,
        output: outputDir,
        xcodeBuildExecution: XcodeBuildExecution(
          buildCommands: buildCommands,
          appDirectory: app.project.hostAppRoot.path,
          buildForPhysicalDevice: buildForDevice,
          buildSettings: buildSettings,
      ),
    );
  }
}

Future<RunResult> _runBuildWithRetries(List<String> buildCommands, BuildableIOSApp app) async {
  int buildRetryDelaySeconds = 1;
  int remainingTries = 8;

  RunResult buildResult;
  while (remainingTries > 0) {
    remainingTries--;
    buildRetryDelaySeconds *= 2;

    buildResult = await processUtils.run(
      buildCommands,
      workingDirectory: app.project.hostAppRoot.path,
      allowReentrantFlutter: true,
    );

    // If the result is anything other than a concurrent build failure, exit
    // the loop after the first build.
    if (!_isXcodeConcurrentBuildFailure(buildResult)) {
      break;
    }

    if (remainingTries > 0) {
      globals.printStatus('Xcode build failed due to concurrent builds, '
        'will retry in $buildRetryDelaySeconds seconds.');
      await Future<void>.delayed(Duration(seconds: buildRetryDelaySeconds));
    } else {
      globals.printStatus(
        'Xcode build failed too many times due to concurrent builds, '
        'giving up.');
      break;
    }
  }

  return buildResult;
}

bool _isXcodeConcurrentBuildFailure(RunResult result) {
return result.exitCode != 0 &&
    result.stdout != null &&
    result.stdout.contains('database is locked') &&
    result.stdout.contains('there are two concurrent builds running');
}

Future<void> diagnoseXcodeBuildFailure(XcodeBuildResult result) async {
  if (result.xcodeBuildExecution != null &&
      result.xcodeBuildExecution.buildForPhysicalDevice &&
      result.stdout?.toUpperCase()?.contains('BITCODE') == true) {
    BuildEvent('xcode-bitcode-failure',
      command: result.xcodeBuildExecution.buildCommands.toString(),
      settings: result.xcodeBuildExecution.buildSettings.toString(),
    ).send();
  }

  // Building for iOS Simulator, but the linked and embedded framework 'App.framework' was built for iOS.
  // or
  // Building for iOS, but the linked and embedded framework 'App.framework' was built for iOS Simulator.
  if (result.stdout?.contains('Building for iOS') == true
      && result.stdout?.contains('but the linked and embedded framework') == true
      && result.stdout?.contains('was built for iOS') == true) {
    globals.printError('');
    globals.printError('Your Xcode project requires migration. See https://flutter.dev/docs/development/ios-project-migration for details.');
    globals.printError('');
    globals.printError('You can temporarily work around this issue by running:');
    globals.printError('  rm -rf ios/Flutter/App.framework');
    return;
  }

  if (result.xcodeBuildExecution != null &&
      result.xcodeBuildExecution.buildForPhysicalDevice &&
      result.stdout?.contains('BCEROR') == true &&
      // May need updating if Xcode changes its outputs.
      result.stdout?.contains("Xcode couldn't find a provisioning profile matching") == true) {
    globals.printError(noProvisioningProfileInstruction, emphasis: true);
    return;
  }
  // Make sure the user has specified one of:
  // * DEVELOPMENT_TEAM (automatic signing)
  // * PROVISIONING_PROFILE (manual signing)
  if (result.xcodeBuildExecution != null &&
      result.xcodeBuildExecution.buildForPhysicalDevice &&
      !<String>['DEVELOPMENT_TEAM', 'PROVISIONING_PROFILE'].any(
        result.xcodeBuildExecution.buildSettings.containsKey)) {
    globals.printError(noDevelopmentTeamInstruction, emphasis: true);
    return;
  }
  if (result.xcodeBuildExecution != null &&
      result.xcodeBuildExecution.buildForPhysicalDevice &&
      result.xcodeBuildExecution.buildSettings['PRODUCT_BUNDLE_IDENTIFIER']?.contains('com.example') == true) {
    globals.printError('');
    globals.printError('It appears that your application still contains the default signing identifier.');
    globals.printError("Try replacing 'com.example' with your signing id in Xcode:");
    globals.printError('  open ios/Runner.xcworkspace');
    return;
  }
  if (result.stdout?.contains('Code Sign error') == true) {
    globals.printError('');
    globals.printError('It appears that there was a problem signing your application prior to installation on the device.');
    globals.printError('');
    globals.printError('Verify that the Bundle Identifier in your project is your signing id in Xcode');
    globals.printError('  open ios/Runner.xcworkspace');
    globals.printError('');
    globals.printError("Also try selecting 'Product > Build' to fix the problem:");
    return;
  }
}

class XcodeBuildResult {
  XcodeBuildResult({
    @required this.success,
    this.output,
    this.stdout,
    this.stderr,
    this.xcodeBuildExecution,
  });

  final bool success;
  final String output;
  final String stdout;
  final String stderr;
  /// The invocation of the build that resulted in this result instance.
  final XcodeBuildExecution xcodeBuildExecution;
}

/// Describes an invocation of a Xcode build command.
class XcodeBuildExecution {
  XcodeBuildExecution({
    @required this.buildCommands,
    @required this.appDirectory,
    @required this.buildForPhysicalDevice,
    @required this.buildSettings,
  });

  /// The original list of Xcode build commands used to produce this build result.
  final List<String> buildCommands;
  final String appDirectory;
  final bool buildForPhysicalDevice;
  /// The build settings corresponding to the [buildCommands] invocation.
  final Map<String, String> buildSettings;
}

const String _xcodeRequirement = 'Xcode $kXcodeRequiredVersionMajor.$kXcodeRequiredVersionMinor or greater is required to develop for iOS.';

bool _checkXcodeVersion() {
  if (!globals.platform.isMacOS) {
    return false;
  }
  if (!globals.xcodeProjectInterpreter.isInstalled) {
    globals.printError('Cannot find "xcodebuild". $_xcodeRequirement');
    return false;
  }
  if (!globals.xcode.isVersionSatisfactory) {
    globals.printError('Found "${globals.xcodeProjectInterpreter.versionText}". $_xcodeRequirement');
    return false;
  }
  return true;
}

// TODO(jmagman): Refactor to IOSMigrator.
bool upgradePbxProjWithFlutterAssets(IosProject project, Logger logger) {
  final File xcodeProjectFile = project.xcodeProjectInfoFile;
  assert(xcodeProjectFile.existsSync());
  final List<String> lines = xcodeProjectFile.readAsLinesSync();

  final RegExp oldAssets = RegExp(r'\/\* (flutter_assets|app\.flx)');
  final StringBuffer buffer = StringBuffer();
  final Set<String> printedStatuses = <String>{};

  for (final String line in lines) {
    final Match match = oldAssets.firstMatch(line);
    if (match != null) {
      if (printedStatuses.add(match.group(1))) {
        logger.printStatus('Removing obsolete reference to ${match.group(1)} from ${project.hostAppBundleName}');
      }
    } else {
      buffer.writeln(line);
    }
  }
  xcodeProjectFile.writeAsStringSync(buffer.toString());
  return true;
}
