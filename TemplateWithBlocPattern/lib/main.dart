import 'package:flutter/material.dart';
import 'package:tTemplateWithBlocPattern/Bloc/Login/loginListingState.dart';
import './PresentationLayer/screens/LoginScreen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tTemplateWithBlocPattern/PresentationLayer/screens/MainScreen.dart';
import 'package:tTemplateWithBlocPattern/DataLayer/Repositories/LoginRepository.dart';
import 'package:tTemplateWithBlocPattern/Bloc/Login/exportLoginBloc.dart';
import 'package:tTemplateWithBlocPattern/PresentationLayer/screens/LoginScreen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // ignore: close_sinks
  final loginListingBloc = LoginListingBloc(loginRepository: LoginRepository());

  @override
  Widget build(BuildContext context) {
    loginListingBloc.add(LoginCheckEvent());
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'OpenSans',
        primarySwatch: Colors.grey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: BlocProvider(
        create: (context) => loginListingBloc,
        child: BlocBuilder<LoginListingBloc, LoginListingState>(
          builder: (ctx, state) {
            if (state is LoginState) {
              return MainScreen();
            }
            return LoginScreen();
          },
        ),
      ),
      routes: { 
      "/mainSc": (ctx) => MainScreen()},
    );
  }
}
