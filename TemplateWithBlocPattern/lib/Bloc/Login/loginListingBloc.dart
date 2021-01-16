import 'package:bloc/bloc.dart';
import 'package:tTemplateWithBlocPattern/Bloc/Login/loginListingEvent.dart';
import 'package:tTemplateWithBlocPattern/Bloc/Login/loginListingState.dart';
import 'package:tTemplateWithBlocPattern/DataLayer/Models/LoginModels/LoginResponseModel.dart';
import 'package:tTemplateWithBlocPattern/DataLayer/Providers/SharedService.dart';
import 'package:tTemplateWithBlocPattern/DataLayer/Repositories/LoginRepository.dart';
import 'dart:io';

class LoginListingBloc extends Bloc<LoginListingEvent, LoginListingState> {
  final LoginRepository loginRepository;

  LoginListingBloc({this.loginRepository})
      : assert(loginRepository != null),
        super(null);

  @override
  Stream<LoginListingState> mapEventToState(LoginListingEvent event) async* {
    SharedService pref = SharedService();

    try {
      if (event is LoginEvent) {
        var resp = await loginRepository.loginAsync(event.model);
        await pref.setLoginData(resp);
        yield LoginState(model: resp);
      } else if (event is LoginCheckEvent) {
        yield await pref.getUser() == null && await pref.getToken() == null
            ? LogoutState()
            : LoginState(model: LoginResponseModel());
      } else if (event is LogoutEvent) {
        yield LogoutState();
      }
    } on HttpException catch(e) {
      yield LoginErrorState(message: e.message);
    }
    catch (e) {
      yield LoginErrorState(message: "Non-Controller error");
    }
   }
}
