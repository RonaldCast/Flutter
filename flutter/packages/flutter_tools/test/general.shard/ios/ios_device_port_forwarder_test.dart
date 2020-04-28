// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/ios/devices.dart';

import '../../src/common.dart';
import '../../src/context.dart';

const Map<String, String> kDyLdLibEntry = <String, String>{
  'DYLD_LIBRARY_PATH': '/path/to/libs',
};

void main() {
  // By default, the .forward() method will try every port between 1024
  // and 65535; this test verifies we are killing iproxy processes when
  // we timeout on a port
  testWithoutContext('IOSDevicePortForwarder.forward will kill iproxy processes before invoking a second', () async {
    const int devicePort = 456;
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>['iproxy', '1024', '456', '1234'],
        // iproxy does not exit with 0 when it cannot forward.
        exitCode: 0,
        stdout: null, // no stdout indicates failure.
        environment: kDyLdLibEntry,
      ),
      const FakeCommand(
        command: <String>['iproxy', '1025', '456', '1234'],
        exitCode: 0,
        stdout: 'not empty',
        environment: kDyLdLibEntry,
      ),
    ]);
    final IOSDevicePortForwarder portForwarder = IOSDevicePortForwarder.test(
      processManager: processManager,
      logger: BufferLogger.test(),
    );
    final int hostPort = await portForwarder.forward(devicePort);

    // First port tried (1024) should fail, then succeed on the next
    expect(hostPort, 1024 + 1);
    expect(processManager.hasRemainingExpectations, false);
  });
}
