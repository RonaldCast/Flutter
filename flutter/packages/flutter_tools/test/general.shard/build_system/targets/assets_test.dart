// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/depfile.dart';
import 'package:flutter_tools/src/build_system/targets/assets.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';

void main() {
  Environment environment;
  FileSystem fileSystem;
  Platform platform;

  setUp(() {
    platform = FakePlatform();
    fileSystem = MemoryFileSystem.test();
    environment = Environment.test(
      fileSystem.currentDirectory,
      processManager: FakeProcessManager.any(),
      artifacts: MockArtifacts(),
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
    );
    fileSystem.file(environment.buildDir.childFile('app.dill')).createSync(recursive: true);
    fileSystem.file('packages/flutter_tools/lib/src/build_system/targets/assets.dart')
      .createSync(recursive: true);
    fileSystem.file('assets/foo/bar.png')
      .createSync(recursive: true);
    fileSystem.file('assets/wildcard/#bar.png')
      .createSync(recursive: true);
    fileSystem.file('.packages')
      .createSync();
    fileSystem.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync('''
name: example

flutter:
  assets:
    - assets/foo/bar.png
    - assets/wildcard/
''');
  });

  testUsingContext('includes LICENSE file inputs in dependencies', () async {
    fileSystem.file('.packages')
      .writeAsStringSync('foo:file:///bar/lib');
    fileSystem.file('bar/LICENSE')
      ..createSync(recursive: true)
      ..writeAsStringSync('THIS IS A LICENSE');

    await const CopyAssets().build(environment);

    final File depfile = environment.buildDir.childFile('flutter_assets.d');

    expect(depfile, exists);

    final DepfileService depfileService = DepfileService(
      logger: null,
      fileSystem: fileSystem,
      platform: platform,
    );
    final Depfile dependencies = depfileService.parse(depfile);

    expect(
      dependencies.inputs.firstWhere((File file) => file.path == '/bar/LICENSE', orElse: () => null),
      isNotNull,
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    Platform: () => platform,
  });

  testUsingContext('Copies files to correct asset directory', () async {
    await const CopyAssets().build(environment);

    expect(fileSystem.file('${environment.buildDir.path}/flutter_assets/AssetManifest.json'), exists);
    expect(fileSystem.file('${environment.buildDir.path}/flutter_assets/FontManifest.json'), exists);
    expect(fileSystem.file('${environment.buildDir.path}/flutter_assets/LICENSE'), exists);
    // See https://github.com/flutter/flutter/issues/35293
    expect(fileSystem.file('${environment.buildDir.path}/flutter_assets/assets/foo/bar.png'), exists);
    // See https://github.com/flutter/flutter/issues/46163
    expect(fileSystem.file('${environment.buildDir.path}/flutter_assets/assets/wildcard/%23bar.png'), exists);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    Platform: () => platform,
  });
}

class MockArtifacts extends Mock implements Artifacts {}
