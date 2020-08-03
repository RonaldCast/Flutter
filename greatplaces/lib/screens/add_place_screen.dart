import 'package:flutter/material.dart';
import '../widgets/image_input.dart';


class AddPlaceScreen extends StatefulWidget {
  static const routeName = '/add-place';

  @override
  _AddPlaceScreenState createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final _tittleController = TextEditingController();
  


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
                      controller: _tittleController,
                      decoration: InputDecoration(labelText: 'Title'),
                    ),
                    SizedBox(height: 10),
                    ImageInput()
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
          
              },
              icon: Icon(Icons.add),
              label: Text('Add Place'))
        ],
      ),
    );
  }
}
