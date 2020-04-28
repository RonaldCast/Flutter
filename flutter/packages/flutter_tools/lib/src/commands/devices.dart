// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/utils.dart';
import '../device.dart';
import '../doctor.dart';
import '../globals.dart' as globals;
import '../runner/flutter_command.dart';

class DevicesCommand extends FlutterCommand {
  DevicesCommand() {
    argParser.addOption(
      'timeout',
      abbr: 't',
      defaultsTo: null,
      help: 'Time in seconds to wait for devices to attach. Longer timeouts may be necessary for networked devices.'
    );
  }

  @override
  final String name = 'devices';

  @override
  final String description = 'List all connected devices.';

  Duration get timeout {
    if (argResults['timeout'] == null) {
      return null;
    }
    if (_timeout == null) {
      final int timeoutSeconds = int.tryParse(stringArg('timeout'));
      if (timeoutSeconds == null) {
        throwToolExit( 'Could not parse -t/--timeout argument. It must be an integer.');
      }
      _timeout = Duration(seconds: timeoutSeconds);
    }
    return _timeout;
  }
  Duration _timeout;

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (!doctor.canListAnything) {
      throwToolExit(
        "Unable to locate a development device; please run 'flutter doctor' for "
        'information about installing additional components.',
        exitCode: 1);
    }

    final List<Device> devices = await deviceManager.refreshAllConnectedDevices(timeout: timeout);

    if (devices.isEmpty) {
      final StringBuffer status = StringBuffer('No devices detected.');
      status.writeln();
      status.writeln();
      status.writeln('Run "flutter emulators" to list and start any available device emulators.');
      status.writeln();
      status.write('If you expected your device to be detected, please run "flutter doctor" to diagnose potential issues. ');
      if (timeout == null) {
        status.write('You may also try increasing the time to wait for connected devices with the --timeout flag. ');
      }
      status.write('Visit https://flutter.dev/setup/ for troubleshooting tips.');

      globals.printStatus(status.toString());
      final List<String> diagnostics = await deviceManager.getDeviceDiagnostics();
      if (diagnostics.isNotEmpty) {
        globals.printStatus('');
        for (final String diagnostic in diagnostics) {
          globals.printStatus('• $diagnostic', hangingIndent: 2);
        }
      }
    } else {
      globals.printStatus('${devices.length} connected ${pluralize('device', devices.length)}:\n');
      await Device.printDevices(devices);
    }

    return FlutterCommandResult.success();
  }
}
