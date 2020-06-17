
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/adaptiveFlatButton.dart';

class NewTransaction extends StatefulWidget {
  final Function addTx;

  NewTransaction(this.addTx){
    print("constructor widget");
  }

  @override
  _NewTransactionState createState() {
    print("createState Newtransaction widget");
    return _NewTransactionState();
  }
}

class _NewTransactionState extends State<NewTransaction> {
  final titleController = TextEditingController();

  final amountController = TextEditingController();
  DateTime _selectDate;

  _NewTransactionState(){
    print('Contructor NewtransactionState State');
  }

  @override
  void initState() {
    print("initState");
    super.initState();
  }

  @override
  void didUpdateWidget(NewTransaction oldWidget) {
        print("didUpdateWidget");
    super.didUpdateWidget(oldWidget);
  }
  @override
  void dispose() {
     print("dispose");
    super.dispose();
  }

  void submitData() {
    if (int.tryParse(amountController.text) == null) {
      return;
    }
    final enteredTitle = titleController.text;
    final enteredAmount = double.parse(amountController.text);

    if (enteredTitle.isEmpty || enteredAmount <= 0 || _selectDate == null) {
      return;
    }
    widget.addTx(enteredTitle, enteredAmount, _selectDate);

    Navigator.of(context)
        .pop(); //cierra todas la pantallas superiores los modal
  }

  void _presentDatePicker() {
    //*Date picker
    showDatePicker(
            context: context,
            initialDate: DateTime.now(), //dia inicia
            firstDate: DateTime(1800), // primer dia o a;o
            lastDate: DateTime.now())
        .then((pickedDate) {
      if (pickedDate == null) {
        return;
      }

      setState(() {
        _selectDate = pickedDate;
      });
    }); // ultimo dia
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Card(
        elevation: 4,
        child: Container(
          padding: EdgeInsets.only(
            top: 10,
            // viewInseta nos da informacion sobre
            //cualquier cosa que este a nuestroa alcance
            bottom: MediaQuery.of(context).viewInsets.bottom * 10,
            left: 10,
            right: 10,
          ),
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
              Container(
                height: 80,
                child: Row(
                  children: <Widget>[
                    Expanded(
                        child: Text(_selectDate == null
                            ? 'No Date chosen!'
                            : "Picked Date: " +
                                DateFormat.yMd().format(_selectDate))),
                  AdaptiveFlatButton("Choose Date",_presentDatePicker )
                  ],
                ),
              ),
              RaisedButton(
                textColor: Theme.of(context).textTheme.button.color,
                child: Text('Add Transation'),
                color: Theme.of(context).primaryColor,
                hoverColor: Theme.of(context).primaryColor,
                onPressed: submitData,
              )
            ],
          ),
        ),
      ),
    );
  }
}
