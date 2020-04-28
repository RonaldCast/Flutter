// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:archive/archive.dart';
import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import '../globals.dart' as globals;
import 'file_system.dart';
import 'io.dart';
import 'logger.dart';
import 'process.dart';

abstract class OperatingSystemUtils {
  factory OperatingSystemUtils({
    @required FileSystem fileSystem,
    @required Logger logger,
    @required Platform platform,
    @required ProcessManager processManager,
  }) {
    if (platform.isWindows) {
      return _WindowsUtils(
        fileSystem: fileSystem,
        logger: logger,
        platform: platform,
        processManager: processManager,
      );
    } else {
      return _PosixUtils(
        fileSystem: fileSystem,
        logger: logger,
        platform: platform,
        processManager: processManager,
      );
    }
  }

  OperatingSystemUtils._private({
    @required FileSystem fileSystem,
    @required Logger logger,
    @required Platform platform,
    @required ProcessManager processManager,
  }) : _fileSystem = fileSystem,
       _logger = logger,
       _platform = platform,
       _processManager = processManager,
       _processUtils = ProcessUtils(
        logger: logger,
        processManager: processManager,
      );

  final FileSystem _fileSystem;
  final Logger _logger;
  final Platform _platform;
  final ProcessManager _processManager;
  final ProcessUtils _processUtils;

  /// Make the given file executable. This may be a no-op on some platforms.
  void makeExecutable(File file);

  /// Updates the specified file system [entity] to have the file mode
  /// bits set to the value defined by [mode], which can be specified in octal
  /// (e.g. `644`) or symbolically (e.g. `u+x`).
  ///
  /// On operating systems that do not support file mode bits, this will be a
  /// no-op.
  void chmod(FileSystemEntity entity, String mode);

  /// Return the path (with symlinks resolved) to the given executable, or null
  /// if `which` was not able to locate the binary.
  File which(String execName) {
    final List<File> result = _which(execName);
    if (result == null || result.isEmpty) {
      return null;
    }
    return result.first;
  }

  /// Return a list of all paths to `execName` found on the system. Uses the
  /// PATH environment variable.
  List<File> whichAll(String execName) => _which(execName, all: true);

  /// Return the File representing a new pipe.
  File makePipe(String path);

  void zip(Directory data, File zipFile);

  void unzip(File file, Directory targetDirectory);

  /// Returns true if the ZIP is not corrupt.
  bool verifyZip(File file);

  void unpack(File gzippedTarFile, Directory targetDirectory);

  /// Returns true if the gzip is not corrupt (does not check tar).
  bool verifyGzip(File gzippedFile);

  /// Returns a pretty name string for the current operating system.
  ///
  /// If available, the detailed version of the OS is included.
  String get name {
    const Map<String, String> osNames = <String, String>{
      'macos': 'Mac OS',
      'linux': 'Linux',
      'windows': 'Windows',
    };
    final String osName = _platform.operatingSystem;
    return osNames.containsKey(osName) ? osNames[osName] : osName;
  }

  List<File> _which(String execName, { bool all = false });

  /// Returns the separator between items in the PATH environment variable.
  String get pathVarSeparator;

  /// Returns an unused network port.
  ///
  /// Returns 0 if an unused port cannot be found.
  ///
  /// The port returned by this function may become used before it is bound by
  /// its intended user.
  Future<int> findFreePort({bool ipv6 = false}) async {
    int port = 0;
    ServerSocket serverSocket;
    final InternetAddress loopback =
        ipv6 ? InternetAddress.loopbackIPv6 : InternetAddress.loopbackIPv4;
    try {
      serverSocket = await ServerSocket.bind(loopback, 0);
      port = serverSocket.port;
    } on SocketException catch (e) {
      // If ipv4 loopback bind fails, try ipv6.
      if (!ipv6) {
        return findFreePort(ipv6: true);
      }
      _logger.printTrace('findFreePort failed: $e');
    } on Exception catch (e) {
      // Failures are signaled by a return value of 0 from this function.
      _logger.printTrace('findFreePort failed: $e');
    } finally {
      if (serverSocket != null) {
        await serverSocket.close();
      }
    }
    return port;
  }
}

class _PosixUtils extends OperatingSystemUtils {
  _PosixUtils({
    @required FileSystem fileSystem,
    @required Logger logger,
    @required Platform platform,
    @required ProcessManager processManager,
  }) : super._private(
    fileSystem: fileSystem,
    logger: logger,
    platform: platform,
    processManager: processManager,
  );

  @override
  void makeExecutable(File file) {
    chmod(file, 'a+x');
  }

  @override
  void chmod(FileSystemEntity entity, String mode) {
    try {
      final ProcessResult result = _processManager.runSync(
        <String>['chmod', mode, entity.path],
      );
      if (result.exitCode != 0) {
        _logger.printTrace(
          'Error trying to run chmod on ${entity.absolute.path}'
          '\nstdout: ${result.stdout}'
          '\nstderr: ${result.stderr}',
        );
      }
    } on ProcessException catch (error) {
      _logger.printTrace(
        'Error trying to run chmod on ${entity.absolute.path}: $error',
      );
    }
  }

  @override
  List<File> _which(String execName, { bool all = false }) {
    final List<String> command = <String>[
      'which',
      if (all) '-a',
      execName,
    ];
    final ProcessResult result = _processManager.runSync(command);
    if (result.exitCode != 0) {
      return const <File>[];
    }
    final String stdout = result.stdout as String;
    return stdout.trim().split('\n').map<File>(
      (String path) => _fileSystem.file(path.trim()),
    ).toList();
  }

  @override
  void zip(Directory data, File zipFile) {
    _processUtils.runSync(
      <String>['zip', '-r', '-q', zipFile.path, '.'],
      workingDirectory: data.path,
      throwOnError: true,
    );
  }

  // unzip -o -q zipfile -d dest
  @override
  void unzip(File file, Directory targetDirectory) {
    _processUtils.runSync(
      <String>['unzip', '-o', '-q', file.path, '-d', targetDirectory.path],
      throwOnError: true,
    );
  }

  @override
  bool verifyZip(File zipFile) =>
    _processUtils.exitsHappySync(<String>['unzip', '-t', '-qq', zipFile.path]);

  // tar -xzf tarball -C dest
  @override
  void unpack(File gzippedTarFile, Directory targetDirectory) {
    _processUtils.runSync(
      <String>['tar', '-xzf', gzippedTarFile.path, '-C', targetDirectory.path],
      throwOnError: true,
    );
  }

  @override
  bool verifyGzip(File gzippedFile) =>
    _processUtils.exitsHappySync(<String>['gzip', '-t', gzippedFile.path]);

  @override
  File makePipe(String path) {
    _processUtils.runSync(
      <String>['mkfifo', path],
      throwOnError: true,
    );
    return _fileSystem.file(path);
  }

  String _name;

  @override
  String get name {
    if (_name == null) {
      if (_platform.isMacOS) {
        final List<RunResult> results = <RunResult>[
          _processUtils.runSync(<String>['sw_vers', '-productName']),
          _processUtils.runSync(<String>['sw_vers', '-productVersion']),
          _processUtils.runSync(<String>['sw_vers', '-buildVersion']),
        ];
        if (results.every((RunResult result) => result.exitCode == 0)) {
          _name = '${results[0].stdout.trim()} ${results[1].stdout
              .trim()} ${results[2].stdout.trim()}';
        }
      }
      _name ??= super.name;
    }
    return _name;
  }

  @override
  String get pathVarSeparator => ':';
}

class _WindowsUtils extends OperatingSystemUtils {
  _WindowsUtils({
    @required FileSystem fileSystem,
    @required Logger logger,
    @required Platform platform,
    @required ProcessManager processManager,
  }) : super._private(
    fileSystem: fileSystem,
    logger: logger,
    platform: platform,
    processManager: processManager,
  );

  @override
  void makeExecutable(File file) {}

  @override
  void chmod(FileSystemEntity entity, String mode) {}

  @override
  List<File> _which(String execName, { bool all = false }) {
    // `where` always returns all matches, not just the first one.
    final ProcessResult result = _processManager.runSync(<String>['where', execName]);
    if (result.exitCode != 0) {
      return const <File>[];
    }
    final List<String> lines = (result.stdout as String).trim().split('\n');
    if (all) {
      return lines.map<File>((String path) => _fileSystem.file(path.trim())).toList();
    }
    return <File>[_fileSystem.file(lines.first.trim())];
  }

  @override
  void zip(Directory data, File zipFile) {
    final Archive archive = Archive();
    for (final FileSystemEntity entity in data.listSync(recursive: true)) {
      if (entity is! File) {
        continue;
      }
      final File file = entity as File;
      final String path = file.fileSystem.path.relative(file.path, from: data.path);
      final List<int> bytes = file.readAsBytesSync();
      archive.addFile(ArchiveFile(path, bytes.length, bytes));
    }
    zipFile.writeAsBytesSync(ZipEncoder().encode(archive), flush: true);
  }

  @override
  void unzip(File file, Directory targetDirectory) {
    final Archive archive = ZipDecoder().decodeBytes(file.readAsBytesSync());
    _unpackArchive(archive, targetDirectory);
  }

  @override
  bool verifyZip(File zipFile) {
    try {
      ZipDecoder().decodeBytes(zipFile.readAsBytesSync(), verify: true);
    } on FileSystemException catch (_) {
      return false;
    } on ArchiveException catch (_) {
      return false;
    }
    return true;
  }

  @override
  void unpack(File gzippedTarFile, Directory targetDirectory) {
    final Archive archive = TarDecoder().decodeBytes(
      GZipDecoder().decodeBytes(gzippedTarFile.readAsBytesSync()),
    );
    _unpackArchive(archive, targetDirectory);
  }

  @override
  bool verifyGzip(File gzipFile) {
    try {
      GZipDecoder().decodeBytes(gzipFile.readAsBytesSync(), verify: true);
    } on FileSystemException catch (_) {
      return false;
    } on ArchiveException catch (_) {
      return false;
    }
    return true;
  }

  void _unpackArchive(Archive archive, Directory targetDirectory) {
    for (final ArchiveFile archiveFile in archive.files) {
      // The archive package doesn't correctly set isFile.
      if (!archiveFile.isFile || archiveFile.name.endsWith('/')) {
        continue;
      }

      final File destFile = _fileSystem.file(_fileSystem.path.join(
        targetDirectory.path,
        archiveFile.name,
      ));
      if (!destFile.parent.existsSync()) {
        destFile.parent.createSync(recursive: true);
      }
      destFile.writeAsBytesSync(archiveFile.content as List<int>);
    }
  }

  @override
  File makePipe(String path) {
    throw UnsupportedError('makePipe is not implemented on Windows.');
  }

  String _name;

  @override
  String get name {
    if (_name == null) {
      final ProcessResult result = _processManager.runSync(
          <String>['ver'], runInShell: true);
      if (result.exitCode == 0) {
        _name = (result.stdout as String).trim();
      } else {
        _name = super.name;
      }
    }
    return _name;
  }

  @override
  String get pathVarSeparator => ';';
}

/// Find and return the project root directory relative to the specified
/// directory or the current working directory if none specified.
/// Return null if the project root could not be found
/// or if the project root is the flutter repository root.
String findProjectRoot([ String directory ]) {
  const String kProjectRootSentinel = 'pubspec.yaml';
  directory ??= globals.fs.currentDirectory.path;
  while (true) {
    if (globals.fs.isFileSync(globals.fs.path.join(directory, kProjectRootSentinel))) {
      return directory;
    }
    final String parent = globals.fs.path.dirname(directory);
    if (directory == parent) {
      return null;
    }
    directory = parent;
  }
}
