

import 'package:tTemplateWithBlocPattern/DataLayer/Models/LoginModels/LoginModel.dart';
import 'package:tTemplateWithBlocPattern/DataLayer/Models/LoginModels/LoginResponseModel.dart';
import 'package:tTemplateWithBlocPattern/DataLayer/Providers/ProviderAPIs/LoginApiProvider.dart';

class LoginRepository {
  
  LoginApiProvider _apiProvider = LoginApiProvider();

   Future<LoginResponseModel> loginAsync(LoginModel model) async
    =>_apiProvider.loginAsync(model);

}