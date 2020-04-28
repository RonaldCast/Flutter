// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

final BoxDecoration kBoxDecorationA = BoxDecoration(border: nonconst(null));
final BoxDecoration kBoxDecorationB = BoxDecoration(border: nonconst(null));
final BoxDecoration kBoxDecorationC = BoxDecoration(border: nonconst(null));

class TestWidget extends StatelessWidget {
  const TestWidget({
    Key key,
    this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

class TestOrientedBox extends SingleChildRenderObjectWidget {
  const TestOrientedBox({ Key key, Widget child }) : super(key: key, child: child);

  Decoration _getDecoration(BuildContext context) {
    final Orientation orientation = MediaQuery.of(context).orientation;
    switch (orientation) {
      case Orientation.landscape:
        return const BoxDecoration(color: Color(0xFF00FF00));
      case Orientation.portrait:
        return const BoxDecoration(color: Color(0xFF0000FF));
    }
    assert(orientation != null);
    return null;
  }

  @override
  RenderDecoratedBox createRenderObject(BuildContext context) => RenderDecoratedBox(decoration: _getDecoration(context));

  @override
  void updateRenderObject(BuildContext context, RenderDecoratedBox renderObject) {
    renderObject.decoration = _getDecoration(context);
  }
}

void main() {
  testWidgets('RenderObjectWidget smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(DecoratedBox(decoration: kBoxDecorationA));
    SingleChildRenderObjectElement element =
        tester.element(find.byElementType(SingleChildRenderObjectElement));
    expect(element, isNotNull);
    expect(element.renderObject, isA<RenderDecoratedBox>());
    RenderDecoratedBox renderObject = element.renderObject as RenderDecoratedBox;
    expect(renderObject.decoration, equals(kBoxDecorationA));
    expect(renderObject.position, equals(DecorationPosition.background));

    await tester.pumpWidget(DecoratedBox(decoration: kBoxDecorationB));
    element = tester.element(find.byElementType(SingleChildRenderObjectElement));
    expect(element, isNotNull);
    expect(element.renderObject, isA<RenderDecoratedBox>());
    renderObject = element.renderObject as RenderDecoratedBox;
    expect(renderObject.decoration, equals(kBoxDecorationB));
    expect(renderObject.position, equals(DecorationPosition.background));
  });

  testWidgets('RenderObjectWidget can add and remove children', (WidgetTester tester) async {

    void checkFullTree() {
      final SingleChildRenderObjectElement element =
          tester.firstElement(find.byElementType(SingleChildRenderObjectElement));
      expect(element, isNotNull);
      expect(element.renderObject, isA<RenderDecoratedBox>());
      final RenderDecoratedBox renderObject = element.renderObject as RenderDecoratedBox;
      expect(renderObject.decoration, equals(kBoxDecorationA));
      expect(renderObject.position, equals(DecorationPosition.background));
      expect(renderObject.child, isNotNull);
      expect(renderObject.child, isA<RenderDecoratedBox>());
      final RenderDecoratedBox child = renderObject.child as RenderDecoratedBox;
      expect(child.decoration, equals(kBoxDecorationB));
      expect(child.position, equals(DecorationPosition.background));
      expect(child.child, isNull);
    }

    void childBareTree() {
      final SingleChildRenderObjectElement element =
          tester.element(find.byElementType(SingleChildRenderObjectElement));
      expect(element, isNotNull);
      expect(element.renderObject, isA<RenderDecoratedBox>());
      final RenderDecoratedBox renderObject = element.renderObject as RenderDecoratedBox;
      expect(renderObject.decoration, equals(kBoxDecorationA));
      expect(renderObject.position, equals(DecorationPosition.background));
      expect(renderObject.child, isNull);
    }

    await tester.pumpWidget(DecoratedBox(
      decoration: kBoxDecorationA,
      child: DecoratedBox(
        decoration: kBoxDecorationB
      ),
    ));

    checkFullTree();

    await tester.pumpWidget(DecoratedBox(
      decoration: kBoxDecorationA,
      child: TestWidget(
        child: DecoratedBox(
          decoration: kBoxDecorationB
        ),
      ),
    ));

    checkFullTree();

    await tester.pumpWidget(DecoratedBox(
      decoration: kBoxDecorationA,
      child: DecoratedBox(
        decoration: kBoxDecorationB
      ),
    ));

    checkFullTree();

    await tester.pumpWidget(DecoratedBox(
      decoration: kBoxDecorationA
    ));

    childBareTree();

    await tester.pumpWidget(DecoratedBox(
      decoration: kBoxDecorationA,
      child: TestWidget(
        child: TestWidget(
          child: DecoratedBox(
            decoration: kBoxDecorationB
          ),
        ),
      ),
    ));

    checkFullTree();

    await tester.pumpWidget(DecoratedBox(
      decoration: kBoxDecorationA
    ));

    childBareTree();
  });

  testWidgets('Detached render tree is intact', (WidgetTester tester) async {

    await tester.pumpWidget(DecoratedBox(
      decoration: kBoxDecorationA,
      child: DecoratedBox(
        decoration: kBoxDecorationB,
        child: DecoratedBox(
          decoration: kBoxDecorationC
        ),
      ),
    ));

    SingleChildRenderObjectElement element =
        tester.firstElement(find.byElementType(SingleChildRenderObjectElement));
    expect(element.renderObject, isA<RenderDecoratedBox>());
    final RenderDecoratedBox parent = element.renderObject as RenderDecoratedBox;
    expect(parent.child, isA<RenderDecoratedBox>());
    final RenderDecoratedBox child = parent.child as RenderDecoratedBox;
    expect(child.decoration, equals(kBoxDecorationB));
    expect(child.child, isA<RenderDecoratedBox>());
    final RenderDecoratedBox grandChild = child.child as RenderDecoratedBox;
    expect(grandChild.decoration, equals(kBoxDecorationC));
    expect(grandChild.child, isNull);

    await tester.pumpWidget(DecoratedBox(
      decoration: kBoxDecorationA
    ));

    element =
        tester.element(find.byElementType(SingleChildRenderObjectElement));
    expect(element.renderObject, isA<RenderDecoratedBox>());
    expect(element.renderObject, equals(parent));
    expect(parent.child, isNull);

    expect(child.parent, isNull);
    expect(child.decoration, equals(kBoxDecorationB));
    expect(child.child, equals(grandChild));
    expect(grandChild.parent, equals(child));
    expect(grandChild.decoration, equals(kBoxDecorationC));
    expect(grandChild.child, isNull);
  });

  testWidgets('Can watch inherited widgets', (WidgetTester tester) async {
    final Key boxKey = UniqueKey();
    final TestOrientedBox box = TestOrientedBox(key: boxKey);

    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(size: Size(400.0, 300.0)),
      child: box,
    ));

    final RenderDecoratedBox renderBox = tester.renderObject(find.byKey(boxKey));
    BoxDecoration decoration = renderBox.decoration as BoxDecoration;
    expect(decoration.color, equals(const Color(0xFF00FF00)));

    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(size: Size(300.0, 400.0)),
      child: box,
    ));

    decoration = renderBox.decoration as BoxDecoration;
    expect(decoration.color, equals(const Color(0xFF0000FF)));
  });
}
