// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_console.dart';
import 'package:flutter_tools/src/android/android_device.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:platform/platform.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  testUsingContext('AndroidDevice stores the requested id', () {
    const String deviceId = '1234';
    final AndroidDevice device = AndroidDevice(deviceId);
    expect(device.id, deviceId);
  });

  group('parseAdbDeviceProperties', () {
    test('parse adb shell output', () {
      final Map<String, String> properties = parseAdbDeviceProperties(kAdbShellGetprop);
      expect(properties, isNotNull);
      expect(properties['ro.build.characteristics'], 'emulator');
      expect(properties['ro.product.cpu.abi'], 'x86_64');
      expect(properties['ro.build.version.sdk'], '23');
    });
  });

  group('adb.exe exiting with heap corruption on windows', () {
    final ProcessManager mockProcessManager = MockProcessManager();
    String hardware;
    String buildCharacteristics;

    setUp(() {
      hardware = 'goldfish';
      buildCharacteristics = 'unused';
      exitCode = -1;
      when(mockProcessManager.run(
        argThat(contains('getprop')),
        stderrEncoding: anyNamed('stderrEncoding'),
        stdoutEncoding: anyNamed('stdoutEncoding'),
      )).thenAnswer((_) {
        final StringBuffer buf = StringBuffer()
          ..writeln('[ro.hardware]: [$hardware]')..writeln(
              '[ro.build.characteristics]: [$buildCharacteristics]');
        final ProcessResult result = ProcessResult(1, exitCode, buf.toString(), '');
        return Future<ProcessResult>.value(result);
      });
    });

    testUsingContext('nonHeapCorruptionErrorOnWindows', () async {
      exitCode = -1073740941;
      final AndroidDevice device = AndroidDevice('test');
      expect(await device.isLocalEmulator, false);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Platform: () => FakePlatform(
        operatingSystem: 'windows',
        environment: <String, String>{
          'ANDROID_HOME': '/',
        },
      ),
    });

    testUsingContext('heapCorruptionOnWindows', () async {
      exitCode = -1073740940;
      final AndroidDevice device = AndroidDevice('test');
      expect(await device.isLocalEmulator, true);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Platform: () => FakePlatform(
        operatingSystem: 'windows',
        environment: <String, String>{
          'ANDROID_HOME': '/',
        },
      ),
    });

    testUsingContext('heapCorruptionExitCodeOnLinux', () async {
      exitCode = -1073740940;
      final AndroidDevice device = AndroidDevice('test');
      expect(await device.isLocalEmulator, false);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Platform: () => FakePlatform(
        operatingSystem: 'linux',
        environment: <String, String>{
          'ANDROID_HOME': '/',
        },
      ),
    });

    testUsingContext('noErrorOnLinux', () async {
      exitCode = 0;
      final AndroidDevice device = AndroidDevice('test');
      expect(await device.isLocalEmulator, true);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Platform: () => FakePlatform(
        operatingSystem: 'linux',
        environment: <String, String>{
          'ANDROID_HOME': '/',
        },
      ),
    });
  });

  group('ABI detection', () {
    ProcessManager mockProcessManager;
    String cpu;
    String abilist;

    setUp(() {
      mockProcessManager = MockProcessManager();
      cpu = 'unknown';
      abilist = 'unknown';
      when(mockProcessManager.run(
        argThat(contains('getprop')),
        stderrEncoding: anyNamed('stderrEncoding'),
        stdoutEncoding: anyNamed('stdoutEncoding'),
      )).thenAnswer((_) {
        final StringBuffer buf = StringBuffer()
          ..writeln('[ro.product.cpu.abi]: [$cpu]')
          ..writeln('[ro.product.cpu.abilist]: [$abilist]');
        final ProcessResult result = ProcessResult(1, 0, buf.toString(), '');
        return Future<ProcessResult>.value(result);
      });
    });

    testUsingContext('detects x64', () async {
      cpu = 'x86_64';
      final AndroidDevice device = AndroidDevice('test');

      expect(await device.targetPlatform, TargetPlatform.android_x64);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager
    });

    testUsingContext('detects x86', () async {
      cpu = 'x86';
      final AndroidDevice device = AndroidDevice('test');

      expect(await device.targetPlatform, TargetPlatform.android_x86);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager
    });

    testUsingContext('unknown device defaults to 32bit arm', () async {
      cpu = '???';
      final AndroidDevice device = AndroidDevice('test');

      expect(await device.targetPlatform, TargetPlatform.android_arm);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager
    });

    testUsingContext('detects 64 bit arm', () async {
      cpu = 'arm64-v8a';
      abilist = 'arm64-v8a,';
      final AndroidDevice device = AndroidDevice('test');

      // If both abi properties agree, we are 64 bit.
      expect(await device.targetPlatform, TargetPlatform.android_arm64);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager
    });

    testUsingContext('detects kindle fire ABI', () async {
      cpu = 'arm64-v8a';
      abilist = 'arm';
      final AndroidDevice device = AndroidDevice('test');

      // If one does not contain arm64, assume 32 bit.
      expect(await device.targetPlatform, TargetPlatform.android_arm);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager
    });
  });

  group('isLocalEmulator', () {
    final ProcessManager mockProcessManager = MockProcessManager();
    String hardware;
    String buildCharacteristics;

    setUp(() {
      hardware = 'unknown';
      buildCharacteristics = 'unused';
      when(mockProcessManager.run(
        argThat(contains('getprop')),
        stderrEncoding: anyNamed('stderrEncoding'),
        stdoutEncoding: anyNamed('stdoutEncoding'),
      )).thenAnswer((_) {
        final StringBuffer buf = StringBuffer()
          ..writeln('[ro.hardware]: [$hardware]')
          ..writeln('[ro.build.characteristics]: [$buildCharacteristics]');
        final ProcessResult result = ProcessResult(1, 0, buf.toString(), '');
        return Future<ProcessResult>.value(result);
      });
    });

    testUsingContext('knownPhysical', () async {
      hardware = 'samsungexynos7420';
      final AndroidDevice device = AndroidDevice('test');
      expect(await device.isLocalEmulator, false);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('knownPhysical Samsung SM G570M', () async {
      hardware = 'samsungexynos7570';
      final AndroidDevice device = AndroidDevice('test');
      expect(await device.isLocalEmulator, false);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('knownEmulator', () async {
      hardware = 'goldfish';
      final AndroidDevice device = AndroidDevice('test');
      expect(await device.isLocalEmulator, true);
      expect(await device.supportsHardwareRendering, true);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('unknownPhysical', () async {
      buildCharacteristics = 'att';
      final AndroidDevice device = AndroidDevice('test');
      expect(await device.isLocalEmulator, false);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('unknownEmulator', () async {
      buildCharacteristics = 'att,emulator';
      final AndroidDevice device = AndroidDevice('test');
      expect(await device.isLocalEmulator, true);
      expect(await device.supportsHardwareRendering, true);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });
  });

  testUsingContext('isSupportedForProject is true on module project', () async {
    globals.fs.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: example

flutter:
  module: {}
''');
    globals.fs.file('.packages').createSync();
    final FlutterProject flutterProject = FlutterProject.current();

    expect(AndroidDevice('test').isSupportedForProject(flutterProject), true);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('isSupportedForProject is true with editable host app', () async {
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    globals.fs.directory('android').createSync();
    final FlutterProject flutterProject = FlutterProject.current();

    expect(AndroidDevice('test').isSupportedForProject(flutterProject), true);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('isSupportedForProject is false with no host app and no module', () async {
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    final FlutterProject flutterProject = FlutterProject.current();

    expect(AndroidDevice('test').isSupportedForProject(flutterProject), false);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  group('emulatorId', () {
    final ProcessManager mockProcessManager = MockProcessManager();
    const String dummyEmulatorId = 'dummyEmulatorId';
    final Future<Socket> Function(String host, int port) unresponsiveSocket =
        (String host, int port) async => MockUnresponsiveAndroidConsoleSocket();
    final Future<Socket> Function(String host, int port) disconnectingSocket =
        (String host, int port) async => MockDisconnectingAndroidConsoleSocket();
    final Future<Socket> Function(String host, int port) workingSocket =
        (String host, int port) async => MockWorkingAndroidConsoleSocket(dummyEmulatorId);
    String hardware;
    bool socketWasCreated;

    setUp(() {
      hardware = 'goldfish'; // Known emulator
      socketWasCreated = false;
      when(mockProcessManager.run(
        argThat(contains('getprop')),
        stderrEncoding: anyNamed('stderrEncoding'),
        stdoutEncoding: anyNamed('stdoutEncoding'),
      )).thenAnswer((_) {
        final StringBuffer buf = StringBuffer()
          ..writeln('[ro.hardware]: [$hardware]');
        final ProcessResult result = ProcessResult(1, 0, buf.toString(), '');
        return Future<ProcessResult>.value(result);
      });
    });

    testUsingContext('returns correct ID for responsive emulator', () async {
      final AndroidDevice device = AndroidDevice('emulator-5555');
      expect(await device.emulatorId, equals(dummyEmulatorId));
    }, overrides: <Type, Generator>{
      AndroidConsoleSocketFactory: () => workingSocket,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('does not create socket for non-emulator devices', () async {
      hardware = 'samsungexynos7420';

      // Still use an emulator-looking ID so we can be sure the failure is due
      // to the isLocalEmulator field and not because the ID doesn't contain a
      // port.
      final AndroidDevice device = AndroidDevice('emulator-5555');
      expect(await device.emulatorId, isNull);
      expect(socketWasCreated, isFalse);
    }, overrides: <Type, Generator>{
      AndroidConsoleSocketFactory: () => (String host, int port) async {
        socketWasCreated = true;
        throw 'Socket was created for non-emulator';
      },
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('does not create socket for emulators with no port', () async {
      final AndroidDevice device = AndroidDevice('emulator-noport');
      expect(await device.emulatorId, isNull);
      expect(socketWasCreated, isFalse);
    }, overrides: <Type, Generator>{
      AndroidConsoleSocketFactory: () => (String host, int port) async {
        socketWasCreated = true;
        throw 'Socket was created for emulator without port in ID';
      },
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('returns null for connection error', () async {
      final AndroidDevice device = AndroidDevice('emulator-5555');
      expect(await device.emulatorId, isNull);
    }, overrides: <Type, Generator>{
      AndroidConsoleSocketFactory: () {
        return (String host, int port) => throw Exception('Fake socket error');
      },
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('returns null for unresponsive device', () async {
      final AndroidDevice device = AndroidDevice('emulator-5555');
      expect(await device.emulatorId, isNull);
    }, overrides: <Type, Generator>{
      AndroidConsoleSocketFactory: () => unresponsiveSocket,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('returns null on early disconnect', () async {
      final AndroidDevice device = AndroidDevice('emulator-5555');
      expect(await device.emulatorId, isNull);
    }, overrides: <Type, Generator>{
      AndroidConsoleSocketFactory: () => disconnectingSocket,
      ProcessManager: () => mockProcessManager,
    });
  });

  group('portForwarder', () {
    final ProcessManager mockProcessManager = MockProcessManager();
    final AndroidDevice device = AndroidDevice('1234');
    final DevicePortForwarder forwarder = device.portForwarder;

    testUsingContext('returns the generated host port from stdout', () async {
      when(mockProcessManager.run(argThat(contains('forward'))))
          .thenAnswer((_) async => ProcessResult(0, 0, '456', ''));

      expect(await forwarder.forward(123), equals(456));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('returns the supplied host port when stdout is empty', () async {
      when(mockProcessManager.run(argThat(contains('forward'))))
          .thenAnswer((_) async => ProcessResult(0, 0, '', ''));

      expect(await forwarder.forward(123, hostPort: 456), equals(456));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('returns the supplied host port when stdout is the host port', () async {
      when(mockProcessManager.run(argThat(contains('forward'))))
          .thenAnswer((_) async => ProcessResult(0, 0, '456', ''));

      expect(await forwarder.forward(123, hostPort: 456), equals(456));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('throws an error when stdout is not blank nor the host port', () async {
      when(mockProcessManager.run(argThat(contains('forward'))))
          .thenAnswer((_) async => ProcessResult(0, 0, '123456', ''));

      expect(forwarder.forward(123, hostPort: 456), throwsA(isA<ProcessException>()));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('forwardedPorts returns empty list when forward failed', () {
      when(mockProcessManager.runSync(argThat(contains('forward'))))
          .thenReturn(ProcessResult(0, 1, '', ''));

      expect(forwarder.forwardedPorts, equals(const <ForwardedPort>[]));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('disposing device disposes the portForwarder', () async {
      bool unforwardCalled = false;
      when(mockProcessManager.run(argThat(containsAll(<String>[
        'forward',
        'tcp:0',
        'tcp:123',
      ])))).thenAnswer((_) async {
        return ProcessResult(0, 0, '456', '');
      });
      when(mockProcessManager.runSync(argThat(containsAll(<String>[
        'forward',
        '--list',
      ])))).thenReturn(ProcessResult(0, 0, '1234 tcp:456 tcp:123', ''));
      when(mockProcessManager.run(argThat(containsAll(<String>[
        'forward',
        '--remove',
        'tcp:456',
      ])))).thenAnswer((_) async {
        unforwardCalled = true;
        return ProcessResult(0, 0, '', '');
      });
      expect(await forwarder.forward(123), equals(456));

      await device.dispose();

      expect(unforwardCalled, isTrue);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });
  });

  group('logcat', () {
    final ProcessManager mockProcessManager = MockProcessManager();
    final AndroidDevice device = AndroidDevice('1234');

    testUsingContext('lastLogcatTimestamp returns null if shell command failed', () async {
      when(mockProcessManager.runSync(argThat(contains('logcat'))))
          .thenReturn(ProcessResult(0, 1, '', ''));
      expect(device.lastLogcatTimestamp, isNull);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('AdbLogReaders for past+future and future logs are not the same', () async {
      when(mockProcessManager.run(
        argThat(contains('getprop')),
        stderrEncoding: anyNamed('stderrEncoding'),
        stdoutEncoding: anyNamed('stdoutEncoding'),
      )).thenAnswer((_) {
        final StringBuffer buf = StringBuffer()
          ..writeln('[ro.build.version.sdk]: [23]');
        final ProcessResult result = ProcessResult(1, exitCode, buf.toString(), '');
        return Future<ProcessResult>.value(result);
      });
      when(mockProcessManager.run(
        argThat(contains('shell')),
        stderrEncoding: anyNamed('stderrEncoding'),
        stdoutEncoding: anyNamed('stdoutEncoding'),
      )).thenAnswer((_) {
        final StringBuffer buf = StringBuffer()
          ..writeln('11-27 15:39:04.506');
        final ProcessResult result = ProcessResult(1, exitCode, buf.toString(), '');
        return Future<ProcessResult>.value(result);
      });
      final DeviceLogReader pastLogReader = await device.getLogReader(includePastLogs: true);
      final DeviceLogReader defaultLogReader = await device.getLogReader();
      expect(pastLogReader, isNot(equals(defaultLogReader)));
      // Getting again is cached.
      expect(pastLogReader, equals(await device.getLogReader(includePastLogs: true)));
      expect(defaultLogReader, equals(await device.getLogReader()));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });
  });

  test('Can parse adb shell dumpsys info', () {
    const String exampleOutput = r'''
Applications Memory Usage (in Kilobytes):
Uptime: 441088659 Realtime: 521464097

** MEMINFO in pid 16141 [io.flutter.demo.gallery] **
                   Pss  Private  Private  SwapPss     Heap     Heap     Heap
                 Total    Dirty    Clean    Dirty     Size    Alloc     Free
                ------   ------   ------   ------   ------   ------   ------
  Native Heap     8648     8620        0       16    20480    12403     8076
  Dalvik Heap      547      424       40       18     2628     1092     1536
 Dalvik Other      464      464        0        0
        Stack      496      496        0        0
       Ashmem        2        0        0        0
      Gfx dev      212      204        0        0
    Other dev       48        0       48        0
     .so mmap    10770      708     9372       25
    .apk mmap      240        0        0        0
    .ttf mmap       35        0       32        0
    .dex mmap     2205        4     1172        0
    .oat mmap       64        0        0        0
    .art mmap     4228     3848       24        2
   Other mmap    20713        4    20704        0
    GL mtrack     2380     2380        0        0
      Unknown    43971    43968        0        1
        TOTAL    95085    61120    31392       62    23108    13495     9612

 App Summary
                       Pss(KB)
                        ------
           Java Heap:     4296
         Native Heap:     8620
                Code:    11288
               Stack:      496
            Graphics:     2584
       Private Other:    65228
              System:     2573

               TOTAL:    95085       TOTAL SWAP PSS:       62

 Objects
               Views:        9         ViewRootImpl:        1
         AppContexts:        3           Activities:        1
              Assets:        4        AssetManagers:        3
       Local Binders:       10        Proxy Binders:       18
       Parcel memory:        6         Parcel count:       24
    Death Recipients:        0      OpenSSL Sockets:        0
            WebViews:        0

 SQL
         MEMORY_USED:        0
  PAGECACHE_OVERFLOW:        0          MALLOC_SIZE:        0
''';

    final AndroidMemoryInfo result = parseMeminfoDump(exampleOutput);

    // Parses correctly
    expect(result.realTime, 521464097);
    expect(result.javaHeap, 4296);
    expect(result.nativeHeap, 8620);
    expect(result.code, 11288);
    expect(result.stack, 496);
    expect(result.graphics, 2584);
    expect(result.privateOther, 65228);
    expect(result.system, 2573);

    // toJson works correctly
    final Map<String, Object> json = result.toJson();

    expect(json, containsPair('Realtime', 521464097));
    expect(json, containsPair('Java Heap', 4296));
    expect(json, containsPair('Native Heap', 8620));
    expect(json, containsPair('Code', 11288));
    expect(json, containsPair('Stack', 496));
    expect(json, containsPair('Graphics', 2584));
    expect(json, containsPair('Private Other', 65228));
    expect(json, containsPair('System', 2573));

    // computed from summation of other fields.
    expect(json, containsPair('Total', 95085));

    // contains identifier for platform in memory info.
    expect(json, containsPair('platform', 'Android'));
  });
}

class MockProcessManager extends Mock implements ProcessManager {}

const String kAdbShellGetprop = '''
[dalvik.vm.dex2oat-Xms]: [64m]
[dalvik.vm.dex2oat-Xmx]: [512m]
[dalvik.vm.heapsize]: [384m]
[dalvik.vm.image-dex2oat-Xms]: [64m]
[dalvik.vm.image-dex2oat-Xmx]: [64m]
[dalvik.vm.isa.x86.variant]: [dalvik.vm.isa.x86.features=default]
[dalvik.vm.isa.x86_64.features]: [default]
[dalvik.vm.isa.x86_64.variant]: [x86_64]
[dalvik.vm.lockprof.threshold]: [500]
[dalvik.vm.stack-trace-file]: [/data/anr/traces.txt]
[debug.atrace.tags.enableflags]: [0]
[debug.force_rtl]: [0]
[gsm.current.phone-type]: [1]
[gsm.network.type]: [Unknown]
[gsm.nitz.time]: [1473102078793]
[gsm.operator.alpha]: []
[gsm.operator.iso-country]: []
[gsm.operator.isroaming]: [false]
[gsm.operator.numeric]: []
[gsm.sim.operator.alpha]: []
[gsm.sim.operator.iso-country]: []
[gsm.sim.operator.numeric]: []
[gsm.sim.state]: [NOT_READY]
[gsm.version.ril-impl]: [android reference-ril 1.0]
[init.svc.adbd]: [running]
[init.svc.bootanim]: [running]
[init.svc.console]: [running]
[init.svc.debuggerd]: [running]
[init.svc.debuggerd64]: [running]
[init.svc.drm]: [running]
[init.svc.fingerprintd]: [running]
[init.svc.gatekeeperd]: [running]
[init.svc.goldfish-logcat]: [stopped]
[init.svc.goldfish-setup]: [stopped]
[init.svc.healthd]: [running]
[init.svc.installd]: [running]
[init.svc.keystore]: [running]
[init.svc.lmkd]: [running]
[init.svc.logd]: [running]
[init.svc.logd-reinit]: [stopped]
[init.svc.media]: [running]
[init.svc.netd]: [running]
[init.svc.perfprofd]: [running]
[init.svc.qemu-props]: [stopped]
[init.svc.ril-daemon]: [running]
[init.svc.servicemanager]: [running]
[init.svc.surfaceflinger]: [running]
[init.svc.ueventd]: [running]
[init.svc.vold]: [running]
[init.svc.zygote]: [running]
[init.svc.zygote_secondary]: [running]
[net.bt.name]: [Android]
[net.change]: [net.qtaguid_enabled]
[net.eth0.dns1]: [10.0.2.3]
[net.eth0.gw]: [10.0.2.2]
[net.gprs.local-ip]: [10.0.2.15]
[net.hostname]: [android-ccd858aa3d3825ee]
[net.qtaguid_enabled]: [1]
[net.tcp.default_init_rwnd]: [60]
[persist.sys.dalvik.vm.lib.2]: [libart.so]
[persist.sys.profiler_ms]: [0]
[persist.sys.timezone]: [America/Los_Angeles]
[persist.sys.usb.config]: [adb]
[qemu.gles]: [1]
[qemu.hw.mainkeys]: [0]
[qemu.sf.fake_camera]: [none]
[qemu.sf.lcd_density]: [420]
[rild.libargs]: [-d /dev/ttyS0]
[rild.libpath]: [/system/lib/libreference-ril.so]
[ro.allow.mock.location]: [0]
[ro.baseband]: [unknown]
[ro.board.platform]: []
[ro.boot.hardware]: [ranchu]
[ro.bootimage.build.date]: [Wed Jul 20 21:03:09 UTC 2016]
[ro.bootimage.build.date.utc]: [1469048589]
[ro.bootimage.build.fingerprint]: [Android/sdk_google_phone_x86_64/generic_x86_64:6.0/MASTER/3079352:userdebug/test-keys]
[ro.bootloader]: [unknown]
[ro.bootmode]: [unknown]
[ro.build.characteristics]: [emulator]
[ro.build.date]: [Wed Jul 20 21:02:14 UTC 2016]
[ro.build.date.utc]: [1469048534]
[ro.build.description]: [sdk_google_phone_x86_64-userdebug 6.0 MASTER 3079352 test-keys]
[ro.build.display.id]: [sdk_google_phone_x86_64-userdebug 6.0 MASTER 3079352 test-keys]
[ro.build.fingerprint]: [Android/sdk_google_phone_x86_64/generic_x86_64:6.0/MASTER/3079352:userdebug/test-keys]
[ro.build.flavor]: [sdk_google_phone_x86_64-userdebug]
[ro.build.host]: [vpba14.mtv.corp.google.com]
[ro.build.id]: [MASTER]
[ro.build.product]: [generic_x86_64]
[ro.build.tags]: [test-keys]
[ro.build.type]: [userdebug]
[ro.build.user]: [android-build]
[ro.build.version.all_codenames]: [REL]
[ro.build.version.base_os]: []
[ro.build.version.codename]: [REL]
[ro.build.version.incremental]: [3079352]
[ro.build.version.preview_sdk]: [0]
[ro.build.version.release]: [6.0]
[ro.build.version.sdk]: [23]
[ro.build.version.security_patch]: [2015-10-01]
[ro.com.google.locationfeatures]: [1]
[ro.config.alarm_alert]: [Alarm_Classic.ogg]
[ro.config.nocheckin]: [yes]
[ro.config.notification_sound]: [OnTheHunt.ogg]
[ro.crypto.state]: [unencrypted]
[ro.dalvik.vm.native.bridge]: [0]
[ro.debuggable]: [1]
[ro.hardware]: [ranchu]
[ro.hardware.audio.primary]: [goldfish]
[ro.hwui.drop_shadow_cache_size]: [6]
[ro.hwui.gradient_cache_size]: [1]
[ro.hwui.layer_cache_size]: [48]
[ro.hwui.path_cache_size]: [32]
[ro.hwui.r_buffer_cache_size]: [8]
[ro.hwui.text_large_cache_height]: [1024]
[ro.hwui.text_large_cache_width]: [2048]
[ro.hwui.text_small_cache_height]: [1024]
[ro.hwui.text_small_cache_width]: [1024]
[ro.hwui.texture_cache_flushrate]: [0.4]
[ro.hwui.texture_cache_size]: [72]
[ro.kernel.android.checkjni]: [1]
[ro.kernel.android.qemud]: [1]
[ro.kernel.androidboot.hardware]: [ranchu]
[ro.kernel.clocksource]: [pit]
[ro.kernel.qemu]: [1]
[ro.kernel.qemu.gles]: [1]
[ro.opengles.version]: [131072]
[ro.product.board]: []
[ro.product.brand]: [Android]
[ro.product.cpu.abi]: [x86_64]
[ro.product.cpu.abilist]: [x86_64,x86]
[ro.product.cpu.abilist32]: [x86]
[ro.product.cpu.abilist64]: [x86_64]
[ro.product.device]: [generic_x86_64]
[ro.product.locale]: [en-US]
[ro.product.manufacturer]: [unknown]
[ro.product.model]: [Android SDK built for x86_64]
[ro.product.name]: [sdk_google_phone_x86_64]
[ro.radio.use-ppp]: [no]
[ro.revision]: [0]
[ro.secure]: [1]
[ro.serialno]: []
[ro.wifi.channels]: []
[ro.zygote]: [zygote64_32]
[selinux.reload_policy]: [1]
[service.bootanim.exit]: [0]
[status.battery.level]: [5]
[status.battery.level_raw]: [50]
[status.battery.level_scale]: [9]
[status.battery.state]: [Slow]
[sys.sysctl.extra_free_kbytes]: [24300]
[sys.usb.config]: [adb]
[sys.usb.state]: [adb]
[vold.has_adoptable]: [1]
[wlan.driver.status]: [unloaded]
[xmpp.auto-presence]: [true]
''';

/// A mock Android Console that presents a connection banner and responds to
/// "avd name" requests with the supplied name.
class MockWorkingAndroidConsoleSocket extends Mock implements Socket {
  MockWorkingAndroidConsoleSocket(this.avdName) {
    _controller.add('Android Console: Welcome!\n');
    // Include OK in the same packet here. In the response to "avd name"
    // it's sent alone to ensure both are handled.
    _controller.add('Android Console: Some intro text\nOK\n');
  }

  final String avdName;
  final StreamController<String> _controller = StreamController<String>();

  @override
  Stream<E> asyncMap<E>(FutureOr<E> convert(Uint8List event)) => _controller.stream as Stream<E>;

  @override
  void add(List<int> data) {
    final String text = ascii.decode(data);
    if (text == 'avd name\n') {
      _controller.add('$avdName\n');
      // Include OK in its own packet here. In welcome banner it's included
      // as part of the previous text to ensure both are handled.
      _controller.add('OK\n');
    } else {
      throw 'Unexpected command $text';
    }
  }
}

/// An Android console socket that drops all input and returns no output.
class MockUnresponsiveAndroidConsoleSocket extends Mock implements Socket {
  final StreamController<String> _controller = StreamController<String>();

  @override
  Stream<E> asyncMap<E>(FutureOr<E> convert(Uint8List event)) => _controller.stream as Stream<E>;

  @override
  void add(List<int> data) {}
}

/// An Android console socket that drops all input and returns no output.
class MockDisconnectingAndroidConsoleSocket extends Mock implements Socket {
  MockDisconnectingAndroidConsoleSocket() {
    _controller.add('Android Console: Welcome!\n');
    // Include OK in the same packet here. In the response to "avd name"
    // it's sent alone to ensure both are handled.
    _controller.add('Android Console: Some intro text\nOK\n');
  }

  final StreamController<String> _controller = StreamController<String>();

  @override
  Stream<E> asyncMap<E>(FutureOr<E> convert(Uint8List event)) => _controller.stream as Stream<E>;

  @override
  void add(List<int> data) {
    _controller.close();
  }
}

class AndroidPackageTest extends ApplicationPackage {
  AndroidPackageTest() : super(id: 'app-id');

  @override
  String get name => 'app-package';
}
