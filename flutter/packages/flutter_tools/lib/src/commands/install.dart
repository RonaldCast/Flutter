// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../application_package.dart';
import '../base/common.dart';
import '../base/io.dart';
import '../cache.dart';
import '../device.dart';
import '../globals.dart' as globals;
import '../runner/flutter_command.dart';

class InstallCommand extends FlutterCommand with DeviceBasedDevelopmentArtifacts {
  InstallCommand() {
    requiresPubspecYaml();
    argParser.addFlag('uninstall-only',
      negatable: true,
      defaultsTo: false,
      help: 'Uninstall the app if already on the device. Skip install.',
    );
  }

  @override
  final String name = 'install';

  @override
  final String description = 'Install a Flutter app on an attached device.';

  Device device;

  bool get uninstallOnly => boolArg('uninstall-only');

  @override
  Future<void> validateCommand() async {
    await super.validateCommand();
    device = await findTargetDevice();
    if (device == null) {
      throwToolExit('No target device found');
    }
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final ApplicationPackage package = await applicationPackages.getPackageForPlatform(await device.targetPlatform);

    Cache.releaseLockEarly();

    if (uninstallOnly) {
      await _uninstallApp(package);
    } else {
      await _installApp(package);
    }
    return FlutterCommandResult.success();
  }

  Future<void> _uninstallApp(ApplicationPackage package) async {
    if (await device.isAppInstalled(package)) {
      globals.printStatus('Uninstalling $package from $device...');
      if (!await device.uninstallApp(package)) {
        globals.printError('Uninstalling old version failed');
      }
    } else {
      globals.printStatus('$package not found on $device, skipping uninstall');
    }
  }

  Future<void> _installApp(ApplicationPackage package) async {
    globals.printStatus('Installing $package to $device...');

    if (!await installApp(device, package)) {
      throwToolExit('Install failed');
    }
  }
}

Future<bool> installApp(Device device, ApplicationPackage package, { bool uninstall = true }) async {
  if (package == null) {
    return false;
  }

  try {
    if (uninstall && await device.isAppInstalled(package)) {
      globals.printStatus('Uninstalling old version...');
      if (!await device.uninstallApp(package)) {
        globals.printError('Warning: uninstalling old version failed');
      }
    }
  } on ProcessException catch (e) {
    globals.printError('Error accessing device ${device.id}:\n${e.message}');
  }

  return device.installApp(package);
}
