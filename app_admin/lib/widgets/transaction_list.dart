import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class TransactionList extends StatelessWidget {
  final List<Transaction> transactions;

  TransactionList(this.transactions);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      child: ListView.builder(
        itemBuilder: (ctx, index) {
          return Card(
            elevation: 5,
            child: Row(children: <Widget>[
              Container(
                decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).primaryColor, width: 2)),
                margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                padding: EdgeInsets.all(10),
                child: Text(
                  'RD\$ ${transactions[index].amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(transactions[index].title,
                      style: Theme.of(context).textTheme.title
                        ),
                  Text(
                    DateFormat('dd-MM-yyyy').format(transactions[index].date),
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  )
                ],
              ),
            ]),
          );
        },
        itemCount: transactions.length,

        // ),
      ),
    );
  }
}
