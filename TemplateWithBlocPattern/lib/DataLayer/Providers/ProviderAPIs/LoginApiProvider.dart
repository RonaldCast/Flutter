import 'dart:io';
import 'package:tTemplateWithBlocPattern/DataLayer/Models/LoginModels/LoginModel.dart';
import 'package:tTemplateWithBlocPattern/DataLayer/Models/LoginModels/LoginResponseModel.dart';

import '../SingletonDio.dart';

class LoginApiProvider {
  SingletonDio _http;
  LoginApiProvider() {
    _http = SingletonDio();
  }

  Future<LoginResponseModel> loginAsync(LoginModel model) async {
    try {
      var resp = await _http
          .getDio()
          .post("/api/v1/Auth/SignIn", data: model.toJson());
      return LoginResponseModel.fromJson(resp.data);
    } catch (e) {
      if(e.error is HttpException){
         throw e.error; 
      }
      var resp = LoginResponseModel.fromJson(e.response.data);
      throw HttpException(resp.message);    
    }
  }

}
