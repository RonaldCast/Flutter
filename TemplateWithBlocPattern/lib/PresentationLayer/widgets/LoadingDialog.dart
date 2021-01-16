import 'package:flutter/material.dart';


import 'package:tTemplateWithBlocPattern/utils/Constants.dart';

class LoadingDialog extends StatelessWidget {
  final String text; 
  const LoadingDialog({Key key, @required this.text} ) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return  Dialog(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(cMENU),
                  backgroundColor: cINPUT,
                ),
                SizedBox(height: 10.1),
                Text(
                  text,
                  style: TextStyle(fontSize: sTEXT_BUTTON, color: cDARK_GRAY),
                ),
              ],
            ),
          ));
  }
}