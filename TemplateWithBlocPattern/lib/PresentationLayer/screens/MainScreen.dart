import 'package:flutter/material.dart';
import './HistoryScree.dart';
import './ProfileScreen.dart';
import './RouteScreen.dart';
import 'package:tTemplateWithBlocPattern/utils/Constants.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Map<String, Object>> _pages;
  int _selectIndex = 0;

  @override
  void initState() {
    super.initState();
    _pages = [
      {"page": RouteScreen()},
      {"page": HistoryScreen()},
      {"page": ProfileScreen()},
    ];
  }

  void _selectTab(int index) {
    setState(() {
      _selectIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectIndex]["page"],
      bottomNavigationBar: BottomAppBar(
        color: cMENU,
        child: ClipRRect(
          borderRadius: BorderRadius.only(
              topRight: Radius.circular(25), topLeft: Radius.circular(25)),
          child: Container(
            // color: Colors.red,
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 20.0, bottom: 20.0, left: 20.0, right: 20.0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TapIcon(
                        path: "assets/icon/map.svg",
                        size: 27,
                        index: 0,
                        currentIndex: _selectIndex,
                        actionSelect: () {
                          _selectTab(0);
                        }),
                    TapIcon(
                        path: "assets/icon/file-text.svg",
                        size: 27,
                        index: 1,
                        currentIndex: _selectIndex,
                        actionSelect: () {
                          _selectTab(1);
                        }),
                    TapIcon(
                        path: "assets/icon/user.svg",
                        size: 27,
                        index: 2,
                        currentIndex: _selectIndex,
                        actionSelect: () {
                          _selectTab(2);
                        }),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}

Widget TapIcon(
    {@required String path,
    @required double size,
    @required int index,
    int currentIndex,
    @required Function actionSelect}) {
  return Container(
      child: GestureDetector(
    child: SvgPicture.asset(
      path,
      allowDrawingOutsideViewBox: true,
      width: size,
      color: index == currentIndex ? cBOTTON : Colors.white,
    ),
    onTap: () {
      actionSelect();
    },
  ));
}

/**
 * [
                       Container(
                        child: GestureDetector(
                            child: SvgPicture.asset(
                      "assets/icon/map.svg",
                      allowDrawingOutsideViewBox: true,
                      width: 27,
                      color: _selectIndex == 0 ? cBOTTON : Colors.white,
                    ),onTap: (){
                      _selectTab(0);
                    }, )),
                 
                    Container(
                        child: GestureDetector(
                            child: SvgPicture.asset(
                      "assets/icon/file-text.svg",
                      allowDrawingOutsideViewBox: true,
                      width: 27,
                      color: _selectIndex == 1 ? cBOTTON : Colors.white,
                    ), onTap: (){
                      _selectTab(1);
                    },)),
                    Container(
                        child: GestureDetector(
                            child: SvgPicture.asset(
                      "assets/icon/user.svg",
                      allowDrawingOutsideViewBox: true,
                      width: 27,
                      color: _selectIndex == 2 ? cBOTTON : Colors.white,
                    
                    ), onTap: ()=> {
                      _selectTab(2)
                    },)
                    ),
                  ]
 */
