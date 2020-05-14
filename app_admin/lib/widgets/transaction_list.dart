import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class TransactionList extends StatelessWidget {
  final List<Transaction> transactions;
  final Function deleteTx;

  TransactionList(this.transactions, this.deleteTx);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.6, //tiene el 60% de la pantalla
      child: transactions.isEmpty
          ? LayoutBuilder (
            builder: (ctx, constraints){
              return Column(
              
                children: <Widget>[
                  SizedBox(height: 20),
                  Text('No Transactions added yet',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.title),
                  SizedBox(
                    height: 20,
                  ),
                  Container(
                    height: constraints.maxHeight * 0.6,
                    child: Image.asset("assets/images/waiting.png",
                        fit: BoxFit.cover),
                  )
                ],
              );
            },
               
          )
          : ListView.builder(
              itemBuilder: (ctx, index) {
                return Card(
                  elevation: 6,
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 30,
                      child: Padding(
                        padding: EdgeInsets.all(7),
                        child: FittedBox(
                          child: Text('\$${transactions[index].amount}'),
                        ),
                      ),
                    ), //widget for icon, image, etc.
                    title: Text( transactions[index].title, style: Theme.of(context).textTheme.title,
                    ),
                    subtitle: Text(
                        DateFormat.yMMMd().format(transactions[index].date)),
                    trailing:  MediaQuery.of(context).size.width > 460 ?
                      FlatButton.icon(
                        icon: Icon(Icons.delete),
                        label: Text("Delete"),
                        textColor: Theme.of(context).errorColor,
                        onPressed:() => deleteTx(transactions[index].id) ,
                        )
                     : IconButton(
                      icon: Icon(Icons.delete),
                      color: Theme.of(context).errorColor,
                      onPressed: () => deleteTx(transactions[index].id), 
                    ) //for button
                  ),
                );
              },
              itemCount: transactions.length,

              // ),
            ),
    );
  }
}

/**
 * 
 * 
 * Card(
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
 */
