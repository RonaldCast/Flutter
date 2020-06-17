import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/cupertino.dart';

class AdaptiveFlatButton extends StatelessWidget {
  final String text;
  final Function handler;

  AdaptiveFlatButton(this.text, this.handler);

  Widget build(BuildContext context) {
    return Container(
        child: Platform.isIOS
            ? CupertinoButton(
                child: Text(text,
                    style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: handler,
              )
            : FlatButton(
                textColor: Theme.of(context).primaryColor,
                child: Text(
                  text,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: handler,
              ));
  }
}
