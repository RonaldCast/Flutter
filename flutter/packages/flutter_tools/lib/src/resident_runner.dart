// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import 'application_package.dart';
import 'artifacts.dart';
import 'asset.dart';
import 'base/command_help.dart';
import 'base/common.dart';
import 'base/file_system.dart';
import 'base/io.dart' as io;
import 'base/logger.dart';
import 'base/signals.dart';
import 'base/utils.dart';
import 'build_info.dart';
import 'codegen.dart';
import 'compile.dart';
import 'dart/package_map.dart';
import 'devfs.dart';
import 'device.dart';
import 'features.dart';
import 'globals.dart' as globals;
import 'project.dart';
import 'run_cold.dart';
import 'run_hot.dart';
import 'vmservice.dart';

class FlutterDevice {
  FlutterDevice(
    this.device, {
    @required this.buildInfo,
    this.fileSystemRoots,
    this.fileSystemScheme,
    this.viewFilter,
    TargetModel targetModel = TargetModel.flutter,
    TargetPlatform targetPlatform,
    List<String> experimentalFlags,
    ResidentCompiler generator,
  }) : assert(buildInfo.trackWidgetCreation != null),
       generator = generator ?? ResidentCompiler(
         globals.artifacts.getArtifactPath(
           Artifact.flutterPatchedSdkPath,
           platform: targetPlatform,
           mode: buildInfo.mode,
         ),
         buildMode: buildInfo.mode,
         trackWidgetCreation: buildInfo.trackWidgetCreation,
         fileSystemRoots: fileSystemRoots ?? <String>[],
         fileSystemScheme: fileSystemScheme,
         targetModel: targetModel,
         experimentalFlags: experimentalFlags,
         dartDefines: buildInfo.dartDefines,
       );

  /// Create a [FlutterDevice] with optional code generation enabled.
  static Future<FlutterDevice> create(
    Device device, {
    @required FlutterProject flutterProject,
    @required String target,
    @required BuildInfo buildInfo,
    List<String> fileSystemRoots,
    String fileSystemScheme,
    String viewFilter,
    TargetModel targetModel = TargetModel.flutter,
    List<String> experimentalFlags,
    ResidentCompiler generator,
  }) async {
    ResidentCompiler generator;
    final TargetPlatform targetPlatform = await device.targetPlatform;
    if (device.platformType == PlatformType.fuchsia) {
      targetModel = TargetModel.flutterRunner;
    }
    // For both web and non-web platforms we initialize dill to/from
    // a shared location for faster bootstrapping. If the compiler fails
    // due to a kernel target or version mismatch, no error is reported
    // and the compiler starts up as normal. Unexpected errors will print
    // a warning message and dump some debug information which can be
    // used to file a bug, but the compiler will still start up correctly.
    if (targetPlatform == TargetPlatform.web_javascript) {
      generator = ResidentCompiler(
        globals.artifacts.getArtifactPath(Artifact.flutterWebSdk, mode: buildInfo.mode),
        buildMode: buildInfo.mode,
        trackWidgetCreation: buildInfo.trackWidgetCreation,
        fileSystemRoots: fileSystemRoots ?? <String>[],
        // Override the filesystem scheme so that the frontend_server can find
        // the generated entrypoint code.
        fileSystemScheme: 'org-dartlang-app',
        initializeFromDill: globals.fs.path.join(getBuildDirectory(), 'cache.dill'),
        targetModel: TargetModel.dartdevc,
        experimentalFlags: experimentalFlags,
        platformDill: globals.fs.file(globals.artifacts
          .getArtifactPath(Artifact.webPlatformKernelDill, mode: buildInfo.mode))
          .absolute.uri.toString(),
        dartDefines: buildInfo.dartDefines,
        librariesSpec: globals.fs.file(globals.artifacts
          .getArtifactPath(Artifact.flutterWebLibrariesJson)).uri.toString()
      );
    } else {
      generator = ResidentCompiler(
        globals.artifacts.getArtifactPath(
          Artifact.flutterPatchedSdkPath,
          platform: targetPlatform,
          mode: buildInfo.mode,
        ),
        buildMode: buildInfo.mode,
        trackWidgetCreation: buildInfo.trackWidgetCreation,
        fileSystemRoots: fileSystemRoots,
        fileSystemScheme: fileSystemScheme,
        targetModel: targetModel,
        experimentalFlags: experimentalFlags,
        dartDefines: buildInfo.dartDefines,
        initializeFromDill: globals.fs.path.join(getBuildDirectory(), 'cache.dill'),
      );
    }

    if (flutterProject.hasBuilders) {
      generator = await CodeGeneratingResidentCompiler.create(
        residentCompiler: generator,
        flutterProject: flutterProject,
      );
    }

    return FlutterDevice(
      device,
      fileSystemRoots: fileSystemRoots,
      fileSystemScheme:fileSystemScheme,
      viewFilter: viewFilter,
      experimentalFlags: experimentalFlags,
      targetModel: targetModel,
      targetPlatform: targetPlatform,
      generator: generator,
      buildInfo: buildInfo,
    );
  }

  final Device device;
  final ResidentCompiler generator;
  final BuildInfo buildInfo;
  Stream<Uri> observatoryUris;
  VMService vmService;
  DevFS devFS;
  ApplicationPackage package;
  List<String> fileSystemRoots;
  String fileSystemScheme;
  StreamSubscription<String> _loggingSubscription;
  bool _isListeningForObservatoryUri;
  final String viewFilter;

  /// Whether the stream [observatoryUris] is still open.
  bool get isWaitingForObservatory => _isListeningForObservatoryUri ?? false;

  /// If the [reloadSources] parameter is not null the 'reloadSources' service
  /// will be registered.
  /// The 'reloadSources' service can be used by other Service Protocol clients
  /// connected to the VM (e.g. Observatory) to request a reload of the source
  /// code of the running application (a.k.a. HotReload).
  /// The 'compileExpression' service can be used to compile user-provided
  /// expressions requested during debugging of the application.
  /// This ensures that the reload process follows the normal orchestration of
  /// the Flutter Tools and not just the VM internal service.
  Future<void> connect({
    ReloadSources reloadSources,
    Restart restart,
    CompileExpression compileExpression,
    ReloadMethod reloadMethod,
  }) {
    final Completer<void> completer = Completer<void>();
    StreamSubscription<void> subscription;
    bool isWaitingForVm = false;

    subscription = observatoryUris.listen((Uri observatoryUri) async {
      // FYI, this message is used as a sentinel in tests.
      globals.printTrace('Connecting to service protocol: $observatoryUri');
      isWaitingForVm = true;
      VMService service;

      try {
        service = await VMService.connect(
          observatoryUri,
          reloadSources: reloadSources,
          restart: restart,
          compileExpression: compileExpression,
          reloadMethod: reloadMethod,
          device: device,
        );
      } on Exception catch (exception) {
        globals.printTrace('Fail to connect to service protocol: $observatoryUri: $exception');
        if (!completer.isCompleted && !_isListeningForObservatoryUri) {
          completer.completeError('failed to connect to $observatoryUri');
        }
        return;
      }
      if (completer.isCompleted) {
        return;
      }
      globals.printTrace('Successfully connected to service protocol: $observatoryUri');

      vmService = service;
      (await device.getLogReader(app: package)).connectedVMService = vmService;
      completer.complete();
      await subscription.cancel();
    }, onError: (dynamic error) {
      globals.printTrace('Fail to handle observatory URI: $error');
    }, onDone: () {
      _isListeningForObservatoryUri = false;
      if (!completer.isCompleted && !isWaitingForVm) {
        completer.completeError('connection to device ended too early');
      }
    });
    _isListeningForObservatoryUri = true;
    return completer.future;
  }

  Future<void> refreshViews() async {
    if (vmService == null) {
      return;
    }
    await vmService.vm.refreshViews(waitForViews: true);
  }

  List<FlutterView> get views {
    if (vmService == null || vmService.isClosed) {
      return <FlutterView>[];
    }

    return (viewFilter != null
        ? vmService.vm.allViewsWithName(viewFilter)
        : vmService.vm.views).toList();
  }

  Future<void> getVMs() => vmService.getVM();

  Future<void> exitApps() async {
    if (!device.supportsFlutterExit) {
      await device.stopApp(package);
      return;
    }
    final List<FlutterView> flutterViews = views;
    if (flutterViews == null || flutterViews.isEmpty) {
      return;
    }
    // If any of the flutter views are paused, we might not be able to
    // cleanly exit since the service extension may not have been registered.
    if (flutterViews.any((FlutterView view) {
      return view != null &&
             view.uiIsolate != null &&
             view.uiIsolate.pauseEvent != null &&
             view.uiIsolate.pauseEvent.isPauseEvent;
      }
    )) {
      await device.stopApp(package);
      return;
    }
    final List<Future<void>> futures = <Future<void>>[];
    for (final FlutterView view in flutterViews) {
      if (view != null && view.uiIsolate != null) {
        assert(!view.uiIsolate.pauseEvent.isPauseEvent);
        futures.add(view.uiIsolate.flutterExit());
      }
    }
    // The flutterExit message only returns if it fails, so just wait a few
    // seconds then assume it worked.
    // TODO(ianh): We should make this return once the VM service disconnects.
    await Future.wait(futures).timeout(const Duration(seconds: 2), onTimeout: () => <void>[]);
  }

  Future<Uri> setupDevFS(
    String fsName,
    Directory rootDirectory, {
    String packagesFilePath,
  }) {
    // One devFS per device. Shared by all running instances.
    devFS = DevFS(
      vmService,
      fsName,
      rootDirectory,
      packagesFilePath: packagesFilePath,
    );
    return devFS.create();
  }

  List<Future<Map<String, dynamic>>> reloadSources(
    String entryPath, {
    bool pause = false,
  }) {
    final Uri deviceEntryUri = devFS.baseUri.resolveUri(globals.fs.path.toUri(entryPath));
    return <Future<Map<String, dynamic>>>[
      for (final Isolate isolate in vmService.vm.isolates)
        isolate.reloadSources(
          pause: pause,
          rootLibUri: deviceEntryUri,
        ),
    ];
  }

  Future<void> resetAssetDirectory() async {
    final Uri deviceAssetsDirectoryUri = devFS.baseUri.resolveUri(
        globals.fs.path.toUri(getAssetBuildDirectory()));
    assert(deviceAssetsDirectoryUri != null);
    await Future.wait<void>(views.map<Future<void>>(
      (FlutterView view) => view.setAssetDirectory(deviceAssetsDirectoryUri)
    ));
  }

  Future<void> debugDumpApp() async {
    for (final FlutterView view in views) {
      await view.uiIsolate.flutterDebugDumpApp();
    }
  }

  Future<void> debugDumpRenderTree() async {
    for (final FlutterView view in views) {
      await view.uiIsolate.flutterDebugDumpRenderTree();
    }
  }

  Future<void> debugDumpLayerTree() async {
    for (final FlutterView view in views) {
      await view.uiIsolate.flutterDebugDumpLayerTree();
    }
  }

  Future<void> debugDumpSemanticsTreeInTraversalOrder() async {
    for (final FlutterView view in views) {
      await view.uiIsolate.flutterDebugDumpSemanticsTreeInTraversalOrder();
    }
  }

  Future<void> debugDumpSemanticsTreeInInverseHitTestOrder() async {
    for (final FlutterView view in views) {
      await view.uiIsolate.flutterDebugDumpSemanticsTreeInInverseHitTestOrder();
    }
  }

  Future<void> toggleDebugPaintSizeEnabled() async {
    for (final FlutterView view in views) {
      await view.uiIsolate.flutterToggleDebugPaintSizeEnabled();
    }
  }

  Future<void> toggleDebugCheckElevationsEnabled() async {
    for (final FlutterView view in views) {
      await view.uiIsolate.flutterToggleDebugCheckElevationsEnabled();
    }
  }

  Future<void> debugTogglePerformanceOverlayOverride() async {
    for (final FlutterView view in views) {
      await view.uiIsolate.flutterTogglePerformanceOverlayOverride();
    }
  }

  Future<void> toggleWidgetInspector() async {
    for (final FlutterView view in views) {
      await view.uiIsolate.flutterToggleWidgetInspector();
    }
  }

  Future<void> toggleProfileWidgetBuilds() async {
    for (final FlutterView view in views) {
      await view.uiIsolate.flutterToggleProfileWidgetBuilds();
    }
  }

  Future<String> togglePlatform({ String from }) async {
    final String to = nextPlatform(from, featureFlags);
    for (final FlutterView view in views) {
      await view.uiIsolate.flutterPlatformOverride(to);
    }
    return to;
  }

  Future<void> startEchoingDeviceLog() async {
    if (_loggingSubscription != null) {
      return;
    }
    final Stream<String> logStream = (await device.getLogReader(app: package)).logLines;
    if (logStream == null) {
      globals.printError('Failed to read device log stream');
      return;
    }
    _loggingSubscription = logStream.listen((String line) {
      if (!line.contains('Observatory listening on http')) {
        globals.printStatus(line, wrap: false);
      }
    });
  }

  Future<void> stopEchoingDeviceLog() async {
    if (_loggingSubscription == null) {
      return;
    }
    await _loggingSubscription.cancel();
    _loggingSubscription = null;
  }

  Future<void> initLogReader() async {
    (await device.getLogReader(app: package)).appPid = vmService.vm.pid;
  }

  Future<int> runHot({
    HotRunner hotRunner,
    String route,
  }) async {
    final bool prebuiltMode = hotRunner.applicationBinary != null;
    final String modeName = hotRunner.debuggingOptions.buildInfo.friendlyModeName;
    globals.printStatus(
      'Launching ${globals.fsUtils.getDisplayPath(hotRunner.mainPath)} '
      'on ${device.name} in $modeName mode...',
    );

    final TargetPlatform targetPlatform = await device.targetPlatform;
    package = await ApplicationPackageFactory.instance.getPackageForPlatform(
      targetPlatform,
      applicationBinary: hotRunner.applicationBinary,
    );

    if (package == null) {
      String message = 'No application found for $targetPlatform.';
      final String hint = await getMissingPackageHintForPlatform(targetPlatform);
      if (hint != null) {
        message += '\n$hint';
      }
      globals.printError(message);
      return 1;
    }

    final Map<String, dynamic> platformArgs = <String, dynamic>{};

    await startEchoingDeviceLog();

    // Start the application.
    final Future<LaunchResult> futureResult = device.startApp(
      package,
      mainPath: hotRunner.mainPath,
      debuggingOptions: hotRunner.debuggingOptions,
      platformArgs: platformArgs,
      route: route,
      prebuiltApplication: prebuiltMode,
      ipv6: hotRunner.ipv6,
    );

    final LaunchResult result = await futureResult;

    if (!result.started) {
      globals.printError('Error launching application on ${device.name}.');
      await stopEchoingDeviceLog();
      return 2;
    }
    if (result.hasObservatory) {
      observatoryUris = Stream<Uri>
        .value(result.observatoryUri)
        .asBroadcastStream();
    } else {
      observatoryUris = const Stream<Uri>
        .empty()
        .asBroadcastStream();
    }
    return 0;
  }


  Future<int> runCold({
    ColdRunner coldRunner,
    String route,
  }) async {
    final TargetPlatform targetPlatform = await device.targetPlatform;
    package = await ApplicationPackageFactory.instance.getPackageForPlatform(
      targetPlatform,
      applicationBinary: coldRunner.applicationBinary,
    );

    final String modeName = coldRunner.debuggingOptions.buildInfo.friendlyModeName;
    final bool prebuiltMode = coldRunner.applicationBinary != null;
    if (coldRunner.mainPath == null) {
      assert(prebuiltMode);
      globals.printStatus(
        'Launching ${package.displayName} '
        'on ${device.name} in $modeName mode...',
      );
    } else {
      globals.printStatus(
        'Launching ${globals.fsUtils.getDisplayPath(coldRunner.mainPath)} '
        'on ${device.name} in $modeName mode...',
      );
    }

    if (package == null) {
      String message = 'No application found for $targetPlatform.';
      final String hint = await getMissingPackageHintForPlatform(targetPlatform);
      if (hint != null) {
        message += '\n$hint';
      }
      globals.printError(message);
      return 1;
    }

    final Map<String, dynamic> platformArgs = <String, dynamic>{};
    if (coldRunner.traceStartup != null) {
      platformArgs['trace-startup'] = coldRunner.traceStartup;
    }

    await startEchoingDeviceLog();

    final LaunchResult result = await device.startApp(
      package,
      mainPath: coldRunner.mainPath,
      debuggingOptions: coldRunner.debuggingOptions,
      platformArgs: platformArgs,
      route: route,
      prebuiltApplication: prebuiltMode,
      ipv6: coldRunner.ipv6,
    );

    if (!result.started) {
      globals.printError('Error running application on ${device.name}.');
      await stopEchoingDeviceLog();
      return 2;
    }
    if (result.hasObservatory) {
      observatoryUris = Stream<Uri>
        .value(result.observatoryUri)
        .asBroadcastStream();
    } else {
      observatoryUris = const Stream<Uri>
        .empty()
        .asBroadcastStream();
    }
    return 0;
  }

  Future<UpdateFSReport> updateDevFS({
    String mainPath,
    String target,
    AssetBundle bundle,
    DateTime firstBuildTime,
    bool bundleFirstUpload = false,
    bool bundleDirty = false,
    bool fullRestart = false,
    String projectRootPath,
    String pathToReload,
    @required String dillOutputPath,
    @required List<Uri> invalidatedFiles,
  }) async {
    final Status devFSStatus = globals.logger.startProgress(
      'Syncing files to device ${device.name}...',
      timeout: timeoutConfiguration.fastOperation,
    );
    UpdateFSReport report;
    try {
      report = await devFS.update(
        mainPath: mainPath,
        target: target,
        bundle: bundle,
        firstBuildTime: firstBuildTime,
        bundleFirstUpload: bundleFirstUpload,
        generator: generator,
        fullRestart: fullRestart,
        dillOutputPath: dillOutputPath,
        trackWidgetCreation: buildInfo.trackWidgetCreation,
        projectRootPath: projectRootPath,
        pathToReload: pathToReload,
        invalidatedFiles: invalidatedFiles,
      );
    } on DevFSException {
      devFSStatus.cancel();
      return UpdateFSReport(success: false);
    }
    devFSStatus.stop();
    globals.printTrace('Synced ${getSizeAsMB(report.syncedBytes)}.');
    return report;
  }

  Future<void> updateReloadStatus(bool wasReloadSuccessful) async {
    if (wasReloadSuccessful) {
      generator?.accept();
    } else {
      await generator?.reject();
    }
  }
}

// Issue: https://github.com/flutter/flutter/issues/33050
// Matches the following patterns:
//    HttpException: Connection closed before full header was received, uri = *
//    HttpException: , uri = *
final RegExp kAndroidQHttpConnectionClosedExp = RegExp(r'^HttpException\:.+\, uri \=.+$');

/// Returns `true` if any of the devices is running Android Q.
Future<bool> hasDeviceRunningAndroidQ(List<FlutterDevice> flutterDevices) async {
  for (final FlutterDevice flutterDevice in flutterDevices) {
    final String sdkNameAndVersion = await flutterDevice.device.sdkNameAndVersion;
    if (sdkNameAndVersion != null && sdkNameAndVersion.startsWith('Android 10')) {
      return true;
    }
  }
  return false;
}

// Shared code between different resident application runners.
abstract class ResidentRunner {
  ResidentRunner(
    this.flutterDevices, {
    this.target,
    this.debuggingOptions,
    String projectRootPath,
    String packagesFilePath,
    this.ipv6,
    this.stayResident = true,
    this.hotMode = true,
    String dillOutputPath,
  }) : mainPath = findMainDartFile(target),
       projectRootPath = projectRootPath ?? globals.fs.currentDirectory.path,
       packagesFilePath = packagesFilePath ?? globals.fs.path.absolute(PackageMap.globalPackagesPath),
       _dillOutputPath = dillOutputPath,
       artifactDirectory = dillOutputPath == null
          ? globals.fs.systemTempDirectory.createTempSync('flutter_tool.')
          : globals.fs.file(dillOutputPath).parent,
       assetBundle = AssetBundleFactory.instance.createBundle(),
       commandHelp = CommandHelp(
         logger: globals.logger,
         terminal: globals.terminal,
         platform: globals.platform,
         outputPreferences: globals.outputPreferences,
       ) {
    if (!artifactDirectory.existsSync()) {
      artifactDirectory.createSync(recursive: true);
    }
  }

  @protected
  @visibleForTesting
  final List<FlutterDevice> flutterDevices;

  final String target;
  final DebuggingOptions debuggingOptions;
  final bool stayResident;
  final bool ipv6;
  final String _dillOutputPath;
  /// The parent location of the incremental artifacts.
  final Directory artifactDirectory;
  final String packagesFilePath;
  final String projectRootPath;
  final String mainPath;
  final AssetBundle assetBundle;

  final CommandHelp commandHelp;

  bool _exited = false;
  Completer<int> _finished = Completer<int>();
  bool hotMode;

  /// Returns true if every device is streaming observatory URIs.
  bool get isWaitingForObservatory {
    return flutterDevices.every((FlutterDevice device) {
      return device.isWaitingForObservatory;
    });
  }

  String get dillOutputPath => _dillOutputPath ?? globals.fs.path.join(artifactDirectory.path, 'app.dill');
  String getReloadPath({ bool fullRestart }) => mainPath + (fullRestart ? '' : '.incremental') + '.dill';

  bool get debuggingEnabled => debuggingOptions.debuggingEnabled;
  bool get isRunningDebug => debuggingOptions.buildInfo.isDebug;
  bool get isRunningProfile => debuggingOptions.buildInfo.isProfile;
  bool get isRunningRelease => debuggingOptions.buildInfo.isRelease;
  bool get supportsServiceProtocol => isRunningDebug || isRunningProfile;
  bool get supportsCanvasKit => false;

  // Returns the Uri of the first connected device for mobile,
  // and only connected device for web.
  //
  // Would be null if there is no device connected or
  // there is no devFS associated with the first device.
  Uri get uri => flutterDevices.first?.devFS?.baseUri;

  /// Returns [true] if the resident runner exited after invoking [exit()].
  bool get exited => _exited;

  /// Whether this runner can hot restart.
  ///
  /// To prevent scenarios where only a subset of devices are hot restarted,
  /// the runner requires that all attached devices can support hot restart
  /// before enabling it.
  bool get canHotRestart {
    return flutterDevices.every((FlutterDevice device) {
      return device.device.supportsHotRestart;
    });
  }

  /// Invoke an RPC extension method on the first attached ui isolate of the first device.
  // TODO(jonahwilliams): Update/Remove this method when refactoring the resident
  // runner to support a single flutter device.
  Future<Map<String, dynamic>> invokeFlutterExtensionRpcRawOnFirstIsolate(
    String method, {
    Map<String, dynamic> params,
  }) {
    return flutterDevices.first.views.first.uiIsolate
        .invokeFlutterExtensionRpcRaw(method, params: params);
  }

  /// Whether this runner can hot reload.
  bool get canHotReload => hotMode;

  /// Start the app and keep the process running during its lifetime.
  ///
  /// Returns the exit code that we should use for the flutter tool process; 0
  /// for success, 1 for user error (e.g. bad arguments), 2 for other failures.
  Future<int> run({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    Completer<void> appStartedCompleter,
    String route,
  });

  Future<int> attach({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    Completer<void> appStartedCompleter,
  });

  bool get supportsRestart => false;

  Future<OperationResult> restart({ bool fullRestart = false, bool pause = false, String reason }) {
    final String mode = isRunningProfile ? 'profile' :
        isRunningRelease ? 'release' : 'this';
    throw '${fullRestart ? 'Restart' : 'Reload'} is not supported in $mode mode';
  }

  /// Toggle whether canvaskit is being used for rendering, returning the new
  /// state.
  ///
  /// Only supported on the web.
  Future<bool> toggleCanvaskit() {
    throw Exception('Canvaskit not supported by this runner.');
  }

  /// The resident runner API for interaction with the reloadMethod vmservice
  /// request.
  ///
  /// This API should only be called for UI only-changes spanning a single
  /// library/Widget.
  ///
  /// The value [classId] should be the identifier of the StatelessWidget that
  /// was invalidated, or the StatefulWidget for the corresponding State class
  /// that was invalidated. This must be provided.
  ///
  /// The value [libraryId] should be the absolute file URI for the containing
  /// library of the widget that was invalidated. This must be provided.
  Future<OperationResult> reloadMethod({ String classId, String libraryId }) {
    throw UnsupportedError('Method is not supported.');
  }

  @protected
  void writeVmserviceFile() {
    if (debuggingOptions.vmserviceOutFile != null) {
      try {
        final String address = flutterDevices.first.vmService.wsAddress.toString();
        final File vmserviceOutFile = globals.fs.file(debuggingOptions.vmserviceOutFile);
        vmserviceOutFile.createSync(recursive: true);
        vmserviceOutFile.writeAsStringSync(address);
      } on FileSystemException {
        globals.printError('Failed to write vmservice-out-file at ${debuggingOptions.vmserviceOutFile}');
      }
    }
  }

  Future<void> exit() async {
    _exited = true;
    await stopEchoingDeviceLog();
    await preExit();
    await exitApp();
  }

  Future<void> detach() async {
    await stopEchoingDeviceLog();
    await preExit();
    appFinished();
  }

  Future<void> refreshViews() async {
    final List<Future<void>> futures = <Future<void>>[
      for (final FlutterDevice device in flutterDevices) device.refreshViews(),
    ];
    await Future.wait(futures);
  }

  Future<void> debugDumpApp() async {
    await refreshViews();
    for (final FlutterDevice device in flutterDevices) {
      await device.debugDumpApp();
    }
  }

  Future<void> debugDumpRenderTree() async {
    await refreshViews();
    for (final FlutterDevice device in flutterDevices) {
      await device.debugDumpRenderTree();
    }
  }

  Future<void> debugDumpLayerTree() async {
    await refreshViews();
    for (final FlutterDevice device in flutterDevices) {
      await device.debugDumpLayerTree();
    }
  }

  Future<void> debugDumpSemanticsTreeInTraversalOrder() async {
    await refreshViews();
    for (final FlutterDevice device in flutterDevices) {
      await device.debugDumpSemanticsTreeInTraversalOrder();
    }
  }

  Future<void> debugDumpSemanticsTreeInInverseHitTestOrder() async {
    await refreshViews();
    for (final FlutterDevice device in flutterDevices) {
      await device.debugDumpSemanticsTreeInInverseHitTestOrder();
    }
  }

  Future<void> debugToggleDebugPaintSizeEnabled() async {
    await refreshViews();
    for (final FlutterDevice device in flutterDevices) {
      await device.toggleDebugPaintSizeEnabled();
    }
  }

  Future<void> debugToggleDebugCheckElevationsEnabled() async {
    await refreshViews();
    for (final FlutterDevice device in flutterDevices) {
      await device.toggleDebugCheckElevationsEnabled();
    }
  }

  Future<void> debugTogglePerformanceOverlayOverride() async {
    await refreshViews();
    for (final FlutterDevice device in flutterDevices) {
      await device.debugTogglePerformanceOverlayOverride();
    }
  }

  Future<void> debugToggleWidgetInspector() async {
    await refreshViews();
    for (final FlutterDevice device in flutterDevices) {
      await device.toggleWidgetInspector();
    }
  }

  Future<void> debugToggleProfileWidgetBuilds() async {
    await refreshViews();
    for (final FlutterDevice device in flutterDevices) {
      await device.toggleProfileWidgetBuilds();
    }
  }

  /// Take a screenshot on the provided [device].
  ///
  /// If the device has a connected vmservice, this method will attempt to hide
  /// and restore the debug banner before taking the screenshot.
  ///
  /// Throws an [AssertionError] if [Devce.supportsScreenshot] is not true.
  Future<void> screenshot(FlutterDevice device) async {
    assert(device.device.supportsScreenshot);

    final Status status = globals.logger.startProgress(
      'Taking screenshot for ${device.device.name}...',
      timeout: timeoutConfiguration.fastOperation,
    );
    final File outputFile = globals.fsUtils.getUniqueFile(
      globals.fs.currentDirectory,
      'flutter',
      'png',
    );
    try {
      if (supportsServiceProtocol && isRunningDebug) {
        await device.refreshViews();
        try {
          for (final FlutterView view in device.views) {
            await view.uiIsolate.flutterDebugAllowBanner(false);
          }
        } on Exception catch (error) {
          status.cancel();
          globals.printError('Error communicating with Flutter on the device: $error');
          return;
        }
      }
      try {
        await device.device.takeScreenshot(outputFile);
      } finally {
        if (supportsServiceProtocol && isRunningDebug) {
          try {
            for (final FlutterView view in device.views) {
              await view.uiIsolate.flutterDebugAllowBanner(true);
            }
          } on Exception catch (error) {
            status.cancel();
            globals.printError('Error communicating with Flutter on the device: $error');
            return;
          }
        }
      }
      final int sizeKB = outputFile.lengthSync() ~/ 1024;
      status.stop();
      globals.printStatus(
        'Screenshot written to ${globals.fs.path.relative(outputFile.path)} (${sizeKB}kB).',
      );
    } on Exception catch (error) {
      status.cancel();
      globals.printError('Error taking screenshot: $error');
    }
  }

  Future<void> debugTogglePlatform() async {
    await refreshViews();
    final String from = await flutterDevices[0].views[0].uiIsolate.flutterPlatformOverride();
    String to;
    for (final FlutterDevice device in flutterDevices) {
      to = await device.togglePlatform(from: from);
    }
    globals.printStatus('Switched operating system to $to');
  }

  Future<void> stopEchoingDeviceLog() async {
    await Future.wait<void>(
      flutterDevices.map<Future<void>>((FlutterDevice device) => device.stopEchoingDeviceLog())
    );
  }

  /// If the [reloadSources] parameter is not null the 'reloadSources' service
  /// will be registered.
  //
  // Failures should be indicated by completing the future with an error, using
  // a string as the error object, which will be used by the caller (attach())
  // to display an error message.
  Future<void> connectToServiceProtocol({
    ReloadSources reloadSources,
    Restart restart,
    CompileExpression compileExpression,
    ReloadMethod reloadMethod,
  }) async {
    if (!debuggingOptions.debuggingEnabled) {
      throw 'The service protocol is not enabled.';
    }

    _finished = Completer<int>();

    bool viewFound = false;
    for (final FlutterDevice device in flutterDevices) {
      await device.connect(
        reloadSources: reloadSources,
        restart: restart,
        compileExpression: compileExpression,
        reloadMethod: reloadMethod,
      );
      await device.getVMs();
      await device.refreshViews();
      if (device.views.isNotEmpty) {
        viewFound = true;
      }
    }
    if (!viewFound) {
      if (flutterDevices.length == 1) {
        throw 'No Flutter view is available on ${flutterDevices.first.device.name}.';
      }
      throw 'No Flutter view is available on any device '
            '(${flutterDevices.map<String>((FlutterDevice device) => device.device.name).join(', ')}).';
    }

    // Listen for service protocol connection to close.
    for (final FlutterDevice device in flutterDevices) {
      // This hooks up callbacks for when the connection stops in the future.
      // We don't want to wait for them. We don't handle errors in those callbacks'
      // futures either because they just print to logger and is not critical.
      unawaited(device.vmService.done.then<void>(
        _serviceProtocolDone,
        onError: _serviceProtocolError,
      ).whenComplete(_serviceDisconnected));
    }
  }

  Future<void> _serviceProtocolDone(dynamic object) async {
    globals.printTrace('Service protocol connection closed.');
  }

  Future<void> _serviceProtocolError(dynamic error, StackTrace stack) {
    globals.printTrace('Service protocol connection closed with an error: $error\n$stack');
    return Future<void>.error(error, stack);
  }

  void _serviceDisconnected() {
    if (_exited) {
      // User requested the application exit.
      return;
    }
    if (_finished.isCompleted) {
      return;
    }
    globals.printStatus('Lost connection to device.');
    _finished.complete(0);
  }

  void appFinished() {
    if (_finished.isCompleted) {
      return;
    }
    globals.printStatus('Application finished.');
    _finished.complete(0);
  }

  Future<int> waitForAppToFinish() async {
    final int exitCode = await _finished.future;
    assert(exitCode != null);
    await cleanupAtFinish();
    return exitCode;
  }

  @mustCallSuper
  Future<void> preExit() async {
    // If _dillOutputPath is null, we created a temporary directory for the dill.
    if (_dillOutputPath == null && artifactDirectory.existsSync()) {
      final File outputDill = artifactDirectory.childFile('app.dill');
      if (outputDill.existsSync()) {
        artifactDirectory.childFile('app.dill')
          .copySync(globals.fs.path.join(getBuildDirectory(), 'cache.dill'));
      }
      artifactDirectory.deleteSync(recursive: true);
    }
  }

  Future<void> exitApp() async {
    final List<Future<void>> futures = <Future<void>>[
      for (final FlutterDevice device in flutterDevices)  device.exitApps(),
    ];
    await Future.wait(futures);
    appFinished();
  }

  /// Called to print help to the terminal.
  void printHelp({ @required bool details });

  void printHelpDetails() {
    if (flutterDevices.any((FlutterDevice d) => d.device.supportsScreenshot)) {
      commandHelp.s.print();
    }
    if (supportsServiceProtocol) {
      commandHelp.w.print();
      commandHelp.t.print();
      if (isRunningDebug) {
        commandHelp.L.print();
        commandHelp.S.print();
        commandHelp.U.print();
        commandHelp.i.print();
        commandHelp.p.print();
        commandHelp.o.print();
        commandHelp.z.print();
      } else {
        commandHelp.S.print();
        commandHelp.U.print();
      }
      if (supportsCanvasKit){
        commandHelp.k.print();
      }
      // `P` should precede `a`
      commandHelp.P.print();
      commandHelp.a.print();
    }
  }

  /// Called when a signal has requested we exit.
  Future<void> cleanupAfterSignal();

  /// Called right before we exit.
  Future<void> cleanupAtFinish();

  // Clears the screen.
  void clearScreen() => globals.logger.clear();
}

class OperationResult {
  OperationResult(this.code, this.message, { this.fatal = false });

  /// The result of the operation; a non-zero code indicates a failure.
  final int code;

  /// A user facing message about the results of the operation.
  final String message;

  /// Whether this error should cause the runner to exit.
  final bool fatal;

  bool get isOk => code == 0;

  static final OperationResult ok = OperationResult(0, '');
}

/// Given the value of the --target option, return the path of the Dart file
/// where the app's main function should be.
String findMainDartFile([ String target ]) {
  target ??= '';
  final String targetPath = globals.fs.path.absolute(target);
  if (globals.fs.isDirectorySync(targetPath)) {
    return globals.fs.path.join(targetPath, 'lib', 'main.dart');
  }
  return targetPath;
}

Future<String> getMissingPackageHintForPlatform(TargetPlatform platform) async {
  switch (platform) {
    case TargetPlatform.android_arm:
    case TargetPlatform.android_arm64:
    case TargetPlatform.android_x64:
    case TargetPlatform.android_x86:
      final FlutterProject project = FlutterProject.current();
      final String manifestPath = globals.fs.path.relative(project.android.appManifestFile.path);
      return 'Is your project missing an $manifestPath?\nConsider running "flutter create ." to create one.';
    case TargetPlatform.ios:
      return 'Is your project missing an ios/Runner/Info.plist?\nConsider running "flutter create ." to create one.';
    default:
      return null;
  }
}

/// Redirects terminal commands to the correct resident runner methods.
class TerminalHandler {
  TerminalHandler(this.residentRunner);

  final ResidentRunner residentRunner;
  bool _processingUserRequest = false;
  StreamSubscription<void> subscription;

  @visibleForTesting
  String lastReceivedCommand;

  void setupTerminal() {
    if (!globals.logger.quiet) {
      globals.printStatus('');
      residentRunner.printHelp(details: false);
    }
    globals.terminal.singleCharMode = true;
    subscription = globals.terminal.keystrokes.listen(processTerminalInput);
  }


  final Map<io.ProcessSignal, Object> _signalTokens = <io.ProcessSignal, Object>{};

  void _addSignalHandler(io.ProcessSignal signal, SignalHandler handler) {
    _signalTokens[signal] = signals.addHandler(signal, handler);
  }

  void registerSignalHandlers() {
    assert(residentRunner.stayResident);

    _addSignalHandler(io.ProcessSignal.SIGINT, _cleanUp);
    _addSignalHandler(io.ProcessSignal.SIGTERM, _cleanUp);
    if (!residentRunner.supportsServiceProtocol || !residentRunner.supportsRestart) {
      return;
    }
    _addSignalHandler(io.ProcessSignal.SIGUSR1, _handleSignal);
    _addSignalHandler(io.ProcessSignal.SIGUSR2, _handleSignal);
  }

  /// Unregisters terminal signal and keystroke handlers.
  void stop() {
    assert(residentRunner.stayResident);
    for (final MapEntry<io.ProcessSignal, Object> entry in _signalTokens.entries) {
      signals.removeHandler(entry.key, entry.value);
    }
    _signalTokens.clear();
    subscription.cancel();
  }

  /// Returns [true] if the input has been handled by this function.
  Future<bool> _commonTerminalInputHandler(String character) async {
    globals.printStatus(''); // the key the user tapped might be on this line
    switch(character) {
      case 'a':
        if (residentRunner.supportsServiceProtocol) {
          await residentRunner.debugToggleProfileWidgetBuilds();
          return true;
        }
        return false;
      case 'c':
        residentRunner.clearScreen();
        return true;
      case 'd':
      case 'D':
        await residentRunner.detach();
        return true;
      case 'h':
      case 'H':
      case '?':
        // help
        residentRunner.printHelp(details: true);
        return true;
      case 'i':
      case 'I':
        if (residentRunner.supportsServiceProtocol) {
          await residentRunner.debugToggleWidgetInspector();
          return true;
        }
        return false;
      case 'k':
        if (residentRunner.supportsCanvasKit) {
          final bool result = await residentRunner.toggleCanvaskit();
          globals.printStatus('${result ? 'Enabled' : 'Disabled'} CanvasKit');
          return true;
        }
        return false;
      case 'l':
        final List<FlutterView> views = residentRunner.flutterDevices
            .expand((FlutterDevice d) => d.views).toList();
        globals.printStatus('Connected ${pluralize('view', views.length)}:');
        for (final FlutterView v in views) {
          globals.printStatus('${v.uiIsolate.name} (${v.uiIsolate.id})', indent: 2);
        }
        return true;
      case 'L':
        if (residentRunner.supportsServiceProtocol) {
          await residentRunner.debugDumpLayerTree();
          return true;
        }
        return false;
      case 'o':
      case 'O':
        if (residentRunner.supportsServiceProtocol && residentRunner.isRunningDebug) {
          await residentRunner.debugTogglePlatform();
          return true;
        }
        return false;
      case 'p':
        if (residentRunner.supportsServiceProtocol && residentRunner.isRunningDebug) {
          await residentRunner.debugToggleDebugPaintSizeEnabled();
          return true;
        }
        return false;
      case 'P':
        if (residentRunner.supportsServiceProtocol) {
          await residentRunner.debugTogglePerformanceOverlayOverride();
          return true;
        }
        return false;
      case 'q':
      case 'Q':
        // exit
        await residentRunner.exit();
        return true;
      case 's':
        for (final FlutterDevice device in residentRunner.flutterDevices) {
          if (device.device.supportsScreenshot) {
            await residentRunner.screenshot(device);
          }
        }
        return true;
      case 'r':
        if (!residentRunner.canHotReload) {
          return false;
        }
        final OperationResult result = await residentRunner.restart(fullRestart: false);
        if (result.fatal) {
          throwToolExit(result.message);
        }
        if (!result.isOk) {
          globals.printStatus('Try again after fixing the above error(s).', emphasis: true);
        }
        return true;
      case 'R':
        // If hot restart is not supported for all devices, ignore the command.
        if (!residentRunner.canHotRestart || !residentRunner.hotMode) {
          return false;
        }
        final OperationResult result = await residentRunner.restart(fullRestart: true);
        if (result.fatal) {
          throwToolExit(result.message);
        }
        if (!result.isOk) {
          globals.printStatus('Try again after fixing the above error(s).', emphasis: true);
        }
        return true;
      case 'S':
        if (residentRunner.supportsServiceProtocol) {
          await residentRunner.debugDumpSemanticsTreeInTraversalOrder();
          return true;
        }
        return false;
      case 't':
      case 'T':
        if (residentRunner.supportsServiceProtocol) {
          await residentRunner.debugDumpRenderTree();
          return true;
        }
        return false;
      case 'U':
        if (residentRunner.supportsServiceProtocol) {
          await residentRunner.debugDumpSemanticsTreeInInverseHitTestOrder();
          return true;
        }
        return false;
      case 'w':
      case 'W':
        if (residentRunner.supportsServiceProtocol) {
          await residentRunner.debugDumpApp();
          return true;
        }
        return false;
      case 'z':
      case 'Z':
        await residentRunner.debugToggleDebugCheckElevationsEnabled();
        return true;
    }
    return false;
  }

  Future<void> processTerminalInput(String command) async {
    // When terminal doesn't support line mode, '\n' can sneak into the input.
    command = command.trim();
    if (_processingUserRequest) {
      globals.printTrace('Ignoring terminal input: "$command" because we are busy.');
      return;
    }
    _processingUserRequest = true;
    try {
      lastReceivedCommand = command;
      await _commonTerminalInputHandler(command);
    // Catch all exception since this is doing cleanup and rethrowing.
    } catch (error, st) { // ignore: avoid_catches_without_on_clauses
      // Don't print stack traces for known error types.
      if (error is! ToolExit) {
        globals.printError('$error\n$st');
      }
      await _cleanUp(null);
      rethrow;
    } finally {
      _processingUserRequest = false;
    }
  }

  Future<void> _handleSignal(io.ProcessSignal signal) async {
    if (_processingUserRequest) {
      globals.printTrace('Ignoring signal: "$signal" because we are busy.');
      return;
    }
    _processingUserRequest = true;

    final bool fullRestart = signal == io.ProcessSignal.SIGUSR2;

    try {
      await residentRunner.restart(fullRestart: fullRestart);
    } finally {
      _processingUserRequest = false;
    }
  }

  Future<void> _cleanUp(io.ProcessSignal signal) async {
    globals.terminal.singleCharMode = false;
    await subscription?.cancel();
    await residentRunner.cleanupAfterSignal();
  }
}

class DebugConnectionInfo {
  DebugConnectionInfo({ this.httpUri, this.wsUri, this.baseUri });

  // TODO(danrubel): the httpUri field should be removed as part of
  // https://github.com/flutter/flutter/issues/7050
  final Uri httpUri;
  final Uri wsUri;
  final String baseUri;
}

/// Returns the next platform value for the switcher.
///
/// These values must match what is available in
/// packages/flutter/lib/src/foundation/binding.dart
String nextPlatform(String currentPlatform, FeatureFlags featureFlags) {
  switch (currentPlatform) {
    case 'android':
      return 'iOS';
    case 'iOS':
      return 'fuchsia';
    case 'fuchsia':
      if (featureFlags.isMacOSEnabled) {
        return 'macOS';
      }
      return 'android';
    case 'macOS':
      return 'android';
    default:
      assert(false); // Invalid current platform.
      return 'android';
  }
}
