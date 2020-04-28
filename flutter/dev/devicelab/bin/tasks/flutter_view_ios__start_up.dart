// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_devicelab/framework/utils.dart';
import 'package:flutter_devicelab/tasks/perf_tests.dart';
import 'package:flutter_devicelab/framework/adb.dart';
import 'package:flutter_devicelab/framework/framework.dart';

Future<void> main() async {
  deviceOperatingSystem = DeviceOperatingSystem.ios;
  await task(() async {
    final Directory iosDirectory = dir(
      '${flutterDirectory.path}/examples/flutter_view/ios',
    );
    await inDirectory(iosDirectory, () async {
      await exec(
        'pod',
        <String>['install'],
        environment: <String, String>{
          'LANG': 'en_US.UTF-8',
        },
      );
    });

    final TaskFunction taskFunction = createFlutterViewStartupTest();
    return await taskFunction();
  });
}
