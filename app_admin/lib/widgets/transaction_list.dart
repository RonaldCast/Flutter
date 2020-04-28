import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';



class TransactionList extends StatelessWidget{
  final List<Transaction> transactions;

  TransactionList(this.transactions);

  @override
  Widget build(BuildContext context){
    return Container(
           height: 400,
          child: ListView(
              children: transactions
                  .map((e) => Card(
                        elevation: 5,
                       
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
           // ),
      ),
    );
  }
}