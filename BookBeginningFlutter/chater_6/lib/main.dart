import 'package:flutter/material.dart';
import './widgets/ContanerWithBoxDecoration.dart';
import './widgets/PopupMenuButtonWidget.dart';
import './screens/image_screen.dart';
import './screens/decoration_screen.dart';
import './screens/form_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter'),
      routes: {
        ImageScreen.routeName: (ctx) => ImageScreen(),
        DecorationScreen.routeName: (ctx) => DecorationScreen(),
        FormScreen.routeName: (ctx) => FormScreen()
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            size: 35.0,
          ),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.note),
            onPressed: () {},
          )
        ],
        title: Text(widget.title),
        //TODO flexibleSpace
        flexibleSpace: SafeArea(
          child: Icon(
            (Icons.phone),
            size: 55.0,
            color: Colors.white70,
          ),
        ),
        bottom: PopupMenuButtonWidget(),

        //   //TODO: bottom
        // bottom: PreferredSize(
        //   child: Container(
        //     color: Colors.white70,
        //     width: double.infinity,
        //     height: 75.0,
        //     child: Center(child: Text("Bottom")),
        //   ),
        //   preferredSize: Size.fromHeight(75.0),
        // ),
      ),

      //TODO: creacion de un bottom menu notch
      bottomNavigationBar: BottomAppBar(
        notchMargin: 1.8,
        shape: CircularNotchedRectangle(),
        color: Colors.blue,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(
                Icons.image,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pushNamed(ImageScreen.routeName);
              },
            ),
            IconButton(
              icon: Icon(Icons.brush, color: Colors.white),
              onPressed: () {
                Navigator.of(context).pushNamed(DecorationScreen.routeName);
              },
            ),
            IconButton(
              icon: Icon(Icons.note, color: Colors.white),
              onPressed: () {
                Navigator.of(context).pushNamed(FormScreen.routeName);
              },
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 15.0),
            )
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                const ContanerWithBoxDecoration(),
                SizedBox(
                  height: 20.0,
                ),
                Column(
                  children: [
                    Text("Column1"),
                    Divider(),
                    Text("Column1"),
                    Divider(),
                    Text("Column1"),
                  ],
                ),
                SizedBox(
                  height: 20.0,
                ),
                Text("Buttons"),
                ButtonBar(
                  alignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FlatButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.ac_unit),
                        label: Text("hola")),
                    IconButton(
                        icon: Icon(
                      Icons.pages,
                    )),
                    FlatButton(
                      child: Text("ss"),
                    ),
                    RaisedButton(
                      child: Text("Flag"),
                      onPressed: () {},
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
