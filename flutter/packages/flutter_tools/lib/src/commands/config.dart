// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../android/android_sdk.dart';
import '../android/android_studio.dart';
import '../base/common.dart';
import '../convert.dart';
import '../features.dart';
import '../globals.dart' as globals;
import '../reporting/reporting.dart';
import '../runner/flutter_command.dart';

class ConfigCommand extends FlutterCommand {
  ConfigCommand({ bool verboseHelp = false }) {
    argParser.addFlag('analytics',
      negatable: true,
      help: 'Enable or disable reporting anonymously tool usage statistics and crash reports.');
    argParser.addFlag('clear-ios-signing-cert',
      negatable: false,
      help: 'Clear the saved development certificate choice used to sign apps for iOS device deployment.');
    argParser.addOption('android-sdk', help: 'The Android SDK directory.');
    argParser.addOption('android-studio-dir', help: 'The Android Studio install directory.');
    argParser.addOption('build-dir', help: 'The relative path to override a projects build directory',
        valueHelp: 'out/');
    argParser.addFlag('machine',
      negatable: false,
      hide: !verboseHelp,
      help: 'Print config values as json.');
    for (final Feature feature in allFeatures) {
      if (feature.configSetting == null) {
        continue;
      }
      argParser.addFlag(
        feature.configSetting,
        help: feature.generateHelpMessage(),
        negatable: true,
      );
    }
    argParser.addFlag(
      'clear-features',
      help: 'Remove all configured features and restore them to the default values.',
      negatable: false,
    );
  }

  @override
  final String name = 'config';

  @override
  final String description =
    'Configure Flutter settings.\n\n'
    'To remove a setting, configure it to an empty string.\n\n'
    'The Flutter tool anonymously reports feature usage statistics and basic crash reports to help improve '
    "Flutter tools over time. See Google's privacy policy: https://www.google.com/intl/en/policies/privacy/";

  @override
  final List<String> aliases = <String>['configure'];

  @override
  bool get shouldUpdateCache => false;

  @override
  String get usageFooter {
    // List all config settings. for feature flags, include whether they
    // are available.
    final Map<String, Feature> featuresByName = <String, Feature>{};
    final String channel = globals.flutterVersion.channel;
    for (final Feature feature in allFeatures) {
      if (feature.configSetting != null) {
        featuresByName[feature.configSetting] = feature;
      }
    }
    String values = globals.config.keys
        .map<String>((String key) {
          String configFooter = '';
          if (featuresByName.containsKey(key)) {
            final FeatureChannelSetting setting = featuresByName[key].getSettingForChannel(channel);
            if (!setting.available) {
              configFooter = '(Unavailable)';
            }
          }
          return '  $key: ${globals.config.getValue(key)} $configFooter';
        }).join('\n');
    if (values.isEmpty) {
      values = '  No settings have been configured.';
    }
    return
      '\nSettings:\n$values\n\n'
      'Analytics reporting is currently ${globals.flutterUsage.enabled ? 'enabled' : 'disabled'}.';
  }

  /// Return null to disable analytics recording of the `config` command.
  @override
  Future<String> get usagePath async => null;

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (boolArg('machine')) {
      await handleMachine();
      return FlutterCommandResult.success();
    }

    if (boolArg('clear-features')) {
      for (final Feature feature in allFeatures) {
        if (feature.configSetting != null) {
          globals.config.removeValue(feature.configSetting);
        }
      }
      return FlutterCommandResult.success();
    }

    if (argResults.wasParsed('analytics')) {
      final bool value = boolArg('analytics');
      // We send the analytics event *before* toggling the flag intentionally
      // to be sure that opt-out events are sent correctly.
      AnalyticsConfigEvent(enabled: value).send();
      globals.flutterUsage.enabled = value;
      globals.printStatus('Analytics reporting ${value ? 'enabled' : 'disabled'}.');
    }

    if (argResults.wasParsed('android-sdk')) {
      _updateConfig('android-sdk', stringArg('android-sdk'));
    }

    if (argResults.wasParsed('android-studio-dir')) {
      _updateConfig('android-studio-dir', stringArg('android-studio-dir'));
    }

    if (argResults.wasParsed('clear-ios-signing-cert')) {
      _updateConfig('ios-signing-cert', '');
    }

    if (argResults.wasParsed('build-dir')) {
      final String buildDir = stringArg('build-dir');
      if (globals.fs.path.isAbsolute(buildDir)) {
        throwToolExit('build-dir should be a relative path');
      }
      _updateConfig('build-dir', buildDir);
    }

    for (final Feature feature in allFeatures) {
      if (feature.configSetting == null) {
        continue;
      }
      if (argResults.wasParsed(feature.configSetting)) {
        final bool keyValue = boolArg(feature.configSetting);
        globals.config.setValue(feature.configSetting, keyValue);
        globals.printStatus('Setting "${feature.configSetting}" value to "$keyValue".');
      }
    }

    if (argResults.arguments.isEmpty) {
      globals.printStatus(usage);
    } else {
      globals.printStatus('\nYou may need to restart any open editors for them to read new settings.');
    }

    return FlutterCommandResult.success();
  }

  Future<void> handleMachine() async {
    // Get all the current values.
    final Map<String, dynamic> results = <String, dynamic>{};
    for (final String key in globals.config.keys) {
      results[key] = globals.config.getValue(key);
    }

    // Ensure we send any calculated ones, if overrides don't exist.
    if (results['android-studio-dir'] == null && androidStudio != null) {
      results['android-studio-dir'] = androidStudio.directory;
    }
    if (results['android-sdk'] == null && androidSdk != null) {
      results['android-sdk'] = androidSdk.directory;
    }

    globals.printStatus(const JsonEncoder.withIndent('  ').convert(results));
  }

  void _updateConfig(String keyName, String keyValue) {
    if (keyValue.isEmpty) {
      globals.config.removeValue(keyName);
      globals.printStatus('Removing "$keyName" value.');
    } else {
      globals.config.setValue(keyName, keyValue);
      globals.printStatus('Setting "$keyName" value to "$keyValue".');
    }
  }
}
