import 'package:flutter/material.dart';

class FormScreen extends StatefulWidget {
  const FormScreen({Key key}) : super(key: key);
  static const String routeName = "/form";

  @override
  _FormScreenState createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final GlobalKey<FormState> _formStateKey = GlobalKey<FormState>();
  final focus = FocusNode();

  Order order = Order();

  String _validateItemRequired(String value) {
    return value.isEmpty ? 'Item Required' : null;
  }

  String _validateItemCount(String value) {
    int _valueAsInteger = value.isEmpty ? 0 :  int.tryParse(value);
    return _valueAsInteger == 0  ||  _valueAsInteger == null? "At least one Item is Required" : null;
  }

  void _submitOrder() {
    if (_formStateKey.currentState.validate()) {
      _formStateKey.currentState.save();
      print('Order Item: ${order.item}');
      print('Order Quantity: ${order.quantity}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Form")),
      body: SafeArea(
        child: Column(children: [
          Form(
            key: _formStateKey,
            autovalidate: true,
            child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      textInputAction: TextInputAction.next,
                      style: TextStyle(fontSize: 18.0),
                      decoration: InputDecoration(
                          labelText: "Item", hintText: 'Espresso'),
                      onFieldSubmitted: (v) {
                        FocusScope.of(context).requestFocus(focus);
                      },
                      validator: (value) => _validateItemRequired(value),
                      onSaved: (value) => order.item = value,
                    ),
                    TextFormField(
                      focusNode: focus,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: 18.0),
                      decoration: InputDecoration(
                        labelText: "Quantity",
                        hintText: "3",
                      ),
                      validator: (value) => _validateItemCount(value),
                      onSaved: (value) => order.quantity = int.tryParse(value) ,
                    ),

                    Divider(height:32.0),
                    RaisedButton(
                      child: Text('Save'),
                      color: Colors.lightGreen,
                      onPressed: () => _submitOrder(),
                    )
                  ],
                )),
          )
        ]),
      ),
    );
  }
}

class Order {
  String item;
  int quantity;
}
