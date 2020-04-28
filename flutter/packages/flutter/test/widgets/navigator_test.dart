// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'observer_tester.dart';
import 'semantics_tester.dart';

class FirstWidget extends StatelessWidget {
  const FirstWidget({ Key key }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/second');
      },
      child: Container(
        color: const Color(0xFFFFFF00),
        child: const Text('X'),
      ),
    );
  }
}

class SecondWidget extends StatefulWidget {
  const SecondWidget({ Key key }) : super(key: key);
  @override
  SecondWidgetState createState() => SecondWidgetState();
}

class SecondWidgetState extends State<SecondWidget> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        color: const Color(0xFFFF00FF),
        child: const Text('Y'),
      ),
    );
  }
}

typedef ExceptionCallback = void Function(dynamic exception);

class ThirdWidget extends StatelessWidget {
  const ThirdWidget({ Key key, this.targetKey, this.onException }) : super(key: key);

  final Key targetKey;
  final ExceptionCallback onException;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: targetKey,
      onTap: () {
        try {
          Navigator.of(context);
        } catch (e) {
          onException(e);
        }
      },
      behavior: HitTestBehavior.opaque,
    );
  }
}

class OnTapPage extends StatelessWidget {
  const OnTapPage({ Key key, this.id, this.onTap }) : super(key: key);

  final String id;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Page $id')),
      body: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          child: Center(
            child: Text(id, style: Theme.of(context).textTheme.headline3),
          ),
        ),
      ),
    );
  }
}

class SlideInOutPageRoute<T> extends PageRouteBuilder<T> {
  SlideInOutPageRoute({WidgetBuilder bodyBuilder, RouteSettings settings}) : super(
    settings: settings,
    pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) => bodyBuilder(context),
    transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0),
            end: Offset.zero,
          ).animate(animation),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-1.0, 0),
            ).animate(secondaryAnimation),
            child: child,
          ),
        );
      },
  );

  @override
  AnimationController get controller => super.controller;
}

void main() {
  testWidgets('Can navigator navigate to and from a stateful widget', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => const FirstWidget(), // X
      '/second': (BuildContext context) => const SecondWidget(), // Y
    };

    await tester.pumpWidget(MaterialApp(routes: routes));
    expect(find.text('X'), findsOneWidget);
    expect(find.text('Y', skipOffstage: false), findsNothing);

    await tester.tap(find.text('X'));
    await tester.pump();
    expect(find.text('X'), findsOneWidget);
    expect(find.text('Y', skipOffstage: false), isOffstage);

    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text('X'), findsOneWidget);
    expect(find.text('Y'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text('X'), findsOneWidget);
    expect(find.text('Y'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text('X'), findsOneWidget);
    expect(find.text('Y'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('X'), findsNothing);
    expect(find.text('X', skipOffstage: false), findsOneWidget);
    expect(find.text('Y'), findsOneWidget);

    await tester.tap(find.text('Y'));
    expect(find.text('X'), findsNothing);
    expect(find.text('Y'), findsOneWidget);

    await tester.pump();
    await tester.pump();
    expect(find.text('X'), findsOneWidget);
    expect(find.text('Y'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text('X'), findsOneWidget);
    expect(find.text('Y'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('X'), findsOneWidget);
    expect(find.text('Y', skipOffstage: false), findsNothing);
  });

  testWidgets('Navigator.of fails gracefully when not found in context', (WidgetTester tester) async {
    const Key targetKey = Key('foo');
    dynamic exception;
    final Widget widget = ThirdWidget(
      targetKey: targetKey,
      onException: (dynamic e) {
        exception = e;
      },
    );
    await tester.pumpWidget(widget);
    await tester.tap(find.byKey(targetKey));
    expect(exception, isFlutterError);
    expect('$exception', startsWith('Navigator operation requested with a context'));
  });

  testWidgets('Navigator.of rootNavigator finds root Navigator', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: Column(
          children: <Widget>[
            const SizedBox(
              height: 300.0,
              child: Text('Root page'),
            ),
            SizedBox(
              height: 300.0,
              child: Navigator(
                onGenerateRoute: (RouteSettings settings) {
                  if (settings.name == '/') {
                    return MaterialPageRoute<void>(
                      builder: (BuildContext context) {
                        return RaisedButton(
                          child: const Text('Next'),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (BuildContext context) {
                                  return RaisedButton(
                                    child: const Text('Inner page'),
                                    onPressed: () {
                                      Navigator.of(context, rootNavigator: true).push(
                                        MaterialPageRoute<void>(
                                          builder: (BuildContext context) {
                                            return const Text('Dialog');
                                          }
                                        ),
                                      );
                                    },
                                  );
                                }
                              ),
                            );
                          },
                        );
                      },
                    );
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    ));

    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Both elements are on screen.
    expect(tester.getTopLeft(find.text('Root page')).dy, 0.0);
    expect(tester.getTopLeft(find.text('Inner page')).dy, greaterThan(300.0));

    await tester.tap(find.text('Inner page'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Dialog is pushed to the whole page and is at the top of the screen, not
    // inside the inner page.
    expect(tester.getTopLeft(find.text('Dialog')).dy, 0.0);
  });

  testWidgets('Gestures between push and build are ignored', (WidgetTester tester) async {
    final List<String> log = <String>[];
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) {
        return Row(
          children: <Widget>[
            GestureDetector(
              onTap: () {
                log.add('left');
                Navigator.pushNamed(context, '/second');
              },
              child: const Text('left'),
            ),
            GestureDetector(
              onTap: () { log.add('right'); },
              child: const Text('right'),
            ),
          ],
        );
      },
      '/second': (BuildContext context) => Container(),
    };
    await tester.pumpWidget(MaterialApp(routes: routes));
    expect(log, isEmpty);
    await tester.tap(find.text('left'));
    expect(log, equals(<String>['left']));
    await tester.tap(find.text('right'));
    expect(log, equals(<String>['left']));
  });

   testWidgets('Pending gestures are rejected', (WidgetTester tester) async {
     final List<String> log = <String>[];
     final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
       '/': (BuildContext context) {
         return Row(
           children: <Widget>[
             GestureDetector(
               onTap: () {
                 log.add('left');
                 Navigator.pushNamed(context, '/second');
               },
               child: const Text('left')
             ),
             GestureDetector(
               onTap: () { log.add('right'); },
               child: const Text('right'),
             ),
           ]
         );
       },
       '/second': (BuildContext context) => Container(),
     };
     await tester.pumpWidget(MaterialApp(routes: routes));
     final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text('right')), pointer: 23);
     expect(log, isEmpty);
     await tester.tap(find.text('left'));
     expect(log, equals(<String>['left']));
     await gesture.up();
     expect(log, equals(<String>['left']));

     // This test doesn't work because it relies on part of the pointer event
     // dispatching mechanism that is mocked out in testing. We should use the real
     // mechanism even during testing and enable this test.
     // TODO(abarth): Test more of the real code and enable this test.
     // See https://github.com/flutter/flutter/issues/4771.
   }, skip: true);

  testWidgets('popAndPushNamed', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/' : (BuildContext context) => OnTapPage(id: '/', onTap: () { Navigator.pushNamed(context, '/A'); }),
      '/A': (BuildContext context) => OnTapPage(id: 'A', onTap: () { Navigator.popAndPushNamed(context, '/B'); }),
      '/B': (BuildContext context) => OnTapPage(id: 'B', onTap: () { Navigator.pop(context); }),
    };

    await tester.pumpWidget(MaterialApp(routes: routes));
    expect(find.text('/'), findsOneWidget);
    expect(find.text('A', skipOffstage: false), findsNothing);
    expect(find.text('B', skipOffstage: false), findsNothing);

    await tester.tap(find.text('/'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('/'), findsNothing);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);

    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('/'), findsNothing);
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('Push and pop should trigger the observers', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/' : (BuildContext context) => OnTapPage(id: '/', onTap: () { Navigator.pushNamed(context, '/A'); }),
      '/A': (BuildContext context) => OnTapPage(id: 'A', onTap: () { Navigator.pop(context); }),
    };
    bool isPushed = false;
    bool isPopped = false;
    final TestObserver observer = TestObserver()
      ..onPushed = (Route<dynamic> route, Route<dynamic> previousRoute) {
        // Pushes the initial route.
        expect(route is PageRoute && route.settings.name == '/', isTrue);
        expect(previousRoute, isNull);
        isPushed = true;
      }
      ..onPopped = (Route<dynamic> route, Route<dynamic> previousRoute) {
        isPopped = true;
      };

    await tester.pumpWidget(MaterialApp(
      routes: routes,
      navigatorObservers: <NavigatorObserver>[observer],
    ));
    expect(find.text('/'), findsOneWidget);
    expect(find.text('A'), findsNothing);
    expect(isPushed, isTrue);
    expect(isPopped, isFalse);

    isPushed = false;
    isPopped = false;
    observer.onPushed = (Route<dynamic> route, Route<dynamic> previousRoute) {
      expect(route is PageRoute && route.settings.name == '/A', isTrue);
      expect(previousRoute is PageRoute && previousRoute.settings.name == '/', isTrue);
      isPushed = true;
    };

    await tester.tap(find.text('/'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('/'), findsNothing);
    expect(find.text('A'), findsOneWidget);
    expect(isPushed, isTrue);
    expect(isPopped, isFalse);

    isPushed = false;
    isPopped = false;
    observer.onPopped = (Route<dynamic> route, Route<dynamic> previousRoute) {
      expect(route is PageRoute && route.settings.name == '/A', isTrue);
      expect(previousRoute is PageRoute && previousRoute.settings.name == '/', isTrue);
      isPopped = true;
    };

    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('/'), findsOneWidget);
    expect(find.text('A'), findsNothing);
    expect(isPushed, isFalse);
    expect(isPopped, isTrue);
  });

  testWidgets('Add and remove an observer should work', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/' : (BuildContext context) => OnTapPage(id: '/', onTap: () { Navigator.pushNamed(context, '/A'); }),
      '/A': (BuildContext context) => OnTapPage(id: 'A', onTap: () { Navigator.pop(context); }),
    };
    bool isPushed = false;
    bool isPopped = false;
    final TestObserver observer1 = TestObserver();
    final TestObserver observer2 = TestObserver()
      ..onPushed = (Route<dynamic> route, Route<dynamic> previousRoute) {
        isPushed = true;
      }
      ..onPopped = (Route<dynamic> route, Route<dynamic> previousRoute) {
        isPopped = true;
      };

    await tester.pumpWidget(MaterialApp(
      routes: routes,
      navigatorObservers: <NavigatorObserver>[observer1],
    ));
    expect(isPushed, isFalse);
    expect(isPopped, isFalse);

    await tester.pumpWidget(MaterialApp(
      routes: routes,
      navigatorObservers: <NavigatorObserver>[observer1, observer2],
    ));
    await tester.tap(find.text('/'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(isPushed, isTrue);
    expect(isPopped, isFalse);

    isPushed = false;
    isPopped = false;

    await tester.pumpWidget(MaterialApp(
      routes: routes,
      navigatorObservers: <NavigatorObserver>[observer1],
    ));
    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(isPushed, isFalse);
    expect(isPopped, isFalse);
  });

  testWidgets('replaceNamed replaces', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/' : (BuildContext context) => OnTapPage(id: '/', onTap: () { Navigator.pushReplacementNamed(context, '/A'); }),
      '/A': (BuildContext context) => OnTapPage(id: 'A', onTap: () { Navigator.pushReplacementNamed(context, '/B'); }),
      '/B': (BuildContext context) => const OnTapPage(id: 'B'),
    };

    await tester.pumpWidget(MaterialApp(routes: routes));
    await tester.tap(find.text('/')); // replaceNamed('/A')
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('/'), findsNothing);
    expect(find.text('A'), findsOneWidget);

    await tester.tap(find.text('A')); // replaceNamed('/B')
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('/'), findsNothing);
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('pushReplacement sets secondaryAnimation after transition, with history change during transition', (WidgetTester tester) async {
    final Map<String, SlideInOutPageRoute<dynamic>> routes = <String, SlideInOutPageRoute<dynamic>>{};
    final Map<String, WidgetBuilder> builders = <String, WidgetBuilder>{
      '/' : (BuildContext context) => OnTapPage(
        id: '/',
        onTap: () {
          Navigator.pushNamed(context, '/A');
        }
      ),
      '/A': (BuildContext context) => OnTapPage(
        id: 'A',
        onTap: () {
          Navigator.pushNamed(context, '/B');
        }
      ),
      '/B': (BuildContext context) => OnTapPage(
        id: 'B',
        onTap: () {
          Navigator.pushReplacementNamed(context, '/C');
        },
      ),
      '/C': (BuildContext context) => OnTapPage(
        id: 'C',
        onTap: () {
          Navigator.removeRoute(context, routes['/']);
        },
      ),
    };
    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (RouteSettings settings) {
        final SlideInOutPageRoute<dynamic> ret = SlideInOutPageRoute<dynamic>(bodyBuilder: builders[settings.name], settings: settings);
        routes[settings.name] = ret;
        return ret;
      }
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('/'));
    await tester.pumpAndSettle();
    final double a2 = routes['/A'].secondaryAnimation.value;
    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(routes['/A'].secondaryAnimation.value, greaterThan(a2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('B'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(routes['/A'].secondaryAnimation.value, equals(1.0));
    await tester.tap(find.text('C'));
    await tester.pumpAndSettle();
    expect(find.text('C'), isOnstage);
    expect(routes['/A'].secondaryAnimation.value, equals(routes['/C'].animation.value));
    final AnimationController controller = routes['/C'].controller;
    controller.value = 1 - controller.value;
    expect(routes['/A'].secondaryAnimation.value, equals(routes['/C'].animation.value));
  });

  testWidgets('new route removed from navigator history druing pushReplacement transition', (WidgetTester tester) async {
    final Map<String, SlideInOutPageRoute<dynamic>> routes = <String, SlideInOutPageRoute<dynamic>>{};
    final Map<String, WidgetBuilder> builders = <String, WidgetBuilder>{
      '/' : (BuildContext context) => OnTapPage(
        id: '/',
        onTap: () {
          Navigator.pushNamed(context, '/A');
        }
      ),
      '/A': (BuildContext context) => OnTapPage(
        id: 'A',
        onTap: () {
          Navigator.pushReplacementNamed(context, '/B');
        }
      ),
      '/B': (BuildContext context) => OnTapPage(
        id: 'B',
        onTap: () {
          Navigator.removeRoute(context, routes['/B']);
        },
      ),
    };
    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (RouteSettings settings) {
        final SlideInOutPageRoute<dynamic> ret = SlideInOutPageRoute<dynamic>(bodyBuilder: builders[settings.name], settings: settings);
        routes[settings.name] = ret;
        return ret;
      }
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('/'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('A'), isOnstage);
    expect(find.text('B'), isOnstage);
    await tester.tap(find.text('B'));
    await tester.pumpAndSettle();
    expect(find.text('/'), isOnstage);
    expect(find.text('B'), findsNothing);
    expect(find.text('A'), findsNothing);
    expect(routes['/'].secondaryAnimation.value, equals(0.0));
    expect(routes['/'].animation.value, equals(1.0));
  });

  testWidgets('pushReplacement triggers secondaryAnimation', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/' : (BuildContext context) => OnTapPage(
        id: '/',
        onTap: () {
          Navigator.pushReplacementNamed(context, '/A');
        }
      ),
      '/A': (BuildContext context) => OnTapPage(
        id: 'A',
        onTap: () {
          Navigator.pushReplacementNamed(context, '/B');
        }
      ),
      '/B': (BuildContext context) => const OnTapPage(id: 'B'),
    };

    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (RouteSettings settings) {
        return SlideInOutPageRoute<dynamic>(bodyBuilder: routes[settings.name]);
      }
    ));
    await tester.pumpAndSettle();
    final Offset rootOffsetOriginal = tester.getTopLeft(find.text('/'));
    await tester.tap(find.text('/'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('/'), isOnstage);
    expect(find.text('A'), isOnstage);
    expect(find.text('B'), findsNothing);
    final Offset rootOffset = tester.getTopLeft(find.text('/'));
    expect(rootOffset.dx, lessThan(rootOffsetOriginal.dx));

    Offset aOffsetOriginal = tester.getTopLeft(find.text('A'));
    await tester.pumpAndSettle();
    Offset aOffset = tester.getTopLeft(find.text('A'));
    expect(aOffset.dx, lessThan(aOffsetOriginal.dx));

    aOffsetOriginal = aOffset;
    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('/'), findsNothing);
    expect(find.text('A'), isOnstage);
    expect(find.text('B'), isOnstage);
    aOffset = tester.getTopLeft(find.text('A'));
    expect(aOffset.dx, lessThan(aOffsetOriginal.dx));
  });

  testWidgets('pushAndRemoveUntil triggers secondaryAnimation', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/' : (BuildContext context) => OnTapPage(
        id: '/',
        onTap: () {
          Navigator.pushNamed(context, '/A');
        }
      ),
      '/A': (BuildContext context) => OnTapPage(
        id: 'A',
        onTap: () {
          Navigator.pushNamedAndRemoveUntil(context, '/B', (Route<dynamic> route) => false);
        }
      ),
      '/B': (BuildContext context) => const OnTapPage(id: 'B'),
    };

    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (RouteSettings settings) {
        return SlideInOutPageRoute<dynamic>(bodyBuilder: routes[settings.name]);
      }
    ));
    await tester.pumpAndSettle();
    final Offset rootOffsetOriginal = tester.getTopLeft(find.text('/'));
    await tester.tap(find.text('/'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('/'), isOnstage);
    expect(find.text('A'), isOnstage);
    expect(find.text('B'), findsNothing);
    final Offset rootOffset = tester.getTopLeft(find.text('/'));
    expect(rootOffset.dx, lessThan(rootOffsetOriginal.dx));

    Offset aOffsetOriginal = tester.getTopLeft(find.text('A'));
    await tester.pumpAndSettle();
    Offset aOffset = tester.getTopLeft(find.text('A'));
    expect(aOffset.dx, lessThan(aOffsetOriginal.dx));

    aOffsetOriginal = aOffset;
    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('/'), findsNothing);
    expect(find.text('A'), isOnstage);
    expect(find.text('B'), isOnstage);
    aOffset = tester.getTopLeft(find.text('A'));
    expect(aOffset.dx, lessThan(aOffsetOriginal.dx));

    await tester.pumpAndSettle();
    expect(find.text('/'), findsNothing);
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), isOnstage);
  });

  testWidgets('replaceNamed returned value', (WidgetTester tester) async {
    Future<String> value;

    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/' : (BuildContext context) => OnTapPage(id: '/', onTap: () { Navigator.pushNamed(context, '/A'); }),
      '/A': (BuildContext context) => OnTapPage(id: 'A', onTap: () { value = Navigator.pushReplacementNamed(context, '/B', result: 'B'); }),
      '/B': (BuildContext context) => OnTapPage(id: 'B', onTap: () { Navigator.pop(context, 'B'); }),
    };

    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (RouteSettings settings) {
        return PageRouteBuilder<String>(
          settings: settings,
          pageBuilder: (BuildContext context, Animation<double> _, Animation<double> __) {
            return routes[settings.name](context);
          },
        );
      }
    ));

    expect(find.text('/'), findsOneWidget);
    expect(find.text('A', skipOffstage: false), findsNothing);
    expect(find.text('B', skipOffstage: false), findsNothing);

    await tester.tap(find.text('/')); // pushNamed('/A'), stack becomes /, /A
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('/'), findsNothing);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);

    await tester.tap(find.text('A')); // replaceNamed('/B'), stack becomes /, /B
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('/'), findsNothing);
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsOneWidget);

    await tester.tap(find.text('B')); // pop, stack becomes /
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('/'), findsOneWidget);
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsNothing);

    final String replaceNamedValue = await value; // replaceNamed result was 'B'
    expect(replaceNamedValue, 'B');
  });

  testWidgets('removeRoute', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> pageBuilders = <String, WidgetBuilder>{
      '/' : (BuildContext context) => OnTapPage(id: '/', onTap: () { Navigator.pushNamed(context, '/A'); }),
      '/A': (BuildContext context) => OnTapPage(id: 'A', onTap: () { Navigator.pushNamed(context, '/B'); }),
      '/B': (BuildContext context) => const OnTapPage(id: 'B'),
    };
    final Map<String, Route<String>> routes = <String, Route<String>>{};

    Route<String> removedRoute;
    Route<String> previousRoute;

    final TestObserver observer = TestObserver()
      ..onRemoved = (Route<dynamic> route, Route<dynamic> previous) {
        removedRoute = route as Route<String>;
        previousRoute = previous as Route<String>;
      };

    await tester.pumpWidget(MaterialApp(
      navigatorObservers: <NavigatorObserver>[observer],
      onGenerateRoute: (RouteSettings settings) {
        routes[settings.name] = PageRouteBuilder<String>(
          settings: settings,
          pageBuilder: (BuildContext context, Animation<double> _, Animation<double> __) {
            return pageBuilders[settings.name](context);
          },
        );
        return routes[settings.name];
      },
    ));

    expect(find.text('/'), findsOneWidget);
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsNothing);

    await tester.tap(find.text('/')); // pushNamed('/A'), stack becomes /, /A
    await tester.pumpAndSettle();
    expect(find.text('/'), findsNothing);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);

    await tester.tap(find.text('A')); // pushNamed('/B'), stack becomes /, /A, /B
    await tester.pumpAndSettle();
    expect(find.text('/'), findsNothing);
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsOneWidget);

    // Verify that the navigator's stack is ordered as expected.
    expect(routes['/'].isActive, true);
    expect(routes['/A'].isActive, true);
    expect(routes['/B'].isActive, true);
    expect(routes['/'].isFirst, true);
    expect(routes['/B'].isCurrent, true);

    final NavigatorState navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.removeRoute(routes['/B']); // stack becomes /, /A
    await tester.pump();
    expect(find.text('/'), findsNothing);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);

    // Verify that the navigator's stack no longer includes /B
    expect(routes['/'].isActive, true);
    expect(routes['/A'].isActive, true);
    expect(routes['/B'].isActive, false);
    expect(routes['/'].isFirst, true);
    expect(routes['/A'].isCurrent, true);

    expect(removedRoute, routes['/B']);
    expect(previousRoute, routes['/A']);

    navigator.removeRoute(routes['/A']); // stack becomes just /
    await tester.pump();
    expect(find.text('/'), findsOneWidget);
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsNothing);

    // Verify that the navigator's stack no longer includes /A
    expect(routes['/'].isActive, true);
    expect(routes['/A'].isActive, false);
    expect(routes['/B'].isActive, false);
    expect(routes['/'].isFirst, true);
    expect(routes['/'].isCurrent, true);
    expect(removedRoute, routes['/A']);
    expect(previousRoute, routes['/']);
  });

  testWidgets('remove a route whose value is awaited', (WidgetTester tester) async {
    Future<String> pageValue;
    final Map<String, WidgetBuilder> pageBuilders = <String, WidgetBuilder>{
      '/':  (BuildContext context) => OnTapPage(id: '/', onTap: () { pageValue = Navigator.pushNamed(context, '/A'); }),
      '/A': (BuildContext context) => OnTapPage(id: 'A', onTap: () { Navigator.pop(context, 'A'); }),
    };
    final Map<String, Route<String>> routes = <String, Route<String>>{};

    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (RouteSettings settings) {
        routes[settings.name] = PageRouteBuilder<String>(
          settings: settings,
          pageBuilder: (BuildContext context, Animation<double> _, Animation<double> __) {
            return pageBuilders[settings.name](context);
          },
        );
        return routes[settings.name];
      }
    ));

    await tester.tap(find.text('/')); // pushNamed('/A'), stack becomes /, /A
    await tester.pumpAndSettle();
    pageValue.then((String value) { assert(false); });

    final NavigatorState navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.removeRoute(routes['/A']); // stack becomes /, pageValue will not complete
  });

  testWidgets('replacing route can be observed', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
    final List<String> log = <String>[];
    final TestObserver observer = TestObserver()
      ..onPushed = (Route<dynamic> route, Route<dynamic> previousRoute) {
        log.add('pushed ${route.settings.name} (previous is ${previousRoute == null ? "<none>" : previousRoute.settings.name})');
      }
      ..onPopped = (Route<dynamic> route, Route<dynamic> previousRoute) {
        log.add('popped ${route.settings.name} (previous is ${previousRoute == null ? "<none>" : previousRoute.settings.name})');
      }
      ..onRemoved = (Route<dynamic> route, Route<dynamic> previousRoute) {
        log.add('removed ${route.settings.name} (previous is ${previousRoute == null ? "<none>" : previousRoute.settings.name})');
      }
      ..onReplaced = (Route<dynamic> newRoute, Route<dynamic> oldRoute) {
        log.add('replaced ${oldRoute.settings.name} with ${newRoute.settings.name}');
      };
    Route<void> routeB;
    await tester.pumpWidget(MaterialApp(
      navigatorKey: key,
      navigatorObservers: <NavigatorObserver>[observer],
      home: FlatButton(
        child: const Text('A'),
        onPressed: () {
          key.currentState.push<void>(routeB = MaterialPageRoute<void>(
            settings: const RouteSettings(name: 'B'),
            builder: (BuildContext context) {
              return FlatButton(
                child: const Text('B'),
                onPressed: () {
                  key.currentState.push<void>(MaterialPageRoute<int>(
                    settings: const RouteSettings(name: 'C'),
                    builder: (BuildContext context) {
                      return FlatButton(
                        child: const Text('C'),
                        onPressed: () {
                          key.currentState.replace(
                            oldRoute: routeB,
                            newRoute: MaterialPageRoute<int>(
                              settings: const RouteSettings(name: 'D'),
                              builder: (BuildContext context) {
                                return const Text('D');
                              },
                            ),
                          );
                        },
                      );
                    },
                  ));
                },
              );
            },
          ));
        },
      ),
    ));
    expect(log, <String>['pushed / (previous is <none>)']);
    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(log, <String>['pushed / (previous is <none>)', 'pushed B (previous is /)']);
    await tester.tap(find.text('B'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(log, <String>['pushed / (previous is <none>)', 'pushed B (previous is /)', 'pushed C (previous is B)']);
    await tester.tap(find.text('C'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(log, <String>['pushed / (previous is <none>)', 'pushed B (previous is /)', 'pushed C (previous is B)', 'replaced B with D']);
  });

  testWidgets('didStartUserGesture observable', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/' : (BuildContext context) => OnTapPage(id: '/', onTap: () { Navigator.pushNamed(context, '/A'); }),
      '/A': (BuildContext context) => OnTapPage(id: 'A', onTap: () { Navigator.pop(context); }),
    };

    Route<dynamic> observedRoute;
    Route<dynamic> observedPreviousRoute;
    final TestObserver observer = TestObserver()
      ..onStartUserGesture = (Route<dynamic> route, Route<dynamic> previousRoute) {
        observedRoute = route;
        observedPreviousRoute = previousRoute;
      };

    await tester.pumpWidget(MaterialApp(
      routes: routes,
      navigatorObservers: <NavigatorObserver>[observer],
    ));

    await tester.tap(find.text('/'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('/'), findsNothing);
    expect(find.text('A'), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator)).didStartUserGesture();

    expect(observedRoute.settings.name, '/A');
    expect(observedPreviousRoute.settings.name, '/');
  });

  testWidgets('ModalRoute.of sets up a route to rebuild if its state changes', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
    final List<String> log = <String>[];
    Route<void> routeB;
    await tester.pumpWidget(MaterialApp(
      navigatorKey: key,
      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      home: FlatButton(
        child: const Text('A'),
        onPressed: () {
          key.currentState.push<void>(routeB = MaterialPageRoute<void>(
            settings: const RouteSettings(name: 'B'),
            builder: (BuildContext context) {
              log.add('building B');
              return FlatButton(
                child: const Text('B'),
                onPressed: () {
                  key.currentState.push<void>(MaterialPageRoute<int>(
                    settings: const RouteSettings(name: 'C'),
                    builder: (BuildContext context) {
                      log.add('building C');
                      log.add('found ${ModalRoute.of(context).settings.name}');
                      return FlatButton(
                        child: const Text('C'),
                        onPressed: () {
                          key.currentState.replace(
                            oldRoute: routeB,
                            newRoute: MaterialPageRoute<int>(
                              settings: const RouteSettings(name: 'D'),
                              builder: (BuildContext context) {
                                log.add('building D');
                                return const Text('D');
                              },
                            ),
                          );
                        },
                      );
                    },
                  ));
                },
              );
            },
          ));
        },
      ),
    ));
    expect(log, <String>[]);
    await tester.tap(find.text('A'));
    await tester.pumpAndSettle(const Duration(milliseconds: 10));
    expect(log, <String>['building B']);
    await tester.tap(find.text('B'));
    await tester.pumpAndSettle(const Duration(milliseconds: 10));
    expect(log, <String>['building B', 'building C', 'found C']);
    await tester.tap(find.text('C'));
    await tester.pumpAndSettle(const Duration(milliseconds: 10));
    expect(log, <String>['building B', 'building C', 'found C', 'building D']);
    key.currentState.pop<void>();
    await tester.pumpAndSettle(const Duration(milliseconds: 10));
    expect(log, <String>['building B', 'building C', 'found C', 'building D', 'building C', 'found C']);
  });

  testWidgets('route semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => OnTapPage(id: '1', onTap: () { Navigator.pushNamed(context, '/A'); }),
      '/A': (BuildContext context) => OnTapPage(id: '2', onTap: () { Navigator.pushNamed(context, '/B/C'); }),
      '/B/C': (BuildContext context) => const OnTapPage(id: '3'),
    };

    await tester.pumpWidget(MaterialApp(routes: routes));

    expect(semantics, includesNodeWith(
      flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
    ));
    expect(semantics, includesNodeWith(
      label: 'Page 1',
      flags: <SemanticsFlag>[
        SemanticsFlag.namesRoute,
        SemanticsFlag.isHeader,
      ],
    ));

    await tester.tap(find.text('1')); // pushNamed('/A')
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(semantics, includesNodeWith(
      flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
    ));
    expect(semantics, includesNodeWith(
      label: 'Page 2',
      flags: <SemanticsFlag>[
        SemanticsFlag.namesRoute,
        SemanticsFlag.isHeader,
      ],
    ));

    await tester.tap(find.text('2')); // pushNamed('/B/C')
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(semantics, includesNodeWith(
      flags: <SemanticsFlag>[
        SemanticsFlag.scopesRoute,
      ],
    ));
    expect(semantics, includesNodeWith(
      label: 'Page 3',
      flags: <SemanticsFlag>[
        SemanticsFlag.namesRoute,
        SemanticsFlag.isHeader,
      ],
    ));


    semantics.dispose();
  });

  testWidgets('arguments for named routes on Navigator', (WidgetTester tester) async {
    GlobalKey currentRouteKey;
    final List<Object> arguments = <Object>[];

    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (RouteSettings settings) {
        arguments.add(settings.arguments);
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) => Center(key: currentRouteKey = GlobalKey(), child: Text(settings.name)),
        );
      },
    ));

    expect(find.text('/'), findsOneWidget);
    expect(arguments.single, isNull);
    arguments.clear();

    Navigator.pushNamed(
      currentRouteKey.currentContext,
      '/A',
      arguments: 'pushNamed',
    );
    await tester.pumpAndSettle();

    expect(find.text('/'), findsNothing);
    expect(find.text('/A'), findsOneWidget);
    expect(arguments.single, 'pushNamed');
    arguments.clear();

    Navigator.popAndPushNamed(
      currentRouteKey.currentContext,
      '/B',
      arguments: 'popAndPushNamed',
    );
    await tester.pumpAndSettle();

    expect(find.text('/'), findsNothing);
    expect(find.text('/A'), findsNothing);
    expect(find.text('/B'), findsOneWidget);
    expect(arguments.single, 'popAndPushNamed');
    arguments.clear();

    Navigator.pushNamedAndRemoveUntil(
      currentRouteKey.currentContext,
      '/C',
      (Route<dynamic> route) => route.isFirst,
      arguments: 'pushNamedAndRemoveUntil',
    );
    await tester.pumpAndSettle();

    expect(find.text('/'), findsNothing);
    expect(find.text('/A'), findsNothing);
    expect(find.text('/B'), findsNothing);
    expect(find.text('/C'), findsOneWidget);
    expect(arguments.single, 'pushNamedAndRemoveUntil');
    arguments.clear();

    Navigator.pushReplacementNamed(
      currentRouteKey.currentContext,
      '/D',
      arguments: 'pushReplacementNamed',
    );
    await tester.pumpAndSettle();

    expect(find.text('/'), findsNothing);
    expect(find.text('/A'), findsNothing);
    expect(find.text('/B'), findsNothing);
    expect(find.text('/C'), findsNothing);
    expect(find.text('/D'), findsOneWidget);
    expect(arguments.single, 'pushReplacementNamed');
    arguments.clear();
  });

  testWidgets('arguments for named routes on NavigatorState', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
    final List<Object> arguments = <Object>[];

    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigatorKey,
      onGenerateRoute: (RouteSettings settings) {
        arguments.add(settings.arguments);
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) => Center(child: Text(settings.name)),
        );
      },
    ));

    expect(find.text('/'), findsOneWidget);
    expect(arguments.single, isNull);
    arguments.clear();

    navigatorKey.currentState.pushNamed(
      '/A',
      arguments:'pushNamed',
    );
    await tester.pumpAndSettle();

    expect(find.text('/'), findsNothing);
    expect(find.text('/A'), findsOneWidget);
    expect(arguments.single, 'pushNamed');
    arguments.clear();

    navigatorKey.currentState.popAndPushNamed(
      '/B',
      arguments: 'popAndPushNamed',
    );
    await tester.pumpAndSettle();

    expect(find.text('/'), findsNothing);
    expect(find.text('/A'), findsNothing);
    expect(find.text('/B'), findsOneWidget);
    expect(arguments.single, 'popAndPushNamed');
    arguments.clear();

    navigatorKey.currentState.pushNamedAndRemoveUntil(
      '/C',
      (Route<dynamic> route) => route.isFirst,
      arguments: 'pushNamedAndRemoveUntil',
    );
    await tester.pumpAndSettle();

    expect(find.text('/'), findsNothing);
    expect(find.text('/A'), findsNothing);
    expect(find.text('/B'), findsNothing);
    expect(find.text('/C'), findsOneWidget);
    expect(arguments.single, 'pushNamedAndRemoveUntil');
    arguments.clear();

    navigatorKey.currentState.pushReplacementNamed(
      '/D',
      arguments: 'pushReplacementNamed',
    );
    await tester.pumpAndSettle();

    expect(find.text('/'), findsNothing);
    expect(find.text('/A'), findsNothing);
    expect(find.text('/B'), findsNothing);
    expect(find.text('/C'), findsNothing);
    expect(find.text('/D'), findsOneWidget);
    expect(arguments.single, 'pushReplacementNamed');
    arguments.clear();
  });

  testWidgets('Initial route can have gaps', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> keyNav = GlobalKey<NavigatorState>();
    const Key keyRoot = Key('Root');
    const Key keyA = Key('A');
    const Key keyABC = Key('ABC');

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: keyNav,
        initialRoute: '/A/B/C',
        routes: <String, WidgetBuilder>{
          '/': (BuildContext context) => Container(key: keyRoot),
          '/A': (BuildContext context) => Container(key: keyA),
          // The route /A/B is intentionally left out.
          '/A/B/C': (BuildContext context) => Container(key: keyABC),
        },
      ),
    );

    // The initial route /A/B/C should've been pushed successfully.
    expect(find.byKey(keyRoot, skipOffstage: false), findsOneWidget);
    expect(find.byKey(keyA, skipOffstage: false), findsOneWidget);
    expect(find.byKey(keyABC), findsOneWidget);

    keyNav.currentState.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(keyRoot, skipOffstage: false), findsOneWidget);
    expect(find.byKey(keyA), findsOneWidget);
    expect(find.byKey(keyABC, skipOffstage: false), findsNothing);
  });

  testWidgets('The full initial route has to be matched', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> keyNav = GlobalKey<NavigatorState>();
    const Key keyRoot = Key('Root');
    const Key keyA = Key('A');
    const Key keyAB = Key('AB');

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: keyNav,
        initialRoute: '/A/B/C',
        routes: <String, WidgetBuilder>{
          '/': (BuildContext context) => Container(key: keyRoot),
          '/A': (BuildContext context) => Container(key: keyA),
          '/A/B': (BuildContext context) => Container(key: keyAB),
          // The route /A/B/C is intentionally left out.
        },
      ),
    );

    final dynamic exception = tester.takeException();
    expect(exception, isA<String>());
    expect(exception.startsWith('Could not navigate to initial route.'), isTrue);

    // Only the root route should've been pushed.
    expect(find.byKey(keyRoot), findsOneWidget);
    expect(find.byKey(keyA), findsNothing);
    expect(find.byKey(keyAB), findsNothing);
  });

  testWidgets("Popping immediately after pushing doesn't crash", (WidgetTester tester) async {
    // Added this test to protect against regression of https://github.com/flutter/flutter/issues/45539
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/' : (BuildContext context) => OnTapPage(id: '/', onTap: () {
        Navigator.pushNamed(context, '/A');
        Navigator.of(context).pop();
      }),
      '/A': (BuildContext context) => OnTapPage(id: 'A', onTap: () { Navigator.pop(context); }),
    };
    bool isPushed = false;
    bool isPopped = false;
    final TestObserver observer = TestObserver()
      ..onPushed = (Route<dynamic> route, Route<dynamic> previousRoute) {
        // Pushes the initial route.
        expect(route is PageRoute && route.settings.name == '/', isTrue);
        expect(previousRoute, isNull);
        isPushed = true;
      }
      ..onPopped = (Route<dynamic> route, Route<dynamic> previousRoute) {
        isPopped = true;
      };

    await tester.pumpWidget(MaterialApp(
      routes: routes,
      navigatorObservers: <NavigatorObserver>[observer],
    ));
    expect(find.text('/'), findsOneWidget);
    expect(find.text('A'), findsNothing);
    expect(isPushed, isTrue);
    expect(isPopped, isFalse);

    isPushed = false;
    isPopped = false;
    observer.onPushed = (Route<dynamic> route, Route<dynamic> previousRoute) {
      expect(route is PageRoute && route.settings.name == '/A', isTrue);
      expect(previousRoute is PageRoute && previousRoute.settings.name == '/', isTrue);
      isPushed = true;
    };

    await tester.tap(find.text('/'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('/'), findsOneWidget);
    expect(find.text('A'), findsNothing);
    expect(isPushed, isTrue);
    expect(isPopped, isTrue);
  });

  group('error control test', () {
    testWidgets('onUnknownRoute null and onGenerateRoute returns null', (WidgetTester tester) async {
      final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(Navigator(
        key: navigatorKey,
        onGenerateRoute: (_) => null,
      ));
      final dynamic exception = tester.takeException();
      expect(exception, isNotNull);
      expect(exception, isFlutterError);
      final FlutterError error = exception as FlutterError;
      expect(error, isNotNull);
      expect(error.diagnostics.last, isA<DiagnosticsProperty<NavigatorState>>());
      expect(
        error.toStringDeep(),
        equalsIgnoringHashCodes(
          'FlutterError\n'
          '   Navigator.onGenerateRoute returned null when requested to build\n'
          '   route "/".\n'
          '   The onGenerateRoute callback must never return null, unless an\n'
          '   onUnknownRoute callback is provided as well.\n'
          '   The Navigator was:\n'
          '     NavigatorState#4d6bf(lifecycle state: created)\n',
        ),
      );
    });

    testWidgets('onUnknownRoute null and onGenerateRoute returns null', (WidgetTester tester) async {
      final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(Navigator(
        key: navigatorKey,
        onGenerateRoute: (_) => null,
        onUnknownRoute: (_) => null,
      ));
      final dynamic exception = tester.takeException();
      expect(exception, isNotNull);
      expect(exception, isFlutterError);
      final FlutterError error = exception as FlutterError;
      expect(error, isNotNull);
      expect(error.diagnostics.last, isA<DiagnosticsProperty<NavigatorState>>());
      expect(
        error.toStringDeep(),
        equalsIgnoringHashCodes(
          'FlutterError\n'
          '   Navigator.onUnknownRoute returned null when requested to build\n'
          '   route "/".\n'
          '   The onUnknownRoute callback must never return null.\n'
          '   The Navigator was:\n'
          '     NavigatorState#38036(lifecycle state: created)\n',
        ),
      );
    });
  });

  testWidgets('OverlayEntry of topmost initial route is marked as opaque', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/38038.

    final Key root = UniqueKey();
    final Key intermediate = UniqueKey();
    final GlobalKey topmost = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/A/B',
        routes: <String, WidgetBuilder>{
          '/': (BuildContext context) => Container(key: root),
          '/A': (BuildContext context) => Container(key: intermediate),
          '/A/B': (BuildContext context) => Container(key: topmost),
        },
      ),
    );

    expect(ModalRoute.of(topmost.currentContext).overlayEntries.first.opaque, isTrue);

    expect(find.byKey(root), findsNothing);  // hidden by opaque Route
    expect(find.byKey(intermediate), findsNothing);  // hidden by opaque Route
    expect(find.byKey(topmost), findsOneWidget);
  });

  testWidgets('OverlayEntry of topmost route is set to opaque after Push', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/38038.

    final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        initialRoute: '/',
        onGenerateRoute: (RouteSettings settings) {
          return NoAnimationPageRoute(
            pageBuilder: (_) => Container(key: ValueKey<String>(settings.name)),
          );
        },
      ),
    );
    expect(find.byKey(const ValueKey<String>('/')), findsOneWidget);

    navigator.currentState.pushNamed('/A');
    await tester.pump();

    final BuildContext topMostContext = tester.element(find.byKey(const ValueKey<String>('/A')));
    expect(ModalRoute.of(topMostContext).overlayEntries.first.opaque, isTrue);

    expect(find.byKey(const ValueKey<String>('/')), findsNothing);  // hidden by /A
    expect(find.byKey(const ValueKey<String>('/A')), findsOneWidget);
  });

  testWidgets('OverlayEntry of topmost route is set to opaque after Replace', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/38038.

    final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        initialRoute: '/A/B',
        onGenerateRoute: (RouteSettings settings) {
          return NoAnimationPageRoute(
            pageBuilder: (_) => Container(key: ValueKey<String>(settings.name)),
          );
        },
      ),
    );
    expect(find.byKey(const ValueKey<String>('/')), findsNothing);
    expect(find.byKey(const ValueKey<String>('/A')), findsNothing);
    expect(find.byKey(const ValueKey<String>('/A/B')), findsOneWidget);

    final Route<dynamic> oldRoute = ModalRoute.of(
      tester.element(find.byKey(const ValueKey<String>('/A'), skipOffstage: false)),
    );
    final Route<void> newRoute = NoAnimationPageRoute(
      pageBuilder: (_) => Container(key: const ValueKey<String>('/C')),
    );

    navigator.currentState.replace<void>(oldRoute: oldRoute, newRoute: newRoute);
    await tester.pump();

    expect(newRoute.overlayEntries.first.opaque, isTrue);

    expect(find.byKey(const ValueKey<String>('/')), findsNothing);  // hidden by /A/B
    expect(find.byKey(const ValueKey<String>('/A')), findsNothing);  // replaced
    expect(find.byKey(const ValueKey<String>('/C')), findsNothing);  // hidden by /A/B
    expect(find.byKey(const ValueKey<String>('/A/B')), findsOneWidget);

    navigator.currentState.pop();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('/')), findsNothing);  // hidden by /C
    expect(find.byKey(const ValueKey<String>('/A')), findsNothing);  // replaced
    expect(find.byKey(const ValueKey<String>('/A/B')), findsNothing); // popped
    expect(find.byKey(const ValueKey<String>('/C')), findsOneWidget);
  });

  testWidgets('Pushing opaque Route does not rebuild routes below', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/45797.

    final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
    final Key bottomRoute = UniqueKey();
    final Key topRoute = UniqueKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            },
          ),
        ),
        navigatorKey: navigator,
        routes: <String, WidgetBuilder>{
          '/' : (BuildContext context) => StatefulTestWidget(key: bottomRoute),
          '/a': (BuildContext context) => StatefulTestWidget(key: topRoute),
        },
      ),
    );
    expect(tester.state<StatefulTestState>(find.byKey(bottomRoute)).rebuildCount, 1);

    navigator.currentState.pushNamed('/a');
    await tester.pumpAndSettle();

    // Bottom route is offstage and did not rebuild.
    expect(find.byKey(bottomRoute), findsNothing);
    expect(tester.state<StatefulTestState>(find.byKey(bottomRoute, skipOffstage: false)).rebuildCount, 1);

    expect(tester.state<StatefulTestState>(find.byKey(topRoute)).rebuildCount, 1);
  });

  testWidgets('initial routes below opaque route are offstage', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> g = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Navigator(
          key: g,
          initialRoute: '/a/b',
          onGenerateRoute: (RouteSettings s) {
            return MaterialPageRoute<void>(
              builder: (BuildContext c) {
                return Text('+${s.name}+');
              },
              settings: s,
            );
          },
        ),
      ),
    );

    expect(find.text('+/+'), findsNothing);
    expect(find.text('+/+', skipOffstage: false), findsOneWidget);
    expect(find.text('+/a+'), findsNothing);
    expect(find.text('+/a+', skipOffstage: false), findsOneWidget);
    expect(find.text('+/a/b+'), findsOneWidget);

    g.currentState.pop();
    await tester.pumpAndSettle();

    expect(find.text('+/+'), findsNothing);
    expect(find.text('+/+', skipOffstage: false), findsOneWidget);
    expect(find.text('+/a+'), findsOneWidget);
    expect(find.text('+/a/b+'), findsNothing);

    g.currentState.pop();
    await tester.pumpAndSettle();

    expect(find.text('+/+'), findsOneWidget);
    expect(find.text('+/a+'), findsNothing);
    expect(find.text('+/a/b+'), findsNothing);
  });

  testWidgets('Can provide custom onGenerateInitialRoutes', (WidgetTester tester) async {
    bool onGenerateInitialRoutesCalled = false;
    final GlobalKey<NavigatorState> g = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Navigator(
          key: g,
          initialRoute: 'Hello World',
          onGenerateInitialRoutes: (NavigatorState navigator, String initialRoute) {
            onGenerateInitialRoutesCalled = true;
            final List<Route<void>> result = <Route<void>>[];
            for (final String route in initialRoute.split(' ')) {
              result.add(MaterialPageRoute<void>(builder: (BuildContext context) {
                return Text(route);
              }));
            }
            return result;
          },
        ),
      ),
    );

    expect(onGenerateInitialRoutesCalled, true);
    expect(find.text('Hello'), findsNothing);
    expect(find.text('World'), findsOneWidget);

    g.currentState.pop();
    await tester.pumpAndSettle();

    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('World'), findsNothing);
  });

  testWidgets('pushAndRemove until animates the push', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/25080.

    const Duration kFourTenthsOfTheTransitionDuration = Duration(milliseconds: 120);
    final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
    final Map<String, MaterialPageRoute<dynamic>> routeNameToContext = <String, MaterialPageRoute<dynamic>>{};

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Navigator(
          key: navigator,
          initialRoute: 'root',
          onGenerateRoute: (RouteSettings settings) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (BuildContext context) {
                routeNameToContext[settings.name] = ModalRoute.of(context) as MaterialPageRoute<dynamic>;
                return Text('Route: ${settings.name}');
              },
            );
          },
        ),
      ),
    );

    expect(find.text('Route: root'), findsOneWidget);

    navigator.currentState.pushNamed('1');
    await tester.pumpAndSettle();

    expect(find.text('Route: 1'), findsOneWidget);

    navigator.currentState.pushNamed('2');
    await tester.pumpAndSettle();

    expect(find.text('Route: 2'), findsOneWidget);

    navigator.currentState.pushNamed('3');
    await tester.pumpAndSettle();

    expect(find.text('Route: 3'), findsOneWidget);
    expect(find.text('Route: 2', skipOffstage: false), findsOneWidget);
    expect(find.text('Route: 1', skipOffstage: false), findsOneWidget);
    expect(find.text('Route: root', skipOffstage: false), findsOneWidget);

    navigator.currentState.pushNamedAndRemoveUntil('4', (Route<dynamic> route) => route.isFirst);
    await tester.pump();

    expect(find.text('Route: 3'), findsOneWidget);
    expect(find.text('Route: 4'), findsOneWidget);
    final Animation<double> route4Entry = routeNameToContext['4'].animation;
    expect(route4Entry.value, 0.0); // Entry animation has not started.

    await tester.pump(kFourTenthsOfTheTransitionDuration);
    expect(find.text('Route: 3'), findsOneWidget);
    expect(find.text('Route: 4'), findsOneWidget);
    expect(route4Entry.value, 0.4);

    await tester.pump(kFourTenthsOfTheTransitionDuration);
    expect(find.text('Route: 3'), findsOneWidget);
    expect(find.text('Route: 4'), findsOneWidget);
    expect(route4Entry.value, 0.8);
    expect(find.text('Route: 2', skipOffstage: false), findsOneWidget);
    expect(find.text('Route: 1', skipOffstage: false), findsOneWidget);
    expect(find.text('Route: root', skipOffstage: false), findsOneWidget);

    // When we hit 1.0 all but root and current have been removed.
    await tester.pump(kFourTenthsOfTheTransitionDuration);
    expect(find.text('Route: 3', skipOffstage: false), findsNothing);
    expect(find.text('Route: 4'), findsOneWidget);
    expect(route4Entry.value, 1.0);
    expect(find.text('Route: 2', skipOffstage: false), findsNothing);
    expect(find.text('Route: 1', skipOffstage: false), findsNothing);
    expect(find.text('Route: root', skipOffstage: false), findsOneWidget);

    navigator.currentState.pop();
    await tester.pumpAndSettle();

    expect(find.text('Route: root'), findsOneWidget);
    expect(find.text('Route: 4', skipOffstage: false), findsNothing);
  });

  testWidgets('Wrapping TickerMode can turn off ticking in routes', (WidgetTester tester) async {
    int tickCount = 0;
    Widget widgetUnderTest({bool enabled}) {
      return TickerMode(
        enabled: enabled,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Navigator(
            initialRoute: 'root',
            onGenerateRoute: (RouteSettings settings) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (BuildContext context) {
                  return _TickingWidget(
                    onTick: () {
                      tickCount++;
                    },
                  );
                },
              );
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(widgetUnderTest(enabled: false));
    expect(tickCount, 0);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(tickCount, 0);

    await tester.pumpWidget(widgetUnderTest(enabled: true));
    expect(tickCount, 0);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(tickCount, 4);
  });

  group('Page api', (){
    Widget buildNavigator(
      List<Page<dynamic>> pages,
      PopPageCallback onPopPage, [
        GlobalKey<NavigatorState> key,
        TransitionDelegate<dynamic> transitionDelegate
      ]) {
      return MediaQuery(
        data: MediaQueryData.fromWindow(WidgetsBinding.instance.window),
        child: Localizations(
          locale: const Locale('en', 'US'),
          delegates: const <LocalizationsDelegate<dynamic>>[
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate
          ],
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Navigator(
              key: key,
              pages: pages,
              onPopPage: onPopPage,
              transitionDelegate: transitionDelegate ?? const DefaultTransitionDelegate<dynamic>(),
            ),
          ),
        ),
      );
    }

    testWidgets('can initialize with pages list', (WidgetTester tester) async {
      final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
      final List<TestPage> myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('1'), name:'initial'),
        const TestPage(key: ValueKey<String>('2'), name:'second'),
        const TestPage(key: ValueKey<String>('3'), name:'third'),
      ];

      bool onPopPage(Route<dynamic> route, dynamic result) {
        myPages.removeWhere((Page<dynamic> page) => route.settings == page);
        return route.didPop(result);
      }

      await tester.pumpWidget(buildNavigator(myPages, onPopPage, navigator));
      expect(find.text('third'), findsOneWidget);
      expect(find.text('second'), findsNothing);
      expect(find.text('initial'), findsNothing);

      navigator.currentState.pop();
      await tester.pumpAndSettle();
      expect(find.text('third'), findsNothing);
      expect(find.text('second'), findsOneWidget);
      expect(find.text('initial'), findsNothing);

      navigator.currentState.pop();
      await tester.pumpAndSettle();
      expect(find.text('third'), findsNothing);
      expect(find.text('second'), findsNothing);
      expect(find.text('initial'), findsOneWidget);
    });

    testWidgets('can push and pop pages using page api', (WidgetTester tester) async {
      Animation<double> secondaryAnimationOfRouteOne;
      Animation<double> primaryAnimationOfRouteOne;
      Animation<double> secondaryAnimationOfRouteTwo;
      Animation<double> primaryAnimationOfRouteTwo;
      Animation<double> secondaryAnimationOfRouteThree;
      Animation<double> primaryAnimationOfRouteThree;
      final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
      List<Page<dynamic>> myPages = <Page<dynamic>>[
        CustomBuilderPage<void>(
          key: const ValueKey<String>('1'),
          name:'initial',
          routeBuilder: (BuildContext context, RouteSettings settings) {
            return PageRouteBuilder<void>(
              settings: settings,
              pageBuilder: (_, Animation<double> animation, Animation<double> secondaryAnimation) {
                secondaryAnimationOfRouteOne = secondaryAnimation;
                primaryAnimationOfRouteOne = animation;
                return const Text('initial');
              },
            );
          },
        ),
      ];

      bool onPopPage(Route<dynamic> route, dynamic result) {
        myPages.removeWhere((Page<dynamic> page) => route.settings == page);
        return route.didPop(result);
      }

      await tester.pumpWidget(buildNavigator(myPages, onPopPage, navigator));
      expect(find.text('initial'), findsOneWidget);

      myPages = <Page<dynamic>>[
        CustomBuilderPage<void>(
          key: const ValueKey<String>('1'),
          name:'initial',
          routeBuilder: (BuildContext context, RouteSettings settings) {
            return PageRouteBuilder<void>(
              settings: settings,
              pageBuilder: (_, Animation<double> animation, Animation<double> secondaryAnimation) {
                secondaryAnimationOfRouteOne = secondaryAnimation;
                primaryAnimationOfRouteOne = animation;
                return const Text('initial');
              },
            );
          },
        ),
        CustomBuilderPage<void>(
          key: const ValueKey<String>('2'),
          name:'second',
          routeBuilder: (BuildContext context, RouteSettings settings) {
            return PageRouteBuilder<void>(
              settings: settings,
              pageBuilder: (_, Animation<double> animation, Animation<double> secondaryAnimation) {
                secondaryAnimationOfRouteTwo = secondaryAnimation;
                primaryAnimationOfRouteTwo = animation;
                return const Text('second');
              },
            );
          },
        ),
        CustomBuilderPage<void>(
          key: const ValueKey<String>('3'),
          name:'third',
          routeBuilder: (BuildContext context, RouteSettings settings) {
            return PageRouteBuilder<void>(
              settings: settings,
              pageBuilder: (_, Animation<double> animation, Animation<double> secondaryAnimation) {
                secondaryAnimationOfRouteThree = secondaryAnimation;
                primaryAnimationOfRouteThree = animation;
                return const Text('third');
              },
            );
          },
        )
      ];

      await tester.pumpWidget(buildNavigator(myPages, onPopPage, navigator));
      // The third page is transitioning, and the secondary animation of first
      // page should chain with the third page. The animation of second page
      // won't start until the third page finishes transition.
      expect(secondaryAnimationOfRouteOne.value, primaryAnimationOfRouteThree.value);
      expect(primaryAnimationOfRouteOne.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteTwo.status, AnimationStatus.dismissed);
      expect(primaryAnimationOfRouteTwo.status, AnimationStatus.dismissed);
      expect(secondaryAnimationOfRouteThree.status, AnimationStatus.dismissed);
      expect(primaryAnimationOfRouteThree.status, AnimationStatus.forward);

      await tester.pump(const Duration(milliseconds: 30));
      expect(secondaryAnimationOfRouteOne.value, primaryAnimationOfRouteThree.value);
      expect(primaryAnimationOfRouteOne.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteTwo.status, AnimationStatus.dismissed);
      expect(primaryAnimationOfRouteTwo.status, AnimationStatus.dismissed);
      expect(secondaryAnimationOfRouteThree.status, AnimationStatus.dismissed);
      expect(primaryAnimationOfRouteThree.value, 0.1);
      await tester.pumpAndSettle();
      // After transition finishes, the routes' animations are correctly chained.
      expect(secondaryAnimationOfRouteOne.value, primaryAnimationOfRouteTwo.value);
      expect(primaryAnimationOfRouteOne.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteTwo.value, primaryAnimationOfRouteThree.value);
      expect(primaryAnimationOfRouteTwo.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteThree.status, AnimationStatus.dismissed);
      expect(primaryAnimationOfRouteThree.status, AnimationStatus.completed);
      expect(find.text('third'), findsOneWidget);
      expect(find.text('second'), findsNothing);
      expect(find.text('initial'), findsNothing);
      // Starts pops the pages using page api and verify the animations chain
      // correctly.

      myPages = <Page<dynamic>>[
        CustomBuilderPage<void>(
          key: const ValueKey<String>('1'),
          name:'initial',
          routeBuilder: (BuildContext context, RouteSettings settings) {
            return PageRouteBuilder<void>(
              settings: settings,
              pageBuilder: (_, Animation<double> animation, Animation<double> secondaryAnimation) {
                secondaryAnimationOfRouteOne = secondaryAnimation;
                primaryAnimationOfRouteOne = animation;
                return const Text('initial');
              },
            );
          },
        ),
        CustomBuilderPage<void>(
          key: const ValueKey<String>('2'),
          name:'second',
          routeBuilder: (BuildContext context, RouteSettings settings) {
            return PageRouteBuilder<void>(
              settings: settings,
              pageBuilder: (_, Animation<double> animation, Animation<double> secondaryAnimation) {
                secondaryAnimationOfRouteTwo = secondaryAnimation;
                primaryAnimationOfRouteTwo = animation;
                return const Text('second');
              },
            );
          },
        ),
      ];

      await tester.pumpWidget(buildNavigator(myPages, onPopPage, navigator));
      await tester.pump(const Duration(milliseconds: 30));
      expect(secondaryAnimationOfRouteOne.value, primaryAnimationOfRouteTwo.value);
      expect(primaryAnimationOfRouteOne.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteTwo.value, primaryAnimationOfRouteThree.value);
      expect(primaryAnimationOfRouteTwo.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteThree.status, AnimationStatus.dismissed);
      expect(primaryAnimationOfRouteThree.value, 0.9);
      await tester.pumpAndSettle();
      expect(secondaryAnimationOfRouteOne.value, primaryAnimationOfRouteTwo.value);
      expect(primaryAnimationOfRouteOne.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteTwo.value, primaryAnimationOfRouteThree.value);
      expect(primaryAnimationOfRouteTwo.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteThree.status, AnimationStatus.dismissed);
      expect(primaryAnimationOfRouteThree.status, AnimationStatus.dismissed);
    });

    testWidgets('can modify routes history and secondary animation still works', (WidgetTester tester) async {
      final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
      Animation<double> secondaryAnimationOfRouteOne;
      Animation<double> primaryAnimationOfRouteOne;
      Animation<double> secondaryAnimationOfRouteTwo;
      Animation<double> primaryAnimationOfRouteTwo;
      Animation<double> secondaryAnimationOfRouteThree;
      Animation<double> primaryAnimationOfRouteThree;
      List<Page<dynamic>> myPages = <CustomBuilderPage<void>>[
        CustomBuilderPage<void>(
          key: const ValueKey<String>('1'),
          name:'initial',
          routeBuilder: (BuildContext context, RouteSettings settings) {
            return PageRouteBuilder<void>(
              settings: settings,
              pageBuilder: (_, Animation<double> animation, Animation<double> secondaryAnimation) {
                secondaryAnimationOfRouteOne = secondaryAnimation;
                primaryAnimationOfRouteOne = animation;
                return const Text('initial');
              },
            );
          },
        ),
        CustomBuilderPage<void>(
          key: const ValueKey<String>('2'),
          name:'second',
          routeBuilder: (BuildContext context, RouteSettings settings) {
            return PageRouteBuilder<void>(
              settings: settings,
              pageBuilder: (_, Animation<double> animation, Animation<double> secondaryAnimation) {
                secondaryAnimationOfRouteTwo = secondaryAnimation;
                primaryAnimationOfRouteTwo = animation;
                return const Text('second');
              },
            );
          },
        ),
        CustomBuilderPage<void>(
          key: const ValueKey<String>('3'),
          name:'third',
          routeBuilder: (BuildContext context, RouteSettings settings) {
            return PageRouteBuilder<void>(
              settings: settings,
              pageBuilder: (_, Animation<double> animation, Animation<double> secondaryAnimation) {
                secondaryAnimationOfRouteThree = secondaryAnimation;
                primaryAnimationOfRouteThree = animation;
                return const Text('third');
              },
            );
          },
        ),
      ];
      bool onPopPage(Route<dynamic> route, dynamic result) {
        myPages.removeWhere((Page<dynamic> page) => route.settings == page);
        return route.didPop(result);
      }
      await tester.pumpWidget(buildNavigator(myPages, onPopPage, navigator));
      expect(find.text('third'), findsOneWidget);
      expect(find.text('second'), findsNothing);
      expect(find.text('initial'), findsNothing);
      expect(secondaryAnimationOfRouteOne.value, primaryAnimationOfRouteTwo.value);
      expect(primaryAnimationOfRouteOne.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteTwo.value, primaryAnimationOfRouteThree.value);
      expect(primaryAnimationOfRouteTwo.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteThree.status, AnimationStatus.dismissed);
      expect(primaryAnimationOfRouteThree.status, AnimationStatus.completed);

      myPages = myPages.reversed.toList();
      await tester.pumpWidget(buildNavigator(myPages, onPopPage, navigator));
      // Reversed routes are still chained up correctly.
      expect(secondaryAnimationOfRouteThree.value, primaryAnimationOfRouteTwo.value);
      expect(primaryAnimationOfRouteThree.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteTwo.value, primaryAnimationOfRouteOne.value);
      expect(primaryAnimationOfRouteTwo.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteOne.status, AnimationStatus.dismissed);
      expect(primaryAnimationOfRouteOne.status, AnimationStatus.completed);

      navigator.currentState.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      expect(secondaryAnimationOfRouteThree.value, primaryAnimationOfRouteTwo.value);
      expect(primaryAnimationOfRouteThree.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteTwo.value, primaryAnimationOfRouteOne.value);
      expect(primaryAnimationOfRouteTwo.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteOne.status, AnimationStatus.dismissed);
      expect(primaryAnimationOfRouteOne.value, 0.9);
      await tester.pumpAndSettle();
      expect(secondaryAnimationOfRouteThree.value, primaryAnimationOfRouteTwo.value);
      expect(primaryAnimationOfRouteThree.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteTwo.value, primaryAnimationOfRouteOne.value);
      expect(primaryAnimationOfRouteTwo.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteOne.status, AnimationStatus.dismissed);
      expect(primaryAnimationOfRouteOne.status, AnimationStatus.dismissed);

      navigator.currentState.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      expect(secondaryAnimationOfRouteThree.value, primaryAnimationOfRouteTwo.value);
      expect(primaryAnimationOfRouteThree.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteTwo.value, primaryAnimationOfRouteOne.value);
      expect(primaryAnimationOfRouteTwo.value, 0.9);
      expect(secondaryAnimationOfRouteOne.status, AnimationStatus.dismissed);
      expect(primaryAnimationOfRouteOne.status, AnimationStatus.dismissed);
      await tester.pumpAndSettle();
      expect(secondaryAnimationOfRouteThree.value, primaryAnimationOfRouteTwo.value);
      expect(primaryAnimationOfRouteThree.status, AnimationStatus.completed);
      expect(secondaryAnimationOfRouteTwo.value, primaryAnimationOfRouteOne.value);
      expect(primaryAnimationOfRouteTwo.status, AnimationStatus.dismissed);
      expect(secondaryAnimationOfRouteOne.status, AnimationStatus.dismissed);
      expect(primaryAnimationOfRouteOne.status, AnimationStatus.dismissed);
    });

    testWidgets('can work with pageless route', (WidgetTester tester) async {
      final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
      List<TestPage> myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('1'), name:'initial'),
        const TestPage(key: ValueKey<String>('2'), name:'second'),
      ];

      bool onPopPage(Route<dynamic> route, dynamic result) {
        myPages.removeWhere((Page<dynamic> page) => route.settings == page);
        return route.didPop(result);
      }

      await tester.pumpWidget(buildNavigator(myPages, onPopPage, navigator));
      expect(find.text('second'), findsOneWidget);
      expect(find.text('initial'), findsNothing);
      // Pushes two pageless routes to second page route
      navigator.currentState.push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const Text('second-pageless1'),
          settings: null,
        )
      );
      navigator.currentState.push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const Text('second-pageless2'),
          settings: null,
        )
      );
      await tester.pumpAndSettle();
      // Now the history should look like
      // [initial, second, second-pageless1, second-pageless2].
      expect(find.text('initial'), findsNothing);
      expect(find.text('second'), findsNothing);
      expect(find.text('second-pageless1'), findsNothing);
      expect(find.text('second-pageless2'), findsOneWidget);

      myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('1'), name:'initial'),
        const TestPage(key: ValueKey<String>('2'), name:'second'),
        const TestPage(key: ValueKey<String>('3'), name:'third'),
      ];
      await tester.pumpWidget(buildNavigator(myPages, onPopPage, navigator));
      await tester.pumpAndSettle();
      expect(find.text('initial'), findsNothing);
      expect(find.text('second'), findsNothing);
      expect(find.text('second-pageless1'), findsNothing);
      expect(find.text('second-pageless2'), findsNothing);
      expect(find.text('third'), findsOneWidget);

      // Pushes one pageless routes to third page route
      navigator.currentState.push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const Text('third-pageless1'),
          settings: null,
        )
      );
      await tester.pumpAndSettle();
      // Now the history should look like
      // [initial, second, second-pageless1, second-pageless2, third, third-pageless1].
      expect(find.text('initial'), findsNothing);
      expect(find.text('second'), findsNothing);
      expect(find.text('second-pageless1'), findsNothing);
      expect(find.text('second-pageless2'), findsNothing);
      expect(find.text('third'), findsNothing);
      expect(find.text('third-pageless1'), findsOneWidget);

      myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('1'), name:'initial'),
        const TestPage(key: ValueKey<String>('3'), name:'third'),
        const TestPage(key: ValueKey<String>('2'), name:'second'),
      ];
      await tester.pumpWidget(buildNavigator(myPages, onPopPage, navigator));
      // Swaps the order without any adding or removing should not trigger any
      // transition. The routes should update without a pumpAndSettle
      // Now the history should look like
      // [initial, third, third-pageless1, second, second-pageless1, second-pageless2].
      expect(find.text('initial'), findsNothing);
      expect(find.text('third'), findsNothing);
      expect(find.text('third-pageless1'), findsNothing);
      expect(find.text('second'), findsNothing);
      expect(find.text('second-pageless1'), findsNothing);
      expect(find.text('second-pageless2'), findsOneWidget);
      // Pops the route one by one to make sure the order is correct.
      navigator.currentState.pop();
      await tester.pumpAndSettle();
      expect(find.text('initial'), findsNothing);
      expect(find.text('third'), findsNothing);
      expect(find.text('third-pageless1'), findsNothing);
      expect(find.text('second'), findsNothing);
      expect(find.text('second-pageless1'), findsOneWidget);
      expect(find.text('second-pageless2'), findsNothing);
      expect(myPages.length, 3);
      navigator.currentState.pop();
      await tester.pumpAndSettle();
      expect(find.text('initial'), findsNothing);
      expect(find.text('third'), findsNothing);
      expect(find.text('third-pageless1'), findsNothing);
      expect(find.text('second'), findsOneWidget);
      expect(find.text('second-pageless1'), findsNothing);
      expect(find.text('second-pageless2'), findsNothing);
      expect(myPages.length, 3);
      navigator.currentState.pop();
      await tester.pumpAndSettle();
      expect(find.text('initial'), findsNothing);
      expect(find.text('third'), findsNothing);
      expect(find.text('third-pageless1'), findsOneWidget);
      expect(find.text('second'), findsNothing);
      expect(find.text('second-pageless1'), findsNothing);
      expect(find.text('second-pageless2'), findsNothing);
      expect(myPages.length, 2);
      navigator.currentState.pop();
      await tester.pumpAndSettle();
      expect(find.text('initial'), findsNothing);
      expect(find.text('third'), findsOneWidget);
      expect(find.text('third-pageless1'), findsNothing);
      expect(find.text('second'), findsNothing);
      expect(find.text('second-pageless1'), findsNothing);
      expect(find.text('second-pageless2'), findsNothing);
      expect(myPages.length, 2);
      navigator.currentState.pop();
      await tester.pumpAndSettle();
      expect(find.text('initial'), findsOneWidget);
      expect(find.text('third'), findsNothing);
      expect(find.text('third-pageless1'), findsNothing);
      expect(find.text('second'), findsNothing);
      expect(find.text('second-pageless1'), findsNothing);
      expect(find.text('second-pageless2'), findsNothing);
      expect(myPages.length, 1);
    });

    testWidgets('complex case 1', (WidgetTester tester) async {
      final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
      List<TestPage> myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('1'), name: 'initial'),
      ];
      bool onPopPage(Route<dynamic> route, dynamic result) {
        myPages.removeWhere((Page<dynamic> page) => route.settings == page);
        return route.didPop(result);
      }

      // Add initial page route with one pageless route.
      await tester.pumpWidget(buildNavigator(myPages, onPopPage, navigator));
      bool initialPageless1Completed = false;
      navigator.currentState.push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const Text('initial-pageless1'),
          settings: null,
        )
      ).then((_) => initialPageless1Completed = true);
      await tester.pumpAndSettle();

      // Pushes second page route with two pageless routes.
      myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('1'), name: 'initial'),
        const TestPage(key: ValueKey<String>('2'), name: 'second'),
      ];
      await tester.pumpWidget(buildNavigator(myPages, onPopPage, navigator));
      await tester.pumpAndSettle();
      bool secondPageless1Completed = false;
      navigator.currentState.push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const Text('second-pageless1'),
          settings: null,
        )
      ).then((_) => secondPageless1Completed = true);
      await tester.pumpAndSettle();
      bool secondPageless2Completed = false;
      navigator.currentState.push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const Text('second-pageless2'),
          settings: null,
        )
      ).then((_) => secondPageless2Completed = true);
      await tester.pumpAndSettle();

      // Pushes third page route with one pageless route.
      myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('1'), name: 'initial'),
        const TestPage(key: ValueKey<String>('2'), name: 'second'),
        const TestPage(key: ValueKey<String>('3'), name: 'third'),
      ];
      await tester.pumpWidget(buildNavigator(myPages, onPopPage, navigator));
      await tester.pumpAndSettle();
      bool thirdPageless1Completed = false;
      navigator.currentState.push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const Text('third-pageless1'),
          settings: null,
        )
      ).then((_) => thirdPageless1Completed = true);
      await tester.pumpAndSettle();

      // Nothing has been popped.
      expect(initialPageless1Completed, false);
      expect(secondPageless1Completed, false);
      expect(secondPageless2Completed, false);
      expect(thirdPageless1Completed, false);

      // Switches order and removes the initial page route.
      myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('3'), name: 'third'),
        const TestPage(key: ValueKey<String>('2'), name: 'second'),
      ];
      await tester.pumpWidget(buildNavigator(myPages, onPopPage, navigator));
      // The pageless route of initial page route should be completed.
      expect(initialPageless1Completed, true);
      expect(secondPageless1Completed, false);
      expect(secondPageless2Completed, false);
      expect(thirdPageless1Completed, false);

      myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('3'), name: 'third'),
      ];
      await tester.pumpWidget(buildNavigator(myPages, onPopPage, navigator));
      await tester.pumpAndSettle();
      expect(secondPageless1Completed, true);
      expect(secondPageless2Completed, true);
      expect(thirdPageless1Completed, false);

      myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('4'), name: 'forth'),
      ];
      await tester.pumpWidget(buildNavigator(myPages, onPopPage, navigator));
      expect(thirdPageless1Completed, true);
      await tester.pumpAndSettle();
      expect(find.text('forth'), findsOneWidget);
    });

    testWidgets('complex case 1 - with always remove transition delegate', (WidgetTester tester) async {
      final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
      final AlwaysRemoveTransitionDelegate transitionDelegate = AlwaysRemoveTransitionDelegate();
      List<TestPage> myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('1'), name: 'initial'),
      ];
      bool onPopPage(Route<dynamic> route, dynamic result) {
        myPages.removeWhere((Page<dynamic> page) => route.settings == page);
        return route.didPop(result);
      }

      // Add initial page route with one pageless route.
      await tester.pumpWidget(buildNavigator(myPages, onPopPage, navigator, transitionDelegate));
      bool initialPageless1Completed = false;
      navigator.currentState.push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const Text('initial-pageless1'),
          settings: null,
        )
      ).then((_) => initialPageless1Completed = true);
      await tester.pumpAndSettle();

      // Pushes second page route with two pageless routes.
      myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('1'), name: 'initial'),
        const TestPage(key: ValueKey<String>('2'), name: 'second'),
      ];
      await tester.pumpWidget(buildNavigator(myPages, onPopPage, navigator, transitionDelegate));
      bool secondPageless1Completed = false;
      navigator.currentState.push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const Text('second-pageless1'),
          settings: null,
        )
      ).then((_) => secondPageless1Completed = true);
      await tester.pumpAndSettle();
      bool secondPageless2Completed = false;
      navigator.currentState.push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const Text('second-pageless2'),
          settings: null,
        )
      ).then((_) => secondPageless2Completed = true);
      await tester.pumpAndSettle();

      // Pushes third page route with one pageless route.
      myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('1'), name: 'initial'),
        const TestPage(key: ValueKey<String>('2'), name: 'second'),
        const TestPage(key: ValueKey<String>('3'), name: 'third'),
      ];
      await tester.pumpWidget(buildNavigator(myPages, onPopPage, navigator, transitionDelegate));
      bool thirdPageless1Completed = false;
      navigator.currentState.push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const Text('third-pageless1'),
          settings: null,
        )
      ).then((_) => thirdPageless1Completed = true);
      await tester.pumpAndSettle();

      // Nothing has been popped.
      expect(initialPageless1Completed, false);
      expect(secondPageless1Completed, false);
      expect(secondPageless2Completed, false);
      expect(thirdPageless1Completed, false);

      // Switches order and removes the initial page route.
      myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('3'), name: 'third'),
        const TestPage(key: ValueKey<String>('2'), name: 'second'),
      ];
      await tester.pumpWidget(buildNavigator(myPages, onPopPage, navigator, transitionDelegate));
      // The pageless route of initial page route should be removed without complete.
      expect(initialPageless1Completed, false);
      expect(secondPageless1Completed, false);
      expect(secondPageless2Completed, false);
      expect(thirdPageless1Completed, false);

      myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('3'), name: 'third'),
      ];
      await tester.pumpWidget(buildNavigator(myPages, onPopPage, navigator, transitionDelegate));
      await tester.pumpAndSettle();
      expect(initialPageless1Completed, false);
      expect(secondPageless1Completed, false);
      expect(secondPageless2Completed, false);
      expect(thirdPageless1Completed, false);

      myPages = <TestPage>[
        const TestPage(key: ValueKey<String>('4'), name: 'forth'),
      ];
      await tester.pumpWidget(buildNavigator(myPages, onPopPage, navigator, transitionDelegate));
      await tester.pump();
      expect(initialPageless1Completed, false);
      expect(secondPageless1Completed, false);
      expect(secondPageless2Completed, false);
      expect(thirdPageless1Completed, false);
      expect(find.text('forth'), findsOneWidget);
    });

  });
}

class _TickingWidget extends StatefulWidget {
  const _TickingWidget({this.onTick});

  final VoidCallback onTick;

  @override
  State<_TickingWidget> createState() => _TickingWidgetState();
}

class _TickingWidgetState extends State<_TickingWidget> with SingleTickerProviderStateMixin {
  Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((Duration _) {
      widget.onTick();
    })..start();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

class AlwaysRemoveTransitionDelegate extends TransitionDelegate<void> {
  @override
  Iterable<RouteTransitionRecord> resolve({
    List<RouteTransitionRecord> newPageRouteHistory,
    Map<RouteTransitionRecord, RouteTransitionRecord> locationToExitingPageRoute,
    Map<RouteTransitionRecord, List<RouteTransitionRecord>> pageRouteToPagelessRoutes,
  }) {
    final List<RouteTransitionRecord> results = <RouteTransitionRecord>[];
    void handleExitingRoute(RouteTransitionRecord location) {
      if (!locationToExitingPageRoute.containsKey(location))
        return;

      final RouteTransitionRecord exitingPageRoute = locationToExitingPageRoute[location];
      final bool hasPagelessRoute = pageRouteToPagelessRoutes.containsKey(exitingPageRoute);

      exitingPageRoute.markForRemove();
      results.add(exitingPageRoute);

      if (hasPagelessRoute) {
        final List<RouteTransitionRecord> pagelessRoutes = pageRouteToPagelessRoutes[exitingPageRoute];
        for (final RouteTransitionRecord pagelessRoute in pagelessRoutes) {
          pagelessRoute.markForRemove();
        }
      }
      handleExitingRoute(exitingPageRoute);
    }
    handleExitingRoute(null);

    for (final RouteTransitionRecord pageRoute in newPageRouteHistory) {
      if (pageRoute.isEntering) {
        pageRoute.markForAdd();
      }
      results.add(pageRoute);
      handleExitingRoute(pageRoute);

    }
    return results;
  }
}

class TestPage extends Page<void> {
  const TestPage({
    LocalKey key,
    String name,
    Object arguments,
  }) : super(key: key, name: name, arguments: arguments);

  @override
  Route<void> createRoute(BuildContext context) {
    return MaterialPageRoute<void>(
      builder: (BuildContext context) => Text(name),
      settings: this,
    );
  }
}

class NoAnimationPageRoute extends PageRouteBuilder<void> {
  NoAnimationPageRoute({WidgetBuilder pageBuilder})
      : super(pageBuilder: (BuildContext context, __, ___) {
          return pageBuilder(context);
        });

  @override
  AnimationController createAnimationController() {
    return super.createAnimationController()..value = 1.0;
  }
}

class StatefulTestWidget extends StatefulWidget {
  const StatefulTestWidget({Key key}) : super(key: key);

  @override
  State<StatefulTestWidget> createState() => StatefulTestState();
}

class StatefulTestState extends State<StatefulTestWidget> {
  int rebuildCount = 0;

  @override
  Widget build(BuildContext context) {
    rebuildCount += 1;
    return Container();
  }
}
