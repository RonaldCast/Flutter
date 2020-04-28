// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

import '../analyze.dart';
import '../utils.dart';
import 'common.dart';

typedef AsyncVoidCallback = Future<void> Function();

Future<String> capture(AsyncVoidCallback callback, { int exitCode = 0 }) async {
  final StringBuffer buffer = StringBuffer();
  final PrintCallback oldPrint = print;
  try {
    print = (Object line) {
      buffer.writeln(line);
    };
    try {
      await callback();
      expect(exitCode, 0);
    } on ExitException catch (error) {
      expect(error.exitCode, exitCode);
    }
  } finally {
    print = oldPrint;
  }
  return buffer.toString();
}

void main() {
  final String testRootPath = path.join('test', 'analyze-test-input', 'root');

  test('analyze.dart - verifyDeprecations', () async {
    final String result = await capture(() => verifyDeprecations(testRootPath, minimumMatches: 2), exitCode: 1);
    expect(result,
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
      +
      (
        'test/analyze-test-input/root/packages/foo/deprecation.dart:12: Deprecation notice does not match required pattern.\n'
        'test/analyze-test-input/root/packages/foo/deprecation.dart:18: Deprecation notice should be a grammatically correct sentence and start with a capital letter; see style guide.\n'
        'test/analyze-test-input/root/packages/foo/deprecation.dart:25: Deprecation notice should be a grammatically correct sentence and end with a period.\n'
        'test/analyze-test-input/root/packages/foo/deprecation.dart:29: Deprecation notice does not match required pattern.\n'
        'test/analyze-test-input/root/packages/foo/deprecation.dart:32: Deprecation notice does not match required pattern.\n'
        'test/analyze-test-input/root/packages/foo/deprecation.dart:37: Deprecation notice does not match required pattern.\n'
        'test/analyze-test-input/root/packages/foo/deprecation.dart:41: Deprecation notice does not match required pattern.\n'
        'test/analyze-test-input/root/packages/foo/deprecation.dart:48: End of deprecation notice does not match required pattern.\n'
        'test/analyze-test-input/root/packages/foo/deprecation.dart:51: Unexpected deprecation notice indent.\n'
        .replaceAll('/', Platform.isWindows ? r'\' : '/')
      )
      +
      'See: https://github.com/flutter/flutter/wiki/Tree-hygiene#handling-breaking-changes\n'
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
    );
  });

  test('analyze.dart - verifyNoMissingLicense', () async {
    final String result = await capture(() => verifyNoMissingLicense(testRootPath, checkMinimums: false), exitCode: 1);
    expect(result,
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
      +
      (
        'The following 1 file does not have the right license header:\n'
        'test/analyze-test-input/root/packages/foo/foo.dart\n'
        .replaceAll('/', Platform.isWindows ? r'\' : '/')
      )
      +
      'The expected license header is:\n'
      '// Copyright 2014 The Flutter Authors. All rights reserved.\n'
      '// Use of this source code is governed by a BSD-style license that can be\n'
      '// found in the LICENSE file.\n'
      '...followed by a blank line.\n'
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
    );
  });

  test('analyze.dart - verifyNoTrailingSpaces', () async {
    final String result = await capture(() => verifyNoTrailingSpaces(testRootPath, minimumMatches: 2), exitCode: 1);
    expect(result,
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
      +
      (
        'test/analyze-test-input/root/packages/foo/spaces.txt:5: trailing U+0020 space character\n'
        'test/analyze-test-input/root/packages/foo/spaces.txt:9: trailing blank line\n'
        .replaceAll('/', Platform.isWindows ? r'\' : '/')
      )
      +
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
    );
  });

  test('analyze.dart - verifyNoBinaries - positive', () async {
    final String result = await capture(() => verifyNoBinaries(
      testRootPath,
      grandfatheredBinaries: <Hash256>{Hash256(0x39A050CD69434936, 0, 0, 0)},
    ), exitCode: Platform.isWindows ? 0 : 1);
    if (!Platform.isWindows) {
      // The output starts with the call to git ls-files, the details of which
      // change from run to run, so we only check the trailing end of the output.
      expect(result, endsWith('\n'
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        'test/analyze-test-input/root/packages/foo/serviceaccount.enc:0: file is not valid UTF-8\n'
        'All files in this repository must be UTF-8. In particular, images and other binaries\n'
        'must not be checked into this repository. This is because we are very sensitive to the\n'
        'size of the repository as it is distributed to all our developers. If you have a binary\n'
        'to which you need access, you should consider how to fetch it from another repository;\n'
        'for example, the "assets-for-api-docs" repository is used for images in API docs.\n'
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
      ));
    }
  });

  test('analyze.dart - verifyNoBinaries - negative', () async {
    await capture(() => verifyNoBinaries(
      testRootPath,
      grandfatheredBinaries: <Hash256>{
        Hash256(0xA8100AE6AA1940D0, 0xB663BB31CD466142, 0xEBBDBD5187131B92, 0xD93818987832EB89), // sha256("\xff")
        Hash256(0x155644D3F13D98BF, 0, 0, 0),
      },
    ), exitCode: 0);
  });
}
