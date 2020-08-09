import 'package:flutter/material.dart';
import '../widgets/image_input.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../providers/great_place.dart';

import '../widgets/location_input.dart';


class AddPlaceScreen extends StatefulWidget {
  static const routeName = '/add-place';
   
  @override
  _AddPlaceScreenState createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final _titleController = TextEditingController();
  File _pickedImage; 
  
  void _selectImage(File pickedImage){
    _pickedImage = pickedImage; 
  }

  void _savePlace(){
    if(_titleController.text.isEmpty || _pickedImage == null){
      return; 
    }
    Provider.of<GreatPlaces>(context, listen: false).addPlace(_titleController.text, _pickedImage);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add a new Place '),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  children: <Widget>[
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(labelText: 'Title'),
                    ),
                    SizedBox(height: 10),
                    ImageInput(_selectImage),
                    SizedBox(height: 20,),
                    LocationInput()
                  ],
                ),
              ),
            ),
          ),
          //contiant a label
          RaisedButton.icon(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              elevation: 0,
              color: Theme.of(context).accentColor,
              onPressed: () {
                   _savePlace();
              },
              icon: Icon(Icons.add),
              label: Text('Add Place'))
        ],
      ),
    );
  }
}
