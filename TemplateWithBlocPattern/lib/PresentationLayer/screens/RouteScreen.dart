import 'package:flutter/material.dart';
import '../../utils/Constants.dart';

class RouteScreen extends StatefulWidget {
  @override
  _RouteScreenState createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: cBACKGROUND,
        body:  ListView(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 25.0, vertical: 13.0),
                child: Stack(
                  overflow: Overflow.visible,
                  children: [
                    Positioned(
                        right: 0,
                        top: 0,
                        child: CircleAvatar(
                            radius: 23,
                            backgroundImage: AssetImage(
                              "images/user.jpg",
                            ))),
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                              margin: EdgeInsets.only(top: 10.0),
                              child: LogoSmall())
                        ]),
                  ],
                ),
              ),
              SizedBox(height: 10.0),
              Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(50),
                        topRight: Radius.circular(50)
                      ),
                        boxShadow: [
                           BoxShadow(
                             color: Colors.grey,
                             
                             spreadRadius: 0.3,
                              blurRadius: 4,
                           )
                        ]
                      ),
                  // color: Colors.red,
                  height: MediaQuery.of(context).size.height,
                  child: null)
            ],
          ),
        );
  }
}

class LogoSmall extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      child: Image.asset(
        "images/logoTreiberLarge.png",
      ),
    );
  }
}
