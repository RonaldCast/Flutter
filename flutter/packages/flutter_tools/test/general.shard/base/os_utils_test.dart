// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  group('OperatingSystemUtils', () {
    Directory tempDir;

    setUp(() {
      tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_tools_os_utils_test.');
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    testUsingContext('makeExecutable', () async {
      final File file = globals.fs.file(globals.fs.path.join(tempDir.path, 'foo.script'));
      file.writeAsStringSync('hello world');
      globals.os.makeExecutable(file);

      // Skip this test on windows.
      if (!globals.platform.isWindows) {
        final String mode = file.statSync().modeString();
        // rwxr--r--
        expect(mode.substring(0, 3), endsWith('x'));
      }
    }, overrides: <Type, Generator>{
      OperatingSystemUtils: () => OperatingSystemUtils(
        fileSystem: globals.fs,
        logger: globals.logger,
        platform: globals.platform,
        processManager: globals.processManager,
      ),
    });
  });
}
