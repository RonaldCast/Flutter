// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/terminal.dart';
import '../base/utils.dart';
import '../cache.dart';
import '../dart/analysis.dart';
import '../dart/sdk.dart' as sdk;
import 'analyze_base.dart';

class AnalyzeContinuously extends AnalyzeBase {
  AnalyzeContinuously(ArgResults argResults, List<String> repoRoots, List<Directory> repoPackages, {
    @required FileSystem fileSystem,
    @required Logger logger,
    @required AnsiTerminal terminal,
    @required Platform platform,
    @required ProcessManager processManager,
  }) : super(
        argResults,
        repoPackages: repoPackages,
        repoRoots: repoRoots,
        fileSystem: fileSystem,
        logger: logger,
        platform: platform,
        terminal: terminal,
        processManager: processManager,
      );

  String analysisTarget;
  bool firstAnalysis = true;
  Set<String> analyzedPaths = <String>{};
  Map<String, List<AnalysisError>> analysisErrors = <String, List<AnalysisError>>{};
  Stopwatch analysisTimer;
  int lastErrorCount = 0;
  Status analysisStatus;

  @override
  Future<void> analyze() async {
    List<String> directories;

    if (argResults['flutter-repo'] as bool) {
      final PackageDependencyTracker dependencies = PackageDependencyTracker();
      dependencies.checkForConflictingDependencies(repoPackages, dependencies);

      directories = repoRoots;
      analysisTarget = 'Flutter repository';

      logger.printTrace('Analyzing Flutter repository:');
      for (final String projectPath in repoRoots) {
        logger.printTrace('  ${fileSystem.path.relative(projectPath)}');
      }
    } else {
      directories = <String>[fileSystem.currentDirectory.path];
      analysisTarget = fileSystem.currentDirectory.path;
    }

    final String sdkPath = argResults['dart-sdk'] as String ?? sdk.dartSdkPath;

    final AnalysisServer server = AnalysisServer(sdkPath, directories,
      fileSystem: fileSystem,
      logger: logger,
      platform: platform,
      processManager: processManager,
      terminal: terminal,
    );
    server.onAnalyzing.listen((bool isAnalyzing) => _handleAnalysisStatus(server, isAnalyzing));
    server.onErrors.listen(_handleAnalysisErrors);

    Cache.releaseLockEarly();

    await server.start();
    final int exitCode = await server.onExit;

    final String message = 'Analysis server exited with code $exitCode.';
    if (exitCode != 0) {
      throwToolExit(message, exitCode: exitCode);
    }
    logger.printStatus(message);

    if (server.didServerErrorOccur) {
      throwToolExit('Server error(s) occurred.');
    }
  }

  void _handleAnalysisStatus(AnalysisServer server, bool isAnalyzing) {
    if (isAnalyzing) {
      analysisStatus?.cancel();
      if (!firstAnalysis) {
        logger.printStatus('\n');
      }
      analysisStatus = logger.startProgress('Analyzing $analysisTarget...', timeout: timeoutConfiguration.slowOperation);
      analyzedPaths.clear();
      analysisTimer = Stopwatch()..start();
    } else {
      analysisStatus?.stop();
      analysisStatus = null;
      analysisTimer.stop();

      logger.printStatus(terminal.clearScreen(), newline: false);

      // Remove errors for deleted files, sort, and print errors.
      final List<AnalysisError> errors = <AnalysisError>[];
      for (final String path in analysisErrors.keys.toList()) {
        if (fileSystem.isFileSync(path)) {
          errors.addAll(analysisErrors[path]);
        } else {
          analysisErrors.remove(path);
        }
      }

      int issueCount = errors.length;

      // count missing dartdocs
      final int undocumentedMembers = errors.where((AnalysisError error) {
        return error.code == 'public_member_api_docs';
      }).length;
      if (!(argResults['dartdocs'] as bool)) {
        errors.removeWhere((AnalysisError error) => error.code == 'public_member_api_docs');
        issueCount -= undocumentedMembers;
      }

      errors.sort();

      for (final AnalysisError error in errors) {
        logger.printStatus(error.toString());
        if (error.code != null) {
          logger.printTrace('error code: ${error.code}');
        }
      }

      dumpErrors(errors.map<String>((AnalysisError error) => error.toLegacyString()));

      // Print an analysis summary.
      String errorsMessage;
      final int issueDiff = issueCount - lastErrorCount;
      lastErrorCount = issueCount;

      if (firstAnalysis) {
        errorsMessage = '$issueCount ${pluralize('issue', issueCount)} found';
      } else if (issueDiff > 0) {
        errorsMessage = '$issueCount ${pluralize('issue', issueCount)} found ($issueDiff new)';
      } else if (issueDiff < 0) {
        errorsMessage = '$issueCount ${pluralize('issue', issueCount)} found (${-issueDiff} fixed)';
      } else if (issueCount != 0) {
        errorsMessage = '$issueCount ${pluralize('issue', issueCount)} found';
      } else {
        errorsMessage = 'no issues found';
      }

      String dartdocMessage;
      if (undocumentedMembers == 1) {
        dartdocMessage = 'one public member lacks documentation';
      } else {
        dartdocMessage = '$undocumentedMembers public members lack documentation';
      }

      final String files = '${analyzedPaths.length} ${pluralize('file', analyzedPaths.length)}';
      final String seconds = (analysisTimer.elapsedMilliseconds / 1000.0).toStringAsFixed(2);
      if (undocumentedMembers > 0) {
        logger.printStatus('$errorsMessage • $dartdocMessage • analyzed $files in $seconds seconds');
      } else {
        logger.printStatus('$errorsMessage • analyzed $files in $seconds seconds');
      }

      if (firstAnalysis && isBenchmarking) {
        writeBenchmark(analysisTimer, issueCount, undocumentedMembers);
        server.dispose().whenComplete(() { exit(issueCount > 0 ? 1 : 0); });
      }

      firstAnalysis = false;
    }
  }

  void _handleAnalysisErrors(FileAnalysisErrors fileErrors) {
    fileErrors.errors.removeWhere((AnalysisError error) => error.type == 'TODO');

    analyzedPaths.add(fileErrors.file);
    analysisErrors[fileErrors.file] = fileErrors.errors;
  }
}
