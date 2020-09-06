import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
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
  List<Widget> _listsWidget = List<Widget>();
  int _currentIndex = 0;
  Widget _currentWidget;

  _changeWidget(index) {
    setState(() {
      _currentIndex = index;
      _currentWidget = _listsWidget[index];
    });
  }

  @override
  void initState() {
    super.initState();
    _listsWidget..add(GridCount())..add(GridExtent())..add(GridBuilder());
    _currentWidget = GridCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => _changeWidget(index),
          items: [
            BottomNavigationBarItem(
                icon: Icon(Icons.view_column), title: Text("Count")),
            BottomNavigationBarItem(
                icon: Icon(Icons.access_time), title: Text("Extent")),
            BottomNavigationBarItem(
                icon: Icon(Icons.accessible_forward), title: Text("Build")),
          ]),
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _currentWidget,
    );
  }
}

class GridCount extends StatelessWidget {
  const GridCount({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      padding: EdgeInsets.all(8.0),
      children: List.generate(7000, (index) {
        return Card(
          margin: EdgeInsets.all(8.0),
          child: InkWell(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.access_alarm),
              Divider(),
              Text(
                'Index $index',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.0,
                ),
              )
            ]),
          ),
        );
      }),
    );
  }
}

class GridExtent extends StatelessWidget {
  const GridExtent({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.extent(
      maxCrossAxisExtent: 175.0,
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.all(18.0),
      children: List.generate(
          20,
          (index) => Card(
                margin: EdgeInsets.all(8.0),
                child: InkWell(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.ac_unit),
                        Divider(),
                        Text(
                          'Index $index',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16.0,
                          ),
                        )
                      ]),
                ),
              )),
    );
  }
}

class GridBuilder extends StatelessWidget {
  
  const GridBuilder({Key key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
 List<IconData> _iconList = GridIcons().getIconList();

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent:150.0),
     itemCount: 20,
     itemBuilder: (ctx, index){
       return Card(
                margin: EdgeInsets.all(8.0),
                child: InkWell(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        
                        Icon(_iconList[index]),
                        Divider(),
                        Text(
                          'Index $index',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16.0,
                          ),
                        )
                      ]),
                ),
       );
     },
     );
  }
}



class GridIcons {
  List<IconData> iconList = [];
  List<IconData> getIconList() {
    iconList
      ..add(Icons.free_breakfast)
      ..add(Icons.access_alarms)
      ..add(Icons.directions_car)
      ..add(Icons.flight)
      ..add(Icons.cake)
      ..add(Icons.card_giftcard)
      ..add(Icons.change_history)
      ..add(Icons.face)
      ..add(Icons.star)
      ..add(Icons.headset_mic)
      ..add(Icons.directions_walk)
      ..add(Icons.sentiment_satisfied)
      ..add(Icons.cloud_queue)
      ..add(Icons.exposure)
      ..add(Icons.gps_not_fixed)
      ..add(Icons.child_friendly)
      ..add(Icons.child_care)
      ..add(Icons.edit_location)
      ..add(Icons.event_seat)
      ..add(Icons.lightbulb_outline);
    return iconList;
  }
}
