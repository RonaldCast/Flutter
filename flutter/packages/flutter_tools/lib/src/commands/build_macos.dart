// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../build_info.dart';
import '../cache.dart';
import '../features.dart';
import '../globals.dart' as globals;
import '../macos/build_macos.dart';
import '../project.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import 'build.dart';

/// A command to build a macOS desktop target through a build shell script.
class BuildMacosCommand extends BuildSubCommand {
  BuildMacosCommand() {
    addTreeShakeIconsFlag();
    addSplitDebugInfoOption();
    usesTargetOption();
    addBuildModeFlags();
    addDartObfuscationOption();
    usesExtraFrontendOptions();
  }

  @override
  final String name = 'macos';

  @override
  bool get hidden => !featureFlags.isMacOSEnabled || !globals.platform.isMacOS;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => <DevelopmentArtifact>{
    DevelopmentArtifact.macOS,
  };

  @override
  String get description => 'build the macOS desktop target.';

  @override
  Future<FlutterCommandResult> runCommand() async {
    Cache.releaseLockEarly();
    final BuildInfo buildInfo = getBuildInfo();
    final FlutterProject flutterProject = FlutterProject.current();
    if (!featureFlags.isMacOSEnabled) {
      throwToolExit('"build macos" is not currently supported.');
    }
    if (!globals.platform.isMacOS) {
      throwToolExit('"build macos" only supported on macOS hosts.');
    }
    await buildMacOS(
      flutterProject: flutterProject,
      buildInfo: buildInfo,
      targetOverride: targetFile,
    );
    return FlutterCommandResult.success();
  }
}
