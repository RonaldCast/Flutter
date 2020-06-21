import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import 'dart:math';  // for import math content

class TransactionItem extends StatefulWidget {
  const TransactionItem({
    Key key,
    @required this.transaction,
    @required this.deleteTx,
  }) : super(key: key);

  final Transaction transaction;
  final Function deleteTx;

  @override
  _TransactionItemState createState() => _TransactionItemState();
}

class _TransactionItemState extends State<TransactionItem> {

  Color _bgColor;

  @override
  void initState() {
    const availbleColors = [
      Colors.red,
      Colors.blue,
      Colors.black,
      Colors.purple
    ];
    this._bgColor = availbleColors[Random().nextInt(4)];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _bgColor,
            radius: 30,
            child: Padding(
              padding: EdgeInsets.all(7),
              child: FittedBox(
                child: Text('\$${widget.transaction.amount}'),
              ),
            ),
          ), //widget for icon, image, etc.
          title: Text(
            widget.transaction.title,
            style: Theme.of(context).textTheme.title,
          ),
          subtitle: Text(DateFormat.yMMMd().format(widget.transaction.date)),
          trailing: MediaQuery.of(context).size.width > 460
              ? FlatButton.icon(
                  icon: Icon(Icons.delete),
                  label: Text("Delete"),
                  textColor: Theme.of(context).errorColor,
                  onPressed: () => widget.deleteTx(widget.transaction.id),
                )
              : IconButton(
                  icon: Icon(Icons.delete),
                  color: Theme.of(context).errorColor,
                  onPressed: () => widget.deleteTx(widget.transaction.id),
                ) //for button
          ),
    );
  }
}
