import 'package:flutter/material.dart';

class CustomRoute<T> extends MaterialPageRoute<T> {
  CustomRoute({WidgetBuilder builder, RouteSettings settings})
      : super(builder: builder, settings: settings);

    //animacion de las transiciones entre paginas 
  @override
  Widget buildTransitions(
       BuildContext context, 
       Animation<double> animation, 
       Animation<double> secondaryAnimation, 
       Widget child) {
    
    if(settings.name == '/'){
      return child;
    }

    return FadeTransition(opacity: animation, child: child);
  }  
}

class CustomePageTransitionBuilder extends PageTransitionsBuilder {
     //animacion de las transiciones entre paginas 
  @override
  Widget buildTransitions<T>(
        PageRoute<T> route,
       BuildContext context, 
       Animation<double> animation, 
       Animation<double> secondaryAnimation, 
       Widget child) {
    
    if(route.settings.name == '/'){
      return child;
    }

    return FadeTransition(opacity: animation, child: child);
  }  
}
