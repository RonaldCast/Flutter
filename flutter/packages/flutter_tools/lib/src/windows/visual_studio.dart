// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../convert.dart';

/// Encapsulates information about the installed copy of Visual Studio, if any.
class VisualStudio {
  VisualStudio({
    @required FileSystem fileSystem,
    @required ProcessManager processManager,
    @required Platform platform,
    @required Logger logger,
  }) : _platform = platform,
       _fileSystem = fileSystem,
       _processUtils = ProcessUtils(processManager: processManager, logger: logger);

  final FileSystem _fileSystem;
  final Platform _platform;
  final ProcessUtils _processUtils;

  /// True if Visual Studio installation was found.
  ///
  /// Versions older than 2017 Update 2 won't be detected, so error messages to
  /// users should take into account that [false] may mean that the user may
  /// have an old version rather than no installation at all.
  bool get isInstalled => _bestVisualStudioDetails.isNotEmpty;

  bool get isAtLeastMinimumVersion {
    final int installedMajorVersion = _majorVersion;
    return installedMajorVersion != null && installedMajorVersion >= _minimumSupportedVersion;
  }

  /// True if there is a version of Visual Studio with all the components
  /// necessary to build the project.
  bool get hasNecessaryComponents => _usableVisualStudioDetails.isNotEmpty;

  /// The name of the Visual Studio install.
  ///
  /// For instance: "Visual Studio Community 2019".
  String get displayName => _bestVisualStudioDetails[_displayNameKey] as String;

  /// The user-friendly version number of the Visual Studio install.
  ///
  /// For instance: "15.4.0".
  String get displayVersion {
    if (_bestVisualStudioDetails[_catalogKey] == null) {
      return null;
    }
    return _bestVisualStudioDetails[_catalogKey][_catalogDisplayVersionKey] as String;
  }

  /// The directory where Visual Studio is installed.
  String get installLocation => _bestVisualStudioDetails[_installationPathKey] as String;

  /// The full version of the Visual Studio install.
  ///
  /// For instance: "15.4.27004.2002".
  String get fullVersion => _bestVisualStudioDetails[_fullVersionKey] as String;

  // Properties that determine the status of the installation. There might be
  // Visual Studio versions that don't include them, so default to a "valid" value to
  // avoid false negatives.

  /// True if there is a complete installation of Visual Studio.
  ///
  /// False if installation is not found.
  bool get isComplete {
    if (_bestVisualStudioDetails.isEmpty) {
      return false;
    }
    return _bestVisualStudioDetails[_isCompleteKey] as bool ?? true;
  }

  /// True if Visual Studio is launchable.
  ///
  /// False if installation is not found.
  bool get isLaunchable {
    if (_bestVisualStudioDetails.isEmpty) {
      return false;
    }
    return _bestVisualStudioDetails[_isLaunchableKey] as bool ?? true;
  }

    /// True if the Visual Studio installation is as pre-release version.
  bool get isPrerelease => _bestVisualStudioDetails[_isPrereleaseKey] as bool ?? false;

  /// True if a reboot is required to complete the Visual Studio installation.
  bool get isRebootRequired => _bestVisualStudioDetails[_isRebootRequiredKey] as bool ?? false;

  /// The name of the recommended Visual Studio installer workload.
  String get workloadDescription => 'Desktop development with C++';

  /// The names of the components within the workload that must be installed.
  ///
  /// The descriptions of some components differ from version to version. When
  /// a supported version is present, the descriptions used will be for that
  /// version.
  List<String> necessaryComponentDescriptions() {
    return _requiredComponents().values.toList();
  }

  /// The consumer-facing version name of the minumum supported version.
  ///
  /// E.g., for Visual Studio 2019 this returns "2019" rather than "16".
  String get minimumVersionDescription {
    return '2019';
  }

  /// The path to vcvars64.bat, or null if no Visual Studio installation has
  /// the components necessary to build.
  String get vcvarsPath {
    final Map<String, dynamic> details = _usableVisualStudioDetails;
    if (details.isEmpty) {
      return null;
    }
    return _fileSystem.path.join(
      _usableVisualStudioDetails[_installationPathKey] as String,
      'VC',
      'Auxiliary',
      'Build',
      'vcvars64.bat',
    );
  }

  /// The major version of the Visual Studio install, as an integer.
  int get _majorVersion => fullVersion != null ? int.tryParse(fullVersion.split('.')[0]) : null;

  /// The path to vswhere.exe.
  ///
  /// vswhere should be installed for VS 2017 Update 2 and later; if it's not
  /// present then there isn't a new enough installation of VS. This path is
  /// not user-controllable, unlike the install location of Visual Studio
  /// itself.
  String get _vswherePath => _fileSystem.path.join(
    _platform.environment['PROGRAMFILES(X86)'],
    'Microsoft Visual Studio',
    'Installer',
    'vswhere.exe',
  );

  /// Components for use with vswhere requirements.
  ///
  /// Maps from component IDs to description in the installer UI.
  /// See https://docs.microsoft.com/en-us/visualstudio/install/workload-and-component-ids
  Map<String, String> _requiredComponents([int majorVersion]) {
    // The description of the C++ toolchain required by the template. The
    // component name is significantly different in different versions.
    // When a new major version of VS is supported, its toochain description
    // should be added below. It should also be made the default, so that when
    // there is no installation, the message shows the string that will be
    // relevant for the most likely fresh install case).
    String cppToolchainDescription;
    switch (majorVersion ?? _majorVersion) {
      case 16:
      default:
        cppToolchainDescription = 'MSVC v142 - VS 2019 C++ x64/x86 build tools';
    }
    // The 'Microsoft.VisualStudio.Component.VC.Tools.x86.x64' ID is assigned to the latest
    // release of the toolchain, and there can be minor updates within a given version of
    // Visual Studio. Since it changes over time, listing a precise version would become
    // wrong after each VC++ toolchain update, so just instruct people to install the
    // latest version.
    cppToolchainDescription += '\n   - If there are multiple build tool versions available, install the latest';
    return <String, String>{
      // The MSBuild tool and related command-line toolchain.
      'Microsoft.Component.MSBuild': 'MSBuild',
      // The C++ toolchain required by the template.
      'Microsoft.VisualStudio.Component.VC.Tools.x86.x64': cppToolchainDescription,
      // The Windows SDK version used by the template.
      'Microsoft.VisualStudio.Component.Windows10SDK.17763':
          'Windows 10 SDK (10.0.17763.0)',
    };
  }

  /// The minimum supported major version.
  static const int _minimumSupportedVersion = 16;  // '16' is VS 2019.

  /// vswhere argument to specificy the minimum version.
  static const String _vswhereMinVersionArgument = '-version';

  /// vswhere argument to allow prerelease versions.
  static const String _vswherePrereleaseArgument = '-prerelease';

  // Keys in a VS details dictionary returned from vswhere.

  /// The root directory of the Visual Studio installation.
  static const String _installationPathKey = 'installationPath';

  /// The user-friendly name of the installation.
  static const String _displayNameKey = 'displayName';

  /// The complete version.
  static const String _fullVersionKey = 'installationVersion';

  /// Keys for the status of the installation.
  static const String _isCompleteKey = 'isComplete';
  static const String _isLaunchableKey = 'isLaunchable';
  static const String _isRebootRequiredKey = 'isRebootRequired';

  /// The 'catalog' entry containing more details.
  static const String _catalogKey = 'catalog';

  /// The key for a pre-release version.
  static const String _isPrereleaseKey = 'isPrerelease';

  /// The user-friendly version.
  ///
  /// This key is under the 'catalog' entry.
  static const String _catalogDisplayVersionKey = 'productDisplayVersion';

  /// Returns the details dictionary for the newest version of Visual Studio
  /// that includes all of [requiredComponents], if there is one.
  Map<String, dynamic> _visualStudioDetails(
      {Iterable<String> requiredComponents, List<String> additionalArguments}) {
    final List<String> requirementArguments = requiredComponents == null
        ? <String>[]
        : <String>['-requires', ...requiredComponents];
    try {
      final List<String> defaultArguments = <String>[
        '-format', 'json',
        '-utf8',
        '-latest',
      ];
      final RunResult whereResult = _processUtils.runSync(<String>[
        _vswherePath,
        ...defaultArguments,
        ...?additionalArguments,
        ...?requirementArguments,
      ]);
      if (whereResult.exitCode == 0) {
        final List<Map<String, dynamic>> installations =
            (json.decode(whereResult.stdout) as List<dynamic>).cast<Map<String, dynamic>>();
        if (installations.isNotEmpty) {
          return installations[0];
        }
      }
    } on ArgumentError {
      // Thrown if vswhere doesnt' exist; ignore and return null below.
    } on ProcessException {
      // Ignored, return null below.
    } on FormatException {
      // may be thrown if invalid JSON is returned.
    }
    return null;
  }

  /// Checks if the given installation has issues that the user must resolve.
  ///
  /// Returns false if the required information is missing since older versions
  /// of Visual Studio might not include them.
  bool installationHasIssues(Map<String, dynamic>installationDetails) {
    assert(installationDetails != null);
    if (installationDetails[_isCompleteKey] != null && !(installationDetails[_isCompleteKey] as bool)) {
      return true;
    }

    if (installationDetails[_isLaunchableKey] != null && !(installationDetails[_isLaunchableKey] as bool)) {
      return true;
    }

    if (installationDetails[_isRebootRequiredKey] != null && installationDetails[_isRebootRequiredKey] as bool) {
      return true;
    }

    return false;
  }

  /// Returns the details dictionary for the latest version of Visual Studio
  /// that has all required components and is a supported version, or {} if
  /// there is no such installation.
  ///
  /// If no installation is found, the cached VS details are set to an empty map
  /// to avoid repeating vswhere queries that have already not found an installation.
  Map<String, dynamic> _cachedUsableVisualStudioDetails;
  Map<String, dynamic> get _usableVisualStudioDetails {
    if (_cachedUsableVisualStudioDetails != null) {
      return _cachedUsableVisualStudioDetails;
    }
    final List<String> minimumVersionArguments = <String>[
      _vswhereMinVersionArgument,
      _minimumSupportedVersion.toString(),
    ];
    Map<String, dynamic> visualStudioDetails = _visualStudioDetails(
        requiredComponents: _requiredComponents(_minimumSupportedVersion).keys,
        additionalArguments: minimumVersionArguments);
    // If a stable version is not found, try searching for a pre-release version.
    visualStudioDetails ??= _visualStudioDetails(
        requiredComponents: _requiredComponents(_minimumSupportedVersion).keys,
        additionalArguments: <String>[...minimumVersionArguments, _vswherePrereleaseArgument]);

    if (visualStudioDetails != null) {
      if (installationHasIssues(visualStudioDetails)) {
        _cachedAnyVisualStudioDetails = visualStudioDetails;
      } else {
        _cachedUsableVisualStudioDetails = visualStudioDetails;
      }
    }
    _cachedUsableVisualStudioDetails ??= <String, dynamic>{};
    return _cachedUsableVisualStudioDetails;
  }

  /// Returns the details dictionary of the latest version of Visual Studio,
  /// regardless of components and version, or {} if no such installation is
  /// found.
  ///
  /// If no installation is found, the cached VS details are set to an empty map
  /// to avoid repeating vswhere queries that have already not found an
  /// installation.
  Map<String, dynamic> _cachedAnyVisualStudioDetails;
  Map<String, dynamic> get _anyVisualStudioDetails {
    // Search for all types of installations.
    _cachedAnyVisualStudioDetails ??= _visualStudioDetails(
        additionalArguments: <String>[_vswherePrereleaseArgument, '-all']);
    // Add a sentinel empty value to avoid querying vswhere again.
    _cachedAnyVisualStudioDetails ??= <String, dynamic>{};
    return _cachedAnyVisualStudioDetails;
  }

  /// Returns the details dictionary of the best available version of Visual
  /// Studio.
  ///
  /// If there's a version that has all the required components, that
  /// will be returned, otherwise returns the latest installed version (if any).
  Map<String, dynamic> get _bestVisualStudioDetails {
    if (_usableVisualStudioDetails.isNotEmpty) {
      return _usableVisualStudioDetails;
    }
    return _anyVisualStudioDetails;
  }
}
