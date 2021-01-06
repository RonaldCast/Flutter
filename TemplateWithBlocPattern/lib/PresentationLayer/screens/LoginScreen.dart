import 'package:flutter/material.dart';
import 'package:tTemplateWithBlocPattern/DataLayer/Models/LoginModel.dart';
import '../widgets/Logo.dart';
import '../../utils/Constants.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({Key key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  Map<String, String> _auth = {"username": "", "password": ""};
  bool _hidPassword = true;
  IconData _iconInputPassword = Icons.visibility;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(10),
        color: Colors.white,
        height: double.infinity,
        width: double.infinity,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Logo(),
              Form(
                key: _form,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40.0, vertical: 10.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 25.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: cINPUT,
                          ),
                          child: TextFormField(
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(color: cDARK_GRAY, fontSize: 18.0),
                            decoration: customInput(hintText: "Usuario"),
                          ),
                        ),
                        Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: cINPUT,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: TextFormField(
                                    obscureText: _hidPassword,
                                    style: TextStyle(
                                        color: cDARK_GRAY, fontSize: 18.0),
                                    decoration:
                                        customInput(hintText: "Contraseña"),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    child: AnimatedOpacity(
                                      duration: Duration(seconds: 1),
                                      opacity: 1,
                                      child: Icon(
                                        _iconInputPassword,
                                        color: cDARK_GRAY,
                                      ),
                                    ),
                                    onTap: () {
                                      if (_hidPassword) {
                                        setState(() {
                                          _hidPassword = false;
                                          _iconInputPassword =
                                              Icons.visibility_off;
                                        });
                                      } else {
                                        setState(() {
                                          _hidPassword = true;
                                          _iconInputPassword = Icons.visibility;
                                        });
                                      }
                                    },
                                  ),
                                )
                              ],
                            ))
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 15.0,
              ),
              FlatButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                color: cBOTTON,
                padding: const EdgeInsets.symmetric(
                    horizontal: 17.0, vertical: 15.0),
                onPressed: () {},
                textColor: Colors.white,
                child: Text(
                  "Iniciar sesión",
                  style: TextStyle(fontSize: sTEXT_BUTTON),
                ),
              ),
              SizedBox(
                height: 20.0,
              ),
              GestureDetector(
                  onTap: () {},
                  child: Text(
                    "¿Olvido su contraseña?",
                    style: TextStyle(
                        fontSize: 14.0,
                        color: cTEXT_GREEN,
                        decoration: TextDecoration.underline),
                  ))
            ],
          ),
        ),
      ),
    );
  }
}
