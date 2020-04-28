// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/services/keyboard_key.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

typedef PostInvokeCallback = void Function({Action action, Intent intent, FocusNode focusNode, ActionDispatcher dispatcher});

class TestAction extends CallbackAction {
  const TestAction({
    @required OnInvokeCallback onInvoke,
  })  : assert(onInvoke != null),
        super(key, onInvoke: onInvoke);

  static const LocalKey key = ValueKey<Type>(TestAction);
}

class TestDispatcher extends ActionDispatcher {
  const TestDispatcher({this.postInvoke});

  final PostInvokeCallback postInvoke;

  @override
  bool invokeAction(Action action, Intent intent, {FocusNode focusNode}) {
    final bool result = super.invokeAction(action, intent, focusNode: focusNode);
    postInvoke?.call(action: action, intent: intent, focusNode: focusNode, dispatcher: this);
    return result;
  }
}

class TestIntent extends Intent {
  const TestIntent() : super(TestAction.key);
}

class TestShortcutManager extends ShortcutManager {
  TestShortcutManager(this.keys);

  List<LogicalKeyboardKey> keys;

  @override
  bool handleKeypress(BuildContext context, RawKeyEvent event, {LogicalKeySet keysPressed}) {
    keys.add(event.logicalKey);
    return super.handleKeypress(context, event, keysPressed: keysPressed);
  }
}

void main() {
  group(LogicalKeySet, () {
    test('LogicalKeySet passes parameters correctly.', () {
      final LogicalKeySet set1 = LogicalKeySet(LogicalKeyboardKey.keyA);
      final LogicalKeySet set2 = LogicalKeySet(
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyB,
      );
      final LogicalKeySet set3 = LogicalKeySet(
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyB,
        LogicalKeyboardKey.keyC,
      );
      final LogicalKeySet set4 = LogicalKeySet(
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyB,
        LogicalKeyboardKey.keyC,
        LogicalKeyboardKey.keyD,
      );
      final LogicalKeySet setFromSet = LogicalKeySet.fromSet(<LogicalKeyboardKey>{
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyB,
        LogicalKeyboardKey.keyC,
        LogicalKeyboardKey.keyD,
      });
      expect(
          set1.keys,
          equals(<LogicalKeyboardKey>{
            LogicalKeyboardKey.keyA,
          }));
      expect(
          set2.keys,
          equals(<LogicalKeyboardKey>{
            LogicalKeyboardKey.keyA,
            LogicalKeyboardKey.keyB,
          }));
      expect(
          set3.keys,
          equals(<LogicalKeyboardKey>{
            LogicalKeyboardKey.keyA,
            LogicalKeyboardKey.keyB,
            LogicalKeyboardKey.keyC,
          }));
      expect(
          set4.keys,
          equals(<LogicalKeyboardKey>{
            LogicalKeyboardKey.keyA,
            LogicalKeyboardKey.keyB,
            LogicalKeyboardKey.keyC,
            LogicalKeyboardKey.keyD,
          }));
      expect(
          setFromSet.keys,
          equals(<LogicalKeyboardKey>{
            LogicalKeyboardKey.keyA,
            LogicalKeyboardKey.keyB,
            LogicalKeyboardKey.keyC,
            LogicalKeyboardKey.keyD,
          }));
    });
    test('LogicalKeySet works as a map key.', () {
      final LogicalKeySet set1 = LogicalKeySet(LogicalKeyboardKey.keyA);
      final LogicalKeySet set2 = LogicalKeySet(
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyB,
        LogicalKeyboardKey.keyC,
        LogicalKeyboardKey.keyD,
      );
      final LogicalKeySet set3 = LogicalKeySet(
        LogicalKeyboardKey.keyD,
        LogicalKeyboardKey.keyC,
        LogicalKeyboardKey.keyB,
        LogicalKeyboardKey.keyA,
      );
      final LogicalKeySet set4 = LogicalKeySet.fromSet(<LogicalKeyboardKey>{
        LogicalKeyboardKey.keyD,
        LogicalKeyboardKey.keyC,
        LogicalKeyboardKey.keyB,
        LogicalKeyboardKey.keyA,
      });
      final Map<LogicalKeySet, String> map = <LogicalKeySet, String>{set1: 'one'};
      expect(set2 == set3, isTrue);
      expect(set2 == set4, isTrue);
      expect(set2.hashCode, set3.hashCode);
      expect(set2.hashCode, set4.hashCode);
      expect(map.containsKey(set1), isTrue);
      expect(map.containsKey(LogicalKeySet(LogicalKeyboardKey.keyA)), isTrue);
      expect(
          set2,
          equals(LogicalKeySet.fromSet(<LogicalKeyboardKey>{
            LogicalKeyboardKey.keyA,
            LogicalKeyboardKey.keyB,
            LogicalKeyboardKey.keyC,
            LogicalKeyboardKey.keyD,
          })),
      );
    });

    test('LogicalKeySet.hashCode is stable', () {
      final LogicalKeySet set1 = LogicalKeySet(LogicalKeyboardKey.keyA);
      expect(set1.hashCode, set1.hashCode);

      final LogicalKeySet set2 = LogicalKeySet(LogicalKeyboardKey.keyA, LogicalKeyboardKey.keyB);
      expect(set2.hashCode, set2.hashCode);

      final LogicalKeySet set3 = LogicalKeySet(LogicalKeyboardKey.keyA, LogicalKeyboardKey.keyB, LogicalKeyboardKey.keyC);
      expect(set3.hashCode, set3.hashCode);

      final LogicalKeySet set4 = LogicalKeySet(LogicalKeyboardKey.keyA, LogicalKeyboardKey.keyB, LogicalKeyboardKey.keyC, LogicalKeyboardKey.keyD);
      expect(set4.hashCode, set4.hashCode);
    });

    test('LogicalKeySet.hashCode is order-independent', () {
      expect(
        LogicalKeySet(LogicalKeyboardKey.keyA).hashCode,
        LogicalKeySet(LogicalKeyboardKey.keyA).hashCode,
      );
      expect(
        LogicalKeySet(LogicalKeyboardKey.keyA, LogicalKeyboardKey.keyB).hashCode,
        LogicalKeySet(LogicalKeyboardKey.keyB, LogicalKeyboardKey.keyA).hashCode,
      );
      expect(
        LogicalKeySet(LogicalKeyboardKey.keyA, LogicalKeyboardKey.keyB, LogicalKeyboardKey.keyC).hashCode,
        LogicalKeySet(LogicalKeyboardKey.keyC, LogicalKeyboardKey.keyB, LogicalKeyboardKey.keyA).hashCode,
      );
      expect(
        LogicalKeySet(LogicalKeyboardKey.keyA, LogicalKeyboardKey.keyB, LogicalKeyboardKey.keyC, LogicalKeyboardKey.keyD).hashCode,
        LogicalKeySet(LogicalKeyboardKey.keyD, LogicalKeyboardKey.keyC, LogicalKeyboardKey.keyB, LogicalKeyboardKey.keyA).hashCode,
      );
    });

    test('LogicalKeySet diagnostics work.', () {
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

      LogicalKeySet(
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyB,
      ).debugFillProperties(builder);

      final List<String> description = builder.properties
          .where((DiagnosticsNode node) {
            return !node.isFiltered(DiagnosticLevel.info);
          })
          .map((DiagnosticsNode node) => node.toString())
          .toList();

      expect(description.length, equals(1));
      expect(description[0], equals('keys: Key A + Key B'));
    });
  });
  group(Shortcuts, () {
    testWidgets('ShortcutManager handles shortcuts', (WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      final List<LogicalKeyboardKey> pressedKeys = <LogicalKeyboardKey>[];
      final TestShortcutManager testManager = TestShortcutManager(pressedKeys);
      bool invoked = false;
      await tester.pumpWidget(
        Actions(
          actions: <LocalKey, ActionFactory>{
            TestAction.key: () => TestAction(
              onInvoke: (FocusNode node, Intent intent) {
                invoked = true;
              },
            ),
          },
          child: Shortcuts(
            manager: testManager,
            shortcuts: <LogicalKeySet, Intent>{
              LogicalKeySet(LogicalKeyboardKey.shift): const TestIntent(),
            },
            child: Focus(
              autofocus: true,
              child: Container(key: containerKey, width: 100, height: 100),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(Shortcuts.of(containerKey.currentContext), isNotNull);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      expect(invoked, isTrue);
      expect(pressedKeys, equals(<LogicalKeyboardKey>[LogicalKeyboardKey.shiftLeft]));
    });
    testWidgets("Shortcuts passes to the next Shortcuts widget if it doesn't map the key", (WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      final List<LogicalKeyboardKey> pressedKeys = <LogicalKeyboardKey>[];
      final TestShortcutManager testManager = TestShortcutManager(pressedKeys);
      bool invoked = false;
      await tester.pumpWidget(
        Shortcuts(
          manager: testManager,
          shortcuts: <LogicalKeySet, Intent>{
            LogicalKeySet(LogicalKeyboardKey.shift): const TestIntent(),
          },
          child: Actions(
            actions: <LocalKey, ActionFactory>{
              TestAction.key: () => TestAction(
                onInvoke: (FocusNode node, Intent intent) {
                  invoked = true;
                },
              ),
            },
            child: Shortcuts(
              shortcuts: <LogicalKeySet, Intent>{
                LogicalKeySet(LogicalKeyboardKey.keyA): Intent.doNothing,
              },
              child: Focus(
                autofocus: true,
                child: Container(key: containerKey, width: 100, height: 100),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(Shortcuts.of(containerKey.currentContext), isNotNull);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      expect(invoked, isTrue);
      expect(pressedKeys, equals(<LogicalKeyboardKey>[LogicalKeyboardKey.shiftLeft]));
    });
    testWidgets('Shortcuts can disable a shortcut with Intent.doNothing', (WidgetTester tester) async {
      final GlobalKey containerKey = GlobalKey();
      final List<LogicalKeyboardKey> pressedKeys = <LogicalKeyboardKey>[];
      final TestShortcutManager testManager = TestShortcutManager(pressedKeys);
      bool invoked = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Shortcuts(
            manager: testManager,
            shortcuts: <LogicalKeySet, Intent>{
              LogicalKeySet(LogicalKeyboardKey.shift): const TestIntent(),
            },
            child: Actions(
              actions: <LocalKey, ActionFactory>{
                TestAction.key: () => TestAction(
                  onInvoke: (FocusNode node, Intent intent) {
                    invoked = true;
                  },
                ),
              },
              child: Shortcuts(
                shortcuts: <LogicalKeySet, Intent>{
                  LogicalKeySet(LogicalKeyboardKey.shift): Intent.doNothing,
                },
                child: Focus(
                  autofocus: true,
                  child: Container(key: containerKey, width: 100, height: 100),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(Shortcuts.of(containerKey.currentContext), isNotNull);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      expect(invoked, isFalse);
      expect(pressedKeys, isEmpty);
    });
    test('Shortcuts diagnostics work.', () {
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

      Shortcuts(shortcuts: <LogicalKeySet, Intent>{LogicalKeySet(
        LogicalKeyboardKey.shift,
        LogicalKeyboardKey.keyA,
      ) : const Intent(ActivateAction.key),
        LogicalKeySet(
        LogicalKeyboardKey.shift,
        LogicalKeyboardKey.arrowRight,
      ) : const DirectionalFocusIntent(TraversalDirection.right)}).debugFillProperties(builder);

      final List<String> description = builder.properties
          .where((DiagnosticsNode node) {
        return !node.isFiltered(DiagnosticLevel.info);
      })
          .map((DiagnosticsNode node) => node.toString())
          .toList();

      expect(description.length, equals(1));
      expect(
          description[0],
          equalsIgnoringHashCodes(
              'shortcuts: {{Shift + Key A}: Intent#00000(key: [<ActivateAction>]), {Shift + Arrow Right}: DirectionalFocusIntent#00000(key: [<DirectionalFocusAction>])}'));
    });
    test('Shortcuts diagnostics work when debugLabel specified.', () {
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

      Shortcuts(
        debugLabel: '<Debug Label>',
        shortcuts: <LogicalKeySet, Intent>{
          LogicalKeySet(
            LogicalKeyboardKey.keyA,
            LogicalKeyboardKey.keyB,
          ): const Intent(ActivateAction.key)
        },
      ).debugFillProperties(builder);

      final List<String> description = builder.properties
          .where((DiagnosticsNode node) {
        return !node.isFiltered(DiagnosticLevel.info);
      })
          .map((DiagnosticsNode node) => node.toString())
          .toList();

      expect(description.length, equals(1));
      expect(description[0], equals('shortcuts: <Debug Label>'));
    });
    test('Shortcuts diagnostics work when manager specified.', () {
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

      Shortcuts(
        manager: ShortcutManager(),
        shortcuts: <LogicalKeySet, Intent>{
          LogicalKeySet(
            LogicalKeyboardKey.keyA,
            LogicalKeyboardKey.keyB,
          ): const Intent(ActivateAction.key)
        },
      ).debugFillProperties(builder);

      final List<String> description = builder.properties
          .where((DiagnosticsNode node) {
        return !node.isFiltered(DiagnosticLevel.info);
      })
          .map((DiagnosticsNode node) => node.toString())
          .toList();

      expect(description.length, equals(2));
      expect(description[0], equalsIgnoringHashCodes('manager: ShortcutManager#00000(shortcuts: {})'));
      expect(description[1], equalsIgnoringHashCodes('shortcuts: {{Key A + Key B}: Intent#00000(key: [<ActivateAction>])}'));
    });
  });
}
