import 'package:app_admin/widgets/newTransaction.dart';
import 'package:flutter/material.dart';
import './models/transaction.dart';
import './widgets/transaction_list.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          textTheme: ThemeData.light().textTheme.copyWith(
            title: TextStyle(fontFamily: "OpenSans",
               fontSize: 18,
               fontWeight: FontWeight.bold
            )
          ) ,
          primarySwatch:
              Colors.red, //para darle a futuro diferentes tonalidades
          accentColor: Colors
              .green, //para realizar tonalidades y convinaciones este color se le aplica a los elementos segundario ofrecido por material
          fontFamily: 'Quicksand',
           // para establecer la funte del tema
          appBarTheme: AppBarTheme(
              textTheme: ThemeData.light().textTheme.copyWith(
                  title: TextStyle(fontFamily: 'OpenSans', fontSize: 20))) // sobre eescribe el tema por defecto
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
  void _addNewTransaction(String txtitle, double txAmount) {
    final newTrans = Transaction(
        title: txtitle,
        amount: txAmount,
        date: DateTime.now(),
        id: DateTime.now().toString());

    setState(() {
      _userTransaction.add(newTrans);
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text('Flutter App'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _startAddNewTransaction(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(children: <Widget>[TransactionList(_userTransaction)]),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _startAddNewTransaction(context);
        },
        backgroundColor: Theme.of(context).accentColor,
        child: Icon(Icons.add),
      ),
    );
  }
}
