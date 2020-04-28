// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../convert.dart';
import '../globals.dart' as globals;

/// An environment variable used to override the location of chrome.
const String kChromeEnvironment = 'CHROME_EXECUTABLE';

/// The expected executable name on linux.
const String kLinuxExecutable = 'google-chrome';

/// The expected executable name on macOS.
const String kMacOSExecutable =
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';

/// The expected executable name on Windows.
const String kWindowsExecutable = r'Google\Chrome\Application\chrome.exe';

/// Find the chrome executable on the current platform.
///
/// Does not verify whether the executable exists.
String findChromeExecutable(Platform platform, FileSystem fileSystem) {
  if (platform.environment.containsKey(kChromeEnvironment)) {
    return platform.environment[kChromeEnvironment];
  }
  if (platform.isLinux) {
    return kLinuxExecutable;
  }
  if (platform.isMacOS) {
    return kMacOSExecutable;
  }
  if (platform.isWindows) {
    /// The possible locations where the chrome executable can be located on windows.
    final List<String> kWindowsPrefixes = <String>[
      platform.environment['LOCALAPPDATA'],
      platform.environment['PROGRAMFILES'],
      platform.environment['PROGRAMFILES(X86)'],
    ];
    final String windowsPrefix = kWindowsPrefixes.firstWhere((String prefix) {
      if (prefix == null) {
        return false;
      }
      final String path = fileSystem.path.join(prefix, kWindowsExecutable);
      return fileSystem.file(path).existsSync();
    }, orElse: () => '.');
    return fileSystem.path.join(windowsPrefix, kWindowsExecutable);
  }
  throwToolExit('Platform ${platform.operatingSystem} is not supported.');
  return null;
}

@visibleForTesting
void resetChromeForTesting() {
  ChromeLauncher._currentCompleter = Completer<Chrome>();
}

@visibleForTesting
void launchChromeInstance(Chrome chrome) {
  ChromeLauncher._currentCompleter.complete(chrome);
}

/// Responsible for launching chrome with devtools configured.
class ChromeLauncher {
  const ChromeLauncher({
    @required FileSystem fileSystem,
    @required Platform platform,
    @required ProcessManager processManager,
    @required OperatingSystemUtils operatingSystemUtils,
    @required Logger logger,
  }) : _fileSystem = fileSystem,
       _platform = platform,
       _processManager = processManager,
       _operatingSystemUtils = operatingSystemUtils,
       _logger = logger;

  final FileSystem _fileSystem;
  final Platform _platform;
  final ProcessManager _processManager;
  final OperatingSystemUtils _operatingSystemUtils;
  final Logger _logger;

  static bool get hasChromeInstance => _currentCompleter.isCompleted;

  static Completer<Chrome> _currentCompleter = Completer<Chrome>();

  /// Whether we can locate the chrome executable.
  bool canFindChrome() {
    final String chrome = findChromeExecutable(_platform, _fileSystem);
    try {
      return _processManager.canRun(chrome);
    } on ArgumentError {
      return false;
    }
  }

  /// Launch the chrome browser to a particular `host` page.
  ///
  /// `headless` defaults to false, and controls whether we open a headless or
  /// a `headfull` browser.
  ///
  /// `debugPort` is Chrome's debugging protocol port. If null, a random free
  /// port is picked automatically.
  ///
  /// `skipCheck` does not attempt to make a devtools connection before returning.
  Future<Chrome> launch(String url, { bool headless = false, int debugPort, bool skipCheck = false, Directory cacheDir }) async {
    if (_currentCompleter.isCompleted) {
      throwToolExit('Only one instance of chrome can be started.');
    }

    final String chromeExecutable = findChromeExecutable(_platform, _fileSystem);
    final Directory userDataDir = _fileSystem.systemTempDirectory.createTempSync('flutter_tools_chrome_device.');

    if (cacheDir != null) {
      // Seed data dir with previous state.
      _restoreUserSessionInformation(cacheDir, userDataDir);
    }

    final int port = debugPort ?? await _operatingSystemUtils.findFreePort();
    final List<String> args = <String>[
      chromeExecutable,
      // Using a tmp directory ensures that a new instance of chrome launches
      // allowing for the remote debug port to be enabled.
      '--user-data-dir=${userDataDir.path}',
      '--remote-debugging-port=$port',
      // When the DevTools has focus we don't want to slow down the application.
      '--disable-background-timer-throttling',
      // Since we are using a temp profile, disable features that slow the
      // Chrome launch.
      '--disable-extensions',
      '--disable-popup-blocking',
      '--bwsi',
      '--no-first-run',
      '--no-default-browser-check',
      '--disable-default-apps',
      '--disable-translate',
      if (headless)
        ...<String>['--headless', '--disable-gpu', '--no-sandbox', '--window-size=2400,1800'],
      url,
    ];

    final Process process = await _processManager.start(args);

    // When the process exits, copy the user settings back to the provided data-dir.
    if (cacheDir != null) {
      unawaited(process.exitCode.whenComplete(() {
        _cacheUserSessionInformation(userDataDir, cacheDir);
      }));
    }

    process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((String line) {
        _logger.printTrace('[CHROME]: $line');
      });

    // Wait until the DevTools are listening before trying to connect.
    await process.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .map((String line) {
        _logger.printTrace('[CHROME]:$line');
        return line;
      })
      .firstWhere((String line) => line.startsWith('DevTools listening'), orElse: () {
        return 'Failed to spawn stderr';
      });
    final Uri remoteDebuggerUri = await _getRemoteDebuggerUrl(Uri.parse('http://localhost:$port'));
    return _connect(Chrome._(
      port,
      ChromeConnection('localhost', port),
      url: url,
      process: process,
      remoteDebuggerUri: remoteDebuggerUri,
    ), skipCheck);
  }

  // This is a JSON file which contains configuration from the browser session,
  // such as window position. It is located under the Chrome data-dir folder.
  String get _preferencesPath => _fileSystem.path.join('Default', 'preferences');

  // The directory that Chrome uses to store local storage information for web apps.
  String get _localStoragePath => _fileSystem.path.join('Default', 'Local Storage');

  /// Copy Chrome user information from a Chrome session into a per-project
  /// cache.
  ///
  /// Note: more detailed docs of the Chrome user preferences store exists here:
  /// https://www.chromium.org/developers/design-documents/preferences.
  void _cacheUserSessionInformation(Directory userDataDir, Directory cacheDir) {
    final File targetPreferencesFile = _fileSystem.file(_fileSystem.path.join(cacheDir?.path ?? '', _preferencesPath));
    final File sourcePreferencesFile = _fileSystem.file(_fileSystem.path.join(userDataDir.path, _preferencesPath));
    final Directory targetLocalStorageDir = _fileSystem.directory(_fileSystem.path.join(cacheDir?.path ?? '', _localStoragePath));
    final Directory sourceLocalStorageDir = _fileSystem.directory(_fileSystem.path.join(userDataDir.path, _localStoragePath));

    if (sourcePreferencesFile.existsSync()) {
      targetPreferencesFile.parent.createSync(recursive: true);
      // If the file contains a crash string, remove it to hide the popup on next run.
      final String contents = sourcePreferencesFile.readAsStringSync();
      targetPreferencesFile.writeAsStringSync(contents
          .replaceFirst('"exit_type":"Crashed"', '"exit_type":"Normal"'));
    }

    if (sourceLocalStorageDir.existsSync()) {
      targetLocalStorageDir.createSync(recursive: true);
      globals.fsUtils.copyDirectorySync(sourceLocalStorageDir, targetLocalStorageDir);
    }
  }

  /// Restore Chrome user information from a per-project cache into Chrome's
  /// user data directory.
  void _restoreUserSessionInformation(Directory cacheDir, Directory userDataDir) {
    final File sourcePreferencesFile = _fileSystem.file(_fileSystem.path.join(cacheDir.path ?? '', _preferencesPath));
    final File targetPreferencesFile = _fileSystem.file(_fileSystem.path.join(userDataDir.path, _preferencesPath));
    final Directory sourceLocalStorageDir = _fileSystem.directory(_fileSystem.path.join(cacheDir.path ?? '', _localStoragePath));
    final Directory targetLocalStorageDir = _fileSystem.directory(_fileSystem.path.join(userDataDir.path, _localStoragePath));

    if (sourcePreferencesFile.existsSync()) {
      targetPreferencesFile.parent.createSync(recursive: true);
      sourcePreferencesFile.copySync(targetPreferencesFile.path);
    }

    if (sourceLocalStorageDir.existsSync()) {
      targetLocalStorageDir.createSync(recursive: true);
      globals.fsUtils.copyDirectorySync(sourceLocalStorageDir, targetLocalStorageDir);
    }
  }

  static Future<Chrome> _connect(Chrome chrome, bool skipCheck) async {
    // The connection is lazy. Try a simple call to make sure the provided
    // connection is valid.
    if (!skipCheck) {
      try {
        await chrome.chromeConnection.getTabs();
      } on Exception catch (e) {
        await chrome.close();
        throwToolExit(
            'Unable to connect to Chrome debug port: ${chrome.debugPort}\n $e');
      }
    }
    _currentCompleter.complete(chrome);
    return chrome;
  }

  static Future<Chrome> get connectedInstance => _currentCompleter.future;

  /// Returns the full URL of the Chrome remote debugger for the main page.
  ///
  /// This takes the [base] remote debugger URL (which points to a browser-wide
  /// page) and uses its JSON API to find the resolved URL for debugging the host
  /// page.
  Future<Uri> _getRemoteDebuggerUrl(Uri base) async {
    try {
      final HttpClient client = HttpClient();
      final HttpClientRequest request = await client.getUrl(base.resolve('/json/list'));
      final HttpClientResponse response = await request.close();
      final List<dynamic> jsonObject = await json.fuse(utf8).decoder.bind(response).single as List<dynamic>;
      if (jsonObject == null || jsonObject.isEmpty) {
        return base;
      }
      return base.resolve(jsonObject.first['devtoolsFrontendUrl'] as String);
    } on Exception {
      // If we fail to talk to the remote debugger protocol, give up and return
      // the raw URL rather than crashing.
      return base;
    }
  }
}

/// A class for managing an instance of Chrome.
class Chrome {
  Chrome._(
    this.debugPort,
    this.chromeConnection, {
    this.url,
    Process process,
    this.remoteDebuggerUri,
  })  : _process = process;

  final String url;
  final int debugPort;
  final Process _process;
  final ChromeConnection chromeConnection;
  final Uri remoteDebuggerUri;

  Future<int> get onExit => _process.exitCode;

  Future<void> close() async {
    if (ChromeLauncher.hasChromeInstance) {
      ChromeLauncher._currentCompleter = Completer<Chrome>();
    }
    chromeConnection.close();
    _process?.kill();
    await _process?.exitCode;
  }
}
