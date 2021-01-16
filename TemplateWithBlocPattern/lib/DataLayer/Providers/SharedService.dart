import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tTemplateWithBlocPattern/DataLayer/Models/LoginModels/LoginResponseModel.dart';
import 'package:tTemplateWithBlocPattern/DataLayer/Models/LoginModels/LoginUserModel.dart';

class SharedService {
  SharedPreferences pref;

  static String kUSER = "user";
  static String kTOKEN = "token";
  static String kREFRESHTOKEN = "refreshToken";

  Future<void> setLoginData(LoginResponseModel userModel) async {
    pref = await SharedPreferences.getInstance();
    pref.setString(kUSER, jsonEncode(userModel.response.user.toJson()));
    pref.setString(kTOKEN, userModel.response.token);
    pref.setString(kREFRESHTOKEN, userModel.response.token);
  }
 
  Future<LoginUserModel> getUser() async {
    pref = await SharedPreferences.getInstance();
    return pref.getString(kUSER) == null
        ? null
        : LoginUserModel.fromJson(jsonDecode(pref.getString(kUSER)));
  }

  Future<String> getToken() async {
    pref = await SharedPreferences.getInstance();
    return pref.getString(kTOKEN);
  }

  Future<String> getRefreshToken() async {
    pref = await SharedPreferences.getInstance();
    return pref.getString(kREFRESHTOKEN);
  }

  void setTokenAndRefreshToken() {}
}
