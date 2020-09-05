

import 'package:flutter/material.dart';

class GratitudeScreen extends StatefulWidget {
  final int radioGroupValue;

  GratitudeScreen(this.radioGroupValue, {Key key}) : super(key: key);

  @override
  _GratitudeScreenState createState() => _GratitudeScreenState();
}

class _GratitudeScreenState extends State<GratitudeScreen> {
  String _selectedGratitude;
  int _radioGroupValue;
  List<String> _gratitudeList = List();


  void _radioOnChanged(int index){
      setState(() {
        _radioGroupValue = index;
       _selectedGratitude = _gratitudeList[index];
       print('_selectedRadioValue $_selectedGratitude');
      });
  }
  @override
  void initState() {
    super.initState();
     _gratitudeList
     ..add('Family')
     ..add("Friends")
     ..add('Coffee');
     _radioGroupValue = widget.radioGroupValue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Gratitude"), actions: [
        IconButton(
          icon: Icon(Icons.check),
          onPressed: () {
            Navigator.pop(context, _selectedGratitude);
          },
        )
      ]),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Radio(
                value: 0,
                groupValue: _radioGroupValue,
                onChanged: (index) => _radioOnChanged(index),
              ),
              Text('Family'),
                Radio(
                value: 1,
                groupValue: _radioGroupValue,
                onChanged: (index) => _radioOnChanged(index),
              ),
               Text('Friends'),
                Radio(
                value: 2,
                groupValue: _radioGroupValue,
                onChanged: (index) => _radioOnChanged(index),
              ),
               Text('Coffee')
            ],
          ),
        ),
      ),
    );
  }
}
