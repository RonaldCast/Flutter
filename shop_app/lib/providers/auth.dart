import 'package:flutter/material.dart';
import "package:http/http.dart" as http;
import 'dart:convert';
import '../models/http_exception.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class Auth with ChangeNotifier {
  String _token;
  DateTime _expiryDate;
  String _userId;
  Timer _authTimer;

  bool get isAuth {
    return token != null;
  }

  String get userId {
    return _userId;
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
      _autoLogout();
      notifyListeners();
      // se crea el tunnel para el store
      final prefs = await SharedPreferences.getInstance();
      //save storage
      final userData = json.encode(
          {'token': _token, 'userId': _userId, 'expiryDate': _expiryDate.toIso8601String()});
      prefs.setString("userData", userData);
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

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey("userData")) {
      return false;
    }

    final extractedUserData =
        json.decode(prefs.getString('userData')) as Map<String, dynamic>;
    final expiryDate = DateTime.parse(extractedUserData['expiryDate']);

    if (expiryDate.isBefore(DateTime.now())) {
      return false;
    }
    _token = extractedUserData['token'];
    _userId = extractedUserData['userId'];
    _expiryDate = _expiryDate;
    notifyListeners();
    _autoLogout();
    return true;
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _expiryDate = null;
    if (_authTimer != null) {
      _authTimer.cancel();
      _authTimer = null;
    }
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();

  }

  void _autoLogout() {
    if (_authTimer != null) {
      _authTimer.cancel();
    }

    final timerToExpiry = _expiryDate.difference(DateTime.now()).inSeconds;
    _authTimer = Timer(Duration(seconds: timerToExpiry), logout);
  }
}
