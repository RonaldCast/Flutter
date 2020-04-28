// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

Future<void> pumpTest(
  WidgetTester tester,
  TargetPlatform platform, {
  bool scrollable = true,
  bool reverse = false,
  ScrollController controller,
  Widget Function(Widget) wrapper,
}) async {
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(
      platform: platform,
    ),
    home: CustomScrollView(
      controller: controller,
      reverse: reverse,
      physics: scrollable ? null : const NeverScrollableScrollPhysics(),
      slivers: const <Widget>[
        SliverToBoxAdapter(child: SizedBox(height: 2000.0)),
      ],
    ),
  ));
  await tester.pump(const Duration(seconds: 5)); // to let the theme animate
}

// Pump a nested scrollable. The outer scrollable contains a sliver of a
// 300-pixel-long scrollable followed by a 2000-pixel-long content.
Future<void> pumpDoubleScrollableTest(
  WidgetTester tester,
  TargetPlatform platform,
) async {
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(
      platform: platform,
    ),
    home: CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Container(
            height: 300,
            child: const CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(child: SizedBox(height: 2000.0)),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 2000.0)),
      ],
    ),
  ));
  await tester.pump(const Duration(seconds: 5)); // to let the theme animate
}

const double dragOffset = 200.0;

final LogicalKeyboardKey modifierKey = defaultTargetPlatform == TargetPlatform.macOS
    ? LogicalKeyboardKey.metaLeft
    : LogicalKeyboardKey.controlLeft;

double getScrollOffset(WidgetTester tester, {bool last = true}) {
  Finder viewportFinder = find.byType(Viewport);
  if (last)
    viewportFinder = viewportFinder.last;
  final RenderViewport viewport = tester.renderObject(viewportFinder);
  return viewport.offset.pixels;
}

double getScrollVelocity(WidgetTester tester) {
  final RenderViewport viewport = tester.renderObject(find.byType(Viewport));
  final ScrollPosition position = viewport.offset as ScrollPosition;
  return position.activity.velocity;
}

void resetScrollOffset(WidgetTester tester) {
  final RenderViewport viewport = tester.renderObject(find.byType(Viewport));
  final ScrollPosition position = viewport.offset as ScrollPosition;
  position.jumpTo(0.0);
}

void main() {
  testWidgets('Flings on different platforms', (WidgetTester tester) async {
    await pumpTest(tester, TargetPlatform.android);
    await tester.fling(find.byType(Viewport), const Offset(0.0, -dragOffset), 1000.0);
    expect(getScrollOffset(tester), dragOffset);
    await tester.pump(); // trigger fling
    expect(getScrollOffset(tester), dragOffset);
    await tester.pump(const Duration(seconds: 5));
    final double androidResult = getScrollOffset(tester);

    resetScrollOffset(tester);

    await pumpTest(tester, TargetPlatform.iOS);
    await tester.fling(find.byType(Viewport), const Offset(0.0, -dragOffset), 1000.0);
    // Scroll starts ease into the scroll on iOS.
    expect(getScrollOffset(tester), moreOrLessEquals(197.16666666666669));
    await tester.pump(); // trigger fling
    expect(getScrollOffset(tester), moreOrLessEquals(197.16666666666669));
    await tester.pump(const Duration(seconds: 5));
    final double iOSResult = getScrollOffset(tester);

    resetScrollOffset(tester);

    await pumpTest(tester, TargetPlatform.macOS);
    await tester.fling(find.byType(Viewport), const Offset(0.0, -dragOffset), 1000.0);
    // Scroll starts ease into the scroll on iOS.
    expect(getScrollOffset(tester), moreOrLessEquals(197.16666666666669));
    await tester.pump(); // trigger fling
    expect(getScrollOffset(tester), moreOrLessEquals(197.16666666666669));
    await tester.pump(const Duration(seconds: 5));
    final double macOSResult = getScrollOffset(tester);

    expect(androidResult, lessThan(iOSResult)); // iOS is slipperier than Android
    expect(androidResult, lessThan(macOSResult)); // macOS is slipperier than Android
  });

  testWidgets('Holding scroll', (WidgetTester tester) async {
    await pumpTest(tester, debugDefaultTargetPlatformOverride);
    await tester.drag(find.byType(Viewport), const Offset(0.0, 200.0), touchSlopY: 0.0);
    expect(getScrollOffset(tester), -200.0);
    await tester.pump(); // trigger ballistic
    await tester.pump(const Duration(milliseconds: 10));
    expect(getScrollOffset(tester), greaterThan(-200.0));
    expect(getScrollOffset(tester), lessThan(0.0));
    final double heldPosition = getScrollOffset(tester);
    // Hold and let go while in overscroll.
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(Viewport)));
    expect(await tester.pumpAndSettle(), 1);
    expect(getScrollOffset(tester), heldPosition);
    await gesture.up();
    // Once the hold is let go, it should still snap back to origin.
    expect(await tester.pumpAndSettle(const Duration(minutes: 1)), 2);
    expect(getScrollOffset(tester), 0.0);
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  testWidgets('Repeated flings builds momentum', (WidgetTester tester) async {
    await pumpTest(tester, debugDefaultTargetPlatformOverride);
    await tester.fling(find.byType(Viewport), const Offset(0.0, -dragOffset), 1000.0);
    await tester.pump(); // trigger fling
    await tester.pump(const Duration(milliseconds: 10));
    // Repeat the exact same motion.
    await tester.fling(find.byType(Viewport), const Offset(0.0, -dragOffset), 1000.0);
    await tester.pump();
    // On iOS, the velocity will be larger than the velocity of the last fling by a
    // non-trivial amount.
    expect(getScrollVelocity(tester), greaterThan(1100.0));
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  testWidgets('Repeated flings do not build momentum on Android', (WidgetTester tester) async {
    await pumpTest(tester, TargetPlatform.android);
    await tester.fling(find.byType(Viewport), const Offset(0.0, -dragOffset), 1000.0);
    await tester.pump(); // trigger fling
    await tester.pump(const Duration(milliseconds: 10));
    // Repeat the exact same motion.
    await tester.fling(find.byType(Viewport), const Offset(0.0, -dragOffset), 1000.0);
    await tester.pump();
    // On Android, there is no momentum build. The final velocity is the same as the
    // velocity of the last fling.
    expect(getScrollVelocity(tester), moreOrLessEquals(1000.0));
  });

  testWidgets('No iOS/macOS momentum build with flings in opposite directions', (WidgetTester tester) async {
    await pumpTest(tester, debugDefaultTargetPlatformOverride);
    await tester.fling(find.byType(Viewport), const Offset(0.0, -dragOffset), 1000.0);
    await tester.pump(); // trigger fling
    await tester.pump(const Duration(milliseconds: 10));
    // Repeat the exact same motion in the opposite direction.
    await tester.fling(find.byType(Viewport), const Offset(0.0, dragOffset), 1000.0);
    await tester.pump();
    // The only applied velocity to the scrollable is the second fling that was in the
    // opposite direction.
    expect(getScrollVelocity(tester), greaterThan(-1000.0));
    expect(getScrollVelocity(tester), lessThan(0.0));
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  testWidgets('No iOS/macOS momentum kept on hold gestures', (WidgetTester tester) async {
    await pumpTest(tester, debugDefaultTargetPlatformOverride);
    await tester.fling(find.byType(Viewport), const Offset(0.0, -dragOffset), 1000.0);
    await tester.pump(); // trigger fling
    await tester.pump(const Duration(milliseconds: 10));
    expect(getScrollVelocity(tester), greaterThan(0.0));
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(Viewport)));
    await tester.pump(const Duration(milliseconds: 40));
    await gesture.up();
    // After a hold longer than 2 frames, previous velocity is lost.
    expect(getScrollVelocity(tester), 0.0);
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  testWidgets('Drags creeping unaffected on Android', (WidgetTester tester) async {
    await pumpTest(tester, TargetPlatform.android);
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(Viewport)));
    await gesture.moveBy(const Offset(0.0, -0.5));
    expect(getScrollOffset(tester), 0.5);
    await gesture.moveBy(const Offset(0.0, -0.5), timeStamp: const Duration(milliseconds: 10));
    expect(getScrollOffset(tester), 1.0);
    await gesture.moveBy(const Offset(0.0, -0.5), timeStamp: const Duration(milliseconds: 20));
    expect(getScrollOffset(tester), 1.5);
  });

  testWidgets('Drags creeping must break threshold on iOS/macOS', (WidgetTester tester) async {
    await pumpTest(tester, debugDefaultTargetPlatformOverride);
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(Viewport)));
    await gesture.moveBy(const Offset(0.0, -0.5));
    expect(getScrollOffset(tester), 0.0);
    await gesture.moveBy(const Offset(0.0, -0.5), timeStamp: const Duration(milliseconds: 10));
    expect(getScrollOffset(tester), 0.0);
    await gesture.moveBy(const Offset(0.0, -0.5), timeStamp: const Duration(milliseconds: 20));
    expect(getScrollOffset(tester), 0.0);
    await gesture.moveBy(const Offset(0.0, -1.0), timeStamp: const Duration(milliseconds: 30));
    // Now -2.5 in total.
    expect(getScrollOffset(tester), 0.0);
    await gesture.moveBy(const Offset(0.0, -1.0), timeStamp: const Duration(milliseconds: 40));
    // Now -3.5, just reached threshold.
    expect(getScrollOffset(tester), 0.0);
    await gesture.moveBy(const Offset(0.0, -0.5), timeStamp: const Duration(milliseconds: 50));
    // -0.5 over threshold transferred.
    expect(getScrollOffset(tester), 0.5);
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  testWidgets('Big drag over threshold magnitude preserved on iOS/macOS', (WidgetTester tester) async {
    await pumpTest(tester, debugDefaultTargetPlatformOverride);
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(Viewport)));
    await gesture.moveBy(const Offset(0.0, -30.0));
    // No offset lost from threshold.
    expect(getScrollOffset(tester), 30.0);
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  testWidgets('Slow threshold breaks are attenuated on iOS/macOS', (WidgetTester tester) async {
    await pumpTest(tester, debugDefaultTargetPlatformOverride);
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(Viewport)));
    // This is a typical 'hesitant' iOS scroll start.
    await gesture.moveBy(const Offset(0.0, -10.0));
    expect(getScrollOffset(tester), moreOrLessEquals(1.1666666666666667));
    await gesture.moveBy(const Offset(0.0, -10.0), timeStamp: const Duration(milliseconds: 20));
    // Subsequent motions unaffected.
    expect(getScrollOffset(tester), moreOrLessEquals(11.16666666666666673));
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  testWidgets('Small continuing motion preserved on iOS/macOS', (WidgetTester tester) async {
    await pumpTest(tester, debugDefaultTargetPlatformOverride);
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(Viewport)));
    await gesture.moveBy(const Offset(0.0, -30.0)); // Break threshold.
    expect(getScrollOffset(tester), 30.0);
    await gesture.moveBy(const Offset(0.0, -0.5), timeStamp: const Duration(milliseconds: 20));
    expect(getScrollOffset(tester), 30.5);
    await gesture.moveBy(const Offset(0.0, -0.5), timeStamp: const Duration(milliseconds: 40));
    expect(getScrollOffset(tester), 31.0);
    await gesture.moveBy(const Offset(0.0, -0.5), timeStamp: const Duration(milliseconds: 60));
    expect(getScrollOffset(tester), 31.5);
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  testWidgets('Motion stop resets threshold on iOS/macOS', (WidgetTester tester) async {
    await pumpTest(tester, debugDefaultTargetPlatformOverride);
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(Viewport)));
    await gesture.moveBy(const Offset(0.0, -30.0)); // Break threshold.
    expect(getScrollOffset(tester), 30.0);
    await gesture.moveBy(const Offset(0.0, -0.5), timeStamp: const Duration(milliseconds: 20));
    expect(getScrollOffset(tester), 30.5);
    await gesture.moveBy(Offset.zero);
    // Stationary too long, threshold reset.
    await gesture.moveBy(Offset.zero, timeStamp: const Duration(milliseconds: 120));
    await gesture.moveBy(const Offset(0.0, -1.0), timeStamp: const Duration(milliseconds: 140));
    expect(getScrollOffset(tester), 30.5);
    await gesture.moveBy(const Offset(0.0, -1.0), timeStamp: const Duration(milliseconds: 150));
    expect(getScrollOffset(tester), 30.5);
    await gesture.moveBy(const Offset(0.0, -1.0), timeStamp: const Duration(milliseconds: 160));
    expect(getScrollOffset(tester), 30.5);
    await gesture.moveBy(const Offset(0.0, -1.0), timeStamp: const Duration(milliseconds: 170));
    // New threshold broken.
    expect(getScrollOffset(tester), 31.5);
    await gesture.moveBy(const Offset(0.0, -1.0), timeStamp: const Duration(milliseconds: 180));
    expect(getScrollOffset(tester), 32.5);
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  testWidgets('Scroll pointer signals are handled on Fuchsia', (WidgetTester tester) async {
    await pumpTest(tester, TargetPlatform.fuchsia);
    final Offset scrollEventLocation = tester.getCenter(find.byType(Viewport));
    final TestPointer testPointer = TestPointer(1, ui.PointerDeviceKind.mouse);
    // Create a hover event so that |testPointer| has a location when generating the scroll.
    testPointer.hover(scrollEventLocation);
    final HitTestResult result = tester.hitTestOnBinding(scrollEventLocation);
    await tester.sendEventToBinding(testPointer.scroll(const Offset(0.0, 20.0)), result);
    expect(getScrollOffset(tester), 20.0);
    // Pointer signals should not cause overscroll.
    await tester.sendEventToBinding(testPointer.scroll(const Offset(0.0, -30.0)), result);
    expect(getScrollOffset(tester), 0.0);
  });

  testWidgets('Scroll pointer signals are handled when there is competion', (WidgetTester tester) async {
    // This is a regression test. When there are multiple scrollables listening
    // to the same event, for example when scrollables are nested, there used
    // to be exceptions at scrolling events.

    await pumpDoubleScrollableTest(tester, TargetPlatform.fuchsia);
    final Offset scrollEventLocation = tester.getCenter(find.byType(Viewport).last);
    final TestPointer testPointer = TestPointer(1, ui.PointerDeviceKind.mouse);
    // Create a hover event so that |testPointer| has a location when generating the scroll.
    testPointer.hover(scrollEventLocation);
    final HitTestResult result = tester.hitTestOnBinding(scrollEventLocation);
    await tester.sendEventToBinding(testPointer.scroll(const Offset(0.0, 20.0)), result);
    expect(getScrollOffset(tester, last: true), 20.0);
    // Pointer signals should not cause overscroll.
    await tester.sendEventToBinding(testPointer.scroll(const Offset(0.0, -30.0)), result);
    expect(getScrollOffset(tester, last: true), 0.0);
  });

  testWidgets('Scroll pointer signals are ignored when scrolling is disabled', (WidgetTester tester) async {
    await pumpTest(tester, TargetPlatform.fuchsia, scrollable: false);
    final Offset scrollEventLocation = tester.getCenter(find.byType(Viewport));
    final TestPointer testPointer = TestPointer(1, ui.PointerDeviceKind.mouse);
    // Create a hover event so that |testPointer| has a location when generating the scroll.
    testPointer.hover(scrollEventLocation);
    final HitTestResult result = tester.hitTestOnBinding(scrollEventLocation);
    await tester.sendEventToBinding(testPointer.scroll(const Offset(0.0, 20.0)), result);
    expect(getScrollOffset(tester), 0.0);
  });

  testWidgets('Scrolls in correct direction when scroll axis is reversed', (WidgetTester tester) async {
    await pumpTest(tester, TargetPlatform.fuchsia, reverse: true);

    final Offset scrollEventLocation = tester.getCenter(find.byType(Viewport));
    final TestPointer testPointer = TestPointer(1, ui.PointerDeviceKind.mouse);
    // Create a hover event so that |testPointer| has a location when generating the scroll.
    testPointer.hover(scrollEventLocation);
    final HitTestResult result = tester.hitTestOnBinding(scrollEventLocation);
    await tester.sendEventToBinding(testPointer.scroll(const Offset(0.0, -20.0)), result);

    expect(getScrollOffset(tester), 20.0);
  });

  testWidgets("Keyboard scrolling doesn't happen if scroll physics are set to NeverScrollableScrollPhysics", (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          platform: TargetPlatform.fuchsia,
        ),
        home: CustomScrollView(
          controller: controller,
          physics: const NeverScrollableScrollPhysics(),
          slivers: List<Widget>.generate(
            20,
            (int index) {
              return SliverToBoxAdapter(
                child: Focus(
                  autofocus: index == 0,
                  child: SizedBox(key: ValueKey<String>('Box $index'), height: 50.0),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(controller.position.pixels, equals(0.0));
    expect(tester.getRect(find.byKey(const ValueKey<String>('Box 0'), skipOffstage: false)), equals(const Rect.fromLTRB(0.0, 0.0, 800.0, 50.0)));
    await tester.sendKeyDownEvent(modifierKey);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(modifierKey);
    await tester.pumpAndSettle();
    expect(controller.position.pixels, equals(0.0));
    expect(tester.getRect(find.byKey(const ValueKey<String>('Box 0'), skipOffstage: false)), equals(const Rect.fromLTRB(0.0, 0.0, 800.0, 50.0)));
    await tester.sendKeyDownEvent(modifierKey);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyUpEvent(modifierKey);
    await tester.pumpAndSettle();
    expect(controller.position.pixels, equals(0.0));
    expect(tester.getRect(find.byKey(const ValueKey<String>('Box 0'), skipOffstage: false)), equals(const Rect.fromLTRB(0.0, 0.0, 800.0, 50.0)));
    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pumpAndSettle();
    expect(controller.position.pixels, equals(0.0));
    expect(tester.getRect(find.byKey(const ValueKey<String>('Box 0'), skipOffstage: false)), equals(const Rect.fromLTRB(0.0, 0.0, 800.0, 50.0)));
    await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
    await tester.pumpAndSettle();
    expect(controller.position.pixels, equals(0.0));
    expect(tester.getRect(find.byKey(const ValueKey<String>('Box 0'), skipOffstage: false)), equals(const Rect.fromLTRB(0.0, 0.0, 800.0, 50.0)));

    // TODO(gspencergoog): Once we can test against TargetPlatform.macOS instead
    // of Platform.isMacOS, don't skip this on web anymore.
    // https://github.com/flutter/flutter/issues/31366
  }, skip: kIsWeb);

  testWidgets('Vertical scrollables are scrolled when activated via keyboard.', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          platform: TargetPlatform.fuchsia,
        ),
        home: CustomScrollView(
          controller: controller,
          slivers: List<Widget>.generate(
            20,
            (int index) {
              return SliverToBoxAdapter(
                child: Focus(
                  autofocus: index == 0,
                  child: SizedBox(key: ValueKey<String>('Box $index'), height: 50.0),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(controller.position.pixels, equals(0.0));
    expect(tester.getRect(find.byKey(const ValueKey<String>('Box 0'), skipOffstage: false)), equals(const Rect.fromLTRB(0.0, 0.0, 800.0, 50.0)));
    await tester.sendKeyDownEvent(modifierKey);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(modifierKey);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const ValueKey<String>('Box 0'), skipOffstage: false)), equals(const Rect.fromLTRB(0.0, -50.0, 800.0, 0.0)));
    await tester.sendKeyDownEvent(modifierKey);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyUpEvent(modifierKey);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const ValueKey<String>('Box 0'), skipOffstage: false)), equals(const Rect.fromLTRB(0.0, 0.0, 800.0, 50.0)));
    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const ValueKey<String>('Box 0'), skipOffstage: false)), equals(const Rect.fromLTRB(0.0, -400.0, 800.0, -350.0)));
    await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const ValueKey<String>('Box 0'), skipOffstage: false)), equals(const Rect.fromLTRB(0.0, 0.0, 800.0, 50.0)));

    // TODO(gspencergoog): Once we can test against TargetPlatform.macOS instead
    // of Platform.isMacOS, don't skip this on web anymore.
    // https://github.com/flutter/flutter/issues/31366
  }, skip: kIsWeb);

  testWidgets('Horizontal scrollables are scrolled when activated via keyboard.', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          platform: TargetPlatform.fuchsia,
        ),
        home: CustomScrollView(
          controller: controller,
          scrollDirection: Axis.horizontal,
          slivers: List<Widget>.generate(
            20,
            (int index) {
              return SliverToBoxAdapter(
                child: Focus(
                  autofocus: index == 0,
                  child: SizedBox(key: ValueKey<String>('Box $index'), width: 50.0),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(controller.position.pixels, equals(0.0));
    expect(tester.getRect(find.byKey(const ValueKey<String>('Box 0'), skipOffstage: false)), equals(const Rect.fromLTRB(0.0, 0.0, 50.0, 600.0)));
    await tester.sendKeyDownEvent(modifierKey);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(modifierKey);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const ValueKey<String>('Box 0'), skipOffstage: false)), equals(const Rect.fromLTRB(-50.0, 0.0, 0.0, 600.0)));
    await tester.sendKeyDownEvent(modifierKey);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyUpEvent(modifierKey);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const ValueKey<String>('Box 0'), skipOffstage: false)), equals(const Rect.fromLTRB(0.0, 0.0, 50.0, 600.0)));

    // TODO(gspencergoog): Once we can test against TargetPlatform.macOS instead
    // of Platform.isMacOS, don't skip this on web anymore.
    // https://github.com/flutter/flutter/issues/31366
  }, skip: kIsWeb);

  testWidgets('Horizontal scrollables are scrolled the correct direction in RTL locales.', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          platform: TargetPlatform.fuchsia,
        ),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: CustomScrollView(
            controller: controller,
            scrollDirection: Axis.horizontal,
            slivers: List<Widget>.generate(
              20,
                  (int index) {
                return SliverToBoxAdapter(
                  child: Focus(
                    autofocus: index == 0,
                    child: SizedBox(key: ValueKey<String>('Box $index'), width: 50.0),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(controller.position.pixels, equals(0.0));
    expect(tester.getRect(find.byKey(const ValueKey<String>('Box 0'), skipOffstage: false)), equals(const Rect.fromLTRB(750.0, 0.0, 800.0, 600.0)));
    await tester.sendKeyDownEvent(modifierKey);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyUpEvent(modifierKey);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const ValueKey<String>('Box 0'), skipOffstage: false)), equals(const Rect.fromLTRB(800.0, 0.0, 850.0, 600.0)));
    await tester.sendKeyDownEvent(modifierKey);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(modifierKey);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const ValueKey<String>('Box 0'), skipOffstage: false)), equals(const Rect.fromLTRB(750.0, 0.0, 800.0, 600.0)));

    // TODO(gspencergoog): Once we can test against TargetPlatform.macOS instead
    // of Platform.isMacOS, don't skip this on web anymore.
    // https://github.com/flutter/flutter/issues/31366
  }, skip: kIsWeb);

  testWidgets('Reversed vertical scrollables are scrolled when activated via keyboard.', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    final FocusNode focusNode = FocusNode(debugLabel: 'SizedBox');
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          platform: TargetPlatform.fuchsia,
        ),
        home: CustomScrollView(
          controller: controller,
          reverse: true,
          slivers: List<Widget>.generate(
            20,
            (int index) {
              return SliverToBoxAdapter(
                child: Focus(
                  focusNode: focusNode,
                  child: SizedBox(key: ValueKey<String>('Box $index'), height: 50.0),
                ),
              );
            },
          ),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(controller.position.pixels, equals(0.0));
    expect(tester.getRect(find.byKey(const ValueKey<String>('Box 0'), skipOffstage: false)), equals(const Rect.fromLTRB(0.0, 550.0, 800.0, 600.0)));
    await tester.sendKeyDownEvent(modifierKey);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyUpEvent(modifierKey);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const ValueKey<String>('Box 0'), skipOffstage: false)), equals(const Rect.fromLTRB(0.0, 600.0, 800.0, 650.0)));
    await tester.sendKeyDownEvent(modifierKey);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(modifierKey);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const ValueKey<String>('Box 0'), skipOffstage: false)), equals(const Rect.fromLTRB(0.0, 550.0, 800.0, 600.0)));
    await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const ValueKey<String>('Box 0'), skipOffstage: false)), equals(const Rect.fromLTRB(0.0, 950.0, 800.0, 1000.0)));
    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const ValueKey<String>('Box 0'), skipOffstage: false)), equals(const Rect.fromLTRB(0.0, 550.0, 800.0, 600.0)));

    // TODO(gspencergoog): Once we can test against TargetPlatform.macOS instead
    // of Platform.isMacOS, don't skip this on web anymore.
    // https://github.com/flutter/flutter/issues/31366
  }, skip: kIsWeb);

  testWidgets('Reversed horizontal scrollables are scrolled when activated via keyboard.', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    final FocusNode focusNode = FocusNode(debugLabel: 'SizedBox');
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          platform: TargetPlatform.fuchsia,
        ),
        home: CustomScrollView(
          controller: controller,
          scrollDirection: Axis.horizontal,
          reverse: true,
          slivers: List<Widget>.generate(
            20,
            (int index) {
              return SliverToBoxAdapter(
                child: Focus(
                  focusNode: focusNode,
                  child: SizedBox(key: ValueKey<String>('Box $index'), width: 50.0),
                ),
              );
            },
          ),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(controller.position.pixels, equals(0.0));
    expect(tester.getRect(find.byKey(const ValueKey<String>('Box 0'), skipOffstage: false)), equals(const Rect.fromLTRB(750.0, 0.0, 800.0, 600.00)));
    await tester.sendKeyDownEvent(modifierKey);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyUpEvent(modifierKey);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const ValueKey<String>('Box 0'), skipOffstage: false)), equals(const Rect.fromLTRB(800.0, 0.0, 850.0, 600.0)));
    await tester.sendKeyDownEvent(modifierKey);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(modifierKey);
    await tester.pumpAndSettle();

    // TODO(gspencergoog): Once we can test against TargetPlatform.macOS instead
    // of Platform.isMacOS, don't skip this on web anymore.
    // https://github.com/flutter/flutter/issues/31366
  }, skip: kIsWeb);

  testWidgets('Custom scrollables with a center sliver are scrolled when activated via keyboard.', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    final List<String> items = List<String>.generate(20, (int index) => 'Item $index');
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          platform: TargetPlatform.fuchsia,
        ),
        home: CustomScrollView(
          controller: controller,
          center: const ValueKey<String>('Center'),
          slivers: items.map<Widget>(
            (String item) {
              return SliverToBoxAdapter(
                key: item == 'Item 10' ? const ValueKey<String>('Center') : null,
                child: Focus(
                  autofocus: item == 'Item 10',
                  child: Container(
                    key: ValueKey<String>(item),
                    alignment: Alignment.center,
                    height: 100,
                    child: Text(item),
                  ),
                ),
              );
            },
          ).toList(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(controller.position.pixels, equals(0.0));
    expect(tester.getRect(find.byKey(const ValueKey<String>('Item 10'), skipOffstage: false)), equals(const Rect.fromLTRB(0.0, 0.0, 800.0, 100.0)));
    for (int i = 0; i < 10; ++i) {
      await tester.sendKeyDownEvent(modifierKey);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(modifierKey);
      await tester.pumpAndSettle();
    }
    // Starts at #10 already, so doesn't work out to 500.0 because it hits bottom.
    expect(controller.position.pixels, equals(400.0));
    expect(tester.getRect(find.byKey(const ValueKey<String>('Item 10'), skipOffstage: false)), equals(const Rect.fromLTRB(0.0, -400.0, 800.0, -300.0)));
    for (int i = 0; i < 10; ++i) {
      await tester.sendKeyDownEvent(modifierKey);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyUpEvent(modifierKey);
      await tester.pumpAndSettle();
    }
    // Goes up two past "center" where it started, so negative.
    expect(controller.position.pixels, equals(-100.0));
    expect(tester.getRect(find.byKey(const ValueKey<String>('Item 10'), skipOffstage: false)), equals(const Rect.fromLTRB(0.0, 100.0, 800.0, 200.0)));

    // TODO(gspencergoog): Once we can test against TargetPlatform.macOS instead
    // of Platform.isMacOS, don't skip this on web anymore.
    // https://github.com/flutter/flutter/issues/31366
  }, skip: kIsWeb);

  testWidgets('Can recommendDeferredLoadingForContext - animation', (WidgetTester tester) async {
    final List<String> widgetTracker = <String>[];
    int cheapWidgets = 0;
    int expensiveWidgets = 0;
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: ListView.builder(
        controller: controller,
        itemBuilder: (BuildContext context, int index) {
          if (Scrollable.recommendDeferredLoadingForContext(context)) {
            cheapWidgets += 1;
            widgetTracker.add('cheap');
            return const SizedBox(height: 50.0);
          }
          widgetTracker.add('expensive');
          expensiveWidgets += 1;
          return const SizedBox(height: 50.0);
        },
      ),
    ));

    await tester.pumpAndSettle();

    expect(expensiveWidgets, 17);
    expect(cheapWidgets, 0);

    // The position value here is different from the maximum velocity we will
    // reach, which is controlled by a combination of curve, duration, and
    // position.
    // This is just meant to be a pretty good simulation. A linear curve
    // with these same parameters will never back off on the velocity enough
    // to reset here.
    controller.animateTo(
      5000,
      duration: const Duration(seconds: 2),
      curve: Curves.linear,
    );

    expect(expensiveWidgets, 17);
    expect(widgetTracker.every((String type) => type == 'expensive'), true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(expensiveWidgets, 17);
    expect(cheapWidgets, 25);
    expect(widgetTracker.skip(17).every((String type) => type == 'cheap'), true);

    await tester.pumpAndSettle();

    expect(expensiveWidgets, 22);
    expect(cheapWidgets, 95);
    expect(widgetTracker.skip(17).skip(25).take(70).every((String type) => type == 'cheap'), true);
    expect(widgetTracker.skip(17).skip(25).skip(70).every((String type) => type == 'expensive'), true);
  });

  testWidgets('Can recommendDeferredLoadingForContext - ballistics', (WidgetTester tester) async {
    int cheapWidgets = 0;
    int expensiveWidgets = 0;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          if (Scrollable.recommendDeferredLoadingForContext(context)) {
            cheapWidgets += 1;
            return const SizedBox(height: 50.0);
          }
          expensiveWidgets += 1;
          return SizedBox(key: ValueKey<String>('Box $index'), height: 50.0);
        },
      ),
    ));

    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('Box 0')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('Box 52')), findsNothing);

    expect(expensiveWidgets, 17);
    expect(cheapWidgets, 0);

    // Getting the tester to simulate a life-like fling is difficult.
    // Instead, just manually drive the activity with a ballistic simulation as
    // if the user has flung the list.
    Scrollable.of(find.byType(SizedBox).evaluate().first).position.activity.delegate.goBallistic(4000);

    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('Box 0')), findsNothing);
    expect(find.byKey(const ValueKey<String>('Box 52')), findsOneWidget);

    expect(expensiveWidgets, 38);
    expect(cheapWidgets, 20);
  });

  testWidgets('Can recommendDeferredLoadingForContext - override heuristic', (WidgetTester tester) async {
    int cheapWidgets = 0;
    int expensiveWidgets = 0;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: ListView.builder(
        physics: SuperPessimisticScrollPhysics(),
        itemBuilder: (BuildContext context, int index) {
          if (Scrollable.recommendDeferredLoadingForContext(context)) {
            cheapWidgets += 1;
            return SizedBox(key: ValueKey<String>('Cheap box $index'), height: 50.0);
          }
          expensiveWidgets += 1;
          return SizedBox(key: ValueKey<String>('Box $index'), height: 50.0);
        },
      ),
    ));
    await tester.pumpAndSettle();

    final ScrollPosition position = Scrollable.of(find.byType(SizedBox).evaluate().first).position;
    final SuperPessimisticScrollPhysics physics = position.physics as SuperPessimisticScrollPhysics;

    expect(find.byKey(const ValueKey<String>('Box 0')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('Cheap box 52')), findsNothing);

    expect(physics.count, 17);
    expect(expensiveWidgets, 17);
    expect(cheapWidgets, 0);

    // Getting the tester to simulate a life-like fling is difficult.
    // Instead, just manually drive the activity with a ballistic simulation as
    // if the user has flung the list.
    position.activity.delegate.goBallistic(4000);

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('Box 0')), findsNothing);
    expect(find.byKey(const ValueKey<String>('Cheap box 52')), findsOneWidget);

    expect(expensiveWidgets, 18);
    expect(cheapWidgets, 40);
    expect(physics.count, 40 + 18);
  });

  testWidgets('Can recommendDeferredLoadingForContext - override heuristic and always return true', (WidgetTester tester) async {
    int cheapWidgets = 0;
    int expensiveWidgets = 0;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: ListView.builder(
        physics: const ExtraSuperPessimisticScrollPhysics(),
        itemBuilder: (BuildContext context, int index) {
          if (Scrollable.recommendDeferredLoadingForContext(context)) {
            cheapWidgets += 1;
            return SizedBox(key: ValueKey<String>('Cheap box $index'), height: 50.0);
          }
          expensiveWidgets += 1;
          return SizedBox(key: ValueKey<String>('Box $index'), height: 50.0);
        },
      ),
    ));
    await tester.pumpAndSettle();

    final ScrollPosition position = Scrollable.of(find.byType(SizedBox).evaluate().first).position;

    expect(find.byKey(const ValueKey<String>('Cheap box 0')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('Cheap box 52')), findsNothing);

    expect(expensiveWidgets, 0);
    expect(cheapWidgets, 17);

    // Getting the tester to simulate a life-like fling is difficult.
    // Instead, just manually drive the activity with a ballistic simulation as
    // if the user has flung the list.
    position.activity.delegate.goBallistic(4000);

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('Cheap box 0')), findsNothing);
    expect(find.byKey(const ValueKey<String>('Cheap box 52')), findsOneWidget);

    expect(expensiveWidgets, 0);
    expect(cheapWidgets, 58);
  });
}

// ignore: must_be_immutable
class SuperPessimisticScrollPhysics extends ScrollPhysics {
  SuperPessimisticScrollPhysics({ScrollPhysics parent}) : super(parent: parent);

  int count = 0;

  @override
  bool recommendDeferredLoading(double velocity, ScrollMetrics metrics, BuildContext context) {
    count++;
    return velocity > 1;
  }

  @override
  ScrollPhysics applyTo(ScrollPhysics ancestor) {
    return SuperPessimisticScrollPhysics(parent: buildParent(ancestor));
  }
}

class ExtraSuperPessimisticScrollPhysics extends ScrollPhysics {
  const ExtraSuperPessimisticScrollPhysics({ScrollPhysics parent}) : super(parent: parent);

  @override
  bool recommendDeferredLoading(double velocity, ScrollMetrics metrics, BuildContext context) {
    return true;
  }

  @override
  ScrollPhysics applyTo(ScrollPhysics ancestor) {
    return ExtraSuperPessimisticScrollPhysics(parent: buildParent(ancestor));
  }
}
