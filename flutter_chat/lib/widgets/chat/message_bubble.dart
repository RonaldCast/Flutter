import 'package:flutter/material.dart';
import 'dart:math';

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final Key key;
  final String username;
  final String userImage;
  Random random = new Random(1);

  MessageBubble(this.message, this.username, this.userImage, this.isMe,
      {this.key});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
    
      Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
                color: isMe ? Colors.grey[300] : Theme.of(context).accentColor,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                    bottomLeft:
                        !isMe ? Radius.circular(0) : Radius.circular(12),
                    bottomRight:
                        !isMe ? Radius.circular(12) : Radius.circular(0))),
            width:150,

            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            margin: EdgeInsets.symmetric(vertical:10, horizontal: 8),
            // ignore: deprecated_member_use
            child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isMe
                            ? Colors.black
                            : Theme.of(context).accentTextTheme.title.color),
                  ),
                  Text(
                    message,
                    style: TextStyle(
                        color: isMe
                            ? Colors.black
                            : Theme.of(context).accentTextTheme.title.color),
                    textAlign: isMe ? TextAlign.end : TextAlign.start,
                  )
                ]),
          ),
        ],
      ),
      
      Positioned(
        top:-5,
        right: isMe ? 125:null ,
        left: isMe ? null : 125,
        child: CircleAvatar(backgroundImage: NetworkImage(userImage),)
      ),
      
    ],
    overflow: Overflow.visible,
    );
  }
}
