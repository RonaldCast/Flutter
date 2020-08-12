import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
          stream: Firestore.instance
              .collection('chats/uUQ0nErS2Z5y1twm1ndk/messages')
              .snapshots(),
          builder: (ctx, snap) {
            if(snap.connectionState == ConnectionState.waiting){
              return Center(child: CircularProgressIndicator(),);
            }
            final documents = snap.data.documents;
            return ListView.builder(
                itemCount:documents.length,
                itemBuilder: (ctx, index) => Container(
                      padding: EdgeInsets.all(8),
                      child: Text(documents[index]['text']),
                    ));
          }),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Firestore.instance
              .collection('chats/uUQ0nErS2Z5y1twm1ndk/messages')
              .add({'text': "dddddddd"});
            
        },
      ),
    );
  }
}
