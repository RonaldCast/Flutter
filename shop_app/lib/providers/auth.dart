import 'package:flutter/material.dart';
import "package:http/http.dart" as http;
import 'dart:convert';

class Auth with ChangeNotifier{

  String _token; 
  DateTime _expiryDate;
  String _userId;

  Future<void> signup(String email, String password) async{
    const url = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=AIzaSyBeek9_9sIIuokiiIGALKC5arExGYIfCO4";
    final resp = await http.post(url, body: json.encode({ 
      "email": email,
      "password": password,
      "returnSecureToken": true
    })); 
    print(resp.body);
  }
}