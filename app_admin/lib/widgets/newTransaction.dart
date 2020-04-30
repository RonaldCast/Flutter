
import 'package:flutter/material.dart';

class NewTransaction extends StatefulWidget {
  final Function addTx;

  NewTransaction(this.addTx);

  @override
  _NewTransactionState createState() => _NewTransactionState();
}

class _NewTransactionState extends State<NewTransaction> {
  final titleController = TextEditingController();

  final amountController = TextEditingController();

  void submitData(){
    final enteredTitle = titleController.text;
    final enteredAmount = double.parse(amountController.text);

    if(enteredTitle.isEmpty || enteredAmount <= 0){
      return;
    }
    widget.addTx(enteredTitle, enteredAmount);

    Navigator.of(context).pop(); //cierra todas la pantallas superiores los modal
  
  }

  @override
  Widget build(BuildContext context) {
    return Card(
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
              controller: titleController,
               onSubmitted: (_) => submitData(),
              //onChanged: (val) {titleInput = val;}
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Amount'),
              controller: amountController,
              keyboardType: TextInputType.number,
              onSubmitted: (_) => submitData(),
              //onChanged: (val) { amountInput = val;} ,
            ),
            FlatButton(
              child: Text('Add Transation'),
              textColor: Colors.purple,
              hoverColor: Colors.purple[50],
              onPressed: submitData,
            )
          ],
        ),
      ),
    );
  }
}
