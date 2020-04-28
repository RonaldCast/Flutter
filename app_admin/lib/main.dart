import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './widgets/transaction_list.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {

  final titleController = TextEditingController();
  final amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple[400],
        title: Text('Flutter App'),
      ),
      body: Column(children: <Widget>[
        Card(
          elevation: 4,
          child: Container(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Title',
                    
                  ),
                  //onChanged: (val) {titleInput = val;}
                  
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Amount'),
                  controller: amountController,
                  //onChanged: (val) { amountInput = val;} ,
                ),
                FlatButton(
                  child: Text('Add Transation'),
                  textColor: Colors.purple,
                  hoverColor: Colors.purple[50],
                  onPressed: (){
                    print(amountController.text);
                  },
                )
              ],
            ),
          ),
        ),
        TransactionList()
      ]),
    );
  }
}
