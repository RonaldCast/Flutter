import 'package:flutter/material.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart';


class TransactionList extends StatefulWidget{

   @override
  _TransactionListState createState() => _TransactionListState(); 
}

class _TransactionListState extends State<TransactionList>{
  final List<Transaction> _userTransaction = [
     Transaction(
        id: 't1', title: 'New Shoes', amount: 69.09, date: DateTime.now()),
    Transaction(
        id: 't2', title: 'New ties', amount: 9.89, date: DateTime.now()),
    Transaction(
        id: 't3', title: 'New short', amount: 24.43, date: DateTime.now()),
    Transaction(
        id: 't4', title: 'New Shoes', amount: 93.33, date: DateTime.now()),
  ];
  @override
  Widget build(BuildContext context){
    return  Column(
          children: _userTransaction
              .map((e) => Card(
                    elevation: 5,
                    shadowColor: Colors.black,
                    child: Row(children: <Widget>[
                      Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.purple, width: 2)),
                        margin:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        padding: EdgeInsets.all(10),
                        child: Text(
                          'RD\$ ${e.amount.toString()}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.purple,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(e.title,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(
                            DateFormat('dd-MM-yyyy').format(e.date),
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          )
                        ],
                      ),
                    ]),
                  ))
              .toList(),
        );
  }
}