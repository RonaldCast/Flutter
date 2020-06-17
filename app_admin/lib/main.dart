//este se utiliza para saber sobre el dispositivo
import 'dart:io'; //debe ser el primero en importarse si se va a usar.

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart'; //para presentar los SytemChrome

import 'package:app_admin/widgets/newTransaction.dart';
import './models/transaction.dart';
import './widgets/transaction_list.dart';
import './widgets/chart.dart';

void main() {
  //  WidgetsFlutterBinding.ensureInitialized();//para que habilite la configuracion
  //  SystemChrome.setPreferredOrientations([
  //    DeviceOrientation.portraitDown, // para que no cambie la orientacion
  //    DeviceOrientation.portraitUp // para cambiar la ortientacion;
  //  ]); //permite realizar configuraciones
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          textTheme: ThemeData.light().textTheme.copyWith(
              title: TextStyle(
                  fontFamily: "OpenSans",
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
              button: TextStyle(color: Colors.white, fontFamily: "OpenSans")),
          primarySwatch:
              Colors.red, //para darle a futuro diferentes tonalidades
          accentColor: Colors
              .green, //para realizar tonalidades y convinaciones este color se le aplica a los elementos segundario ofrecido por material
          fontFamily: 'Quicksand',
          // para establecer la funte del tema
          appBarTheme: AppBarTheme(
              textTheme: ThemeData.light().textTheme.copyWith(
                  title: TextStyle(
                      fontFamily: 'OpenSans',
                      fontSize: 20))) // sobre eescribe el tema por defecto
          ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<Transaction> _userTransaction = [
    // Transaction(
    //     id: 't1', title: 'New Shoes', amount: 69.09, date: DateTime.now()),
    // Transaction(
    //     id: 't2', title: 'OK New ties', amount: 9.89, date: DateTime.now()),
    // Transaction(
    //     id: 't3', title: 'New short', amount: 24.43, date: DateTime.now()),
    // Transaction(
    //     id: 't4', title: 'New Shoes', amount: 93.33, date: DateTime.now()),
  ];

  List<Transaction> get _recentTransaction {
    return _userTransaction.where((txt) {
      return txt.date.isAfter(DateTime.now().subtract(Duration(days: 7)));
    }).toList();
  }

  bool _showChart = false;

  void _addNewTransaction(String txtitle, double txAmount, DateTime date) {
    final newTrans = Transaction(
        title: txtitle,
        amount: txAmount,
        date: date,
        id: DateTime.now().toString());

    setState(() {
      _userTransaction.add(newTrans);
    });
  }

  void _deleteTrasaction(String id) {
    setState(() {
      _userTransaction.removeWhere((tx) => tx.id == id);
    });
  }

  void _startAddNewTransaction(BuildContext ctx) {
    showModalBottomSheet(
        context: ctx,
        builder: (_) {
          return GestureDetector(
            child: NewTransaction(_addNewTransaction),
            onTap: () {},
            behavior: HitTestBehavior.opaque,
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    // to know orientation
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final PreferredSizeWidget appBar = Platform.isIOS ? CupertinoNavigationBar(
      middle: Text("Personal Expenses"),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          GestureDetector(
            child: Icon(CupertinoIcons.add), //cupertino Icons
            onTap: () => _startAddNewTransaction(context),
          )
        ],
      ),
    ) : AppBar(
      backgroundColor: Theme.of(context).primaryColor,
      title: Text('Personal Expenses'),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.add),
          onPressed: () => _startAddNewTransaction(context),
        )
      ],
    );
    final txListWidget = Container(
        height: (MediaQuery.of(context).size.height -
                appBar.preferredSize.height -
                MediaQuery.of(context).padding.top) *
            0.7,
        child: TransactionList(
            _userTransaction.reversed.toList(), _deleteTrasaction));
    print(appBar.preferredSize.height);
    final pageBody = SafeArea( child:SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (isLandscape)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text("Show Chart", style: Theme.of(context).textTheme.title),
                          Switch.adaptive(
                              // para adaptar a Ios and Android
                              activeColor: Theme.of(context)
                                  .accentColor, //[ara que tome el color adecuda y no el de cupertino]
                              value: _showChart,
                              onChanged: (value) {
                                setState(() {
                                  _showChart = value;
                                });
                                print(value);
                              }),
                        ],
                      ),
                    if (!isLandscape)
                      Container(
                          height: (MediaQuery.of(context).size.height -
                                  appBar.preferredSize.height -
                                  MediaQuery.of(context).padding.top) *
                              0.3,
                          child: Chart(_recentTransaction)),
                    if (!isLandscape) txListWidget,
                    if (isLandscape)
                      _showChart
                          ? Container(
                              height: (MediaQuery.of(context).size.height -
                                      appBar.preferredSize.height -
                                      MediaQuery.of(context).padding.top) *
                                  0.7,
                              child: Chart(_recentTransaction))
                          : txListWidget
                  ]),
            ));
    return Platform.isIOS
        ? CupertinoPageScaffold(child: pageBody, navigationBar: appBar)
        : Scaffold(
            appBar: appBar,
            body:pageBody,
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            floatingActionButton: Platform.isIOS
                ? Container
                : FloatingActionButton(
                    onPressed: () {
                      _startAddNewTransaction(context);
                    },
                    backgroundColor: Theme.of(context).accentColor,
                    child: Icon(Icons.add),
                  ),
          );
  }
}
