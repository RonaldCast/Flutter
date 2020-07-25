import 'package:flutter/material.dart';
import "package:http/http.dart" as http;
import 'dart:convert';
import '../models/http_exception.dart';

class Auth with ChangeNotifier {
  String _token;
  DateTime _expiryDate;
  String _userId;

  bool get isAuth {
    return token != null;
  }

  String get token {
    if (_expiryDate != null &&
        _expiryDate.isAfter(DateTime.now()) &&
        _token != null) {
      return _token;
    }
    return null;
  }

  Future<void> _autenticate(
      String email, String password, String urlSegment) async {
    final url =
        "https://identitytoolkit.googleapis.com/v1/accounts:$urlSegment?key=AIzaSyBeek9_9sIIuokiiIGALKC5arExGYIfCO4";
    try {
      final resp = await http.post(url,
          body: json.encode({
            "email": email,
            "password": password,
            "returnSecureToken": true
          }));
      final respData = json.decode(resp.body);
      print(respData.toString());
      if (respData['error'] != null) {
        throw HttpException(respData['error']['message']);
      }
      _token = respData['idToken'];
      _userId = respData['localId'];
      _expiryDate = DateTime.now()
          .add(Duration(seconds: int.parse(respData['expiresIn'])));
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> signup(String email, String password) async {
    // const url = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=AIzaSyBeek9_9sIIuokiiIGALKC5arExGYIfCO4";
    return _autenticate(email, password, "signUp");
  }

  Future<void> login(String email, String password) async {
    // const url = 'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=IzaSyBeek9_9sIIuokiiIGALKC5arExGYIfCO4';
    return _autenticate(email, password, "signInWithPassword");
  }
}
