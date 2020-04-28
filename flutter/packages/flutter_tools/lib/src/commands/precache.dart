// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../cache.dart';
import '../features.dart';
import '../globals.dart' as globals;
import '../runner/flutter_command.dart';

class PrecacheCommand extends FlutterCommand {
  PrecacheCommand({bool verboseHelp = false}) {
    argParser.addFlag('all-platforms', abbr: 'a', negatable: false,
        help: 'Precache artifacts for all host platforms.');
    argParser.addFlag('force', abbr: 'f', negatable: false,
        help: 'Force downloading of artifacts.');
    argParser.addFlag('android', negatable: true, defaultsTo: true,
        help: 'Precache artifacts for Android development.',
        hide: verboseHelp);
    argParser.addFlag('android_gen_snapshot', negatable: true, defaultsTo: true,
        help: 'Precache gen_snapshot for Android development.',
        hide: !verboseHelp);
    argParser.addFlag('android_maven', negatable: true, defaultsTo: true,
        help: 'Precache Gradle dependencies for Android development.',
        hide: !verboseHelp);
    argParser.addFlag('android_internal_build', negatable: true, defaultsTo: false,
        help: 'Precache dependencies for internal Android development.',
        hide: !verboseHelp);
    argParser.addFlag('ios', negatable: true, defaultsTo: true,
        help: 'Precache artifacts for iOS development.');
    argParser.addFlag('web', negatable: true, defaultsTo: false,
        help: 'Precache artifacts for web development.');
    argParser.addFlag('linux', negatable: true, defaultsTo: false,
        help: 'Precache artifacts for Linux desktop development.');
    argParser.addFlag('windows', negatable: true, defaultsTo: false,
        help: 'Precache artifacts for Windows desktop development.');
    argParser.addFlag('macos', negatable: true, defaultsTo: false,
        help: 'Precache artifacts for macOS desktop development.');
    argParser.addFlag('fuchsia', negatable: true, defaultsTo: false,
        help: 'Precache artifacts for Fuchsia development.');
    argParser.addFlag('universal', negatable: true, defaultsTo: true,
        help: 'Precache artifacts required for any development platform.');
    argParser.addFlag('flutter_runner', negatable: true, defaultsTo: false,
        help: 'Precache the flutter runner artifacts.', hide: true);
    argParser.addFlag('use-unsigned-mac-binaries', negatable: true, defaultsTo: false,
        help: 'Precache the unsigned mac binaries when available.', hide: true);
  }

  @override
  final String name = 'precache';

  @override
  final String description = "Populates the Flutter tool's cache of binary artifacts.";

  @override
  bool get shouldUpdateCache => false;

  /// Some flags are umbrella names that expand to include multiple artifacts.
  static const Map<String, List<String>> _expandedArtifacts = <String, List<String>>{
    'android': <String>[
      'android_gen_snapshot',
      'android_maven',
      'android_internal_build',
    ]
  };

  /// Returns a reverse mapping of _expandedArtifacts, from child artifact name
  /// to umbrella name.
  Map<String, String> _umbrellaForArtifactMap() {
    return <String, String>{
      for (final MapEntry<String, List<String>> entry in _expandedArtifacts.entries)
        for (final String childArtifactName in entry.value)
          childArtifactName: entry.key
    };
  }

  /// Returns the name of all artifacts that were explicitly chosen via flags.
  ///
  /// If an umbrella is chosen, its children will be included as well.
  Set<String> _explicitArtifactSelections() {
    final Map<String, String> umbrellaForArtifact = _umbrellaForArtifactMap();
    final Set<String> selections = <String>{};
    bool explicitlySelected(String name) => boolArg(name) && argResults.wasParsed(name);
    for (final DevelopmentArtifact artifact in DevelopmentArtifact.values) {
      final String umbrellaName = umbrellaForArtifact[artifact.name];
      if (explicitlySelected(artifact.name) ||
          (umbrellaName != null && explicitlySelected(umbrellaName))) {
        selections.add(artifact.name);
      }
    }
    return selections;
  }

  @override
  Future<void> validateCommand() {
    _expandedArtifacts.forEach((String umbrellaName, List<String> childArtifactNames) {
      if (!argResults.arguments.contains('--no-$umbrellaName')) {
        return;
      }
      for (final String childArtifactName in childArtifactNames) {
        if (argResults.arguments.contains('--$childArtifactName')) {
          throwToolExit('--$childArtifactName requires --$umbrellaName');
        }
      }
    });

    return super.validateCommand();
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final bool includeAllPlatforms = boolArg('all-platforms');
    if (includeAllPlatforms) {
      globals.cache.includeAllPlatforms = true;
    }
    if (boolArg('use-unsigned-mac-binaries')) {
      globals.cache.useUnsignedMacBinaries = true;
    }
    globals.cache.platformOverrideArtifacts = _explicitArtifactSelections();
    final Map<String, String> umbrellaForArtifact = _umbrellaForArtifactMap();
    final Set<DevelopmentArtifact> requiredArtifacts = <DevelopmentArtifact>{};
    for (final DevelopmentArtifact artifact in DevelopmentArtifact.values) {
      // Don't include unstable artifacts on stable branches.
      if (!globals.flutterVersion.isMaster && artifact.unstable) {
        continue;
      }
      if (artifact.feature != null && !featureFlags.isEnabled(artifact.feature)) {
        continue;
      }

      final String argumentName = umbrellaForArtifact[artifact.name] ?? artifact.name;
      if (includeAllPlatforms || boolArg(argumentName)) {
        requiredArtifacts.add(artifact);
      }
    }
    final bool forceUpdate = boolArg('force');
    if (forceUpdate || !globals.cache.isUpToDate()) {
      await globals.cache.updateAll(requiredArtifacts);
    } else {
      globals.printStatus('Already up-to-date.');
    }
    return FlutterCommandResult.success();
  }
}
