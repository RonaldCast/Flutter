import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as syspath;

class ImageInput extends StatefulWidget {
  final Function onSelectImage;
  
  ImageInput(this.onSelectImage);

  @override
  _ImageInputState createState() => _ImageInputState();
}

class _ImageInputState extends State<ImageInput> {
  File _storedImage;
  Future<void> _takePicture() async {
    final picker = ImagePicker();
    final imageFile =
        await picker.getImage(source: ImageSource.camera, maxWidth: 600);

    setState(() {
      _storedImage = File(imageFile.path);
    });

    if(imageFile == null){
      return;
    }

    //find app directory where app is locate 
    final appDir = await syspath.getApplicationSupportDirectory();
    final fileName =  path.basename(imageFile.path);
    final savedImage = await File(imageFile.path).copy('${appDir.path}/$fileName');
    widget.onSelectImage(savedImage);
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: <Widget>[
      Container(
        alignment: Alignment.center,
        width: 150,
        height: 150,
        decoration:
            BoxDecoration(border: Border.all(width: 1, color: Colors.grey)),
        child: _storedImage != null
            ? Image.file(
                _storedImage,
                fit: BoxFit.cover,
                width: double.infinity,
              )
            : Text(
                "No Image Taken",
                textAlign: TextAlign.center,
              ),
      ),
      SizedBox(width: 10),
      Expanded(
        child: FlatButton.icon(
          icon: Icon(Icons.camera),
          label: Text('Take Picture'),
          textColor: Theme.of(context).primaryColor,
          onPressed: () {
            _takePicture();
          },
        ),
      )
    ]);
  }
}
