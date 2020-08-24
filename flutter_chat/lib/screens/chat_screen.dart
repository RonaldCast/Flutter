import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_chat/widgets/chat/messages.dart';
import 'package:flutter_chat/widgets/chat/new_message.dart';
import '../widgets/chat/messages.dart';
import '../widgets/chat/new_message.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key key}) : super(key: key);
  

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

    @override
  void initState(){
     super.initState();
   final fbm=  FirebaseMessaging();
   fbm.requestNotificationPermissions();
   fbm.configure(onMessage: (msg){
     print(msg);
     return;
   }, onLaunch: (msg){
     print(msg);
     return; 
   }, onResume: (msg){
     print(msg);
     return; 
   });
   fbm.subscribeToTopic('chat');
  
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("FlutterChat"),
        actions: [
          DropdownButton(
            underline: Container(),
            icon: Icon(
              Icons.more_vert,
              color: Theme.of(context).primaryIconTheme.color,
            ),
            items: [
              DropdownMenuItem(
                child: Container(
                  child: Row(children: [
                    Icon(Icons.exit_to_app),
                    SizedBox(
                      width: 8,
                    ),
                    Text('Logout')
                  ]),
                ),
                value: 'Logout', //identificacion
              )
            ],
            onChanged: (item) {
              if (item == 'Logout') {
                FirebaseAuth.instance.signOut();
              }
            },
          )
        ],
      ),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child:
                Container(margin: EdgeInsets.only(top: 10), child: Messages()),
          ),
          NewMessage()
        ]),
      ),
    );
  }
}

/*
 StreamBuilder(
          stream: Firestore.instance
              .collection('chats/uUQ0nErS2Z5y1twm1ndk/messages')
              .snapshots(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            final documents = snap.data.documents;
            return ListView.builder(
                itemCount: documents.length,
                itemBuilder: (ctx, index) => Container(
                      padding: EdgeInsets.all(8),
                      child: Text(documents[index]['text']),
                    ));
          })



 */
