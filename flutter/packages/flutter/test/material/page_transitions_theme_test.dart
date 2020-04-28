// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Default PageTranstionsTheme platform', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Text('home')));
    final PageTransitionsTheme theme = Theme.of(tester.element(find.text('home'))).pageTransitionsTheme;
    expect(theme.builders, isNotNull);
    for (final TargetPlatform platform in TargetPlatform.values) {
      if (platform == TargetPlatform.fuchsia) {
        // No builder on Fuchsia.
        continue;
      }
      expect(theme.builders[platform], isNotNull, reason: 'theme builder for $platform is null');
    }
  });

  testWidgets('Default PageTranstionsTheme builds a CupertionPageTransition', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => Material(
        child: FlatButton(
          child: const Text('push'),
          onPressed: () { Navigator.of(context).pushNamed('/b'); },
        ),
      ),
      '/b': (BuildContext context) => const Text('page b'),
    };

    await tester.pumpWidget(
      MaterialApp(
        routes: routes,
      ),
    );

    expect(Theme.of(tester.element(find.text('push'))).platform, debugDefaultTargetPlatformOverride);
    expect(find.byType(CupertinoPageTransition), findsOneWidget);

    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    expect(find.text('page b'), findsOneWidget);
    expect(find.byType(CupertinoPageTransition), findsOneWidget);
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  testWidgets('Default PageTransitionsTheme builds a _FadeUpwardsPageTransition for android', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => Material(
        child: FlatButton(
          child: const Text('push'),
          onPressed: () { Navigator.of(context).pushNamed('/b'); },
        ),
      ),
      '/b': (BuildContext context) => const Text('page b'),
    };

    await tester.pumpWidget(
      MaterialApp(
        routes: routes,
      ),
    );

    Finder findFadeUpwardsPageTransition() {
      return find.descendant(
        of: find.byType(MaterialApp),
        matching: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_FadeUpwardsPageTransition'),
      );
    }

    expect(Theme.of(tester.element(find.text('push'))).platform, debugDefaultTargetPlatformOverride);
    expect(findFadeUpwardsPageTransition(), findsOneWidget);

    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    expect(find.text('page b'), findsOneWidget);
    expect(findFadeUpwardsPageTransition(), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('pageTranstionsTheme override builds a _OpenUpwardsPageTransition', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => Material(
        child: FlatButton(
          child: const Text('push'),
          onPressed: () { Navigator.of(context).pushNamed('/b'); },
        ),
      ),
      '/b': (BuildContext context) => const Text('page b'),
    };

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(), // creates a _OpenUpwardsPageTransition
            },
          ),
        ),
        routes: routes,
      ),
    );

    Finder findOpenUpwardsPageTransition() {
      return find.descendant(
        of: find.byType(MaterialApp),
        matching: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_OpenUpwardsPageTransition'),
      );
    }

    expect(Theme.of(tester.element(find.text('push'))).platform, debugDefaultTargetPlatformOverride);
    expect(findOpenUpwardsPageTransition(), findsOneWidget);

    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    expect(find.text('page b'), findsOneWidget);
    expect(findOpenUpwardsPageTransition(), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('pageTranstionsTheme override builds a _ZoomPageTransition', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => Material(
        child: FlatButton(
          child: const Text('push'),
          onPressed: () { Navigator.of(context).pushNamed('/b'); },
        ),
      ),
      '/b': (BuildContext context) => const Text('page b'),
    };

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: ZoomPageTransitionsBuilder(), // creates a _ZoomPageTransition
            },
          ),
        ),
        routes: routes,
      ),
    );

    Finder findZoomPageTransition() {
      return find.descendant(
        of: find.byType(MaterialApp),
        matching: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_ZoomPageTransition'),
      );
    }

    expect(Theme.of(tester.element(find.text('push'))).platform, debugDefaultTargetPlatformOverride);
    expect(findZoomPageTransition(), findsOneWidget);

    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    expect(find.text('page b'), findsOneWidget);
    expect(findZoomPageTransition(), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
