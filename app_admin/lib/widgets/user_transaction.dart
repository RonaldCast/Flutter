import 'package:flutter/material.dart';
import './newTransaction.dart';
import './transaction_list.dart';
import '../models/transaction.dart';

class UserTransaction extends StatefulWidget {
  @override
  _UserTransactionState createState() => _UserTransactionState();
}

class _UserTransactionState extends State<UserTransaction> {
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
  void _addNewTransaction(String txtitle, double txAmount) {
    final newTrans =
        Transaction(title: txtitle, amount: txAmount, date: DateTime.now(), id: DateTime.now().toString());

    setState(() {
      _userTransaction.add(newTrans);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      NewTransaction(_addNewTransaction),
      TransactionList(_userTransaction)
    ]);
  }
}
