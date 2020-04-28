// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import 'base/common.dart';
import 'base/file_system.dart';
import 'base/io.dart';
import 'base/process.dart';
import 'base/time.dart';
import 'cache.dart';
import 'convert.dart';
import 'globals.dart' as globals;

/// The names of each channel/branch in order of increasing stability.
enum Channel {
  master,
  dev,
  beta,
  stable,
}

/// The flutter GitHub repository.
const String _flutterGit = 'https://github.com/flutter/flutter.git';

/// Retrieve a human-readable name for a given [channel].
///
/// Requires [FlutterVersion.officialChannels] to be correctly ordered.
String getNameForChannel(Channel channel) {
  return FlutterVersion.officialChannels.elementAt(channel.index);
}

/// Retrieve the [Channel] representation for a string [name].
///
/// Returns `null` if [name] is not in the list of official channels, according
/// to [FlutterVersion.officialChannels].
Channel getChannelForName(String name) {
  if (FlutterVersion.officialChannels.contains(name)) {
    return Channel.values[FlutterVersion.officialChannels.toList().indexOf(name)];
  }
  return null;
}

class FlutterVersion {
  /// Parses the Flutter version from currently available tags in the local
  /// repo.
  ///
  /// Call [fetchTagsAndUpdate] to update the version based on the latest tags
  /// available upstream.
  FlutterVersion([this._clock = const SystemClock(), this._workingDirectory]) {
    _frameworkRevision = _runGit(
      gitLog(<String>['-n', '1', '--pretty=format:%H']).join(' '),
      processUtils,
      _workingDirectory,
    );
    _gitTagVersion = GitTagVersion.determine(processUtils, workingDirectory: _workingDirectory, fetchTags: false);
    _frameworkVersion = gitTagVersion.frameworkVersionFor(_frameworkRevision);
  }

  /// Fetchs tags from the upstream Flutter repository and re-calculates the
  /// version.
  ///
  /// This carries a performance penalty, and should only be called when the
  /// user explicitly wants to get the version, e.g. for `flutter --version` or
  /// `flutter doctor`.
  void fetchTagsAndUpdate() {
    _gitTagVersion = GitTagVersion.determine(processUtils, workingDirectory: _workingDirectory, fetchTags: true);
    _frameworkVersion = gitTagVersion.frameworkVersionFor(_frameworkRevision);
  }

  final SystemClock _clock;
  final String _workingDirectory;

  String _repositoryUrl;
  String get repositoryUrl {
    final String _ = channel;
    return _repositoryUrl;
  }

  /// Whether we are currently on the master branch.
  bool get isMaster {
    final String branchName = getBranchName();
    return !<String>['dev', 'beta', 'stable'].contains(branchName);
  }

  // Beware: Keep order in accordance with stability
  static const Set<String> officialChannels = <String>{
    'master',
    'dev',
    'beta',
    'stable',
  };

  /// This maps old branch names to the names of branches that replaced them.
  ///
  /// For example, in early 2018 we changed from having an "alpha" branch to
  /// having a "dev" branch, so anyone using "alpha" now gets transitioned to
  /// "dev".
  static Map<String, String> obsoleteBranches = <String, String>{
    'alpha': 'dev',
    'hackathon': 'dev',
    'codelab': 'dev',
  };

  String _channel;
  /// The channel is the upstream branch.
  /// `master`, `dev`, `beta`, `stable`; or old ones, like `alpha`, `hackathon`, ...
  String get channel {
    if (_channel == null) {
      final String channel = _runGit(
        'git rev-parse --abbrev-ref --symbolic @{u}',
        processUtils,
        _workingDirectory,
      );
      final int slash = channel.indexOf('/');
      if (slash != -1) {
        final String remote = channel.substring(0, slash);
        _repositoryUrl = _runGit(
          'git ls-remote --get-url $remote',
          processUtils,
          _workingDirectory,
        );
        _channel = channel.substring(slash + 1);
      } else if (channel.isEmpty) {
        _channel = 'unknown';
      } else {
        _channel = channel;
      }
    }
    return _channel;
  }

  GitTagVersion _gitTagVersion;
  GitTagVersion get gitTagVersion => _gitTagVersion;

  /// The name of the local branch.
  /// Use getBranchName() to read this.
  String _branch;

  String _frameworkRevision;
  String get frameworkRevision => _frameworkRevision;
  String get frameworkRevisionShort => _shortGitRevision(frameworkRevision);

  String _frameworkAge;
  String get frameworkAge {
    return _frameworkAge ??= _runGit(
      gitLog(<String>['-n', '1', '--pretty=format:%ar']).join(' '),
      processUtils,
      _workingDirectory,
    );
  }

  String _frameworkVersion;
  String get frameworkVersion => _frameworkVersion;

  String get frameworkDate => frameworkCommitDate;

  String get dartSdkVersion => globals.cache.dartSdkVersion;

  String get engineRevision => globals.cache.engineRevision;
  String get engineRevisionShort => _shortGitRevision(engineRevision);

  Future<void> ensureVersionFile() {
    globals.fs.file(globals.fs.path.join(Cache.flutterRoot, 'version')).writeAsStringSync(_frameworkVersion);
    return Future<void>.value();
  }

  @override
  String toString() {
    final String versionText = frameworkVersion == 'unknown' ? '' : ' $frameworkVersion';
    final String flutterText = 'Flutter$versionText • channel $channel • ${repositoryUrl ?? 'unknown source'}';
    final String frameworkText = 'Framework • revision $frameworkRevisionShort ($frameworkAge) • $frameworkCommitDate';
    final String engineText = 'Engine • revision $engineRevisionShort';
    final String toolsText = 'Tools • Dart $dartSdkVersion';

    // Flutter 1.10.2-pre.69 • channel master • https://github.com/flutter/flutter.git
    // Framework • revision 340c158f32 (84 minutes ago) • 2018-10-26 11:27:22 -0400
    // Engine • revision 9c46333e14
    // Tools • Dart 2.1.0 (build 2.1.0-dev.8.0 bf26f760b1)

    return '$flutterText\n$frameworkText\n$engineText\n$toolsText';
  }

  Map<String, Object> toJson() => <String, Object>{
    'frameworkVersion': frameworkVersion ?? 'unknown',
    'channel': channel,
    'repositoryUrl': repositoryUrl ?? 'unknown source',
    'frameworkRevision': frameworkRevision,
    'frameworkCommitDate': frameworkCommitDate,
    'engineRevision': engineRevision,
    'dartSdkVersion': dartSdkVersion,
  };

  /// A date String describing the last framework commit.
  ///
  /// If a git command fails, this will return a placeholder date.
  String get frameworkCommitDate => _latestGitCommitDate(lenient: true);

  // The date of the latest commit on the given branch. If no branch is
  // specified, then it is the current local branch.
  //
  // If lenient is true, and the git command fails, a placeholder date is
  // returned. Otherwise, the VersionCheckError exception is propagated.
  static String _latestGitCommitDate({
    String branch,
    bool lenient = false,
  }) {
    final List<String> args = gitLog(<String>[
      if (branch != null) branch,
      '-n',
      '1',
      '--pretty=format:%ad',
      '--date=iso',
    ]);
    try {
      // Don't plumb 'lenient' through directly so that we can print an error
      // if something goes wrong.
      return _runSync(args, lenient: false);
    } on VersionCheckError catch (e) {
      if (lenient) {
        final DateTime dummyDate = DateTime.fromMillisecondsSinceEpoch(0);
        globals.printError('Failed to find the latest git commit date: $e\n'
          'Returning $dummyDate instead.');
        // Return something that DateTime.parse() can parse.
        return dummyDate.toString();
      } else {
        rethrow;
      }
    }
  }

  /// The name of the temporary git remote used to check for the latest
  /// available Flutter framework version.
  ///
  /// In the absence of bugs and crashes a Flutter developer should never see
  /// this remote appear in their `git remote` list, but also if it happens to
  /// persist we do the proper clean-up for extra robustness.
  static const String _versionCheckRemote = '__flutter_version_check__';

  /// The date of the latest framework commit in the remote repository.
  ///
  /// Throws [VersionCheckError] if a git command fails, for example, when the
  /// remote git repository is not reachable due to a network issue.
  static Future<String> fetchRemoteFrameworkCommitDate(String branch) async {
    await _removeVersionCheckRemoteIfExists();
    try {
      await _run(<String>[
        'git',
        'remote',
        'add',
        _versionCheckRemote,
        _flutterGit,
      ]);
      await _run(<String>['git', 'fetch', _versionCheckRemote, branch]);
      return _latestGitCommitDate(
        branch: '$_versionCheckRemote/$branch',
        lenient: false,
      );
    } finally {
      await _removeVersionCheckRemoteIfExists();
    }
  }

  static Future<void> _removeVersionCheckRemoteIfExists() async {
    final List<String> remotes = (await _run(<String>['git', 'remote']))
        .split('\n')
        .map<String>((String name) => name.trim()) // to account for OS-specific line-breaks
        .toList();
    if (remotes.contains(_versionCheckRemote)) {
      await _run(<String>['git', 'remote', 'remove', _versionCheckRemote]);
    }
  }

  /// Return a short string for the version (e.g. `master/0.0.59-pre.92`, `scroll_refactor/a76bc8e22b`).
  String getVersionString({ bool redactUnknownBranches = false }) {
    if (frameworkVersion != 'unknown') {
      return '${getBranchName(redactUnknownBranches: redactUnknownBranches)}/$frameworkVersion';
    }
    return '${getBranchName(redactUnknownBranches: redactUnknownBranches)}/$frameworkRevisionShort';
  }

  /// Return the branch name.
  ///
  /// If [redactUnknownBranches] is true and the branch is unknown,
  /// the branch name will be returned as `'[user-branch]'`.
  String getBranchName({ bool redactUnknownBranches = false }) {
    _branch ??= () {
      final String branch = _runGit('git rev-parse --abbrev-ref HEAD', processUtils);
      return branch == 'HEAD' ? channel : branch;
    }();
    if (redactUnknownBranches || _branch.isEmpty) {
      // Only return the branch names we know about; arbitrary branch names might contain PII.
      if (!officialChannels.contains(_branch) &&
          !obsoleteBranches.containsKey(_branch)) {
        return '[user-branch]';
      }
    }
    return _branch;
  }

  /// Returns true if `tentativeDescendantRevision` is a direct descendant to
  /// the `tentativeAncestorRevision` revision on the Flutter framework repo
  /// tree.
  bool checkRevisionAncestry({
    String tentativeDescendantRevision,
    String tentativeAncestorRevision,
  }) {
    final ProcessResult result = globals.processManager.runSync(
      <String>[
        'git',
        'merge-base',
        '--is-ancestor',
        tentativeAncestorRevision,
        tentativeDescendantRevision
      ],
      workingDirectory: Cache.flutterRoot,
    );
    return result.exitCode == 0;
  }

  /// The amount of time we wait before pinging the server to check for the
  /// availability of a newer version of Flutter.
  @visibleForTesting
  static const Duration checkAgeConsideredUpToDate = Duration(days: 3);

  /// We warn the user if the age of their Flutter installation is greater than
  /// this duration. The durations are slightly longer than the expected release
  /// cadence for each channel, to give the user a grace period before they get
  /// notified.
  ///
  /// For example, for the beta channel, this is set to five weeks because
  /// beta releases happen approximately every month.
  @visibleForTesting
  static Duration versionAgeConsideredUpToDate(String channel) {
    switch (channel) {
      case 'stable':
        return const Duration(days: 365 ~/ 2); // Six months
      case 'beta':
        return const Duration(days: 7 * 8); // Eight weeks
      case 'dev':
        return const Duration(days: 7 * 4); // Four weeks
      default:
        return const Duration(days: 7 * 3); // Three weeks
    }
  }

  /// The amount of time we wait between issuing a warning.
  ///
  /// This is to avoid annoying users who are unable to upgrade right away.
  @visibleForTesting
  static const Duration maxTimeSinceLastWarning = Duration(days: 1);

  /// The amount of time we pause for to let the user read the message about
  /// outdated Flutter installation.
  ///
  /// This can be customized in tests to speed them up.
  @visibleForTesting
  static Duration timeToPauseToLetUserReadTheMessage = const Duration(seconds: 2);

  /// Reset the version freshness information by removing the stamp file.
  ///
  /// New version freshness information will be regenerated when
  /// [checkFlutterVersionFreshness] is called after this. This is typically
  /// used when switching channels so that stale information from another
  /// channel doesn't linger.
  static Future<void> resetFlutterVersionFreshnessCheck() async {
    try {
      await globals.cache.getStampFileFor(
        VersionCheckStamp.flutterVersionCheckStampFile,
      ).delete();
    } on FileSystemException {
      // Ignore, since we don't mind if the file didn't exist in the first place.
    }
  }

  /// Checks if the currently installed version of Flutter is up-to-date, and
  /// warns the user if it isn't.
  ///
  /// This function must run while [Cache.lock] is acquired because it reads and
  /// writes shared cache files.
  Future<void> checkFlutterVersionFreshness() async {
    // Don't perform update checks if we're not on an official channel.
    if (!officialChannels.contains(channel)) {
      return;
    }

    DateTime localFrameworkCommitDate;
    try {
      localFrameworkCommitDate = DateTime.parse(_latestGitCommitDate(
        lenient: false
      ));
    } on VersionCheckError {
      // Don't perform the update check if the verison check failed.
      return;
    }

    final Duration frameworkAge = _clock.now().difference(localFrameworkCommitDate);
    final bool installationSeemsOutdated = frameworkAge > versionAgeConsideredUpToDate(channel);

    // Get whether there's a newer version on the remote. This only goes
    // to the server if we haven't checked recently so won't happen on every
    // command.
    final DateTime latestFlutterCommitDate = await _getLatestAvailableFlutterDate();
    final VersionCheckResult remoteVersionStatus = latestFlutterCommitDate == null
        ? VersionCheckResult.unknown
        : latestFlutterCommitDate.isAfter(localFrameworkCommitDate)
          ? VersionCheckResult.newVersionAvailable
          : VersionCheckResult.versionIsCurrent;

    // Do not load the stamp before the above server check as it may modify the stamp file.
    final VersionCheckStamp stamp = await VersionCheckStamp.load();
    final DateTime lastTimeWarningWasPrinted = stamp.lastTimeWarningWasPrinted ?? _clock.ago(maxTimeSinceLastWarning * 2);
    final bool beenAWhileSinceWarningWasPrinted = _clock.now().difference(lastTimeWarningWasPrinted) > maxTimeSinceLastWarning;

    // We show a warning if either we know there is a new remote version, or we couldn't tell but the local
    // version is outdated.
    final bool canShowWarning =
      remoteVersionStatus == VersionCheckResult.newVersionAvailable ||
        (remoteVersionStatus == VersionCheckResult.unknown &&
          installationSeemsOutdated);

    if (beenAWhileSinceWarningWasPrinted && canShowWarning) {
      final String updateMessage =
        remoteVersionStatus == VersionCheckResult.newVersionAvailable
          ? newVersionAvailableMessage()
          : versionOutOfDateMessage(frameworkAge);
      globals.printStatus(updateMessage, emphasis: true);
      await Future.wait<void>(<Future<void>>[
        stamp.store(
          newTimeWarningWasPrinted: _clock.now(),
        ),
        Future<void>.delayed(timeToPauseToLetUserReadTheMessage),
      ]);
    }
  }

  /// log.showSignature=false is a user setting and it will break things,
  /// so we want to disable it for every git log call.  This is a convenience
  /// wrapper that does that.
  @visibleForTesting
  static List<String> gitLog(List<String> args) {
    return <String>['git', '-c', 'log.showSignature=false', 'log'] + args;
  }

  @visibleForTesting
  static String versionOutOfDateMessage(Duration frameworkAge) {
    String warning = 'WARNING: your installation of Flutter is ${frameworkAge.inDays} days old.';
    // Append enough spaces to match the message box width.
    warning += ' ' * (74 - warning.length);

    return '''
  ╔════════════════════════════════════════════════════════════════════════════╗
  ║ $warning ║
  ║                                                                            ║
  ║ To update to the latest version, run "flutter upgrade".                    ║
  ╚════════════════════════════════════════════════════════════════════════════╝
''';
  }

  @visibleForTesting
  static String newVersionAvailableMessage() {
    return '''
  ╔════════════════════════════════════════════════════════════════════════════╗
  ║ A new version of Flutter is available!                                     ║
  ║                                                                            ║
  ║ To update to the latest version, run "flutter upgrade".                    ║
  ╚════════════════════════════════════════════════════════════════════════════╝
''';
  }

  /// Gets the release date of the latest available Flutter version.
  ///
  /// This method sends a server request if it's been more than
  /// [checkAgeConsideredUpToDate] since the last version check.
  ///
  /// Returns null if the cached version is out-of-date or missing, and we are
  /// unable to reach the server to get the latest version.
  Future<DateTime> _getLatestAvailableFlutterDate() async {
    Cache.checkLockAcquired();
    final VersionCheckStamp versionCheckStamp = await VersionCheckStamp.load();

    if (versionCheckStamp.lastTimeVersionWasChecked != null) {
      final Duration timeSinceLastCheck = _clock.now().difference(
        versionCheckStamp.lastTimeVersionWasChecked,
      );

      // Don't ping the server too often. Return cached value if it's fresh.
      if (timeSinceLastCheck < checkAgeConsideredUpToDate) {
        return versionCheckStamp.lastKnownRemoteVersion;
      }
    }

    // Cache is empty or it's been a while since the last server ping. Ping the server.
    try {
      final DateTime remoteFrameworkCommitDate = DateTime.parse(
        await FlutterVersion.fetchRemoteFrameworkCommitDate(channel),
      );
      await versionCheckStamp.store(
        newTimeVersionWasChecked: _clock.now(),
        newKnownRemoteVersion: remoteFrameworkCommitDate,
      );
      return remoteFrameworkCommitDate;
    } on VersionCheckError catch (error) {
      // This happens when any of the git commands fails, which can happen when
      // there's no Internet connectivity. Remote version check is best effort
      // only. We do not prevent the command from running when it fails.
      globals.printTrace('Failed to check Flutter version in the remote repository: $error');
      // Still update the timestamp to avoid us hitting the server on every single
      // command if for some reason we cannot connect (eg. we may be offline).
      await versionCheckStamp.store(
        newTimeVersionWasChecked: _clock.now(),
      );
      return null;
    }
  }
}

/// Contains data and load/save logic pertaining to Flutter version checks.
@visibleForTesting
class VersionCheckStamp {
  const VersionCheckStamp({
    this.lastTimeVersionWasChecked,
    this.lastKnownRemoteVersion,
    this.lastTimeWarningWasPrinted,
  });

  final DateTime lastTimeVersionWasChecked;
  final DateTime lastKnownRemoteVersion;
  final DateTime lastTimeWarningWasPrinted;

  /// The prefix of the stamp file where we cache Flutter version check data.
  @visibleForTesting
  static const String flutterVersionCheckStampFile = 'flutter_version_check';

  static Future<VersionCheckStamp> load() async {
    final String versionCheckStamp = globals.cache.getStampFor(flutterVersionCheckStampFile);

    if (versionCheckStamp != null) {
      // Attempt to parse stamp JSON.
      try {
        final dynamic jsonObject = json.decode(versionCheckStamp);
        if (jsonObject is Map<String, dynamic>) {
          return fromJson(jsonObject);
        } else {
          globals.printTrace('Warning: expected version stamp to be a Map but found: $jsonObject');
        }
      } on Exception catch (error, stackTrace) {
        // Do not crash if JSON is malformed.
        globals.printTrace('${error.runtimeType}: $error\n$stackTrace');
      }
    }

    // Stamp is missing or is malformed.
    return const VersionCheckStamp();
  }

  static VersionCheckStamp fromJson(Map<String, dynamic> jsonObject) {
    DateTime readDateTime(String property) {
      return jsonObject.containsKey(property)
          ? DateTime.parse(jsonObject[property] as String)
          : null;
    }

    return VersionCheckStamp(
      lastTimeVersionWasChecked: readDateTime('lastTimeVersionWasChecked'),
      lastKnownRemoteVersion: readDateTime('lastKnownRemoteVersion'),
      lastTimeWarningWasPrinted: readDateTime('lastTimeWarningWasPrinted'),
    );
  }

  Future<void> store({
    DateTime newTimeVersionWasChecked,
    DateTime newKnownRemoteVersion,
    DateTime newTimeWarningWasPrinted,
  }) async {
    final Map<String, String> jsonData = toJson();

    if (newTimeVersionWasChecked != null) {
      jsonData['lastTimeVersionWasChecked'] = '$newTimeVersionWasChecked';
    }

    if (newKnownRemoteVersion != null) {
      jsonData['lastKnownRemoteVersion'] = '$newKnownRemoteVersion';
    }

    if (newTimeWarningWasPrinted != null) {
      jsonData['lastTimeWarningWasPrinted'] = '$newTimeWarningWasPrinted';
    }

    const JsonEncoder prettyJsonEncoder = JsonEncoder.withIndent('  ');
    globals.cache.setStampFor(flutterVersionCheckStampFile, prettyJsonEncoder.convert(jsonData));
  }

  Map<String, String> toJson({
    DateTime updateTimeVersionWasChecked,
    DateTime updateKnownRemoteVersion,
    DateTime updateTimeWarningWasPrinted,
  }) {
    updateTimeVersionWasChecked = updateTimeVersionWasChecked ?? lastTimeVersionWasChecked;
    updateKnownRemoteVersion = updateKnownRemoteVersion ?? lastKnownRemoteVersion;
    updateTimeWarningWasPrinted = updateTimeWarningWasPrinted ?? lastTimeWarningWasPrinted;

    final Map<String, String> jsonData = <String, String>{};

    if (updateTimeVersionWasChecked != null) {
      jsonData['lastTimeVersionWasChecked'] = '$updateTimeVersionWasChecked';
    }

    if (updateKnownRemoteVersion != null) {
      jsonData['lastKnownRemoteVersion'] = '$updateKnownRemoteVersion';
    }

    if (updateTimeWarningWasPrinted != null) {
      jsonData['lastTimeWarningWasPrinted'] = '$updateTimeWarningWasPrinted';
    }

    return jsonData;
  }
}

/// Thrown when we fail to check Flutter version.
///
/// This can happen when we attempt to `git fetch` but there is no network, or
/// when the installation is not git-based (e.g. a user clones the repo but
/// then removes .git).
class VersionCheckError implements Exception {

  VersionCheckError(this.message);

  final String message;

  @override
  String toString() => '$VersionCheckError: $message';
}

/// Runs [command] and returns the standard output as a string.
///
/// If [lenient] is true and the command fails, returns an empty string.
/// Otherwise, throws a [ToolExit] exception.
String _runSync(List<String> command, { bool lenient = true }) {
  final ProcessResult results = globals.processManager.runSync(
    command,
    workingDirectory: Cache.flutterRoot,
  );

  if (results.exitCode == 0) {
    return (results.stdout as String).trim();
  }

  if (!lenient) {
    throw VersionCheckError(
      'Command exited with code ${results.exitCode}: ${command.join(' ')}\n'
      'Standard out: ${results.stdout}\n'
      'Standard error: ${results.stderr}'
    );
  }

  return '';
}

String _runGit(String command, ProcessUtils processUtils, [String workingDirectory]) {
  return processUtils.runSync(
    command.split(' '),
    workingDirectory: workingDirectory ?? Cache.flutterRoot,
  ).stdout.trim();
}

/// Runs [command] in the root of the Flutter installation and returns the
/// standard output as a string.
///
/// If the command fails, throws a [ToolExit] exception.
Future<String> _run(List<String> command) async {
  final ProcessResult results = await globals.processManager.run(command, workingDirectory: Cache.flutterRoot);

  if (results.exitCode == 0) {
    return (results.stdout as String).trim();
  }

  throw VersionCheckError(
    'Command exited with code ${results.exitCode}: ${command.join(' ')}\n'
    'Standard error: ${results.stderr}'
  );
}

String _shortGitRevision(String revision) {
  if (revision == null) {
    return '';
  }
  return revision.length > 10 ? revision.substring(0, 10) : revision;
}

/// Version of Flutter SDK parsed from git
class GitTagVersion {
  const GitTagVersion({
    this.x,
    this.y,
    this.z,
    this.hotfix,
    this.devVersion,
    this.devPatch,
    this.commits,
    this.hash,
  });
  const GitTagVersion.unknown()
    : x = null,
      y = null,
      z = null,
      hotfix = null,
      commits = 0,
      devVersion = null,
      devPatch = null,
      hash = '';

  /// The X in vX.Y.Z.
  final int x;

  /// The Y in vX.Y.Z.
  final int y;

  /// The Z in vX.Y.Z.
  final int z;

  /// the F in vX.Y.Z+hotfix.F
  final int hotfix;

  /// Number of commits since the vX.Y.Z tag.
  final int commits;

  /// The git hash (or an abbreviation thereof) for this commit.
  final String hash;

  /// The N in X.Y.Z-dev.N.M
  final int devVersion;

  /// The M in X.Y.Z-dev.N.M
  final int devPatch;

  static GitTagVersion determine(ProcessUtils processUtils, {String workingDirectory, bool fetchTags = false}) {
    if (fetchTags) {
      final String channel = _runGit('git rev-parse --abbrev-ref HEAD', processUtils, workingDirectory);
      if (channel == 'dev' || channel == 'beta' || channel == 'stable') {
        globals.printTrace('Skipping request to fetchTags - on well known channel $channel.');
      } else {
        _runGit('git fetch $_flutterGit --tags', processUtils, workingDirectory);
      }
    }
    // `--match` glob must match old version tag `v1.2.3` and new `1.2.3-dev.4.5`
    return parse(_runGit('git describe --match *.*.* --first-parent --long --tags', processUtils, workingDirectory));
  }

  // TODO(fujino): Deprecate this https://github.com/flutter/flutter/issues/53850
  /// Check for the release tag format pre-v1.17.0
  static GitTagVersion parseLegacyVersion(String version) {
    final RegExp versionPattern = RegExp(
      r'^v([0-9]+)\.([0-9]+)\.([0-9]+)(?:\+hotfix\.([0-9]+))?-([0-9]+)-g([a-f0-9]+)$');

    final List<String> parts = versionPattern.matchAsPrefix(version)?.groups(<int>[1, 2, 3, 4, 5, 6]);
    if (parts == null) {
      return const GitTagVersion.unknown();
    }
    final List<int> parsedParts = parts.take(5).map<int>((String source) => source == null ? null : int.tryParse(source)).toList();
    return GitTagVersion(
      x: parsedParts[0],
      y: parsedParts[1],
      z: parsedParts[2],
      hotfix: parsedParts[3],
      commits: parsedParts[4],
      hash: parts[5],
    );
  }

  /// Check for the release tag format from v1.17.0 on
  static GitTagVersion parseVersion(String version) {
    final RegExp versionPattern = RegExp(
      r'^([0-9]+)\.([0-9]+)\.([0-9]+)(-dev\.[0-9]+\.[0-9]+)?-([0-9]+)-g([a-f0-9]+)$');
    final List<String> parts = versionPattern.matchAsPrefix(version)?.groups(<int>[1, 2, 3, 4, 5, 6]);
    if (parts == null) {
      return const GitTagVersion.unknown();
    }
    final List<int> parsedParts = parts.take(5).map<int>((String source) => source == null ? null : int.tryParse(source)).toList();
    List<int> devParts = <int>[null, null];
    if (parts[3] != null) {
      devParts = RegExp(r'^-dev\.(\d+)\.(\d+)')
        .matchAsPrefix(parts[3])
        ?.groups(<int>[1, 2])
        ?.map<int>(
          (String source) => source == null ? null : int.tryParse(source)
        )?.toList() ?? <int>[null, null];
    }
    return GitTagVersion(
      x: parsedParts[0],
      y: parsedParts[1],
      z: parsedParts[2],
      devVersion: devParts[0],
      devPatch: devParts[1],
      commits: parsedParts[4],
      hash: parts[5],
    );
  }

  static GitTagVersion parse(String version) {
    GitTagVersion gitTagVersion;

    gitTagVersion = parseLegacyVersion(version);
    if (gitTagVersion != const GitTagVersion.unknown()) {
      return gitTagVersion;
    }
    gitTagVersion = parseVersion(version);
    if (gitTagVersion != const GitTagVersion.unknown()) {
      return gitTagVersion;
    }
    globals.printTrace('Could not interpret results of "git describe": $version');
    return const GitTagVersion.unknown();
  }

  String frameworkVersionFor(String revision) {
    if (x == null || y == null || z == null || !revision.startsWith(hash)) {
      return '0.0.0-unknown';
    }
    if (commits == 0) {
      if (hotfix != null) {
        return '$x.$y.$z+hotfix.$hotfix';
      }
      return '$x.$y.$z';
    }
    if (hotfix != null) {
      return '$x.$y.$z+hotfix.${hotfix + 1}-pre.$commits';
    }
    return '$x.$y.${z + 1}-pre.$commits';
  }
}

enum VersionCheckResult {
  /// Unable to check whether a new version is available, possibly due to
  /// a connectivity issue.
  unknown,
  /// The current version is up to date.
  versionIsCurrent,
  /// A newer version is available.
  newVersionAvailable,
}
