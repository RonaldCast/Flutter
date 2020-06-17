
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class TransactionItem extends StatelessWidget {
  const TransactionItem({
    Key key,
    @required this.transaction,
    @required this.deleteTx,
  }) : super(key: key);

  final Transaction transaction;
  final Function deleteTx;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: ListTile(
        leading: CircleAvatar(
          radius: 30,
          child: Padding(
            padding: EdgeInsets.all(7),
            child: FittedBox(
              child: Text('\$${transaction.amount}'),
            ),
          ),
        ), //widget for icon, image, etc.
        title: Text( transaction.title, style: Theme.of(context).textTheme.title,
        ),
        subtitle: Text(
            DateFormat.yMMMd().format(transaction.date)),
        trailing:  MediaQuery.of(context).size.width > 460 ?
          FlatButton.icon(
            icon: Icon(Icons.delete),
            label: Text("Delete"),
            textColor: Theme.of(context).errorColor,
            onPressed:() => deleteTx(transaction.id) ,
            )
         : IconButton(
          icon: Icon(Icons.delete),
          color: Theme.of(context).errorColor,
          onPressed: () => deleteTx(transaction.id), 
        ) //for button
      ),
    );
  }
}