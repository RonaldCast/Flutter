import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tTemplateWithBlocPattern/DataLayer/Models/LoginModels/LoginModel.dart';
import 'package:tTemplateWithBlocPattern/PresentationLayer/widgets/LoadingDialog.dart';
import '../widgets/Logo.dart';
import '../../utils/Constants.dart';
import 'package:tTemplateWithBlocPattern/Bloc/Login/exportLoginBloc.dart';

class LoginScreen extends StatefulWidget {
  static String routeName = "/login";
  LoginScreen({Key key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  Map<String, String> _auth = {"email": "", "password": ""};
  bool _hidPassword = true;
  double showMessageEmail = 0;
  double showMessagePassword = 0;
  IconData _iconInputPassword = Icons.visibility;
  bool _loading = false;

  Future<void> _submit(BuildContext context) async {
    if (!_form.currentState.validate()) {
      return;
    }
    _form.currentState.save();

    if (!_loading)
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return LoadingDialog(text: "Loading");
        },
      );

    setState(() {
      _loading = true;
    });

    LoginModel model =
        LoginModel(email: _auth["email"], password: _auth["password"]);
    BlocProvider.of<LoginListingBloc>(context).add(LoginEvent(model: model));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<LoginListingBloc, LoginListingState>(
        listener: (context, state) {
          if (state is LoginState) {
            if (_loading) {
              Navigator.of(context).pop();
              setState(() {
                _loading = false;
              });
            }
          } else if (state is LoginErrorState) {
            if (_loading) {
              Navigator.of(context).pop();
              setState(() {
                _loading = false;
              });
            }

            Flushbar(
              flushbarPosition: FlushbarPosition.TOP,
              title: "Alert",
              message: state.message,
              duration: Duration(seconds: 3),
              backgroundColor: Colors.red[400],
              margin: EdgeInsets.all(8),
              borderRadius: 8,
            )..show(context);
          }
        },
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SafeArea(
                  child: Column(
                    children: [
                      Logo(),
                      Container(
                        child: Form(
                          key: _form,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40.0, vertical: 10.0),
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      color: cINPUT,
                                    ),
                                    child: TextFormField(
                                      keyboardType: TextInputType.emailAddress,
                                      style: TextStyle(
                                          color: cDARK_GRAY, fontSize: 18.0),
                                      decoration:
                                          customInput(hintText: "Usuario"),
                                      // ignore: missing_return
                                      validator: (value) {
                                        RegExp exp = RegExp(rVALID_EMAIL);
                                        if (!exp.hasMatch(value)) {
                                          setState(() {
                                            showMessageEmail = 1;
                                          });
                                          return '';
                                        }
                                        setState(() {
                                          showMessageEmail = 0;
                                        });
                                      },
                                      onSaved: (value) {
                                        _auth["email"] = value;
                                      },
                                    ),
                                  ),
                                  animationErrorMessge(showMessageEmail,
                                      "Invalid Email", 9.0, 1),
                                  Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        color: cINPUT,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            flex: 5,
                                            child: TextFormField(
                                              obscureText: _hidPassword,
                                              style: TextStyle(
                                                  color: cDARK_GRAY,
                                                  fontSize: 18.0),
                                              decoration: customInput(
                                                  hintText: "Contraseña"),
                                              // ignore: missing_return
                                              validator: (value) {
                                                if (value.isEmpty) {
                                                  setState(() {
                                                    showMessagePassword = 1;
                                                  });
                                                  return '';
                                                }
                                                setState(() {
                                                  showMessagePassword = 0;
                                                });
                                              },
                                              onSaved: (value) {
                                                _auth["password"] = value;
                                              },
                                            ),
                                          ),
                                          Expanded(
                                            child: GestureDetector(
                                              child: Icon(
                                                _iconInputPassword,
                                                color: cDARK_GRAY,
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
                                                    _iconInputPassword =
                                                        Icons.visibility;
                                                  });
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      )),
                                  animationErrorMessge(showMessagePassword,
                                      "Enter your password", 0.0, 1),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      FlatButton(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        color: cBOTTON,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 17.0, vertical: 15.0),
                        onPressed: () async {
                          await _submit(context);
                        },
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
                          onTap: () async {},
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget animationErrorMessge(
    double opacity, String message, double bottomM, double topM) {
  return AnimatedOpacity(
    opacity: opacity,
    duration: const Duration(milliseconds: 350),
    child: Container(
      alignment: Alignment.topLeft,
      margin: EdgeInsets.only(bottom: bottomM, top: topM),
      child: Text(
        message,
        style: TextStyle(color: Colors.red[400]),
      ),
    ),
  );
}
