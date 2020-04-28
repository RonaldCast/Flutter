// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/ios/code_signing.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';

void main() {
  group('Auto signing', () {
    ProcessManager mockProcessManager;
    Config mockConfig;
    IosProject mockIosProject;
    BuildableIOSApp app;
    AnsiTerminal testTerminal;
    BufferLogger logger;

    setUp(() async {
      logger = BufferLogger.test();
      mockProcessManager = MockProcessManager();
      // Assume all binaries exist and are executable
      when(mockProcessManager.canRun(any)).thenReturn(true);
      mockConfig = MockConfig();
      mockIosProject = MockIosProject();
      when(mockIosProject.buildSettings).thenAnswer((_) {
        return Future<Map<String, String>>.value(<String, String>{
          'For our purposes': 'a non-empty build settings map is valid',
        });
      });
      testTerminal = TestTerminal();
      testTerminal.usesTerminalUi = true;
      app = await BuildableIOSApp.fromProject(mockIosProject);
    });

    testWithoutContext('No auto-sign if Xcode project settings are not available', () async {
      when(mockIosProject.buildSettings).thenReturn(null);
      final Map<String, String> signingConfigs = await getCodeSigningIdentityDevelopmentTeam(
        iosApp: app,
        processManager: mockProcessManager,
        logger: logger,
      );
      expect(signingConfigs, isNull);
    });

    testWithoutContext('No discovery if development team specified in Xcode project', () async {
      when(mockIosProject.buildSettings).thenAnswer((_) {
        return Future<Map<String, String>>.value(<String, String>{
          'DEVELOPMENT_TEAM': 'abc',
        });
      });
      final Map<String, String> signingConfigs = await getCodeSigningIdentityDevelopmentTeam(
        iosApp: app,
        processManager: mockProcessManager,
        logger: logger,
      );
      expect(signingConfigs, isNull);
      expect(logger.statusText, equals(
        'Automatically signing iOS for device deployment using specified development team in Xcode project: abc\n'
      ));
    });

    testWithoutContext('No auto-sign if security or openssl not available', () async {
      when(mockProcessManager.run(<String>['which', 'security']))
          .thenAnswer((_) => Future<ProcessResult>.value(exitsFail));
      final Map<String, String> signingConfigs = await getCodeSigningIdentityDevelopmentTeam(
        iosApp: app,
        processManager: mockProcessManager,
        logger: logger,
      );
      expect(signingConfigs, isNull);
    });

    testUsingContext('No valid code signing certificates shows instructions', () async {
      when(mockIosProject.buildSettings).thenAnswer((_) {
        return Future<Map<String, String>>.value(<String, String>{});
      });
      when(mockProcessManager.run(
        <String>['which', 'security'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        <String>['which', 'openssl'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        argThat(contains('find-identity')),
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));

      expect(() async => await getCodeSigningIdentityDevelopmentTeam(
        iosApp: app,
        processManager: mockProcessManager,
        logger: logger,
      ), throwsToolExit(message: 'No development certificates available to code sign app for device deployment'));
    },
    overrides: <Type, Generator>{
      OutputPreferences: () => OutputPreferences(wrapText: false),
    });

    testWithoutContext('Test single identity and certificate organization works', () async {
      when(mockProcessManager.run(
        <String>['which', 'security'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        <String>['which', 'openssl'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        argThat(contains('find-identity')),
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(
        1, // pid
        0, // exitCode
        '''
1) 86f7e437faa5a7fce15d1ddcb9eaeaea377667b8 "iPhone Developer: Profile 1 (1111AAAA11)"
    1 valid identities found''',
        '',
      )));
      when(mockProcessManager.run(
        <String>['security', 'find-certificate', '-c', '1111AAAA11', '-p'],
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(
        1, // pid
        0, // exitCode
        'This is a mock certificate',
        '',
      )));

      final MockProcess mockProcess = MockProcess();
      final MockStdIn mockStdIn = MockStdIn();
      final MockStream mockStdErr = MockStream();

      when(mockProcessManager.start(
        argThat(contains('openssl')),
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((Invocation invocation) => Future<Process>.value(mockProcess));

      when(mockProcess.stdin).thenReturn(mockStdIn);
      when(mockProcess.stdout)
          .thenAnswer((Invocation invocation) => Stream<List<int>>.fromFuture(
            Future<List<int>>.value(utf8.encode(
              'subject= /CN=iPhone Developer: Profile 1 (1111AAAA11)/OU=3333CCCC33/O=My Team/C=US'
            ))
          ));
      when(mockProcess.stderr).thenAnswer((Invocation invocation) => mockStdErr);
      when(mockProcess.exitCode).thenAnswer((_) async => 0);

      final Map<String, String> signingConfigs = await getCodeSigningIdentityDevelopmentTeam(
        iosApp: app,
        processManager: mockProcessManager,
        logger: logger,
      );

      expect(logger.statusText, contains('iPhone Developer: Profile 1 (1111AAAA11)'));
      expect(logger.errorText, isEmpty);
      verify(mockStdIn.write('This is a mock certificate'));
      expect(signingConfigs, <String, String>{'DEVELOPMENT_TEAM': '3333CCCC33'});
    });

    testWithoutContext('Test single identity (Catalina format) and certificate organization works', () async {
      when(mockProcessManager.run(
        <String>['which', 'security'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        <String>['which', 'openssl'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        argThat(contains('find-identity')),
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(
        1, // pid
        0, // exitCode
        '''
1) 86f7e437faa5a7fce15d1ddcb9eaeaea377667b8 "Apple Development: Profile 1 (1111AAAA11)"
    1 valid identities found''',
        '',
      )));
      when(mockProcessManager.run(
        <String>['security', 'find-certificate', '-c', '1111AAAA11', '-p'],
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(
        1, // pid
        0, // exitCode
        'This is a mock certificate',
        '',
      )));

      final MockProcess mockProcess = MockProcess();
      final MockStdIn mockStdIn = MockStdIn();
      final MockStream mockStdErr = MockStream();

      when(mockProcessManager.start(
        argThat(contains('openssl')),
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((Invocation invocation) => Future<Process>.value(mockProcess));

      when(mockProcess.stdin).thenReturn(mockStdIn);
      when(mockProcess.stdout)
          .thenAnswer((Invocation invocation) => Stream<List<int>>.fromFuture(
            Future<List<int>>.value(utf8.encode(
              'subject= /CN=iPhone Developer: Profile 1 (1111AAAA11)/OU=3333CCCC33/O=My Team/C=US'
            ))
          ));
      when(mockProcess.stderr).thenAnswer((Invocation invocation) => mockStdErr);
      when(mockProcess.exitCode).thenAnswer((_) async => 0);

      Map<String, String> signingConfigs;
      try {
        signingConfigs = await getCodeSigningIdentityDevelopmentTeam(
          iosApp: app,
          processManager: mockProcessManager,
          logger: logger,
        );
      } on Exception catch (e) {
        // This should not throw
        fail('Code signing threw: $e');
      }

      expect(logger.statusText, contains('Apple Development: Profile 1 (1111AAAA11)'));
      expect(logger.errorText, isEmpty);
      verify(mockStdIn.write('This is a mock certificate'));
      expect(signingConfigs, <String, String>{'DEVELOPMENT_TEAM': '3333CCCC33'});
    });

    testUsingContext('Test multiple identity and certificate organization works', () async {
      when(mockProcessManager.run(
        <String>['which', 'security'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        <String>['which', 'openssl'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        argThat(contains('find-identity')),
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(
        1, // pid
        0, // exitCode
        '''
1) 86f7e437faa5a7fce15d1ddcb9eaeaea377667b8 "iPhone Developer: Profile 1 (1111AAAA11)"
2) da4b9237bacccdf19c0760cab7aec4a8359010b0 "iPhone Developer: Profile 2 (2222BBBB22)"
3) 5bf1fd927dfb8679496a2e6cf00cbe50c1c87145 "iPhone Developer: Profile 3 (3333CCCC33)"
    3 valid identities found''',
        '',
      )));
      mockTerminalStdInStream =
          Stream<String>.fromFuture(Future<String>.value('3'));
      when(mockProcessManager.run(
        <String>['security', 'find-certificate', '-c', '3333CCCC33', '-p'],
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(
        1, // pid
        0, // exitCode
        'This is a mock certificate',
        '',
      )));

      final MockProcess mockOpenSslProcess = MockProcess();
      final MockStdIn mockOpenSslStdIn = MockStdIn();
      final MockStream mockOpenSslStdErr = MockStream();

      when(mockProcessManager.start(
        argThat(contains('openssl')),
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((Invocation invocation) => Future<Process>.value(mockOpenSslProcess));

      when(mockOpenSslProcess.stdin).thenReturn(mockOpenSslStdIn);
      when(mockOpenSslProcess.stdout)
          .thenAnswer((Invocation invocation) => Stream<List<int>>.fromFuture(
            Future<List<int>>.value(utf8.encode(
              'subject= /CN=iPhone Developer: Profile 3 (3333CCCC33)/OU=4444DDDD44/O=My Team/C=US'
            ))
          ));
      when(mockOpenSslProcess.stderr).thenAnswer((Invocation invocation) => mockOpenSslStdErr);
      when(mockOpenSslProcess.exitCode).thenAnswer((_) => Future<int>.value(0));

      final Map<String, String> signingConfigs = await getCodeSigningIdentityDevelopmentTeam(
        iosApp: app,
        processManager: mockProcessManager,
        logger: logger,
      );

      expect(
        logger.statusText,
        contains('Please select a certificate for code signing [<bold>1</bold>|2|3|a]: 3'),
      );
      expect(
        logger.statusText,
        contains('Signing iOS app for device deployment using developer identity: "iPhone Developer: Profile 3 (3333CCCC33)"'),
      );
      expect(logger.errorText, isEmpty);
      verify(mockOpenSslStdIn.write('This is a mock certificate'));
      expect(signingConfigs, <String, String>{'DEVELOPMENT_TEAM': '4444DDDD44'});

      verify(globals.config.setValue('ios-signing-cert', 'iPhone Developer: Profile 3 (3333CCCC33)'));
    },
    overrides: <Type, Generator>{
      Config: () => mockConfig,
      AnsiTerminal: () => testTerminal,
      OutputPreferences: () => OutputPreferences(wrapText: false),
    });

    testUsingContext('Test multiple identity in machine mode works', () async {
      testTerminal.usesTerminalUi = false;
      when(mockProcessManager.run(
        <String>['which', 'security'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        <String>['which', 'openssl'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        argThat(contains('find-identity')),
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(
        1, // pid
        0, // exitCode
        '''
1) 86f7e437faa5a7fce15d1ddcb9eaeaea377667b8 "iPhone Developer: Profile 1 (1111AAAA11)"
2) da4b9237bacccdf19c0760cab7aec4a8359010b0 "iPhone Developer: Profile 2 (2222BBBB22)"
3) 5bf1fd927dfb8679496a2e6cf00cbe50c1c87145 "iPhone Developer: Profile 3 (3333CCCC33)"
    3 valid identities found''',
          '',
      )));
      mockTerminalStdInStream =
        Stream<String>.fromFuture(Future<String>.error(Exception('Cannot read from StdIn')));
      when(mockProcessManager.run(
        <String>['security', 'find-certificate', '-c', '1111AAAA11', '-p'],
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(
        1, // pid
        0, // exitCode
        'This is a mock certificate',
        '',
      )));

      final MockProcess mockOpenSslProcess = MockProcess();
      final MockStdIn mockOpenSslStdIn = MockStdIn();
      final MockStream mockOpenSslStdErr = MockStream();

      when(mockProcessManager.start(
        argThat(contains('openssl')),
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((Invocation invocation) => Future<Process>.value(mockOpenSslProcess));

      when(mockOpenSslProcess.stdin).thenReturn(mockOpenSslStdIn);
      when(mockOpenSslProcess.stdout)
          .thenAnswer((Invocation invocation) => Stream<List<int>>.fromFuture(
            Future<List<int>>.value(utf8.encode(
              'subject= /CN=iPhone Developer: Profile 1 (1111AAAA11)/OU=5555EEEE55/O=My Team/C=US'
            )),
          ));
      when(mockOpenSslProcess.stderr).thenAnswer((Invocation invocation) => mockOpenSslStdErr);
      when(mockOpenSslProcess.exitCode).thenAnswer((_) => Future<int>.value(0));

      final Map<String, String> signingConfigs = await getCodeSigningIdentityDevelopmentTeam(
        iosApp: app,
        processManager: mockProcessManager,
        logger: logger,
      );

      expect(
        logger.statusText,
        contains('Signing iOS app for device deployment using developer identity: "iPhone Developer: Profile 1 (1111AAAA11)"'),
      );
      expect(logger.errorText, isEmpty);
      verify(mockOpenSslStdIn.write('This is a mock certificate'));
      expect(signingConfigs, <String, String>{'DEVELOPMENT_TEAM': '5555EEEE55'});
    },
    overrides: <Type, Generator>{
      Config: () => mockConfig,
      AnsiTerminal: () => testTerminal,
      OutputPreferences: () => OutputPreferences(wrapText: false),
    });

    testUsingContext('Test saved certificate used', () async {
      when(mockProcessManager.run(
        <String>['which', 'security'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        <String>['which', 'openssl'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        argThat(contains('find-identity')),
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(
        1, // pid
        0, // exitCode
        '''
1) 86f7e437faa5a7fce15d1ddcb9eaeaea377667b8 "iPhone Developer: Profile 1 (1111AAAA11)"
2) da4b9237bacccdf19c0760cab7aec4a8359010b0 "iPhone Developer: Profile 2 (2222BBBB22)"
3) 5bf1fd927dfb8679496a2e6cf00cbe50c1c87145 "iPhone Developer: Profile 3 (3333CCCC33)"
    3 valid identities found''',
        '',
      )));
      when(mockProcessManager.run(
        <String>['security', 'find-certificate', '-c', '3333CCCC33', '-p'],
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(
        1, // pid
        0, // exitCode
        'This is a mock certificate',
        '',
      )));

      final MockProcess mockOpenSslProcess = MockProcess();
      final MockStdIn mockOpenSslStdIn = MockStdIn();
      final MockStream mockOpenSslStdErr = MockStream();

      when(mockProcessManager.start(
        argThat(contains('openssl')),
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((Invocation invocation) => Future<Process>.value(mockOpenSslProcess));

      when(mockOpenSslProcess.stdin).thenReturn(mockOpenSslStdIn);
      when(mockOpenSslProcess.stdout)
          .thenAnswer((Invocation invocation) => Stream<List<int>>.fromFuture(
            Future<List<int>>.value(utf8.encode(
              'subject= /CN=iPhone Developer: Profile 3 (3333CCCC33)/OU=4444DDDD44/O=My Team/C=US'
            ))
          ));
      when(mockOpenSslProcess.stderr).thenAnswer((Invocation invocation) => mockOpenSslStdErr);
      when(mockOpenSslProcess.exitCode).thenAnswer((_) => Future<int>.value(0));
      when<String>(mockConfig.getValue('ios-signing-cert') as String).thenReturn('iPhone Developer: Profile 3 (3333CCCC33)');

      final Map<String, String> signingConfigs = await getCodeSigningIdentityDevelopmentTeam(
        iosApp: app,
        processManager: mockProcessManager,
        logger: logger,
      );

      expect(
        logger.statusText,
        contains('Found saved certificate choice "iPhone Developer: Profile 3 (3333CCCC33)". To clear, use "flutter config"'),
      );
      expect(
        logger.statusText,
        contains('Signing iOS app for device deployment using developer identity: "iPhone Developer: Profile 3 (3333CCCC33)"'),
      );
      expect(logger.errorText, isEmpty);
      verify(mockOpenSslStdIn.write('This is a mock certificate'));
      expect(signingConfigs, <String, String>{'DEVELOPMENT_TEAM': '4444DDDD44'});
    },
    overrides: <Type, Generator>{
      Config: () => mockConfig,
      OutputPreferences: () => OutputPreferences(wrapText: false),
    });

    testUsingContext('Test invalid saved certificate shows error and prompts again', () async {
      when(mockProcessManager.run(
        <String>['which', 'security'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        <String>['which', 'openssl'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        argThat(contains('find-identity')),
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(
        1, // pid
        0, // exitCode
        '''
1) 86f7e437faa5a7fce15d1ddcb9eaeaea377667b8 "iPhone Developer: Profile 1 (1111AAAA11)"
2) da4b9237bacccdf19c0760cab7aec4a8359010b0 "iPhone Developer: Profile 2 (2222BBBB22)"
3) 5bf1fd927dfb8679496a2e6cf00cbe50c1c87145 "iPhone Developer: Profile 3 (3333CCCC33)"
    3 valid identities found''',
        '',
      )));
      mockTerminalStdInStream =
          Stream<String>.fromFuture(Future<String>.value('3'));
      when(mockProcessManager.run(
        <String>['security', 'find-certificate', '-c', '3333CCCC33', '-p'],
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(
        1, // pid
        0, // exitCode
        'This is a mock certificate',
        '',
      )));


      final MockProcess mockOpenSslProcess = MockProcess();
      final MockStdIn mockOpenSslStdIn = MockStdIn();
      final MockStream mockOpenSslStdErr = MockStream();

      when(mockProcessManager.start(
        argThat(contains('openssl')),
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((Invocation invocation) => Future<Process>.value(mockOpenSslProcess));

      when(mockOpenSslProcess.stdin).thenReturn(mockOpenSslStdIn);
      when(mockOpenSslProcess.stdout)
          .thenAnswer((Invocation invocation) => Stream<List<int>>.fromFuture(
            Future<List<int>>.value(utf8.encode(
              'subject= /CN=iPhone Developer: Profile 3 (3333CCCC33)/OU=4444DDDD44/O=My Team/C=US'
            ))
          ));
      when(mockOpenSslProcess.stderr).thenAnswer((Invocation invocation) => mockOpenSslStdErr);
      when(mockOpenSslProcess.exitCode).thenAnswer((_) => Future<int>.value(0));
      when<String>(mockConfig.getValue('ios-signing-cert') as String).thenReturn('iPhone Developer: Invalid Profile');

      final Map<String, String> signingConfigs = await getCodeSigningIdentityDevelopmentTeam(
        iosApp: app,
        processManager: mockProcessManager,
        logger: logger,
      );

      expect(
        logger.errorText.replaceAll('\n', ' '),
        contains('Saved signing certificate "iPhone Developer: Invalid Profile" is not a valid development certificate'),
      );
      expect(
        logger.statusText,
        contains('Certificate choice "iPhone Developer: Profile 3 (3333CCCC33)"'),
      );
      expect(signingConfigs, <String, String>{'DEVELOPMENT_TEAM': '4444DDDD44'});
      verify(globals.config.setValue('ios-signing-cert', 'iPhone Developer: Profile 3 (3333CCCC33)'));
    },
    overrides: <Type, Generator>{
      Config: () => mockConfig,
      AnsiTerminal: () => testTerminal,
    });

    testWithoutContext('find-identity failure', () async {
      when(mockProcessManager.run(
        <String>['which', 'security'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        <String>['which', 'openssl'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        argThat(contains('find-identity')),
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) => Future<ProcessResult>.value(
        ProcessResult(0, 1, '', '')
      ));

      final Map<String, String> signingConfigs = await getCodeSigningIdentityDevelopmentTeam(
        iosApp: app,
        processManager: mockProcessManager,
        logger: logger,
      );
      expect(signingConfigs, isNull);
    });

    testUsingContext('find-certificate failure', () async {
      when(mockProcessManager.run(
        <String>['which', 'security'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        <String>['which', 'openssl'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        argThat(contains('find-identity')),
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(
            1, // pid
            0, // exitCode
            '''
1) 86f7e437faa5a7fce15d1ddcb9eaeaea377667b8 "iPhone Developer: Profile 1 (1111AAAA11)"
2) da4b9237bacccdf19c0760cab7aec4a8359010b0 "iPhone Developer: Profile 2 (2222BBBB22)"
3) 5bf1fd927dfb8679496a2e6cf00cbe50c1c87145 "iPhone Developer: Profile 3 (3333CCCC33)"
    3 valid identities found''',
            '',
      )));
      mockTerminalStdInStream =
          Stream<String>.fromFuture(Future<String>.value('3'));
      when(mockProcessManager.run(
        <String>['security', 'find-certificate', '-c', '3333CCCC33', '-p'],
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) => Future<ProcessResult>.value(
        ProcessResult(1, 1, '', '' ))
      );

      final Map<String, String> signingConfigs = await getCodeSigningIdentityDevelopmentTeam(
        iosApp: app,
        processManager: mockProcessManager,
        logger: logger,
      );
      expect(signingConfigs, isNull);
    },
    overrides: <Type, Generator>{
      Config: () => mockConfig,
      AnsiTerminal: () => testTerminal,
    });
  });
}

final ProcessResult exitsHappy = ProcessResult(
  1, // pid
  0, // exitCode
  '', // stdout
  '', // stderr
);

final ProcessResult exitsFail = ProcessResult(
  2, // pid
  1, // exitCode
  '', // stdout
  '', // stderr
);

class MockProcessManager extends Mock implements ProcessManager {}
class MockProcess extends Mock implements Process {}
class MockStream extends Mock implements Stream<List<int>> {}
class MockStdIn extends Mock implements IOSink {}
class MockConfig extends Mock implements Config {}

Stream<String> mockTerminalStdInStream;

class TestTerminal extends AnsiTerminal {
  TestTerminal() : super(stdio: globals.stdio, platform: globals.platform);

  @override
  String bolden(String message) => '<bold>$message</bold>';

  @override
  Stream<String> get keystrokes {
    return mockTerminalStdInStream;
  }
}
