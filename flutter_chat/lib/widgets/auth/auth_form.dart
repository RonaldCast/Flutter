import 'package:flutter/material.dart';
import '../chat/pickers/user_image_picker.dart';
import 'dart:io';

class AuthForm extends StatefulWidget {
  AuthForm(this.submitFn, this.isLoading);

  final bool isLoading;
  final void Function(String email, String password, String userName,
      File image,
      bool isLogin, BuildContext ctx) submitFn;

  @override
  _AuthFormState createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  String _userName = '';
  String _userEmail = '';
  String _userPassword = '';
  bool _isLogin = true;
  File _userImageFile;

  void _trySubmit() {
    final isValid = _formKey.currentState.validate();
    FocusScope.of(context).unfocus();

    if (_userImageFile == null && !_isLogin) {
      Scaffold.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          backgroundColor: Theme.of(context).errorColor,
          content: Text("Please pick an image"),
        ));
      return;
    }

    if (isValid) {
      _formKey.currentState.save();

      widget.submitFn(_userEmail.trim(), _userPassword.trim(), _userName.trim(),
         _userImageFile,
          _isLogin, context);
    }
  }

  void _pickedImage(File image) {
    _userImageFile = image;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: EdgeInsets.all(30),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(children: [
                if (!_isLogin) UserImagePicker(_pickedImage),
                TextFormField(
                  textInputAction: TextInputAction.next,
                  key: ValueKey('email'),
                  autocorrect: false,
                  textCapitalization: TextCapitalization.none,
                  enableSuggestions: false,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: "Email address"),
                  validator: (value) {
                    if (value.isEmpty || !value.contains('@')) {
                      return 'Please enter a valid email address.';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _userEmail = value.trim();
                  },
                ),
                if (!_isLogin)
                  TextFormField(
                    key: ValueKey('username'),
                    autocorrect: true,
                    textCapitalization: TextCapitalization.words,
                    enableSuggestions: false,
                    decoration: InputDecoration(labelText: 'Username'),
                    validator: (value) {
                      if (value.isEmpty || value.length < 4) {
                        return 'Please enter at least 4 characters';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _userName = value.trim();
                    },
                  ),
                TextFormField(
                  key: ValueKey('password'),
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Password'),
                  validator: (value) {
                    if (value.isEmpty || value.length < 7) {
                      return "Password must be at least 7 characters long";
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _userPassword = value;
                  },
                ),
                SizedBox(
                  height: 12,
                ),
                if (widget.isLoading)
                  CircularProgressIndicator(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                if (!widget.isLoading)
                  RaisedButton(
                    child: Text(_isLogin ? "Login" : "Signup"),
                    onPressed: _trySubmit,
                  ),
                if (!widget.isLoading)
                  FlatButton(
                    textColor: Theme.of(context).primaryColor,
                    child: Text(_isLogin
                        ? "Create new account"
                        : "I already have a account"),
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                      });
                    },
                  )
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
