import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget{

  @override
  State<StatefulWidget> createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage>{
 int _batteryLevel;

 Future<void> _getBatteryLavel() async{
     //para usar codigo nativo en el MethodChannel se pasa un unico idenifier 
     //con una identificacion unica 
    const platform = MethodChannel('course.flutter.dev/battery');
  
    try{
        // se pasa el nombre del metodo que se creo en ios o android
    final batteryLevel = await platform.invokeMethod('getBatteryLevel');

       setState(() {
        _batteryLevel = batteryLevel;
      });

    } on PlatformException catch(e){
      print(e);
      setState(() {
        _batteryLevel = null;
      });
    }
 }
 

 @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getBatteryLavel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text("Native Code"),),
      body: Center(child: Text("Battery Level: $_batteryLevel"),),
    );
  }
}