import 'package:flutter/material.dart';

//COLORS
const cINPUT = Color.fromRGBO(72, 173, 126, 0.14);
const cBOTTON = Color.fromRGBO(12, 80, 40, 1);
const cTEXT_GREEN = Color.fromRGBO(12, 67, 40, 1);
const cBLUE = Color.fromRGBO(61, 135, 172, 1);
const cTITLE = Color.fromRGBO(209, 196, 109, 1);
const cLIGH_GREEN = Color.fromRGBO(151, 59, 68, 1);
const cGRAY = Color.fromRGBO(218, 220, 221, 1);
const cLIGTH_GRAY = Color.fromRGBO(183, 191, 195, 1);
const cDARK_GRAY = Color.fromRGBO(116, 113, 113, 1);
const cBACKGROUND = Color.fromRGBO(242, 244, 247, 1);
const cMENU = Color.fromRGBO(72, 174, 125, 1);

//SIZE
const sTEXT_BUTTON = 15.0;

//URLS
const API_URL = "http://localhost:5001";

const rVALID_EMAIL = r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';

InputDecoration customInput({String hintText}) {
  return InputDecoration(
      hintText: hintText != null ? hintText : "Text input",
      floatingLabelBehavior: FloatingLabelBehavior.never,
      labelStyle: TextStyle(color: cDARK_GRAY, fontSize: 17.0),
      border: OutlineInputBorder(),
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      errorStyle: TextStyle(height: 0),
      contentPadding:
          const EdgeInsets.only(left: 15, bottom: 11, top: 11, right: 15));
}


