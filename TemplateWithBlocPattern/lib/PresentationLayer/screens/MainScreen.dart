import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tTemplateWithBlocPattern/Bloc/Login/loginListingBloc.dart';
import 'package:tTemplateWithBlocPattern/Bloc/Login/exportLoginBloc.dart';
import 'package:tTemplateWithBlocPattern/DataLayer/Models/LoginModels/RevokeTokenModel.dart';

class MainScreen extends StatelessWidget {
  static String routeName = "/main";
  const MainScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: RaisedButton(
        child: Text("Hello"),
        onPressed: () async {
          SharedPreferences pref = await SharedPreferences.getInstance();
          pref.clear();
          BlocProvider.of<LoginListingBloc>(context).add(
              LogoutEvent(model: RevokeTokenModel(refreshToken: "sssssss")));
        },
      ),
    );
  }
}
